# Health Agent UI v2 Industrial H5

这是 `apps/health-agent/product/uiv2` 第二版 UI 的工业级 H5 复刻实现。

本目录不是把设计稿整图直接放进页面，而是按前端工程流程拆成：

- 可维护 HTML 结构
- 组件化 JavaScript 渲染
- 响应式 CSS 视觉系统
- 从资产图切出的独立 PNG 资产
- manifest、QA contact sheet、源图标注与过程说明

## 目录

```text
uiv2-industrial/
├── index.html
├── styles.css
├── app.js
├── assets/
│   ├── manifest.json
│   ├── brand_app_icon.png
│   ├── mascot_hero_wave.png
│   └── ...
├── asset_cutout_project/
│   ├── manifest.json
│   ├── manifest.csv
│   ├── PROCESS_NOTES.md
│   ├── qa/qa_contact_sheet.png
│   ├── source_previews/
│   └── original_sources/
└── tools/
    └── build_assets.py
```

## 设计还原原则

1. 源设计稿只作为视觉参考，不作为页面背景。
2. 可复用元素从 `资产图001-003.png` 切成透明 PNG，并通过 manifest 管理。
3. 手机壳、卡片、图表、按钮、状态条、列表、Tab 等全部用 HTML/CSS/JS 组件实现。
4. 吉祥物、品牌图标、插画资产使用独立 PNG，不把整屏 UI 当图片塞入页面。
5. 桌面端按第二版设计稿的四机位展示还原；移动端按真实 H5 响应式规则重排。

## 本地运行

```bash
cd apps/health-agent/h5/uiv2-industrial
python -m http.server 4176
```

访问：

```text
http://localhost:4176
```

## 资产重建

```bash
python tools/build_assets.py
```

脚本会重新生成：

- `assets/*.png`
- `assets/manifest.json`
- `asset_cutout_project/manifest.json`
- `asset_cutout_project/manifest.csv`
- `asset_cutout_project/qa/qa_contact_sheet.png`
- `asset_cutout_project/source_previews/*_numbered.png`

## QA 截图

当前已输出：

- `qa-desktop.png`
- `qa-mobile.png`
- `qa-ui001-home.png`

推荐每次改动后重新跑桌面和移动端截图，检查是否有横向溢出、文字裁切、资产边缘污染、层级错乱。

## UI001 首页专题

首页专题入口：

```text
http://localhost:4176/ui001.html
```

对应文件：

- `ui001.html`
- `ui001.css`
- `ui001.js`
- `tools/build_ui001_home_audit.py`
- `ui001_home_audit/manifest.json`
- `ui001_home_audit/PROCESS_NOTES.md`

这个专题页针对 `asset_cutout_project/original_sources/ui001.png` 单独处理，不复用通用四场景页。它按 1448 × 1086 画布拆解首页展示稿，重建了顶部品牌区、信任卡、吉祥物气泡、四台 iPhone、底部价值条、手机内卡片、图表、ECG 波形和导航控件。

已生成审核资料：

- `ui001_home_audit/diagnostics/ui001_regions_numbered.png`
- `ui001_home_audit/diagnostics/ui001_pixel_diff_heatmap.png`
- `ui001_home_audit/ui001_audit.psd`
- `ui001_home_audit/ui001_audit.pptx`

## 与旧版 H5 的区别

`apps/health-agent/h5/uiv2` 是早期像素审核方案，主要用于对照源设计稿。

`apps/health-agent/h5/uiv2-industrial` 才是当前主实现：页面由组件、样式和独立资产组成，可继续接入真实数据、动效和交互。
