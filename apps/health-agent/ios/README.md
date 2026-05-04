# HealthAgent iOS 工程目录

这个目录用于放置真实的 Xcode 工程。

请在 macOS 上用 Xcode 创建项目：

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

当前 CI 配置指向：

- Workspace：`HealthAgent.xcworkspace`
- Xcode Project：`HealthAgent.xcodeproj`
- Scheme：`HealthAgent`

第一次接入 CI 前，请确认：

- Scheme 已设置为 shared
- 工程文件已提交到仓库
- Bundle ID 与 `apps/health-agent/ci/ios.json` 保持一致
- 如果启用 TestFlight，证书、profile、App Store Connect App 已准备好
