# Health Agent UI 输出

本目录保存 Health Agent 的视觉设计产物和可用于 iOS 实现的图片资产。

## 目录

```text
ui/
  README.md
  design-system.md
  generation-plan.md
  mockups/
  assets/
```

## 高保真 UI 图

| 文件 | 页面 |
| --- | --- |
| `mockups/today-home.png` | 今日首页 |
| `mockups/recovery-insight.png` | 恢复分析页 |
| `mockups/sleep-insight.png` | 睡眠分析页 |
| `mockups/heart-status.png` | 心脏状态页 |
| `mockups/ecg-detail.png` | ECG 解读页 |
| `mockups/anomaly-center.png` | 异常中心 |
| `mockups/weekly-report.png` | 周报页 |

同时提供 4 倍放大的高清版本：

```text
mockups/8k/
```

## App 图片资产

| 文件 | 用途 |
| --- | --- |
| `assets/today-hero-background.png` | SwiftUI 首页 Hero 背景 |
| `assets/ecg-waveform-sample.png` | SwiftUI ECG 波形卡片 |

这些资产已经复制到：

```text
apps/health-agent/ios/HealthAgent/Resources/Assets.xcassets/
```

对应资源名：

- `TodayHeroBackground`
- `ECGWaveformSample`

## 设计原则

- 首页先回答“我今天怎么样”。
- ECG 作为证据层出现，不作为所有分析的默认入口。
- 所有健康表达保持非诊断化。
- 图表和数据卡保持克制，不制造医疗焦虑。
