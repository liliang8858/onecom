# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iOS monorepo for multiple apps sharing a single GitHub repository. Each app lives under `apps/<app-name>/` with its own iOS project and CI configuration. CI/CD runs on a self-hosted Mac runner via GitHub Actions with Fastlane.

## Repository Structure

```
apps/
  <app-name>/
    ios/              # Xcode workspace/project
    ci/ios.json       # Build manifest (required for CI discovery)
shared/               # Shared code across apps
ci/
  discover_ios_projects.py  # Auto-discovers apps from ios.json files
fastlane/
  Fastfile            # Unified build lane for all apps
.github/workflows/
  ios-monorepo-build.yml    # Main CI/CD workflow
```

## Key Conventions

### Adding a New App
1. Create `apps/<name>/ios/` with Xcode project
2. Create `apps/<name>/ci/ios.json` with required fields: `id`, `project_path`, `scheme`, `configuration`, `export_method`, `bundle_id`
3. Initialize signing: `bundle exec fastlane match appstore -a <bundle_id>` (one-time, on admin machine)
4. Push — CI auto-discovers via `ios.json` scan

### CI Build Triggers
| Trigger | Behavior |
|---------|----------|
| `push develop` | Build only changed apps |
| `push main` | Build changed apps, upload ipa artifact |
| `tag ios/<app>/v<ver>` | Build only that app, upload TestFlight |
| `workflow_dispatch project=all` | Manual full rebuild |

### Shared Code Changes
Changes to `shared/`, `ci/`, `fastlane/`, `Gemfile`, or the workflow file trigger builds for **all** apps. Controlled by `SHARED_PATH_PREFIXES` in `discover_ios_projects.py`.

### Tag Convention
`ios/{project_id}/v{version}` — e.g., `ios/shop/v1.2.0`

## CI/CD Stack
- **GitHub Actions** with dynamic matrix from `discover_ios_projects.py`
- **Fastlane** (`bundle exec fastlane ios monorepo_build`) for building and uploading
- **fastlane match** (readonly in CI) for code signing
- **Self-hosted Mac runner** labeled `[self-hosted, macOS, ios-builder]`
- `max-parallel: 1` — only one concurrent iOS build (single Mac constraint)

## Required GitHub Secrets
`MATCH_PASSWORD`, `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_CONTENT`
