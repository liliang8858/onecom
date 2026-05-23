# CLAUDE.md

本文件用于说明在当前仓库中协作、阅读和修改代码时应遵守的项目约定。

## 项目概览

OneCom 是一个配置驱动的 Monorepo，统一管理 **iOS 客户端应用**（`apps/`）和 **AI Agent 云端系统**（`agents/`）。每个子 App 放在 `apps/<app-name>/` 下，拥有自己的 iOS 工程和 CI 配置；每个云端 Agent 系统放在 `agents/<agent-name>/` 下，独立设计、开发和部署。仓库目标是通过 GitHub Actions、Fastlane 和自托管 Mac Runner 实现统一发现、构建、签名和发布。

## 当前状态
### 当前仓库已经初始化第一个子 agents 项目：
```text
agents/enterprise-agent/
```
它的产品定位是： 企业级 AI Agent 项目万能模板项目

### 当前仓库已经初始化第一个子 App：

```text
apps/health-agent/
```

它的产品定位是：

```text
Health Agent with ECG Intelligence
```

也就是一个以 Apple Health 连续健康数据为底座、以 ECG 心电作为关键事件增强证据的智能健康 Agent App。

注意：当前 `apps/health-agent/ios/` 还没有真实 Xcode 工程，只有占位说明。根级 CI/CD 骨架也还没有落地，包括：

- `ci/discover_ios_projects.py`
- `fastlane/Fastfile`
- `.github/workflows/ios-monorepo-build.yml`
- `Gemfile`

## 仓库结构约定

目标结构：

```text
apps/
  <app-name>/
    ios/              # Xcode workspace/project
    ci/ios.json       # 构建清单，CI 自动发现入口
shared/               # 多应用共享代码
ci/
  discover_ios_projects.py
fastlane/
  Fastfile
  Matchfile
.github/workflows/
  ios-monorepo-build.yml
docs/
```

## 新增子 App 约定

新增 iOS 子项目时，应创建：

```text
apps/<name>/ios/
apps/<name>/ci/ios.json
```

`ios.json` 至少包含：

- `id`
- `project_path`
- `scheme`
- `configuration`
- `export_method`
- `bundle_id`

可选但推荐包含：

- `name`
- `workspace`
- `xcodeproj`
- `dependency`
- `upload`
- `product_type`
- `description`

## CI/CD 触发约定

| 触发方式 | 行为 |
| --- | --- |
| `push develop` | 只构建发生变化的应用 |
| `push main` | 构建发生变化的应用，并上传 ipa artifact |
| `tag ios/<app>/v<version>` | 只构建指定应用，并上传 TestFlight |
| `workflow_dispatch project=all` | 手动全量构建 |
| `workflow_dispatch project=<app>` | 手动构建指定应用 |

## 共享路径变更

这些路径的变化应触发全量构建：

- `shared/`
- `packages/`
- `ci/`
- `fastlane/`
- `Gemfile`
- `Gemfile.lock`
- `.github/workflows/ios-monorepo-build.yml`

## Tag 规范

发布 tag 使用：

```text
ios/{project_id}/v{version}
```

示例：

```bash
git tag ios/health-agent/v1.0.0
git push origin ios/health-agent/v1.0.0
```

## 技术栈

- GitHub Actions 动态 Matrix
- Fastlane 统一构建 lane
- fastlane match 管理签名
- Self-hosted Mac Runner 执行 iOS 打包
- SwiftUI 作为 Health Agent 首选 UI 技术
- Swift Package Manager 作为 Health Agent 当前依赖方案

## Health Agent 产品约定

Health Agent 不是普通健康 Dashboard。首页应采用 `Today Health Home`，先回答“我今天怎么样”，再进入智能问题和深度分析。

核心顺序：

```text
今日状态
  -> Agent 发现
  -> 健康模块
  -> 智能问题
  -> 动态分析页
  -> ECG 增强解释
```

关键原则：

- Apple Health 连续数据负责日常分析。
- ECG 负责关键事件的增强解释，不是所有分析的必需入口。
- Agent 不生成 iOS 代码，只生成 UI Schema。
- App 端通过白名单 SwiftUI 组件渲染动态页面。
- 健康表达必须克制、非诊断化。
- 原始健康数据默认留在本地。

## 开发注意事项

- 不要提交 App Store Connect API Key、match 密码、证书、profile 或其他密钥。
- 新 App 第一次接入 CI 前，应确认 Xcode scheme 已 shared。
- `upload` 建议先设为 `none`，跑通构建后再改为 `testflight`。
- CI 中 `fastlane match` 应保持 `readonly: true`。
- 如果修改文档，请保持中文为主，技术标识、文件名、命令和 API 名称可保留英文。
