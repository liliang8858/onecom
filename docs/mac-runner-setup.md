下面是 **Mac self-hosted runner 的具体配置步骤**。你按这个做，就能让 GitHub Actions 把 iOS 打包任务派发到你这台 Mac 上。

---

# 0. 先确认你的 Mac 适合作为 runner

GitHub self-hosted runner 是你自己管理的一台机器，用来执行 GitHub Actions workflow jobs；macOS 需要 **macOS 11 Big Sur 或以上**，机器需要能访问 GitHub Actions，并有足够资源执行你的构建任务。([GitHub Docs][1])

iOS 打包建议：

```text
Mac 机型：Mac mini / MacBook / iMac 都可以
系统：macOS 11+
Xcode：安装正式版 Xcode
网络：能访问 github.com、api.github.com、*.actions.githubusercontent.com
用途：只跑你自己的私有仓库
```

GitHub 官方建议 self-hosted runner 尽量只用于私有仓库，因为公开仓库的 fork PR 有可能让不可信代码跑到你的机器上。([GitHub Docs][2])

---

# 1. Mac 上创建专用用户

建议单独建一个 macOS 用户：

```text
用户名：ci
用途：只给 GitHub Actions runner 和 iOS 打包用
```

这样证书、keychain、Xcode 缓存、构建目录都集中在这个用户下面，后面排查签名问题会简单很多。

切到这个用户后，打开终端。

---

# 2. 安装基础环境

在 Mac 上执行：

```bash
xcodebuild -version
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

安装 Homebrew：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

安装常用工具：

```bash
brew install git ruby
gem install bundler
```

如果你的 iOS 项目用 CocoaPods：

```bash
gem install cocoapods
```

如果用 fastlane：

```bash
gem install fastlane
```

确认：

```bash
git --version
ruby -v
bundle -v
fastlane --version
xcodebuild -version
```

---

# 3. 关闭 Mac 睡眠

CI 机器不能睡眠：

```bash
sudo pmset -a sleep 0
sudo pmset -a disksleep 0
sudo pmset -a displaysleep 10
```

建议同时设置：

```text
系统设置 → 电池 / 节能 → 防止自动睡眠
系统设置 → 锁定屏幕 → 不要太快锁屏
系统设置 → 网络 → 保持 Wi-Fi / 有线网络稳定
```

如果是 MacBook，建议长期接电使用。

---

# 4. 在 GitHub 仓库里创建 self-hosted runner

进入你的 GitHub 总仓库：

```text
Repository → Settings → Actions → Runners → New self-hosted runner
```

选择：

```text
Operating system: macOS
Architecture: ARM64  # Apple Silicon, M1/M2/M3/M4
或
Architecture: x64    # Intel Mac
```

GitHub 页面会生成专属的下载和注册命令。官方流程就是：选择系统和架构，然后在 runner 机器上按页面给出的命令下载 runner、解压、运行 `config` 脚本注册；注册 token 是自动生成且有时效的。([GitHub Docs][2])

---

# 5. 在 Mac 上安装 runner

下面命令是模板，**真正的下载地址和 token 用 GitHub 页面给你的**。

Apple Silicon Mac：

```bash
mkdir -p ~/actions-runner
cd ~/actions-runner

curl -o actions-runner-osx-arm64.tar.gz -L "GitHub页面给你的runner下载地址"

tar xzf actions-runner-osx-arm64.tar.gz
```

Intel Mac：

```bash
mkdir -p ~/actions-runner
cd ~/actions-runner

curl -o actions-runner-osx-x64.tar.gz -L "GitHub页面给你的runner下载地址"

tar xzf actions-runner-osx-x64.tar.gz
```

---

# 6. 注册 runner

在 `~/actions-runner` 目录执行：

```bash
./config.sh \
  --url https://github.com/你的GitHub用户名或组织名/你的总仓库 \
  --token GitHub页面给你的TOKEN \
  --name mac-ios-builder-01 \
  --labels macOS,ios-builder,xcode,fastlane \
  --work _work
```

我建议你的标签这样设计：

```text
macOS
ios-builder
xcode
fastlane
```

GitHub self-hosted runner 会自动带有默认标签，比如 `self-hosted`、`macOS`、`x64` 或 `ARM64`；你也可以在注册时通过 `--labels` 加自定义标签。workflow 里的 `runs-on` 会要求 runner 同时满足这些标签。([GitHub Docs][3])

---

# 7. 先手动启动一次测试

```bash
cd ~/actions-runner
./run.sh
```

如果成功，你会看到类似：

```text
√ Connected to GitHub
Listening for Jobs
```

GitHub 官方也说明，runner 应用必须处于 active 状态才能接收 job，连接成功后会显示 `Connected to GitHub` 和 `Listening for Jobs`。([GitHub Docs][2])

这时去 GitHub：

```text
Repository → Settings → Actions → Runners
```

应该能看到：

```text
mac-ios-builder-01
Status: Idle
Labels: self-hosted, macOS, ARM64, ios-builder, xcode, fastlane
```

---

# 8. 配置为开机自启动服务

手动 `./run.sh` 只适合测试。正式使用要装成 macOS 服务。

先停止刚才的 `./run.sh`，然后在 `~/actions-runner` 目录执行：

```bash
./svc.sh install
./svc.sh start
./svc.sh status
```

GitHub 官方说明，self-hosted runner 可以配置成服务，让 runner application 在机器启动时自动启动；macOS 上使用 runner 目录里的 `svc.sh` 管理服务。([GitHub Docs][4])

常用命令：

```bash
cd ~/actions-runner

./svc.sh status
./svc.sh stop
./svc.sh start
./svc.sh uninstall
```

如果命令提示需要权限，再加 `sudo`：

```bash
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

---

# 9. 在 workflow 里指定这台 Mac

在你的 GitHub 仓库里创建：

```text
.github/workflows/test-mac-runner.yml
```

内容：

```yaml
name: Test Mac Runner

on:
  workflow_dispatch:

jobs:
  test:
    runs-on: [self-hosted, macOS, ios-builder]

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Show machine info
        run: |
          whoami
          hostname
          sw_vers
          uname -m
          xcodebuild -version

      - name: Show working directory
        run: |
          pwd
          ls -la
```

然后到 GitHub：

```text
Actions → Test Mac Runner → Run workflow
```

如果跑成功，说明 Mac runner 已经接入成功。

`runs-on: [self-hosted, macOS, ios-builder]` 的意思是：这个 job 只能跑在同时拥有这些标签的在线空闲 runner 上；GitHub 会查找匹配 `runs-on` labels 的 runner，找不到就排队等待。([GitHub Docs][1])

---

# 10. 改成你的 iOS 打包 workflow

测试成功后，把正式打包 workflow 里的 runner 写成：

```yaml
runs-on: [self-hosted, macOS, ios-builder]
```

比如：

```yaml
name: iOS Build

on:
  push:
    branches:
      - main
      - develop
    tags:
      - "ios/*/v*"
  workflow_dispatch:

jobs:
  build-ios:
    runs-on: [self-hosted, macOS, ios-builder]

    timeout-minutes: 90

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

      - name: Show versions
        run: |
          whoami
          xcodebuild -version
          ruby -v
          bundle -v

      - name: Install dependencies
        run: bundle install

      - name: Build
        env:
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          APP_STORE_CONNECT_API_KEY_ID: ${{ secrets.APP_STORE_CONNECT_API_KEY_ID }}
          APP_STORE_CONNECT_API_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_API_ISSUER_ID }}
          APP_STORE_CONNECT_API_KEY_CONTENT: ${{ secrets.APP_STORE_CONNECT_API_KEY_CONTENT }}
        run: bundle exec fastlane ios monorepo_build
```

---

# 11. 配置 GitHub Secrets

进入：

```text
Repository → Settings → Secrets and variables → Actions → New repository secret
```

建议添加：

```text
MATCH_PASSWORD
APP_STORE_CONNECT_API_KEY_ID
APP_STORE_CONNECT_API_ISSUER_ID
APP_STORE_CONNECT_API_KEY_CONTENT
```

如果证书仓库是私有仓库，Mac 本地还要配置 SSH key：

```bash
ssh-keygen -t ed25519 -C "mac-ios-ci"
cat ~/.ssh/id_ed25519.pub
```

把 public key 加到 GitHub：

```text
GitHub → Settings → SSH and GPG keys
```

或者加到证书仓库的 Deploy Key。

测试：

```bash
ssh -T git@github.com
```

---

# 12. Mac runner 的目录和缓存位置

runner 会在这里工作：

```text
~/actions-runner/_work/
```

每次 job 大概会放到：

```text
~/actions-runner/_work/你的仓库名/你的仓库名/
```

Xcode 缓存一般在：

```text
~/Library/Developer/Xcode/DerivedData
```

Archives 一般在：

```text
~/Library/Developer/Xcode/Archives
```

建议定期清理：

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Developer/Xcode/Archives/*
```

也可以每周清理一次：

```bash
crontab -e
```

加入：

```cron
0 3 * * 0 rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

---

# 13. 常见问题排查

## 1. GitHub 页面显示 runner Offline

在 Mac 上检查：

```bash
cd ~/actions-runner
./svc.sh status
```

重启：

```bash
./svc.sh stop
./svc.sh start
```

看日志：

```bash
ls -la ~/actions-runner/_diag
tail -n 100 ~/actions-runner/_diag/*.log
```

检查网络：

```bash
curl -I https://github.com
curl -I https://api.github.com
```

GitHub self-hosted runner 需要能对外访问 GitHub 相关域名，并通过 HTTPS 443 通信。([GitHub Docs][1])

---

## 2. Workflow 一直 Queued

通常是标签不匹配。

workflow 写了：

```yaml
runs-on: [self-hosted, macOS, ios-builder]
```

那么 GitHub runner 页面里必须看到这几个标签：

```text
self-hosted
macOS
ios-builder
```

注意：标签组合是累加条件，runner 必须同时满足所有标签才会被分配 job。([GitHub Docs][3])

---

## 3. 能启动但 iOS 打包失败

优先查这几个：

```bash
xcodebuild -version
xcode-select -p
security find-identity -v -p codesigning
```

常见原因：

```text
Xcode 没选对
Xcode license 没接受
证书不在当前 ci 用户 keychain
provisioning profile 不匹配
scheme 没有 shared
runner 服务不是用 ci 用户运行
```

---

## 4. 证书签名报 `User interaction is not allowed`

说明 keychain 没被 CI 正确解锁，或者证书装在了另一个 macOS 用户下面。

建议：

```text
runner 用 ci 用户运行
证书也装在 ci 用户的 keychain
fastlane 里使用 setup_ci
match 用 readonly: true
```

---

# 14. 推荐你的最终配置

你的场景建议这样定：

```text
Runner 类型：Repository-level runner
Runner 名称：mac-ios-builder-01
Runner 用户：macOS ci 用户
Runner 标签：macOS, ios-builder, xcode, fastlane
Workflow runs-on：[self-hosted, macOS, ios-builder]
并发：max-parallel: 1
仓库：私有 GitHub monorepo
```

注册命令大概是：

```bash
cd ~/actions-runner

./config.sh \
  --url https://github.com/你的账号/你的总仓库 \
  --token GitHub页面给你的TOKEN \
  --name mac-ios-builder-01 \
  --labels macOS,ios-builder,xcode,fastlane \
  --work _work

./svc.sh install
./svc.sh start
./svc.sh status
```

跑通验证 workflow 后，这台 Mac 就正式变成你的 iOS 云端打包机了。

[1]: https://docs.github.com/en/actions/reference/runners/self-hosted-runners "Self-hosted runners reference - GitHub Docs"
[2]: https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/add-runners "Adding self-hosted runners - GitHub Docs"
[3]: https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/use-in-a-workflow "Using self-hosted runners in a workflow - GitHub Docs"
[4]: https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/configure-the-application "Configuring the self-hosted runner application as a service - GitHub Docs"
