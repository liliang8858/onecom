# Health Agent Schema 与 Agent 工作流

## 架构原则

Agent 不能动态生成 iOS 代码。

Agent 只生成结构化 UI Schema。iOS App 负责校验 Schema，并用白名单 SwiftUI 组件渲染。

```text
用户意图
  -> Agent Planner
  -> Health Context Builder
  -> UI Schema Generator
  -> Policy / Safety / Permission Checker
  -> SwiftUI Component Renderer
  -> 用户反馈
  -> 偏好记忆
```

## 为什么使用 Schema

使用受控 Schema 可以获得：

- 更符合 App Store 审核边界
- 保持原生 SwiftUI 体验
- 保持稳定安全边界
- 支持服务端智能编排
- 支持组件白名单
- 支持版本化、校验、降级和回滚
- 支持个性化，但不让界面失控

## Schema 外层结构

```json
{
  "schema_version": "1.0",
  "screen_id": "recovery_status_30d",
  "screen_type": "health_exploration",
  "title": "我最近恢复得好吗？",
  "intent": "recovery_analysis",
  "layout": "insight_dashboard",
  "style": "insight_first",
  "time_range": "30d",
  "safety_level": "non_diagnostic",
  "blocks": [],
  "actions": [],
  "data_sources": [],
  "fallback_view": "list"
}
```

## 洞察按钮 Schema

```json
{
  "question_id": "recovery_status_30d",
  "title": "我最近恢复得好吗？",
  "subtitle": "HRV 下降，静息心率略升高",
  "category": "recovery",
  "priority": 0.91,
  "reason": "过去 7 天恢复相关指标出现同步变化",
  "required_metrics": [
    "hrv",
    "resting_heart_rate",
    "sleep_duration"
  ],
  "optional_metrics": [
    "workouts",
    "active_energy",
    "respiratory_rate",
    "ecg"
  ],
  "time_range": "30d",
  "compare_to": "personal_baseline",
  "analysis_method": "baseline_deviation + trend + anomaly_detection",
  "ui_template": "recovery_dashboard",
  "style": "insight_first",
  "safety_level": "non_diagnostic",
  "next_questions": [
    "只看睡眠因素",
    "加入运动数据分析",
    "和状态好的日子对比"
  ]
}
```

## 组件类型白名单

MVP 支持的 block：

- `insight_summary`
- `metric_delta_grid`
- `trend_chart`
- `multi_metric_timeline`
- `anomaly_list`
- `correlation_card`
- `suggested_questions`
- `permission_prompt`
- `data_source_card`
- `ecg_episode_card`
- `ecg_waveform`
- `ecg_quality`
- `rr_interval_chart`
- `ecg_context_timeline`

未知组件不能让 App 崩溃。渲染器应降级为列表、摘要或不支持提示。

## 恢复页 Schema 示例

```json
{
  "schema_version": "1.0",
  "screen_id": "recovery_status_30d",
  "title": "我最近恢复得好吗？",
  "time_range": "30d",
  "style": "insight_first",
  "safety_level": "non_diagnostic",
  "blocks": [
    {
      "type": "insight_summary",
      "title": "恢复状态偏弱",
      "summary": "过去 7 天你的 HRV 下降，静息心率略高，同时睡眠时间减少。"
    },
    {
      "type": "metric_delta_grid",
      "metrics": [
        {
          "id": "hrv",
          "label": "HRV",
          "change": "-12%",
          "status": "down"
        },
        {
          "id": "resting_heart_rate",
          "label": "静息心率",
          "change": "+4 bpm",
          "status": "up"
        },
        {
          "id": "sleep_duration",
          "label": "睡眠",
          "change": "-42 min",
          "status": "down"
        }
      ]
    },
    {
      "type": "trend_chart",
      "metric": "hrv",
      "range": "30d"
    },
    {
      "type": "multi_metric_timeline",
      "metrics": [
        "sleep_duration",
        "resting_heart_rate",
        "active_energy"
      ],
      "range": "14d"
    },
    {
      "type": "suggested_questions",
      "items": [
        "只看睡眠因素",
        "加入运动负荷分析",
        "和状态好的日子对比"
      ]
    }
  ]
}
```

## ECG 增强组件

当 ECG 存在且与当前问题相关时，Agent 可以插入：

```json
{
  "type": "ecg_episode_card",
  "ecg_id": "latest_ecg",
  "title": "最近一次 ECG",
  "subtitle": "可作为本次分析的补充证据",
  "quality": "good",
  "classification": "available",
  "context_window": "24h"
}
```

## 问题生成输入

输入来源：

- 用户历史问题
- 洞察按钮点击行为
- 用户固定或隐藏的问题
- Apple Health 指标变化
- 近期异常
- 日期、时间、周期节点
- HealthKit 权限状态
- ECG 事件
- 用户 UI 偏好
- 安全风险等级

## 按钮排序

MVP 可以采用规则分数加 Agent 排序：

```text
score =
  用户点击频率分
  + 指标变化分
  + 时间相关性分
  + 权限完整度分
  + 偏好分
  + ECG 事件分
  - 安全风险分
```

## 展示意图分类

- 阅读型：摘要卡、重点高亮、证据说明
- 比较型：对比表、指标变化表
- 决策型：推荐方案、风险列表、下一步
- 监控型：仪表盘、趋势、异常列表
- 复盘型：时间线、周报、变更记录
- 专业 ECG 型：波形、RR 间期、质量、专业细节

## 用户偏好记忆

用户表达可以沉淀为 UI Profile：

```json
{
  "default_density": "concise",
  "preferred_chart_range": "90d",
  "sleep_view": "timeline",
  "health_insight_style": "risk_first",
  "heart_view": "evidence_first",
  "show_medical_disclaimer": true,
  "confirm_before_sensitive_actions": true
}
```

示例：

- 以后恢复状态都用图表给我看。
- 睡眠相关问题默认显示时间线。
- 不要给我太多解释，只给结论和动作。
- 心脏相关页面默认展开证据。

## 安全检查要求

渲染前必须检查：

- 不支持的组件类型或动作类型要拒绝或降级。
- 诊断式表达要降级为非诊断观察。
- ECG 和心脏相关解释要加入必要提醒。
- 检查数据权限。
- 数据不完整时标注置信度。
- 敏感操作必须走稳定确认 UI。

## iOS 渲染模型建议

SwiftUI 数据结构可以这样抽象：

```swift
struct HealthPageSchema: Codable {
    let schemaVersion: String
    let screenID: String
    let title: String
    let layout: String
    let style: String
    let blocks: [HealthUIBlock]
}

enum HealthUIBlock: Codable, Identifiable {
    case insightSummary(InsightSummaryConfig)
    case metricDeltaGrid(MetricDeltaGridConfig)
    case trendChart(TrendChartConfig)
    case multiMetricTimeline(MultiMetricTimelineConfig)
    case anomalyList(AnomalyListConfig)
    case suggestedQuestions(SuggestedQuestionsConfig)
    case ecgEpisode(ECGEpisodeConfig)

    var id: String {
        switch self {
        case .insightSummary(let config): return config.id
        case .metricDeltaGrid(let config): return config.id
        case .trendChart(let config): return config.id
        case .multiMetricTimeline(let config): return config.id
        case .anomalyList(let config): return config.id
        case .suggestedQuestions(let config): return config.id
        case .ecgEpisode(let config): return config.id
        }
    }
}
```
