可以，建议按 **Monorepo 自动发现子项目 + 动态 Matrix 构建** 来做。

核心思路是：

```text
一个 GitHub 总仓库
├── apps/
│   ├── app-a/
│   │   ├── ios/
│   │   └── ci/ios.json
│   ├── app-b/
│   │   ├── ios/
│   │   └── ci/ios.json
│   └── app-c/
│       ├── ios/
│       └── ci/ios.json
├── shared/
├── ci/
│   └── discover_ios_projects.py
├── fastlane/
│   └── Fastfile
└── .github/workflows/ios-monorepo-build.yml
```

以后新增子项目时，只要新增：

```text
apps/new-app/ci/ios.json
```

CI 每次运行时会扫描这个文件，自动把新项目加入打包队列。GitHub Actions 支持用上一个 job 的输出动态生成 matrix，后续 job 可以用 `fromJSON(...)` 读取这个 matrix 并生成多项目构建任务；这正好适合 monorepo 的动态子项目发现。([GitHub Docs][1])

---

# 1. 推荐仓库结构

```text
your-monorepo/
├── apps/
│   ├── shop/
│   │   ├── ios/
│   │   │   ├── Shop.xcworkspace
│   │   │   ├── Shop.xcodeproj
│   │   │   └── ...
│   │   └── ci/
│   │       └── ios.json
│   │
│   ├── driver/
│   │   ├── ios/
│   │   │   ├── Driver.xcworkspace
│   │   │   └── ...
│   │   └── ci/
│   │       └── ios.json
│   │
├── shared/
├── ci/
│   └── discover_ios_projects.py
├── fastlane/
│   ├── Fastfile
│   └── Matchfile
├── Gemfile
└── .github/
    └── workflows/
        └── ios-monorepo-build.yml
```

这个设计里，**每个子项目自己声明如何打包**，总仓库只负责发现和调度。

---

# 2. 每个子项目放一个 `ios.json`

例如：

```text
apps/shop/ci/ios.json
```

内容：

```json
{
  "id": "shop",
  "name": "Shop iOS",
  "project_path": "apps/shop/ios",
  "workspace": "Shop.xcworkspace",
  "scheme": "Shop",
  "configuration": "Release",
  "export_method": "app-store",
  "bundle_id": "com.yourcompany.shop",
  "dependency": "cocoapods",
  "upload": "testflight"
}
```

另一个项目：

```text
apps/driver/ci/ios.json
```

```json
{
  "id": "driver",
  "name": "Driver iOS",
  "project_path": "apps/driver/ios",
  "workspace": "Driver.xcworkspace",
  "scheme": "Driver",
  "configuration": "Release",
  "export_method": "app-store",
  "bundle_id": "com.yourcompany.driver",
  "dependency": "spm",
  "upload": "testflight"
}
```

这里的 `id` 很重要。以后可以用 tag 控制单项目发布：

```bash
git tag ios/shop/v1.0.0
git push origin ios/shop/v1.0.0
```

表示只发布 `shop`。

---

# 3. 自动发现脚本

新建：

```text
ci/discover_ios_projects.py
```

内容如下：

```python
#!/usr/bin/env python3

import json
import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APPS_DIR = ROOT / "apps"

SHARED_PATH_PREFIXES = [
    "shared/",
    "packages/",
    "ci/",
    "fastlane/",
    "Gemfile",
    "Gemfile.lock",
    ".github/workflows/ios-monorepo-build.yml"
]


def run(cmd):
    return subprocess.check_output(cmd, cwd=ROOT, text=True).strip()


def load_projects():
    projects = []

    for config_path in sorted(APPS_DIR.glob("*/ci/ios.json")):
        with open(config_path, "r", encoding="utf-8") as f:
            cfg = json.load(f)

        required = [
            "id",
            "project_path",
            "scheme",
            "configuration",
            "export_method",
            "bundle_id"
        ]

        missing = [key for key in required if not cfg.get(key)]
        if missing:
            raise RuntimeError(f"{config_path} missing required keys: {missing}")

        cfg["config_path"] = str(config_path.relative_to(ROOT))
        cfg["app_root"] = str(config_path.parents[1].relative_to(ROOT))
        projects.append(cfg)

    return projects


def get_changed_files():
    base_sha = os.environ.get("BASE_SHA", "").strip()
    head_sha = os.environ.get("HEAD_SHA", "").strip()

    if not base_sha or not head_sha:
        return None

    if set(base_sha) == {"0"}:
        return None

    try:
        output = run(["git", "diff", "--name-only", base_sha, head_sha])
        return [line.strip() for line in output.splitlines() if line.strip()]
    except Exception:
        return None


def has_shared_change(changed_files):
    if changed_files is None:
        return True

    for file in changed_files:
        for prefix in SHARED_PATH_PREFIXES:
            if file == prefix or file.startswith(prefix):
                return True

    return False


def project_changed(project, changed_files):
    if changed_files is None:
        return True

    app_root = project["app_root"].rstrip("/") + "/"
    project_path = project["project_path"].rstrip("/") + "/"

    return any(
        file.startswith(app_root) or file.startswith(project_path)
        for file in changed_files
    )


def select_projects(projects):
    event_name = os.environ.get("EVENT_NAME", "")
    ref_name = os.environ.get("REF_NAME", "")
    manual_project = os.environ.get("MANUAL_PROJECT", "").strip()

    # 手动触发：指定项目或 all
    if event_name == "workflow_dispatch":
        if manual_project and manual_project != "all":
            return [p for p in projects if p["id"] == manual_project]
        return projects

    # tag 触发：ios/shop/v1.0.0 只打 shop
    if ref_name.startswith("ios/"):
        parts = ref_name.split("/")
        if len(parts) >= 3:
            project_id = parts[1]
            return [p for p in projects if p["id"] == project_id]

    # 普通 push：只打发生变化的项目；shared/ci/fastlane 改动则全量打
    changed_files = get_changed_files()

    if has_shared_change(changed_files):
        return projects

    return [p for p in projects if project_changed(p, changed_files)]


def main():
    projects = load_projects()
    selected = select_projects(projects)

    matrix = {
        "include": selected
    }

    print(json.dumps(matrix, ensure_ascii=False, indent=2))

    github_output = os.environ.get("GITHUB_OUTPUT")
    if github_output:
        with open(github_output, "a", encoding="utf-8") as f:
            f.write(f"matrix={json.dumps(matrix, ensure_ascii=False)}\n")
            f.write(f"count={len(selected)}\n")


if __name__ == "__main__":
    main()
```

这个脚本负责三件事：

```text
1. 扫描 apps/*/ci/ios.json
2. 判断本次 commit 改了哪些子项目
3. 输出 GitHub Actions matrix
```

所以新增子项目时，Mac 不需要改配置。只要仓库里出现新的 `apps/xxx/ci/ios.json`，下一次 CI 就能发现它。

---

# 4. 总 Fastfile

新建或修改：

```text
fastlane/Fastfile
```

示例：

```ruby
default_platform(:ios)

platform :ios do
  desc "Build one iOS project from monorepo matrix"
  lane :monorepo_build do
    setup_ci

    project_id = ENV.fetch("PROJECT_ID")
    project_path = ENV.fetch("PROJECT_PATH")
    workspace = ENV["WORKSPACE_NAME"]
    xcodeproj = ENV["XCODEPROJ_NAME"]
    scheme = ENV.fetch("SCHEME_NAME")
    configuration = ENV.fetch("CONFIGURATION")
    export_method = ENV.fetch("EXPORT_METHOD")
    bundle_id = ENV.fetch("BUNDLE_ID")
    dependency = ENV["DEPENDENCY"]
    upload_target = ENV["UPLOAD_TARGET"]

    api_key = nil

    if upload_target == "testflight"
      api_key = app_store_connect_api_key(
        key_id: ENV["APP_STORE_CONNECT_API_KEY_ID"],
        issuer_id: ENV["APP_STORE_CONNECT_API_ISSUER_ID"],
        key_content: ENV["APP_STORE_CONNECT_API_KEY_CONTENT"],
        is_key_content_base64: false
      )
    end

    match(
      type: "appstore",
      app_identifier: bundle_id,
      readonly: true
    )

    Dir.chdir(project_path) do
      if dependency == "cocoapods"
        sh("bundle exec pod install || pod install")
      end
    end

    build_number = ENV["GITHUB_RUN_NUMBER"] || Time.now.strftime("%Y%m%d%H%M")

    increment_build_number(
      build_number: build_number,
      xcodeproj: xcodeproj ? File.join(project_path, xcodeproj) : nil
    )

    output_dir = File.join("build", project_id)

    build_options = {
      scheme: scheme,
      configuration: configuration,
      export_method: export_method,
      clean: true,
      output_directory: output_dir,
      output_name: "#{project_id}.ipa"
    }

    if workspace && !workspace.empty?
      build_options[:workspace] = File.join(project_path, workspace)
    elsif xcodeproj && !xcodeproj.empty?
      build_options[:project] = File.join(project_path, xcodeproj)
    else
      UI.user_error!("Either workspace or xcodeproj must be provided for #{project_id}")
    end

    build_app(build_options)

    if upload_target == "testflight"
      upload_to_testflight(
        api_key: api_key,
        ipa: File.join(output_dir, "#{project_id}.ipa"),
        skip_waiting_for_build_processing: true
      )
    end
  end
end
```

`fastlane build_app` 支持通过 `export_method`、`export_team_id`、`include_symbols` 等参数控制 Xcode 导出选项，适合把不同子项目的打包参数从配置文件传进来。([Fastlane Docs][2])

---

# 5. GitHub Actions workflow

新建：

```text
.github/workflows/ios-monorepo-build.yml
```

内容：

```yaml
name: iOS Monorepo CI/CD

on:
  push:
    branches:
      - main
      - develop
    tags:
      - "ios/*/v*"
  workflow_dispatch:
    inputs:
      project:
        description: "Project id to build, or all"
        required: true
        default: "all"

concurrency:
  group: ios-monorepo-${{ github.ref }}
  cancel-in-progress: true

jobs:
  discover:
    name: Discover iOS projects
    runs-on: ubuntu-latest

    outputs:
      matrix: ${{ steps.discover.outputs.matrix }}
      count: ${{ steps.discover.outputs.count }}

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Discover changed iOS projects
        id: discover
        env:
          BASE_SHA: ${{ github.event.before }}
          HEAD_SHA: ${{ github.sha }}
          EVENT_NAME: ${{ github.event_name }}
          REF_NAME: ${{ github.ref_name }}
          MANUAL_PROJECT: ${{ github.event.inputs.project }}
        run: python3 ci/discover_ios_projects.py

  build:
    name: Build ${{ matrix.id }}
    needs: discover

    if: needs.discover.outputs.count != '0'

    runs-on: [self-hosted, macOS, ios-builder]

    strategy:
      fail-fast: false
      max-parallel: 1
      matrix: ${{ fromJSON(needs.discover.outputs.matrix) }}

    timeout-minutes: 90

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Show build target
        run: |
          echo "Project: ${{ matrix.id }}"
          echo "Path: ${{ matrix.project_path }}"
          echo "Scheme: ${{ matrix.scheme }}"
          echo "Bundle ID: ${{ matrix.bundle_id }}"

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

      - name: Install Ruby dependencies
        run: bundle install

      - name: Build project
        env:
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}

          APP_STORE_CONNECT_API_KEY_ID: ${{ secrets.APP_STORE_CONNECT_API_KEY_ID }}
          APP_STORE_CONNECT_API_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_API_ISSUER_ID }}
          APP_STORE_CONNECT_API_KEY_CONTENT: ${{ secrets.APP_STORE_CONNECT_API_KEY_CONTENT }}

          PROJECT_ID: ${{ matrix.id }}
          PROJECT_PATH: ${{ matrix.project_path }}
          WORKSPACE_NAME: ${{ matrix.workspace }}
          XCODEPROJ_NAME: ${{ matrix.xcodeproj }}
          SCHEME_NAME: ${{ matrix.scheme }}
          CONFIGURATION: ${{ matrix.configuration }}
          EXPORT_METHOD: ${{ matrix.export_method }}
          BUNDLE_ID: ${{ matrix.bundle_id }}
          DEPENDENCY: ${{ matrix.dependency }}
          UPLOAD_TARGET: ${{ matrix.upload }}
        run: bundle exec fastlane ios monorepo_build

      - name: Upload ipa artifact
        uses: actions/upload-artifact@v4
        with:
          name: ${{ matrix.id }}-ipa
          path: build/${{ matrix.id }}/*.ipa
```

这里 `runs-on: [self-hosted, macOS, ios-builder]` 会把真正的打包任务路由到你的 Mac。GitHub 的 self-hosted runner 可以通过 label 管理和路由任务，所以建议给这台 Mac 加上 `ios-builder` 标签。([GitHub Docs][3])

`max-parallel: 1` 很重要。你现在只有一台 Mac，不建议同时跑多个 iOS archive，容易出现 Xcode、keychain、DerivedData、签名资源抢占问题。GitHub Actions 的 matrix 支持 `max-parallel` 控制并发数量。([GitHub Docs][1])

---

# 6. 新增子项目的标准流程

以后新增一个项目，比如 `customer`：

```text
apps/customer/
├── ios/
│   ├── Customer.xcworkspace
│   └── Customer.xcodeproj
└── ci/
    └── ios.json
```

`apps/customer/ci/ios.json`：

```json
{
  "id": "customer",
  "name": "Customer iOS",
  "project_path": "apps/customer/ios",
  "workspace": "Customer.xcworkspace",
  "scheme": "Customer",
  "configuration": "Release",
  "export_method": "app-store",
  "bundle_id": "com.yourcompany.customer",
  "dependency": "cocoapods",
  "upload": "testflight"
}
```

然后提交：

```bash
git add apps/customer
git commit -m "feat: add customer ios app"
git push origin develop
```

CI 会自动：

```text
扫描 apps/*/ci/ios.json
→ 发现 customer
→ 判断 customer 发生变化
→ 生成 matrix
→ Mac runner 打包 customer
```

---

# 7. 发布某个子项目

建议用 tag 规范：

```text
ios/{project_id}/v{version}
```

例如：

```bash
git tag ios/shop/v1.2.0
git push origin ios/shop/v1.2.0
```

CI 会解析：

```text
REF_NAME = ios/shop/v1.2.0
project_id = shop
```

然后只打 `shop`。

发布 `driver`：

```bash
git tag ios/driver/v2.0.0
git push origin ios/driver/v2.0.0
```

---

# 8. push 分支时只打改动项目

比如这次只改了：

```text
apps/shop/ios/LoginViewController.swift
```

CI 只打：

```text
shop
```

比如改了：

```text
shared/network/ApiClient.swift
```

CI 会打全部项目，因为共享代码可能影响所有 app：

```text
shop
driver
customer
...
```

这个判断逻辑在 `SHARED_PATH_PREFIXES` 里控制：

```python
SHARED_PATH_PREFIXES = [
    "shared/",
    "packages/",
    "ci/",
    "fastlane/",
    "Gemfile",
    "Gemfile.lock",
    ".github/workflows/ios-monorepo-build.yml"
]
```

后面你可以根据实际结构调整。

---

# 9. 证书和 Bundle ID 怎么处理

Monorepo 多子项目时，每个 app 通常都有独立的：

```text
Bundle ID
Provisioning Profile
App Store Connect App
Scheme
Team 配置
```

但是它们可以共用同一个 Apple Developer Team 的 distribution certificate。

建议仍然用 `fastlane match`。每个子项目的 `bundle_id` 从 `ios.json` 传入：

```ruby
match(
  type: "appstore",
  app_identifier: bundle_id,
  readonly: true
)
```

这里要注意：**CI 里建议 `readonly: true`**。也就是说，CI 只拉取已经准备好的证书和 profile，不在自动打包过程中偷偷创建或修改证书。这样更安全、更可控。

新增子项目时，第一次需要管理员在 Mac 或本机执行一次签名初始化，例如：

```bash
bundle exec fastlane match appstore -a com.yourcompany.customer
```

然后再提交子项目配置。这样 CI 第一次构建时就能拉到正确的 profile。

---

# 10. Mac 怎么“感知”新项目

严格说，不是 Mac 主动感知，而是 GitHub Actions 每次运行时做这个流程：

```text
1. GitHub 收到 push/tag/manual 触发
2. discover job checkout 总仓库
3. discover_ios_projects.py 扫描 apps/*/ci/ios.json
4. 输出动态 matrix
5. build job 被派发给 Mac self-hosted runner
6. Mac 根据 matrix 逐个项目打包
```

这个机制比让 Mac 常驻扫描文件夹更稳定。

---

# 11. 完整自动化策略建议

我建议你这样分层：

| 触发方式                             | 行为                         |
| -------------------------------- | -------------------------- |
| `push develop`                   | 只打发生变化的子项目，验证能否编译          |
| `push main`                      | 只打发生变化的子项目，生成 ipa artifact |
| `tag ios/shop/v1.2.0`            | 只打 `shop` 并上传 TestFlight   |
| `workflow_dispatch project=all`  | 手动全量打包                     |
| `workflow_dispatch project=shop` | 手动只打 `shop`                |

这样新增子项目也简单：

```text
新增 apps/xxx/ci/ios.json
→ push
→ 自动发现
→ 自动打包
```

---

# 12. 我推荐的最终方案

你这个需求最适合用这套模式：

```text
GitHub 单仓库 monorepo
+ apps/*/ci/ios.json 作为子项目声明
+ discover_ios_projects.py 自动扫描项目
+ GitHub Actions 动态 matrix
+ self-hosted Mac runner 执行打包
+ fastlane 统一打包和上传 TestFlight
+ tag ios/{project}/v{version} 控制单项目发布
```

这样以后新增子项目不需要改 Mac，也不需要改 workflow 主逻辑。只要子项目按规范加配置文件，CI/CD 就能自动纳管。

[1]: https://docs.github.com/zh/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations "在工作流中运行作业变体 - GitHub 文档"
[2]: https://docs.fastlane.tools/actions/build_app/ "build_app - fastlane docs"
[3]: https://docs.github.com/actions/how-tos/manage-runners/self-hosted-runners/apply-labels "Using labels with self-hosted runners - GitHub Docs"
