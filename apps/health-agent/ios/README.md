# HealthAgent iOS 工程目录

本目录已经包含 Health Agent 的 SwiftUI 源码雏形和图片资产目录，可迁入真实 Xcode 工程。

## 创建真实 Xcode 工程

推荐方式：在 macOS 上用 XcodeGen 生成工程。

```bash
cd apps/health-agent/ios
brew install xcodegen
xcodegen generate
open HealthAgent.xcodeproj
```

也可以手动用 Xcode 创建项目：

- Product Name：`HealthAgent`
- Interface：SwiftUI
- Language：Swift
- Bundle Identifier：`com.yourcompany.healthagent`
- 最低系统：iOS 15+

创建完成后的预期结构：

```text
apps/health-agent/ios/
  HealthAgent.xcodeproj
  HealthAgent.xcworkspace
  HealthAgent/
```

如果使用 XcodeGen，`project.yml` 会生成：

```text
HealthAgent.xcodeproj
```

当前已经准备好的源码目录：

```text
HealthAgent/
  App/
  Features/
  Components/
  Agent/
  Renderer/
  Models/
  Resources/Assets.xcassets/
```

当前 CI 配置指向：

- Workspace：空，当前优先使用 Xcode project
- Xcode Project：`HealthAgent.xcodeproj`
- Scheme：`HealthAgent`

第一次接入 CI 前，请确认：

- Scheme 已设置为 shared
- 工程文件已提交到仓库
- Bundle ID 与 `apps/health-agent/ci/ios.json` 保持一致
- 如果启用 TestFlight，证书、profile、App Store Connect App 已准备好

## 已实现功能

- 今日首页 `TodayView`
- 今日状态 Hero 卡
- Agent 发现卡
- 健康模块卡
- 洞察按钮
- 动态分析页 Renderer
- 恢复分析、睡眠分析、心脏状态、异常中心 mock schema
- ECG 事件卡和 ECG 波形展示
- ECG 详情页
- Onboarding 关注方向选择
- HealthKit 权限引导卡
- HealthKit 数据服务桩和 MockStore
- 探索、心脏、报告、我的基础 Tab

## 图片资产

已接入 `Assets.xcassets`：

- `TodayHeroBackground`
- `ECGWaveformSample`

资产源文件来自：

```text
apps/health-agent/product/ui/assets/
```

## 后续接入

1. 在 Xcode 工程中加入 `HealthAgent/` 下所有 Swift 文件。
2. 确认 `Assets.xcassets` 被加入 target。
3. 先运行 mock 数据版本。
4. 再逐步替换 `MockAgentClient` 为真实 HealthKit 和 Agent 数据。
5. 接入 HealthKit 前，先完成渐进式权限说明和隐私文案。

如果使用 `project.yml`，前两步由 XcodeGen 自动完成。

## 本地结构校验

在仓库根目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\validate_health_agent.ps1
```

该脚本会检查：

- `ios.json`
- Asset Catalog JSON
- `Info.plist`
- HealthKit entitlements
- 项目自动发现脚本
- Swift 静态危险模式
- UI 图和高清图数量

## CI 当前行为

`apps/health-agent/ci/ios.json` 当前为：

```json
"upload": "none"
```

在这个阶段，Fastlane 会执行无签名 iOS Simulator 构建验证：

```text
CODE_SIGNING_ALLOWED=NO
```

这可以在 Team、证书和 TestFlight 未准备好时先验证源码和资源是否能编译。等签名准备完成后，再把 `upload` 改成 `testflight`，并配置 fastlane match 和 App Store Connect secrets。
