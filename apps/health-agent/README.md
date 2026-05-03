# Health Agent iOS

Health Agent is an iOS app built around Apple Health continuous data and ECG-enhanced health intelligence.

It is not a traditional health dashboard. The app starts from a daily Today Health Home, detects what the user may care about, and turns health data into interactive insight flows.

## Product Definition

Health Agent with ECG Intelligence:

> A health Agent app built on continuous Apple Health data, using ECG as high-value evidence for key event interpretation.

Daily Apple Health data answers:

- How am I today?
- Why do I feel this way?
- What changed recently?
- What should I look at next?

ECG adds depth when available:

- What does the latest ECG show?
- How does this ECG compare with previous ones?
- What happened before and after this ECG event?
- Is this heart-related signal connected to sleep, recovery, workout load, or symptoms?

## Core Experience

- Today Health Home
- Agent-generated insight buttons
- Dynamic SwiftUI insight pages
- Apple Health continuous data analysis
- ECG-enhanced event explanation
- Privacy-first local health data processing

## MVP

- Today status overview
- Recovery analysis
- Sleep analysis
- Weekly state explanation
- Anomaly center
- Heart status, with ECG enhancement when available
- Latest ECG interpretation when ECG data exists

## Directory Layout

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

## iOS Project

Target Xcode project:

- Product Name: `HealthAgent`
- Interface: SwiftUI
- Language: Swift
- Bundle Identifier: `com.yourcompany.healthagent`
- Dependency manager: Swift Package Manager

The real Xcode project should be created on macOS and placed under:

```text
apps/health-agent/ios/
```

CI is configured with `upload: none` until signing, Bundle ID, App Store Connect, and TestFlight are ready.
