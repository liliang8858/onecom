# Apps — iOS 客户端应用

`apps/` 是 OneCom Monorepo 的 **客户端应用线**，与 `agents/`（云端 AI Agent 系统线）平起平坐。

每个子目录是一个独立的 iOS 应用，通过 `ci/ios.json` 配置文件声明，CI 自动发现并构建。

---

## 当前应用

| 应用 | 路径 | 定位 | CI 状态 |
|------|------|------|---------|
| Health Agent | `health-agent/` | Apple Health + ECG 智能健康 Agent | `upload: none`（模拟器构建验证） |

---

## 新增 iOS 应用

1. 创建 `apps/<app-name>/ios/`，放入 SwiftUI 源码
2. 创建 `apps/<app-name>/ci/ios.json`，填写构建清单
3. 可选：`apps/<app-name>/h5/` 原型、`apps/<app-name>/product/` 设计稿
4. 提交即自动纳入 CI

**`ios.json` 必填字段**：`id`、`project_path`、`scheme`、`configuration`、`export_method`、`bundle_id`

**不要修改** `.github/workflows/`、`fastlane/Fastfile`、`ci/discover_ios_projects.py`——新增应用只加 JSON 即可。

---

## 应用目录规范

```
apps/<app-name>/
├── ios/                    # Xcode workspace / project + 源码
│   ├── project.yml         #   XcodeGen 项目定义
│   └── <AppName>/          #   SwiftUI 源码
├── ci/
│   └── ios.json            #   构建清单（CI 自动发现入口）
├── h5/                     #   H5 高保真交互原型（可选）
├── product/                #   PRD、UI 设计稿、Agent Schema（可选）
└── README.md               #   应用说明
```
