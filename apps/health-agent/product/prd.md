# Health Agent PRD

## Product Name

Health Agent with ECG Intelligence

## One-Sentence Positioning

An intelligent health Agent app built on continuous Apple Health data, using ECG as event-level enhancement evidence to explain heart-related moments more deeply.

## Product Thesis

Most health apps show metrics first. Health Agent starts from the user's actual question:

- How am I today?
- Why do I feel off?
- What changed recently?
- What should I pay attention to?
- When ECG exists, what does it add to the story?

The app should not feel like a metric dashboard or a chat prompt launcher. It should feel like a daily health home that gives the user a clear status, a reason, and the next best health questions to explore.

## Core Product Principles

- Apple Health continuous data is the daily analysis foundation.
- ECG is a high-value enhancement layer, not the required entry point for every analysis.
- The home screen answers "How am I today?" before showing questions.
- The app organizes health data by user questions, not by raw metrics.
- Agent output must be rendered through controlled UI schema and native SwiftUI components.
- Health insights must stay non-diagnostic and avoid medical claims.
- Raw HealthKit data should stay local by default; upload only explicitly approved summaries.

## Target Experience

The core flow is:

```text
Today health state
  -> Agent discovery
  -> Health modules
  -> Smart insight questions
  -> Dynamic analysis page
  -> Evidence layer
  -> Next questions or saved preference
```

The user should feel:

> I do not need to understand every metric. The app notices what may matter, explains why, and lets me go deeper when I want.

## MVP Scope

First version should focus on six core capabilities:

- Today Health Home
- "Am I recovering well recently?"
- "How did I sleep last night?"
- "Why do I feel worse this week?"
- "What changed abnormally recently?"
- "Is my heart status stable recently?", enhanced by ECG when available
- "Interpret my latest ECG", shown only when ECG data exists

## MVP Buttons

The initial insight buttons:

1. 我最近恢复得好吗？
2. 昨晚睡得怎么样？
3. 为什么这周状态差？
4. 最近有什么异常？
5. 最近心脏状态稳定吗？
6. 解读最新一次 ECG

The ECG button should not appear as a dead entry. It appears only when ECG data exists or when a heart-related flow can explain why ECG would help.

## Primary User Jobs

### Daily Check-In

The user opens the app and wants a fast answer:

```text
Today state: normal / weak / needs attention / data insufficient
Main reasons: sleep, HRV, resting heart rate, workout load, anomaly
Next actions: view reason, generate today's suggestion, ask health data
```

### Recovery Analysis

The user asks whether their body is recovering well.

Core metrics:

- HRV
- Resting heart rate
- Sleep duration
- Sleep regularity
- Workout load
- Active energy

Optional enhancement:

- Recent ECG event stability
- ECG average heart rate compared with personal baseline

### Sleep Analysis

The user asks how last night went or why sleep is poor.

Core metrics:

- Sleep duration
- Sleep stages
- Time asleep / awake
- Night heart rate
- Respiratory rate
- Blood oxygen where available

### Weekly State Explanation

The user asks why this week feels worse.

Core method:

- Compare current 7 days with previous 7 days
- Find largest metric deltas
- Rank likely drivers
- Show a conclusion-first analysis with evidence

### Anomaly Center

The app detects deviations against personal baseline and turns each anomaly into a clickable question.

Examples:

- Resting heart rate has been high for four days.
- HRV is below the 30-day baseline.
- Sleep duration dropped compared with last week.
- Night heart rate is higher than usual.

### Heart Status

The user asks if their heart state looks stable.

Without ECG:

- Resting heart rate
- HRV
- Heart rate variability across the day
- High / low heart rate events where available
- Sleep and workout context

With ECG:

- ECG event card
- ECG classification
- ECG signal quality
- Rhythm stability
- ECG waveform evidence
- Context around the ECG time

## ECG Product Role

ECG is not the whole product. ECG is a depth amplifier.

Daily mode:

```text
Continuous Apple Health data -> trends, recovery, sleep, workouts, anomalies
```

ECG-enhanced mode:

```text
Key event -> ECG episode -> waveform + rhythm + context -> deeper explanation
```

ECG should appear in these situations:

- A new ECG exists.
- The user asks about palpitations, chest discomfort, heart rhythm, or a heart-related event.
- Continuous metrics show heart-related changes.
- Workout recovery looks unusual and ECG was recorded nearby.
- Sleep, HRV, and heart signals suggest a deeper event review.

## Non-Goals For MVP

- No medical diagnosis.
- No claim that the app can rule out disease.
- No treatment recommendations.
- No dynamic Swift or executable code from the server.
- No upload of raw HealthKit data by default.
- No full app layout rewrites based on freeform model output.

## Product Language Guardrails

Prefer:

- "发现值得关注的变化"
- "心电相关观察点"
- "帮助你回看当时状态"
- "这不是医学诊断"
- "如果持续不适，建议咨询医生"

Avoid:

- "诊断房颤"
- "排除心脏病"
- "你有心脏风险"
- "治疗建议"
- "你的心电异常" as a final diagnosis

## Success Criteria

MVP succeeds if:

- Users can understand today's health state within a few seconds.
- Users naturally tap insight buttons instead of hunting through metric pages.
- A question opens a composed analysis page, not a static chart.
- ECG feels useful when present but the app remains valuable without ECG.
- Health explanations show evidence, data sources, and confidence.
- The app can persist user display preferences for future analyses.
