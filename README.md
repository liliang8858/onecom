<p align="center">
  <h1 align="center">OneCom iOS Monorepo</h1>
  <p align="center">多应用统一仓库 · 自动发现构建 · 一键发布 TestFlight</p>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2015%2B-blue?style=flat-square&logo=apple" />
  <img src="https://img.shields.io/badge/Xcode-15%2B-147EFB?style=flat-square&logo=xcode" />
  <img src="https://img.shields.io/badge/CI-GitHub%20Actions-2088FF?style=flat-square&logo=githubactions" />
  <img src="https://img.shields.io/badge/Lane-Fastlane-FFAC45?style=flat-square&logo=ruby" />
  <img src="https://img.shields.io/badge/Signing-match-G2E313E?style=flat-square&logo=letsencrypt" />
  <img src="https://img.shields.io/badge/License-Private-red?style=flat-square" />
</p>

---

## 项目简介

OneCom 是一个 iOS Monorepo 方案，将多个 iOS 应用统一管理在同一个 Git 仓库中。通过 **配置驱动 + 自动发现** 机制，新增应用无需修改 CI 主流程，只需提交一个 `ios.json` 配置文件即可自动纳入构建管线。

### 已初始化子项目

| 项目 | 路径 | 定位 | CI 配置 |
|------|------|------|---------|
| Health Agent iOS | `apps/health-agent/` | Apple Health 连续数据 + ECG 增强的智能健康 Agent App | `apps/health-agent/ci/ios.json` |

### 核心特性

- **零配置发现** — 新增子项目只需添加 `apps/<name>/ci/ios.json`，CI 自动扫描识别
- **智能增量构建** — 仅构建发生变更的应用，共享代码改动时自动全量触发
- **动态 Matrix 调度** — GitHub Actions 根据变更范围动态生成构建矩阵
- **统一签名管理** — fastlane match 集中管理证书与 Provisioning Profile
- **Tag 驱动发布** — `ios/<app>/v<version>` 格式 Tag 触发单应用 TestFlight 上传
- **Self-Hosted Mac Runner** — 专用 Mac 构建机，稳定可控

---

## 仓库结构

```
onecom/
├── apps/                           # 应用目录
│   ├── shop/                       #   商城应用
│   │   ├── ios/                    #     Xcode 工程
│   │   └── ci/
│   │       └── ios.json            #     构建清单
│   ├── driver/                     #   司机端应用
│   │   ├── ios/
│   │   └── ci/ios.json
│   └── customer/                   #   客户端应用
│       ├── ios/
│       └── ci/ios.json
├── shared/                         # 共享代码 / 公共组件
├── ci/
│   └── discover_ios_projects.py    # 子项目自动发现脚本
├── fastlane/
│   ├── Fastfile                    # 统一构建 Lane
│   └── Matchfile                   # 签名配置
├── .github/
│   └── workflows/
│       └── ios-monorepo-build.yml  # 主 CI/CD 流水线
├── docs/                           # 项目文档
│   ├── ios-monorepo-ci.md          #   CI/CD 架构设计
│   └── mac-runner-setup.md         #   Mac Runner 配置指南
└── CLAUDE.md
```

---

## 快速开始

### 1. 新增子项目

创建应用目录与构建清单：

```
apps/<app-name>/
├── ios/                  # Xcode workspace / project
└── ci/
    └── ios.json          # 构建配置
```

**`ios.json` 示例：**

```json
{
  "id": "shop",
  "name": "Shop iOS",
  "project_path": "apps/shop/ios",
  "workspace": "Shop.xcworkspace",
  "scheme": "Shop",
  "configuration": "Release",
  "export_method": "app-store",
  "bundle_id": "com.yourcompany.shop",
  "dependency": "cocoapods",
  "upload": "testflight"
}
```

### 2. 初始化签名（首次）

```bash
bundle exec fastlane match appstore -a com.yourcompany.shop
```

### 3. 提交即上线

```bash
git add apps/shop
git commit -m "feat: add shop iOS app"
git push origin develop
```

CI 自动发现 → 生成 Matrix → 派发至 Mac Runner → 构建完成。

---

## CI/CD 触发策略

| 触发方式 | 行为 | 用途 |
|---------|------|------|
| `push develop` | 仅构建变更的应用 | 日常开发验证 |
| `push main` | 构建变更应用 + 上传 ipa artifact | 主分支制品归档 |
| `tag ios/<app>/v<ver>` | 构建指定应用 + 上传 TestFlight | 正式发布 |
| `workflow_dispatch (all)` | 手动全量构建 | 紧急 / 回归验证 |
| `workflow_dispatch (shop)` | 手动构建指定应用 | 单项目调试 |

### 智能变更检测

```
变更文件 ∈ apps/shop/     → 仅构建 shop
变更文件 ∈ shared/        → 全量构建（共享代码影响所有应用）
变更文件 ∈ ci/ 或 fastlane/ → 全量构建（基础设施变更）
```

---

## 技术栈

| 组件 | 技术方案 |
|------|---------|
| 仓库模式 | Monorepo（多应用统一管理） |
| CI/CD | GitHub Actions + Dynamic Matrix |
| 构建工具 | Fastlane (`build_app` + `match`) |
| 签名管理 | fastlane match（readonly in CI） |
| 构建机 | Self-hosted Mac Runner |
| 依赖管理 | CocoaPods / SPM（按应用配置） |
| 发布渠道 | TestFlight（App Store Connect API） |

---

## Mac Runner 配置

详见 [Mac Runner 配置指南](docs/mac-runner-setup.md)

**Runner 规格要求：**

| 项目 | 要求 |
|------|------|
| 系统 | macOS 11 Big Sur 或以上 |
| Xcode | 正式版（与项目匹配） |
| 网络 | 可访问 github.com / api.github.com |
| 标签 | `self-hosted`, `macOS`, `ios-builder` |
| 并发 | `max-parallel: 1`（单机构建） |

**注册命令：**

```bash
cd ~/actions-runner
./config.sh \
  --url https://github.com/<org>/<repo> \
  --token <TOKEN> \
  --name mac-ios-builder-01 \
  --labels macOS,ios-builder,xcode,fastlane

./svc.sh install && ./svc.sh start
```

---

## 发布流程

```bash
# 发布 shop v1.2.0
git tag ios/shop/v1.2.0
git push origin ios/shop/v1.2.0

# 发布 driver v2.0.0
git tag ios/driver/v2.0.0
git push origin ios/driver/v2.0.0
```

Tag 格式：`ios/{project_id}/v{version}`

CI 解析 Tag → 仅构建目标应用 → 签名 → 上传 TestFlight。

---

## GitHub Secrets

在 `Repository → Settings → Secrets and variables → Actions` 中配置：

| Secret 名称 | 用途 |
|-------------|------|
| `MATCH_PASSWORD` | fastlane match 加密密码 |
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API Key ID |
| `APP_STORE_CONNECT_API_ISSUER_ID` | App Store Connect Issuer ID |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | App Store Connect API Key 内容 |

---

## 文档

| 文档 | 说明 |
|------|------|
| [CI/CD 架构设计](docs/ios-monorepo-ci.md) | Monorepo 自动发现 + 动态 Matrix 完整方案 |
| [Mac Runner 配置指南](docs/mac-runner-setup.md) | Self-hosted Mac Runner 安装与注册 |

---

## 设计理念

> **一个仓库，一套流程，N 个应用。**

新增应用的成本 = **提交一个 JSON 文件**。

不需要改 Workflow，不需要改 Fastfile，不需要动 Mac Runner。CI 自动扫描、自动发现、自动构建。
