# OneCom 项目记忆

更新时间：2026-05-03

## 全局语言规则

第一规则：可以在英文环境下思考，但所有面向用户的输出必须使用中文。

这条规则属于 Codex 全局协作记忆，只保存在本文件中，不需要散落写入每一份业务文档或产品文档。

## 项目定位

OneCom 是一个面向多 iOS 应用的 monorepo 方案。核心目标是把多个 iOS App 放在同一个 GitHub 仓库中统一管理，并通过配置驱动的 CI/CD 自动发现、构建、签名和发布。

项目设计口号可以概括为：

> 一个仓库，一套流程，N 个应用。

新增应用的理想成本是：提交 `apps/<app-name>/ci/ios.json`，不需要修改 GitHub Actions 主流程、Fastlane 主 lane 或 Mac runner 配置。

## 当前仓库实际状态

当前仓库已经提交并维护的核心文件包括：

- `README.md`
- `CLAUDE.md`
- `docs/ios-monorepo-ci.md`
- `docs/mac-runner-setup.md`
- `apps/health-agent/README.md`
- `apps/health-agent/ci/ios.json`
- `apps/health-agent/ios/README.md`
- `apps/health-agent/product/prd.md`
- `apps/health-agent/product/ui-spec.md`
- `apps/health-agent/product/agent-schema.md`
- `apps/health-agent/product/health-data-model.md`

当前存在目录：

- `apps/`
- `docs/`

`apps/health-agent/` 已作为第一个子 app 初始化。文档中提到的根级 `shared/`、`ci/`、`fastlane/`、`.github/workflows/`、`Gemfile` 等，目前还没有实际落地到仓库。

因此当前项目更准确地说是：已经有第一个产品子项目和 CI manifest 的 iOS monorepo 方案仓库，但尚未生成可运行的根级 CI/CD 工程骨架，也尚未加入真实 Xcode 工程。

## 已初始化子项目：Health Agent

第一个子项目路径：

```text
apps/health-agent/
```

产品正式定义：

> Health Agent with ECG Intelligence：一个以 Apple Health 连续健康数据为底座、以 ECG 心电作为关键事件增强证据的智能健康 Agent App。

核心定位：

- 不是普通健康 Dashboard。
- 首页应是 `Today Health Home`，先回答“我今天怎么样”。
- 主体验顺序是：今日状态 → Agent 发现 → 健康模块 → 智能问题 → 深度分析。
- Apple Health 连续数据负责日常监测、趋势、恢复、睡眠、运动、异常和周报。
- ECG 不是所有分析的必要入口，而是关键事件的增强证据和心脏深度解释层。
- Agent 不动态生成 iOS 代码，只生成 UI Schema，由 App 端白名单 SwiftUI 组件渲染。

Health Agent 的 CI manifest：

```text
apps/health-agent/ci/ios.json
```

当前配置：

- `id`: `health-agent`
- `name`: `Health Agent iOS`
- `project_path`: `apps/health-agent/ios`
- `workspace`: `HealthAgent.xcworkspace`
- `xcodeproj`: `HealthAgent.xcodeproj`
- `scheme`: `HealthAgent`
- `bundle_id`: `com.yourcompany.healthagent`
- `dependency`: `spm`
- `upload`: `none`

注意：当前 `apps/health-agent/ios/` 只有说明文件，真实 `HealthAgent.xcodeproj` / `HealthAgent.xcworkspace` 需要在 macOS Xcode 中创建后放入该目录。现阶段不能直接打包。

2026-05-04 更新：`apps/health-agent/ios/HealthAgent/` 已加入 SwiftUI 源码雏形，包含 App、Features、Components、Agent、Renderer、Models、Resources/Assets.xcassets 等目录。当前仍没有真实 Xcode project/workspace，但源码可迁入 Xcode 工程。

2026-05-04 更新：`apps/health-agent/product/ui/` 已加入视觉系统、高保真 UI 图和 App 图片资产。生成的 UI 图位于 `mockups/`，可用图片资产位于 `assets/`，并已复制到 iOS `Assets.xcassets`。

2026-05-04 更新：根级 CI/CD 骨架已落地，包括 `ci/discover_ios_projects.py`、`.github/workflows/ios-monorepo-build.yml`、`fastlane/Fastfile`、`fastlane/Matchfile`、`Gemfile`。`health-agent` 当前 `upload` 为 `none`，Fastlane 会走无签名 iOS Simulator 构建验证；切到 `testflight` 后才走 match、归档和上传。

2026-05-04 更新：新增 `scripts/validate_health_agent.ps1`，用于校验 Health Agent 的 `ios.json`、Asset Catalog、plist、entitlements、项目发现脚本、Swift 静态危险模式、UI 图数量。新增 `.gitignore`，忽略 Xcode 生成物、DerivedData、Fastlane 构建产物和 Python 缓存。

## 目标仓库结构

文档规划的目标结构如下：

```text
apps/
  <app-name>/
    ios/              # Xcode workspace/project
    ci/ios.json       # 构建清单，CI 自动发现入口
shared/               # 多应用共享代码
ci/
  discover_ios_projects.py
fastlane/
  Fastfile
  Matchfile
Gemfile
.github/workflows/
  ios-monorepo-build.yml
docs/
```

## 子项目配置约定

每个 app 通过 `apps/<app-name>/ci/ios.json` 声明构建信息。关键字段：

- `id`：项目唯一标识，也用于发布 tag，如 `shop`
- `name`：展示名
- `project_path`：iOS 工程目录，如 `apps/shop/ios`
- `workspace` 或 `xcodeproj`：二选一，指向 Xcode workspace/project
- `scheme`：Xcode scheme，必须是 shared scheme
- `configuration`：通常是 `Release`
- `export_method`：通常是 `app-store`
- `bundle_id`：App Bundle ID
- `dependency`：如 `cocoapods` 或 `spm`
- `upload`：如 `testflight`

示例：

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

## CI/CD 设计

CI/CD 采用 GitHub Actions + Dynamic Matrix + self-hosted Mac runner + Fastlane。

流程：

1. GitHub Actions 的 `discover` job 在 Ubuntu runner 上运行。
2. `ci/discover_ios_projects.py` 扫描 `apps/*/ci/ios.json`。
3. 脚本根据事件类型、tag、手动输入和变更文件生成 matrix。
4. `build` job 使用 `fromJSON(...)` 读取 matrix。
5. 真正的 iOS build 派发到 `[self-hosted, macOS, ios-builder]` Mac runner。
6. Fastlane lane `ios monorepo_build` 完成签名、构建和 TestFlight 上传。

## 触发策略

- `push develop`：只构建发生变化的应用，用于日常验证。
- `push main`：构建发生变化的应用，并上传 ipa artifact。
- `tag ios/<app>/v<version>`：只构建指定 app，并上传 TestFlight。
- `workflow_dispatch project=all`：手动全量构建。
- `workflow_dispatch project=<app>`：手动构建指定 app。

发布 tag 约定：

```text
ios/{project_id}/v{version}
```

示例：

```bash
git tag ios/shop/v1.2.0
git push origin ios/shop/v1.2.0
```

## 增量构建规则

普通 push 时：

- 改动 `apps/<app>/` 或该 app 的 `project_path`：只构建对应 app。
- 改动共享或基础设施路径：全量构建所有 app。

文档建议的共享路径前缀：

```python
SHARED_PATH_PREFIXES = [
    "shared/",
    "packages/",
    "ci/",
    "fastlane/",
    "Gemfile",
    "Gemfile.lock",
    ".github/workflows/ios-monorepo-build.yml",
]
```

## Fastlane 约定

目标 lane：

```text
bundle exec fastlane ios monorepo_build
```

lane 从环境变量读取 matrix 传入的配置：

- `PROJECT_ID`
- `PROJECT_PATH`
- `WORKSPACE_NAME`
- `XCODEPROJ_NAME`
- `SCHEME_NAME`
- `CONFIGURATION`
- `EXPORT_METHOD`
- `BUNDLE_ID`
- `DEPENDENCY`
- `UPLOAD_TARGET`

签名使用 `fastlane match`，CI 中应保持：

```ruby
readonly: true
```

这样 CI 只拉取已准备好的证书和 provisioning profile，不在构建过程中创建或修改签名资产。

## Mac Runner 约定

推荐配置：

- 类型：repository-level self-hosted runner
- 名称：`mac-ios-builder-01`
- macOS 用户：单独的 `ci` 用户
- 标签：`macOS`, `ios-builder`, `xcode`, `fastlane`
- workflow `runs-on`：`[self-hosted, macOS, ios-builder]`
- 并发：`max-parallel: 1`

原因：单台 Mac 同时跑多个 iOS archive 容易遇到 Xcode、keychain、DerivedData、签名资源争用问题。

Mac 基础要求：

- macOS 11 Big Sur 或以上
- 正式版 Xcode
- 可访问 `github.com`、`api.github.com`、`*.actions.githubusercontent.com`
- 安装 Git、Ruby、Bundler、Fastlane；如项目使用 CocoaPods，则安装 CocoaPods
- 关闭睡眠，保持网络稳定

## GitHub Secrets

文档要求配置：

- `MATCH_PASSWORD`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_CONTENT`

如果 match 证书仓库是私有仓库，还需要让 Mac runner 的 `ci` 用户具备访问证书仓库的 SSH 权限或 deploy key。

## 重要风险和后续注意事项

- 当前仓库还没有实际 CI 脚本和 workflow，不能直接运行 GitHub Actions 打包。
- `README.md` 和 `docs/` 内容是 UTF-8 中文；PowerShell 默认输出可能出现乱码，读取时建议设置 UTF-8 输出。
- 后续落地时，应优先实现 `ci/discover_ios_projects.py`、`.github/workflows/ios-monorepo-build.yml`、`fastlane/Fastfile`、`Gemfile`。
- 新增真实 iOS app 前，应先确认 Xcode scheme 已 shared，Bundle ID 已在 Apple Developer / App Store Connect 侧准备好。
- 每个新 app 第一次上 CI 前，应由管理员执行一次 `fastlane match appstore -a <bundle_id>` 准备签名。
- CI 中处理 App Store Connect API key 和 match 密码时，必须只通过 GitHub Secrets 注入，不要提交到仓库。

## 我后续处理本项目时的默认判断

- 这是一个配置驱动的 iOS monorepo 自动化项目，不是普通单 app iOS 项目。
- 当前优先级应该是把文档方案变成实际工程骨架。
- 修改时应尽量保持“新增 app 只加 `ios.json`”这个核心抽象。
- CI 发现逻辑应该放在 Python 脚本中，GitHub Actions 只负责调度。
- Fastlane 应该只提供统一 lane，具体 app 差异来自 `ios.json` 和 matrix 环境变量。
- Mac runner 只负责执行构建，不应该承担发现新项目或维护 app 列表的职责。
