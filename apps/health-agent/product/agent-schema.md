# Health Agent Schema And Agent Workflow

## Architecture Principle

The Agent must not generate iOS code.

The Agent generates structured UI schema. The iOS app validates that schema and renders it using a whitelist of native SwiftUI components.

```text
User intent
  -> Agent planner
  -> Health context builder
  -> UI schema generator
  -> Policy / safety / permission checker
  -> SwiftUI component renderer
  -> User feedback
  -> Preference memory
```

## Why Schema Instead Of Dynamic Code

Controlled UI schema gives:

- App Store friendly behavior
- Native SwiftUI rendering
- Stable safety boundaries
- Server-side UI orchestration
- Component whitelisting
- Versioning, validation, fallback, and rollback
- Personalization without arbitrary app rewrites

## Schema Envelope

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

## Insight Button Schema

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

## Block Types

MVP block whitelist:

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

Unknown blocks must not crash the app. The renderer should fall back to a supported list or summary block.

## Recovery Page Example

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

## ECG Enhancement Block

When ECG exists and is relevant, the Agent can insert:

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

## Question Generation Inputs

Inputs:

- User historical questions
- Insight button clicks
- Pinned / hidden questions
- Apple Health metric changes
- Recent anomalies
- Time of day / week / month
- Permission availability
- ECG events
- User UI preference profile
- Safety risk class

## Button Ranking

MVP ranking can be rule-based plus Agent reordering:

```text
score =
  user_frequency_score
  + metric_change_score
  + time_relevance_score
  + permission_completeness_score
  + preference_score
  + ecg_event_score
  - safety_risk_score
```

## Display Intent Categories

- Reading: summary card, highlight, evidence
- Comparison: comparison table, metric delta grid
- Decision: recommendation, risk list, next steps
- Monitoring: dashboard, trend, anomaly list
- Review: timeline, weekly report, change history
- Professional ECG: waveform, RR interval, quality, details

## Preference Memory

User statements can become UI profile fields:

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

Preference examples:

- "以后恢复状态都用图表给我看。"
- "睡眠相关问题默认显示时间线。"
- "不要给我太多解释，只给结论和动作。"
- "心脏相关页面默认展开证据。"

## Safety Checker Requirements

Before rendering schema:

- Reject unsupported block types or action types.
- Downgrade diagnostic claims to non-diagnostic observations.
- Add disclaimers for ECG and heart-related interpretations.
- Check data permissions.
- Mark confidence when data is incomplete.
- Keep sensitive operations behind stable confirmation UI.

## iOS Rendering Model

Suggested SwiftUI shape:

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
