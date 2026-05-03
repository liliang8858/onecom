# Health Agent UI Spec

## UI Direction

The product should be a Today Health Home, not a metric dashboard and not a prompt launcher.

The first screen should answer:

```text
How am I today?
Why?
What can I do or inspect next?
Can ECG help me go deeper when relevant?
```

## Information Architecture

Recommended tabs:

- Today
- Explore
- Heart
- Reports
- Me

Chinese labels:

- 今日
- 探索
- 心脏
- 报告
- 我的

## Today Health Home

The home screen has five zones:

1. Top status bar: date, Apple Health sync state, profile, permission state
2. Today Health Hero: overall body state and main drivers
3. Agent Discovery: one or two meaningful findings
4. Health Modules: sleep, recovery, heart, workout, anomalies
5. Smart Exploration: insight chips and health input

## First Screen Wireframe

```text
Today
May 1 · Apple Health synced

今日身体状态
偏弱
Recovery 62

睡眠不足 · HRV 下降 · 静息心率略高

[查看原因] [今日建议]

Agent 发现
过去 7 天，你的睡眠减少，同时运动负荷上升，恢复指标同步走弱。
[为什么？] [看时间线]

今日模块
[睡眠 6h12m] [心脏 稳定]
[恢复 偏弱]  [运动 偏高]

继续探索
[为什么这周状态差？]
[睡眠影响心脏状态吗？]
[运动是不是太多了？]

Ask your health data...
```

## Today Health Hero

Hero card fields:

- Overall state: 良好 / 正常 / 偏弱 / 建议关注 / 数据不足
- Composite score: recovery or daily readiness score
- Main drivers: sleep, HRV, resting heart rate, activity, workout load
- Primary actions: view reason, generate today's suggestion
- Data confidence: sufficient / partial / missing key data

Example:

```text
今日状态
偏弱
Recovery 62

HRV -12%
Sleep -42m
RHR +4 bpm

主要原因：睡眠减少 + 运动负荷上升
[查看完整分析]
```

## Insight Buttons

Insight buttons are not ordinary feature buttons. They are Health Agent shortcuts.

Each button contains:

- Question title
- Data subtitle
- Status tag
- Data sources
- Priority signal
- Optional ECG-enhanced marker

Example:

```text
我最近恢复得好吗？
HRV 下降 · 静息心率略高
相关数据：睡眠 / HRV / 心率 / 运动
建议查看
```

Button states:

- Normal
- New discovery
- Suggested
- ECG enhancement available
- Permission missing
- Pinned by user
- Low confidence / insufficient data

Long press actions:

- Edit this insight button
- Pin to Today
- Hide
- Change default view style
- Change time range
- Change trigger condition

## Dynamic Analysis Page

Every analysis page keeps a stable skeleton:

1. User question
2. Direct answer
3. Key evidence
4. Data visualization
5. Explanation logic
6. Next question chips
7. Data source and confidence

Agent may dynamically choose:

- Which metrics to include
- Which blocks to show
- Block order
- Explanation depth
- Whether ECG is inserted
- UI style mode

## UI Style Modes

Supported MVP styles:

- Insight-first: conclusion, evidence, charts, next actions
- Chart mode: trend charts, comparison charts, anomaly points
- Timeline mode: daily sequence of sleep, HRV, heart rate, workout, ECG events

Future styles:

- Minimal
- Report
- Professional ECG / quantified self

## ECG UI Placement

ECG should be an event enhancement layer, not the default home structure.

Without ECG, heart pages use:

- Resting heart rate
- HRV
- Daytime heart rate changes
- High / low heart rate events
- Sleep
- Workout
- Blood oxygen / respiration where available

With ECG, the page inserts:

- ECG episode card
- ECG signal quality
- ECG waveform
- Rhythm stability
- Apple classification explanation
- Self-developed observations
- Context before and after ECG

## ECG Detail Page

Three layers:

### User Layer

- Main observation
- Signal quality
- Average heart rate
- Rhythm stability
- Non-diagnostic disclaimer
- Suggested next action

### Evidence Layer

- ECG waveform
- RR interval chart
- Apple classification
- Sleep / HRV / heart rate context

### Professional Layer

Collapsed by default:

- RR interval variation
- QRS duration estimate
- QT / QTc estimate
- Noise level
- Baseline wander
- Beat classification

## Key Screens

### Recovery Page

Answers:

> 我最近是不是累了？恢复得好吗？

Blocks:

- Recovery summary card
- HRV trend
- Resting heart rate trend
- Sleep and workout timeline
- Key anomaly dates
- Next questions

### Heart Status Page

Answers:

> 最近心脏状态稳定吗？

Blocks:

- Heart status summary
- Heart rate trend
- HRV trend
- High / low heart rate events
- ECG event if available
- Sleep and workout context
- Next questions

### Anomaly Center

Each anomaly becomes a clickable question:

```text
静息心率连续 4 天偏高
可能相关：睡眠减少、运动负荷增加
[查看原因]
```

### Relationship Exploration Page

Example question:

> 运动对睡眠有帮助吗？

Blocks:

- Conclusion card
- Workout day vs non-workout day comparison
- Scatter plot
- Timeline samples
- Next questions

## Onboarding

Step 1: Choose focus areas:

- Sleep
- Recovery
- Heart
- Workout
- Stress proxy
- ECG
- Weight
- Overall health

Step 2: Request progressive HealthKit permissions based on selected areas.

Step 3: Generate first insight buttons.

Step 4: Choose UI preference:

- Simple conclusion
- More charts
- Report style
- Timeline review
- Professional data mode

## Permission UX

Do not show empty pages when data is missing.

Show what can be unlocked:

```text
我最近恢复得好吗？

还需要 2 类数据：
- HRV
- 睡眠

授权后可以分析：
- 最近恢复趋势
- 睡眠是否影响恢复
- 运动后是否恢复充分

[授权健康数据]
```

## Tone

The UI should be calm, trustworthy, and non-alarming.

Prefer:

- "今天恢复偏弱。主要和睡眠减少、运动负荷上升有关。"
- "最近心率略高，建议查看影响因素。"
- "这次数据中有值得关注的心律相关信号。"

Avoid:

- Fear-based labels
- Diagnostic language
- Dense medical jargon in the default layer

## Component Library

Core components:

- `InsightButtonCard`
- `InsightSummaryCard`
- `MetricDeltaGrid`
- `TrendChartBlock`
- `MultiMetricTimeline`
- `AnomalyListBlock`
- `CorrelationCard`
- `SuggestedQuestionBar`
- `PermissionPromptCard`
- `DataSourceCard`
- `ConfidenceBadge`

ECG components:

- `ECGEpisodeCard`
- `ECGWaveformView`
- `ECGQualityCard`
- `RhythmStabilityCard`
- `RRIntervalChart`
- `ECGComparisonView`
- `ECGContextTimeline`
- `ECGProfessionalDetails`
