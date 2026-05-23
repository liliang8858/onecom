# AGENTS.md — OneCom Monorepo

> Context an agent needs to work in this repo without asking obvious questions.

---

## What This Repo Is

A **config-driven monorepo**. Multiple iOS apps live under `apps/`, each declared by a single `ci/ios.json` file. A Python discovery script + GitHub Actions dynamic Matrix handles build orchestration. No CI changes needed to add a new app.

Currently two projects exist: `apps/health-agent/` (iOS) and `agents/enterprise-agent/` (cloud).

---


## Agents System (`agents/`)

Cloud-side AI Agent projects. Currently one:

### `enterprise-agent` — 企业级 AI Agent 万能模板

Architecture: LangGraph orchestration, LLM gateway (GPT/Claude/Qwen), memory (short/long/vector/graph), tool layer, hybrid RAG, multi-agent collaboration. Covers full lifecycle from entry to production.

| File | Purpose |
|------|---------|
| `agents/enterprise-agent/README.md` | Project overview |
| `agents/enterprise-agent/docs/AI Agent 企业级开发技术设计文档.md` | Full architecture & implementation guide (v1.0) |

---


## Key Commands

| What | Command | Where |
|------|---------|-------|
| Generate Xcode project | `cd apps/health-agent/ios && xcodegen generate` | Mac only |
| Validate structure | `powershell -ExecutionPolicy Bypass -File apps/scripts/validate_health_agent.ps1` | Any OS |
| Preview H5 prototype | `cd apps/health-agent/h5 && python -m http.server 4173` | Any OS |
| Build via Fastlane | `bundle exec fastlane ios monorepo_build` | CI / Mac runner |
| Init signing (admin) | `bundle exec fastlane match appstore -a <bundle_id>` | Mac, one-time per app |
| Install Ruby deps | `bundle install` | Mac runner or local |

---

## Adding a New App

1. Create `apps/<name>/ios/` with SwiftUI source code under `HealthAgent/`-style directory
2. Create `apps/<name>/ci/ios.json` with at minimum: `id`, `project_path`, `scheme`, `configuration`, `export_method`, `bundle_id`
3. Include a `project.yml` at `apps/<name>/ios/project.yml` (XcodeGen)
4. Optionally add `apps/<name>/h5/` prototype and `apps/<name>/product/` design assets
5. Commit and push — CI discovers it automatically

**Do NOT modify** `.github/workflows/`, `apps/fastlane/Fastfile`, or `apps/ci/discover_ios_projects.py` when adding an app.

---

## CI/CD Flow

```
push (develop/main) or tag or workflow_dispatch
  → discover job (Ubuntu): runs apps/ci/discover_ios_projects.py
    → scans apps/*/ci/ios.json
    → compares changed files against SHARED_PATH_PREFIXES
    → outputs dynamic GitHub Actions matrix
  → build job (self-hosted Mac runner):
    → xcodegen generate (if project.yml exists)
    → bundle install
    → bundle exec fastlane ios monorepo_build
    → upload ipa artifact (always) + TestFlight (if upload=testflight)
```

### Incrementality Rules

- Files under `apps/<app-name>/` → build only that app
- Files under `shared/`, `packages/`, `apps/ci/`, `apps/fastlane/`, `apps/Gemfile`, `apps/Gemfile.lock`, `.github/workflows/ios-monorepo-build.yml` → build **all** apps
- Tag `ios/<id>/v<ver>` → build only that app, upload to TestFlight
- `workflow_dispatch` with `project=<id>` → build only that app
- `workflow_dispatch` with `project=all` → build everything

---

## Fastlane Lane Details

Lane: `ios monorepo_build` in `apps/fastlane/Fastfile`

Reads these env vars (injected from Matrix + CI secrets):
- `PROJECT_ID`, `PROJECT_PATH`, `SCHEME_NAME`, `CONFIGURATION`, `EXPORT_METHOD`, `BUNDLE_ID` (required)
- `WORKSPACE_NAME`, `XCODEPROJ_NAME`, `DEPENDENCY`, `UPLOAD_TARGET` (optional)

Behavior:
- If `DEPENDENCY=cocoapods` → runs `pod install`
- If `UPLOAD_TARGET=none` → unsigned simulator build (`CODE_SIGNING_ALLOWED=NO`), **no signing step**
- If `UPLOAD_TARGET=testflight` → `match` (readonly) → `build_app` → `upload_to_testflight`

Matchfile is at `apps/fastlane/Matchfile`: `type("appstore")` + `readonly(true)`.

---

## Mac Runner Requirements

| Requirement | Value |
|-------------|-------|
| Labels | `self-hosted`, `macOS`, `ios-builder`, `xcode`, `fastlane` |
| Concurrency | `max-parallel: 1` (prevents Xcode/keychain contention) |
| Xcode | Official release version |
| Software | Git, Ruby, Bundler, Fastlane, (CocoaPods if needed) |
| Network | Access to `github.com`, `api.github.com`, `*.actions.githubusercontent.com` |
| Sleep | Disabled (`sudo pmset -a sleep 0`) |
| User | Dedicated `ci` macOS user recommended |

Secrets required in GitHub repo settings: `MATCH_PASSWORD`, `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_CONTENT`.

---

## Health Agent — Product Constraints

These are non-negotiable for the `health-agent` app specifically:

- **First screen is `Today Health Home`** — answers "how am I today?" before anything else
- **Experience order**: Today status → Agent discovery → Health modules → Smart questions → Dynamic analysis → ECG enhancement
- **ECG is optional/enhancement** — never a gate for other features; only enriches cardiac analysis when data exists
- **No diagnostic language** — all health expressions must be non-diagnostic and restrained
- **Health data stays local** by default
- **Agent generates UI Schema (JSON), not iOS code** — app renders via a white-listed set of SwiftUI components
- **Dependency management**: Swift Package Manager (not CocoaPods)

---

## Project Structure Quirks

- Swift sources live at `apps/health-agent/ios/HealthAgent/` — the `HealthAgent` directory is directly inside `ios/`, not nested in an `.xcodeproj` package. `project.yml` references `path: HealthAgent`.
- Xcode projects are **not committed** — `.gitignore` excludes `HealthAgent.xcodeproj/`. They're generated by `xcodegen generate` on the Mac runner (and locally for dev).
- The `upload` field in `ios.json` is intentionally `"none"` — this enables unsigned simulator builds for CI validation before signing is set up.
- Validation script (`apps/scripts/validate_health_agent.ps1`) forbids: `NavigationStack`, `import Charts`, `TODO`, `fatalError`, medical diagnosis terms, and large cornerRadius (>8).

---

## What NOT to Commit

- App Store Connect API keys, match passwords, certificates, profiles → GitHub Secrets only
- Generated `.xcodeproj` / `.xcworkspace` / `xcuserdata` → in `.gitignore`
- `DerivedData/`, `build/`, `*.ipa`, `*.xcarchive`, `vendor/bundle/` → in `.gitignore`
- `.env`, `.env.*` → in `.gitignore`

---

## Reference Files

| File | Purpose |
|------|---------|
| `README.md` | High-level repo overview |
| `CLAUDE.md` | Detailed project conventions and design rationale |
| `apps/ci/discover_ios_projects.py` | The auto-discovery script (source of truth for incrementality) |
| `.github/workflows/ios-monorepo-build.yml` | CI workflow |
| `apps/fastlane/Fastfile` | Build lane |
| `apps/fastlane/Matchfile` | Signing config |
| `apps/health-agent/ci/ios.json` | Current app's build manifest |
| `apps/health-agent/ios/project.yml` | XcodeGen project definition |
| `apps/docs/ios-monorepo-ci.md` | Full CI/CD architecture explainer |
| `apps/docs/mac-runner-setup.md` | Runner installation and troubleshooting |
\| `CODEX_PROJECT_MEMORY\.md` \| Detailed project memory
| `agents/enterprise-agent/docs/AI Agent 企业级开发技术设计文档.md` | Enterprise Agent architecture | (less frequently needed) |