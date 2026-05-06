# Health Agent UI v2 切图过程记录

## 目标

从 `apps/health-agent/product/uiv2` 中提取可复用 H5 资产，而不是把整张设计稿作为页面背景。

## 方法

- 吉祥物、Logo、局部装饰采用人工框选 + 近白棋盘背景透明化。
- UI 图标和图表尽量用 CSS/SVG 重建，避免过度依赖栅格切图。
- 保留所有原始源图到 `original_sources/`。
- 输出 manifest、source preview、QA contact sheet。

## 资产数量

- 共输出 10 个 PNG 资产。

## 限制

- 原始资产图是烘焙棋盘背景，不是真透明源。当前透明化适合 H5 原型和视觉审核，若进入生产 App，可针对关键吉祥物再做 AI matte 精修。