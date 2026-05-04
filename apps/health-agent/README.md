# Health Agent iOS

Health Agent 是一个围绕 Apple Health 连续健康数据和 ECG 心电增强智能构建的 iOS App。

它不是传统健康 Dashboard。它的首页应从 `Today Health Home` 开始，先告诉用户“今天身体状态怎么样”，再把值得关注的问题、Agent 发现和深度分析路径组织起来。

## 产品定义

正式定位：

```text
Health Agent with ECG Intelligence
```

中文定义：

> 一个以 Apple Health 连续健康数据为底座、以 ECG 心电作为关键事件增强证据的智能健康 Agent App。

日常 Apple Health 数据负责回答：

- 我今天怎么样？
- 为什么今天状态这样？
- 最近什么指标变了？
- 我现在最应该关注什么？

ECG 在有数据时提供增强解释：

- 最新一次 ECG 显示了什么？
- 这次 ECG 和上次有什么不同？
- 这次 ECG 前后发生了什么？
- 这次心脏相关信号是否和睡眠、恢复、运动负荷或症状有关？

## 核心体验

- Today Health Home 今日健康首页
- Agent 生成的洞察按钮
- 动态 SwiftUI 分析页
- Apple Health 连续数据分析
- ECG 增强事件解释
- 隐私优先的本地健康数据处理

## MVP 范围

- 今日状态概览
- 恢复状态分析
- 睡眠分析
- 本周状态解释
- 异常中心
- 心脏状态分析，存在 ECG 时自动增强
- 最新 ECG 解读，仅在 ECG 数据存在时出现

## 目录结构

```text
apps/health-agent/
  README.md
  ci/
    ios.json
  ios/
    README.md
  product/
    prd.md
    ui-spec.md
    agent-schema.md
    health-data-model.md
```

## iOS 工程

目标 Xcode 工程：

- Product Name：`HealthAgent`
- Interface：SwiftUI
- Language：Swift
- Bundle Identifier：`com.yourcompany.healthagent`
- 依赖管理：Swift Package Manager

真实 Xcode 工程需要在 macOS 上创建，并放入：

```text
apps/health-agent/ios/
```

当前已提供 `apps/health-agent/ios/project.yml`，可在 Mac 上用 XcodeGen 生成 `HealthAgent.xcodeproj`。

当前 CI 中 `upload` 设置为 `none`。等 Bundle ID、签名、App Store Connect App 和 TestFlight 都准备好后，再切换为 `testflight`。
