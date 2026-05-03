# Health Data Model

## Data Philosophy

Health Agent should organize Apple Health data around user questions rather than raw metric pages.

The app has three data classes:

| Type | Examples | Product Role | ECG Dependency |
| --- | --- | --- | --- |
| Continuous data | Heart rate, resting heart rate, HRV, sleep, steps, active energy, respiratory rate, blood oxygen | Daily analysis foundation | No |
| Event data | Workouts, symptoms, abnormal heart events, user notes | Explains what happened around a time point | No |
| Enhancement data | ECG waveform, ECG classification, rhythm features | Deep interpretation of key heart-related events | Requires ECG |

## HealthKit Access Principle

HealthKit access must be progressive and purpose-driven.

The app should request only the data needed for the user's selected question or module. It should explain:

- What data is needed
- Why it is needed
- What analysis it unlocks
- Whether the analysis can run with partial data

## Privacy Boundary

Default:

- Raw HealthKit data stays on device.
- Derived metrics and local summaries are used for rendering.
- Server/Agent receives only user-approved summaries when needed.

User controls:

- View data sources used in every insight.
- Delete analysis history.
- Delete preference memory.
- Revoke permissions.
- Avoid upload of raw ECG waveform unless explicitly approved for a clearly defined purpose.

## Normalized Metric Model

Each HealthKit metric should be normalized into a stable app model:

```text
metric_id
display_name
unit
category
sample_type
aggregation_method
time_granularity
permission_status
available_range
source_devices
```

Example metric IDs:

- `heart_rate`
- `resting_heart_rate`
- `heart_rate_variability`
- `sleep_duration`
- `sleep_stage`
- `step_count`
- `active_energy`
- `workouts`
- `vo2_max`
- `respiratory_rate`
- `blood_oxygen`
- `body_weight`
- `mindful_minutes`
- `ecg`

## Derived Feature Layer

The Agent should not reason directly over raw samples. The app should derive structured features:

- 7-day average
- 30-day average
- 90-day trend
- Personal baseline
- Week-over-week delta
- Deviation from baseline
- Anomaly points
- Variability
- Missing data windows
- Recovery score
- Sleep debt
- Training load
- Heart rate recovery
- Correlation candidates
- Good-state and bad-state sample days

## Data Packs

### Recovery Pack

Metrics:

- HRV
- Resting heart rate
- Sleep duration
- Sleep regularity
- Workout load
- Active energy

Answers:

- 我最近恢复得好吗？
- 运动是不是太多了？
- 为什么这周状态差？

### Sleep Pack

Metrics:

- Sleep stages
- Sleep duration
- Bedtime and wake time
- Night heart rate
- Respiratory rate
- Blood oxygen where available

Answers:

- 昨晚睡得怎么样？
- 为什么我睡不好？
- 睡眠影响心脏状态吗？

### Heart Pack

Metrics:

- Heart rate
- Resting heart rate
- HRV
- Walking heart rate
- Heart rate recovery
- ECG where available

Answers:

- 最近心脏状态稳定吗？
- 最近心率为什么偏高？
- 最近心律稳定吗？

### Training Load Pack

Metrics:

- Workouts
- Active energy
- Exercise minutes
- Heart rate zones
- Steps
- HRV
- Resting heart rate

Answers:

- 运动是不是太多了？
- 运动后恢复好吗？
- 运动对睡眠有帮助吗？

### Anomaly Pack

Metrics:

- All authorized core metrics
- Personal baseline
- Missing data
- Device source quality

Answers:

- 最近有什么异常？
- 我该关注哪个指标？

### Weekly Review Pack

Metrics:

- Sleep
- Heart rate
- HRV
- Workouts
- Activity
- Anomalies
- ECG events where available

Answers:

- 这周健康状态总结
- 下周我应该关注什么？

## ECG Episode Model

Every ECG should be represented as an event:

```text
ecg_id
start_time
end_time
apple_classification
average_heart_rate
sampling_frequency
voltage_measurements_reference
signal_quality_score
rhythm_stability_score
waveform_features
context_before
context_after
symptom_tags
episode_summary
```

ECG waveform and advanced analysis should be handled carefully because it is highly sensitive health data.

## ECG Feature Layer

Potential self-developed ECG features:

- Signal quality
- Noise level
- Baseline wander
- RR interval sequence
- Rhythm regularity
- P wave observations
- QRS observations
- T wave observations
- QT / QTc estimate
- Beat classification
- Comparison to prior ECGs

All outputs should be phrased as observations, not diagnosis.

## ECG Context Window

For ECG event explanation, collect context around the event:

| Window | Data | Purpose |
| --- | --- | --- |
| Previous 24 hours | Sleep, workout, HRV, heart rate, blood oxygen | Find possible background factors |
| Previous 2 hours | Heart rate, activity, symptoms, caffeine/alcohol tags if user supplied | Find immediate context |
| ECG duration | Waveform, heart rate, quality | Analyze the ECG event itself |
| Next 2 hours | Heart rate and symptom state | See whether the event persisted |
| Next 24 hours | HRV, sleep, resting heart rate | See follow-up impact |

## ECG-Enhanced Questions

Questions that can run without ECG but improve with ECG:

- 最近心脏状态稳定吗？
- 为什么我最近容易心慌？
- 运动后心脏恢复好吗？
- 睡眠差会影响心脏状态吗？
- 最近心率为什么偏高？

ECG-only questions:

- 解读我最新一次心电
- 这次 ECG 和上次有什么不同？
- 为什么这次 ECG 不可判读？
- 这次心电的信号质量怎么样？
- 最近几次 ECG 有什么变化？

## Required iOS Data Services

Suggested module split:

```text
HealthKit/
  HealthKitPermissionManager.swift
  HealthDataStore.swift
  HealthMetricQueryService.swift
  ECGQueryService.swift

Agent/
  AgentClient.swift
  UISchemaModels.swift
  InsightQuestionModels.swift
  HealthContextBuilder.swift

Renderer/
  DynamicInsightPageView.swift
  HealthBlockRenderer.swift
  ComponentRegistry.swift

Models/
  HealthMetric.swift
  DerivedInsight.swift
  ECGEpisode.swift
  UserPreference.swift
```

## MVP Data Requirements

For the first version, prioritize:

- Sleep
- HRV
- Resting heart rate
- Heart rate
- Active energy
- Workouts
- Steps
- Respiratory rate where available
- Blood oxygen where available
- ECG if available

The app should still be useful if ECG is unavailable.
