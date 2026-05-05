# Health Agent H5 高保真原型

这个目录是 Health Agent iOS App 的 H5 高保真交互原型，用于快速检查 UI 布局、视觉层级和交互路径。

## 运行方式

可以直接打开：

```text
apps/health-agent/h5/index.html
```

也可以在仓库根目录启动本地静态服务：

```powershell
cd apps\health-agent\h5
python -m http.server 4173
```

然后访问：

```text
http://localhost:4173
```

## 已实现交互

- 今日 / 探索 / 心脏 / 报告 / 我的 Tab
- 今日状态 Hero
- Agent 发现
- 今日模块
- 洞察按钮
- 恢复分析页
- 睡眠分析页
- 心脏状态页
- ECG 详情页
- 异常中心及筛选
- 周报页
- 我的页和 Onboarding 入口

## 预览截图

已生成一张本地渲染截图：

```text
screenshots/today-home-h5.png
```

截图通过 Chrome Headless 在 `430x932` 移动视口下生成。

## 资产

H5 复用项目生成资产：

- `assets/today-hero-background.png`
- `assets/ecg-waveform-sample.png`

这些资产来源于：

```text
apps/health-agent/product/ui/assets/
```

## 设计原则

- 页面布局跟 iOS SwiftUI 实现保持一致。
- H5 用于检查视觉和交互，不替代原生 App。
- 所有健康表达保持非诊断化。
