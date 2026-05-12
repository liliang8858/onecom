# ADR-001: Health Agent Twin 架构设计

> **状态**：草稿 | **日期**：2025-05-08 | **作者**：OneCom 架构组

---

## 1. 背景与动机

Health Agent Twin 不是传统健康 Dashboard 或聊天机器人，而是一个由云端健康 Agent 驱动的**动态健康画布**。系统根据用户健康数据、当前情境、长期偏好、可控记忆和健康风险等级，动态生成用户此刻最需要的 UI。

PRD v3.0 定义了完整的产品愿景：让用户不再需要频繁依赖 App，因为他们已经通过 App 形成了自己的健康直觉。

## 2. 架构总览

```
┌──────────────────────────────────────────────────────────┐
│                    Health Agent Twin                      │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ┌─────────────┐   ┌──────────────┐   ┌───────────────┐  │
│  │  UI Layer    │◄──│  Schema      │◄──│  Agent        │  │
│  │  (iOS)       │   │  Generator   │   │  (Cloud)      │  │
│  │              │   │              │   │               │  │
│  │ Fixed White- │   │ 动态 UI      │   │ - Intent      │  │
│  │ list Compo-  │   │ Schema JSON  │   │ - Twin Model  │  │
│  │ nents        │   │ + Safety +   │   │ - Memory      │  │
│  │              │   │   Feedback   │   │ - Scoring     │  │
│  └──────┬───────┘   └──────┬───────┘   └───────┬───────┘  │
│         │                  │                   │          │
│  ┌──────▼──────────────────▼───────────────────▼───────┐  │
│  │              Shared Data Layer                       │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐  │  │
│  │  │ HealthKit│ │ UserTwin │ │ Memory   │ │Feedback│  │  │
│  │  │ Data     │ │ Profile  │ │ Engine   │ │ Engine │  │  │
│  │  └──────────┘ └──────────┘ └──────────┘ └────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

## 3. 数据模型层

### 3.1 标准化指标模型 (HealthMetric)

`HealthMetric.swift` — 基础指标单元，用于 Today 模块网格等场景。

```
- id: String                    // "sleep", "hrv", "resting_heart_rate"
- label: String                 // "睡眠", "HRV"
- value: String                 // "6h12m", "42ms"
- detail: String                // "比平时少 42m"
- status: MetricStatus          // normal | up | down | attention | missing
- colorName: String             // "sleep" | "heart" | "recovery" | "workout"
```

### 3.2 派生特征层 (MetricSnapshot + DerivedInsight)

> **核心原则**：Agent 不应直接分析原始 HealthKit 样本。App 应先生成结构化特征。

`DerivedInsight.swift` 包含：

- **DailyHealthSnapshot** — 每日聚合：恢复分、睡眠分、心脏分、活动分、异常数、ECG 数、数据完整度
- **MetricSnapshot** — 单指标快照：值、单位、状态、与基线偏差、7d/30d 趋势
- **DerivedInsight** — 派生洞察：标题、严重程度、相关指标、置信度、建议行动、是否 ECG 相关
- **HealthNeedScore** — 健康必要性评分（5 维加权，不受用户偏好影响）
- **ExperienceFitScore** — 体验匹配评分（5 维加权）
- **SortedInsight** — 最终排序结果（结合 HealthNeedScore + ExperienceFitScore + SafetyLevel）

### 3.3 User Twin 五层画像

`UserTwin.swift` — 个性化、记忆、排序和 UI 编排的核心数据对象。

| 层级 | 字段 | 说明 |
|------|------|------|
| L1: HealthFocus | domainWeights, confidence, dataAgeDays | 用户关注的健康维度权重 |
| L2: UserPreference | explanationDepth, actionPreference, uiPreference, notificationTolerance, anxietyProne, agencyDefault, chartRangeDays | UI 和交互偏好 |
| L3: UserBehavior | clickThroughRates, actionCompletionRates, fatigueCounts, detailPreferenceScore, anxietyScore | 学习到的行为模式 |
| L4: Goals | ActiveGoal[] | 当前健康目标及进度 |
| L5: RiskProfile | sensitivity, flaggedConditions, requiresEscalation | 安全风险画像 |

### 3.4 心电事件模型 (ECGEpisode)

`ECGEpisode.swift` — 最小可用模型，支持：
- id, recordedAt, quality, rhythmSummary, averageHeartRate, classification, note
- 未来可扩展：voltageSamples, rrIntervals, qrsDuration, qtInterval

## 4. 记忆系统 (Memory Engine)

`Memory.swift` — 记忆生命周期状态机：

```
原始信号 → 候选记忆 → 待确认 → 已确认 → 已调整/已废弃
          (observing)  (candidate) (pendingConfirm) (confirmed) (adjusted/deprecated)
```

**关键设计决策**：
- MemoryEngine 是**协议**，支持 stub / 本地 / 云端多种实现
- 当前 `MemoryEngineStub` 不产生真实数据，等待离线管道就绪
- 反馈机制 (MemoryFeedback) 支持：accurate / inaccurate / deferLater / remove
- ChangeLog 完整记录每次状态变更，确保可追溯

## 5. 安全与合规 (Compliance)

`ComplianceModels.swift` — 五级安全分级：

| 级别 | 处理策略 | 可隐藏? |
|------|---------|---------|
| INFO | 正常展示 | 可 |
| ADVISORY | +免责声明 | 仅语气可调 |
| MONITORING | 可延后但必须可见 | 仅语气 |
| ELEVATED | 前 3 位 + 安抚 → 解释 → 行动 | **不可隐藏** |
| CRITICAL | 强制置顶 + 全屏弹窗 + HITL | **禁止个性化** |

**NonDiagnosticDisclaimer**：根据场景（ECG/异常/恢复）自动选择对应的非诊断声明文案。

**EscalationThreshold**：内置阈值（HR ≥ 150 → CRITICAL，HR ≥ 120 → ELEVATED，SpO2 < 90 → CRITICAL 等）。

## 6. UI Schema 规范

`UISchemaModels.swift` — **完整的 v3.0 Schema 结构**。

UISchema 包含：
- **元数据**：screen, intent, layout, contextMode, agencyMode, safetyLevel
- **个性化上下文**：personalizationReason, personalizationFactors, emotionalFraming
- **Block 数组**：每个 block 独立携带 safetyLevel、healthNeedScore、experienceFitScore、whyShownReason
- **已废弃 DataSource block**：现在由 feedbackBar + schema-level metadata 替代

### 支持的 Block Types (共 14 种)

| 类型 | 用途 |
|------|------|
| insightSummary | 摘要卡片 |
| metricDeltaGrid | 指标对比网格 |
| trendChart | 趋势图 |
| multiMetricTimeline | 多指标时间线 |
| anomalyList | 异常列表 |
| suggestedQuestions | 推荐问题 |
| ecgEpisodeCard | ECG 事件卡 |
| ecgWaveform | ECG 波形图 |
| ecgQuality | 信号质量卡 |
| rrIntervalChart | RR 间期图 |
| ecgContextTimeline | ECG 上下文时间线 |
| actionPlanCard | 行动计划卡 |
| progressTracker | 进度追踪 |
| feedbackBar | 反馈入口 |
| separatorSpacer | 分隔符 |

## 7. 前端组件库

### 7.1 核心组件（已完成）

| 组件 | 路径 | 状态 |
|------|------|------|
| TodayHealthHeroCard | `Components/TodayHealthHeroCard.swift` | ✅ 完成 |
| MetricDeltaGrid | `Components/MetricDeltaGrid.swift` | ✅ 完成 |
| TrendChartBlock + LineChart | `Components/TrendChartBlock.swift` | ✅ 完成 |
| MultiMetricTimeline | `Components/MultiMetricTimeline.swift` | ✅ 完成 |
| AnomalyListBlock | `Components/AnomalyListBlock.swift` | ✅ 完成 |
| SuggestedQuestionBar | `Components/InsightButtonCard.swift` (内嵌) | ✅ 完成 |
| ECGWaveformView | `Components/ECGWaveformView.swift` | ✅ 波形绘制完成 |
| ECGQualityCard | `Components/ECGQualityCard.swift` | ✅ 新增 |
| RRIntervalChartView | `Components/RRIntervalChart.swift` | ✅ 新增 |
| ECGContextTimeline | `Components/ECGContextTimeline.swift` | ✅ 新增 |
| HACard + DesignSystem | `Components/DesignSystem.swift` | ✅ 完成 |
| ConfidenceBadge | `Components/ConfidenceBadge.swift` | ✅ 升级为动态置信度 |
| AgencyToggle | `Components/AgencyToggle.swift` | ✅ 新增 |
| WhyThisCard | `Components/WhyThisCard.swift` | ✅ 新增 |
| PersonalizationBadge | `Components/PersonalizationBadge.swift` | ✅ 新增 |
| FeedbackBar | `Components/FeedbackBar.swift` | ✅ 新增 |
| FeedbackEngine | `Agent/FeedbackEngine.swift` | ✅ 显性 + 隐性反馈 |
| ProgressTracker | `Components/ProgressTracker.swift` | ✅ 新增 |
| ActionPlanCard | `Components/ActionPlanCard.swift` | ✅ 新增，完整的行动建议 UI |

### 7.2 分身页组件（新增）

| 组件 | 路径 | 状态 |
|------|------|------|
| LearningCard | `Components/LearningCard.swift` | ✅ 新增 |
| MemoryCard | `Components/MemoryCard.swift` | ✅ 新增 |
| ConfirmCard | `Components/ConfirmCard.swift` | ✅ 新增 |
| PreferenceTuner | `Components/PreferenceTuner.swift` | ✅ 新增 |
| ColdStartBanner | `Components/ColdStartBanner.swift` | ✅ 新增 |
| ChangeLogEntryView | `Components/ChangeLogEntryView.swift` | ✅ 新增 |

### 7.3 页面级视图

| 页面 | 路径 | 状态 |
|------|------|------|
| AppRouter | `App/AppRouter.swift` | ✅ 5-tab 路由 |
| HealthAgentApp | `App/HealthAgentApp.swift` | ✅ 入口 |
| TodayView | `Features/Today/TodayView.swift` | ✅ 已集成 AgencyToggle, ColdStartBanner, WhyThisCard, ActionPlanCompact |
| HeartView | `Features/Heart/HeartView.swift` | ✅ 完成 |
| ECGDetailView | `Features/Heart/ECGDetailView.swift` | ✅ 完成 |
| ExploreView | `Features/Explore/ExploreView.swift` | ⚠️ 骨架 |
| ReportsView | `Features/Reports/ReportsView.swift` | ✅ 完成 |
| MeView | `Features/Me/MeView.swift` | ⚠️ 骨架 |
| OnboardingView | `Features/Onboarding/OnboardingView.swift` | ✅ UI 完成 |

## 8. 健康数据服务层

`HealthKit/` 目录结构：

```
HealthKit/
├── HealthDataStore.swift              ← 协议：fetchDailySnapshot, fetchMetricSeries, fetchLatestECG
├── HealthKitHealthDataStore.swift     ← 真实 HK 实现 + Mock fallback
├── HealthKitPermissionManager.swift   ← 权限管理 (MVP 阶段为 stub)
├── HealthMetricQueryService.swift     ← 真实 HK 数据查询
├── HealthKitHealthDataStore.swift     ← 真实 HealthKit 查询
└── ECGQueryService.swift              ← ECG 查询 + 上下文窗口
```

**已实现的真实查询**：HRV (7d)、静息心率 (7d)、睡眠 (7d)、活动能量 (7d)、ECG 元数据
**待补充**：波形数据 (voltage samples)、实时心率、呼吸频率、血氧

## 9. Agent 层

`Agent/` 目录结构：

```
Agent/
├── AgentClient.swift                  ← 协议：fetchCanvasSchema, chat, submitMemoryFeedback 等
├── MockAgentClient.swift              ← Mock 实现，生成 v3.0 UISchema
├── UISchemaModels.swift               ← 完整 Schema 模型系统 (v3.0)
├── HealthContextBuilder.swift         ← 构建 HealthContext (目前未被调用)
├── DerivedInsight.swift              ← DerivedInsight, HealthAction, DailyHealthSnapshot 等
├── ComplianceModels.swift             ← SafetyLevel, SafetyPolicy, NonDiagnosticDisclaimer
├── FeedbackEngine.swift              ← FeedbackProcessing 协议 + stub 实现
└── UserTwin.swift                     ← 五层画像 + RiskProfile + MemoryStatistics
```

**关键设计决策**：
- AgentClient 设计为**网络可达**的协议，Mock 版本返回硬编码 Schema
- 真实版本上线时，只需替换 `MockAgentClient` → `NetworkAgentClient`
- 所有 Schema 兼容 `Codable`，可直接序列化/反序列化为 JSON

## 10. 渲染引擎

`Renderer/HealthBlockRenderer.swift` — 动态渲染引擎。

**核心能力**：
- 遍历 `UISchema.blocks` 数组
- 根据 `BlockType` 分发到对应组件
- 每个 block 自带 `dataPayload` (JSON)，运行时解码为对应 Config struct
- 未知 block type 降级处理（预留 fallback 逻辑）

**当前支持的 14 种 block**：全部有 renderer 对应

## 11. 文件清单

### 基础设施（已有，未经修改）
```
fastlane/Fastfile                          ← CI 构建 lane
ci/discover_ios_projects.py              ← 动态矩阵发现
.github/workflows/ios-monorepo-build.yml ← GitHub Actions
Gemfile                                  ← Ruby 依赖
fastlane/Matchfile                       ← 签名配置
scripts/validate_health_agent.ps1        ← 校验脚本
```

### 产品定义
```
product/prd.md                            ← PRD v3.0
product/agent-schema.md                   ← Schema 规范
product/health-data-model.md             ← 健康数据模型
product/ui-spec.md                        ← UI 规范
```

### iOS 源码（新增文件以 `*` 标记）
```
ios/
├── HealthAgent/
│   ├── App/
│   │   ├── AppRouter.swift              （已有）
│   │   └── HealthAgentApp.swift          （已有）
│   ├── Features/
│   │   ├── Today/
│   │   │   └── TodayView.swift           （已更新）
│   │   ├── Heart/
│   │   │   ├── HeartView.swift           （已有）
│   │   │   └── ECGDetailView.swift       （已有）
│   │   ├── Explore/
│   │   │   └── ExploreView.swift         （已有，skeleton）
│   │   ├── Reports/
│   │   │   └── ReportsView.swift         （已有）
│   │   ├── Me/
│   │   │   └── MeView.swift              （已有，skeleton）
│   │   └── Onboarding/
│   │       └── OnboardingView.swift      （已有）
│   ├── Components/
│   │   ├── TodayHealthHeroCard.swift     （已有）
│   │   ├── MetricDeltaGrid.swift         （已有）
│   │   ├── TrendChartBlock.swift         （已有）
│   │   ├── MultiMetricTimeline.swift     （已有）
│   │   ├── AnomalyListBlock.swift        （已有）
│   │   ├── InsightButtonCard.swift       （已有）
│   │   ├── ECGWaveformView.swift         （已有，更新）
│   │   ├── ECGEpisodeCard.swift          （已有）
│   │   ├── PermissionPromptCard.swift    （已有）
│   │   ├── DesignSystem.swift            （已有）
│   │   ├── ConfidenceBadge.swift         （已更新）
│   │   ├── AgencyToggle.swift            * 新增
│   │   ├── WhyThisCard.swift             * 新增
│   │   ├── PersonalizationBadge.swift    * 新增
│   │   ├── FeedbackBar.swift             * 新增
│   │   ├── LearningCard.swift            * 新增
│   │   ├── MemoryCard.swift              * 新增
│   │   ├── ConfirmCard.swift             * 新增
│   │   ├── PreferenceTuner.swift         * 新增
│   │   ├── ColdStartBanner.swift         * 新增
│   │   ├── ActionPlanCard.swift          * 新增
│   │   ├── ProgressTracker.swift         * 新增
│   │   ├── ChangeLogEntryView.swift      * 新增
│   │   ├── ECGQualityCard.swift          * 新增
│   │   ├── RRIntervalChart.swift         * 新增
│   │   └── ECGContextTimeline.swift      * 新增
│   ├── Agent/
│   │   ├── UISchemaModels.swift          （已更新为 v3.0）
│   │   ├── AgentClient.swift              * 新增
│   │   ├── MockAgentClient.swift          （已更新为 v3.0）
│   │   ├── HealthContextBuilder.swift     （已有）
│   │   ├── DerivedInsight.swift           （已更新为 v3.0）
│   │   ├── ComplianceModels.swift         * 新增
│   │   └── FeedbackEngine.swift           * 新增
│   ├── HealthKit/
│   │   ├── HealthDataStore.swift          （已有）
│   │   ├── HealthKitHealthDataStore.swift （已有）
│   │   ├── HealthKitPermissionManager.swift（已有）
│   │   ├── HealthMetricQueryService.swift （已有）
│   │   └── ECGQueryService.swift          （已有）
│   ├── Models/
│   │   ├── HealthMetric.swift             （已有）
│   │   ├── ECGEpisode.swift               （已有）
│   │   ├── DerivedInsight.swift           → 移至 Agent/
│   │   └── UserTwin.swift                 * 新增
│   ├── Renderer/
│   │   ├── HealthBlockRenderer.swift      （已更新）
│   │   └── DynamicInsightPageView.swift   （已有）
│   └── Resources/
│       ├── Info.plist
│       ├── HealthAgent.entitlements
│       └── Assets.xcassets/
├── project.yml
└── README.md
```

**注意**：`DerivedInsight.swift` 原在 `Models/`，但因包含 `HealthNeedScore`、`ExperienceFitScore`、`DailyHealthSnapshot` 等逻辑，应移至 `Agent/`。

## 12. P0 完整性检查

| P0 需求 (PRD v3.0 §16.1) | 状态 |
|---------------------------|------|
| Onboarding 三问 | ✅ UI 框架已就位（OnboardingView.swift） |
| 个性化今日画布 | ✅ UISchema + TodayView 已集成 |
| UI Schema Renderer | ✅ HealthBlockRenderer v3.0 完成 |
| User Twin 基础画像 | ✅ UserTwin.swift 完成 |
| Health Need Scorer V1 | ✅ DerivedInsight.swift 完成 |
| Health Outcome Policy Engine V1 | ⚠️ ComplianceModels.swift 完成，Policy Engine 需云端 |
| Experience Fit Scorer V1 | ✅ DerivedInsight.swift 完成 |
| WhyThisCard | ✅ 新增组件 |
| FeedbackBar | ✅ 新增组件 + FeedbackEngine stub |
| PersonalizationBadge | ✅ 新增组件 |
| AgencyToggle | ✅ 新增组件 |
| 冷启动诚实文案 | ✅ 新增 ColdStartBanner 组件 |
| 安全分级与非诊断声明 | ✅ ComplianceModels + 渲染器集成 |

## 13. 已知差异与风险项

| 编号 | 差异 | 影响 | 建议 |
|------|------|------|------|
| D-01 | HealthContextBuilder 已构建但未被视图调用 | TodayView 仍用 MockAgentClient | 下一步连线真实数据流 |
| D-02 | HealthMetricQueryService 构建但未被调用 | 数据停留在 mock | 在 ViewModel 层注入真实 service |
| D-03 | HealthKitPermissionManager.requestRecoveryPermissions() 为 stub | 权限流不可验证 | 接入真实 HK requestAuthorization |
| D-04 | HealthOutcomePolicyEngine 需云端实现 | 本地仅有安全分级 | 与算法团队确认 Policy API 设计 |
| D-05 | UISchema Codable 兼容 | AnyCodable 编解码可能影响性能 | 生产环境建议用具体类型 |
| D-06 | DerivedInsight 模型从 Models/ 移至 Agent/ | Xcode 文件路径变更 | 需更新 XcodeGen project.yml |
| D-07 | 新增 12 个 Swift 文件 | 编译速度略有影响 | 确认无循环依赖后 xcodegen generate |
| D-08 | ConfidenceBadge 重构 | 老版本用 String，新版本用 Double | 更新所有引用点 |

## 14. 下一步行动

1. **连线数据流**：TodayView → HealthContextBuilder → HealthKitHealthDataStore
2. **完善安全分级**：根据临床团队输入确认 ELEVATED/CRITICAL 阈值
3. **实现动态分析页**：DoubleInsightPageView 支持追问 refinement
4. **构建分身页**：TwinView 集成 LearningCard, MemoryCard, ConfirmCard, PreferenceTuner
5. **编写 Unit Test**：HealthBlockRenderer snapshot test + Schema validation test
6. **xcodegen generate**：验证新增文件在 XcodeGen 工程下编译通过