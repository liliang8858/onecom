# HealthAgent iOS Project

This directory is reserved for the real Xcode project.

Create the project on macOS with Xcode:

- Product Name: `HealthAgent`
- Interface: SwiftUI
- Language: Swift
- Bundle Identifier: `com.yourcompany.healthagent`
- Minimum target: iOS 15+

Expected files after Xcode setup:

```text
apps/health-agent/ios/
  HealthAgent.xcodeproj
  HealthAgent.xcworkspace
  HealthAgent/
```

CI already points at:

- Workspace: `HealthAgent.xcworkspace`
- Xcode project: `HealthAgent.xcodeproj`
- Scheme: `HealthAgent`

Before the first CI build, make sure the scheme is shared and committed.
