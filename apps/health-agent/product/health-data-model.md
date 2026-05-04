# Health Agent 健康数据模型

## 数据原则

Health Agent 不按原始指标页组织体验，而按用户真正关心的问题组织健康数据。

数据分三类：

| 类型 | 示例 | 产品角色 | 是否依赖 ECG |
| --- | --- | --- | --- |
| 连续数据 | 心率、静息心率、HRV、睡眠、步数、活动能量、呼吸频率、血氧 | 日常分析底座 | 否 |
| 事件数据 | 运动记录、症状、异常心率事件、用户备注 | 解释某个时间点发生了什么 | 否 |
| 增强数据 | ECG 波形、ECG 分类、节律特征 | 深度解释关键心脏事件 | 需要 ECG |

## HealthKit 访问原则

HealthKit 权限必须渐进、明确、按需请求。

App 应解释：

- 需要什么数据
- 为什么需要这些数据
- 这些数据能解锁什么分析
- 部分数据缺失时还能分析到什么程度

## 隐私边界

默认策略：

- 原始 HealthKit 数据留在设备本地。
- 洞察页优先使用本地派生指标和摘要。
- 服务端或 Agent 只接收用户明确同意的摘要数据。

用户控制：

- 查看每次洞察使用的数据来源。
- 删除分析历史。
- 删除偏好记忆。
- 撤销 HealthKit 权限。
- 未经明确授权，不上传原始 ECG 波形。

## 标准化指标模型

每个 HealthKit 指标应标准化为稳定模型：

```text
metric_id
display_name
unit
category
sample_type
aggregation_method
time_granularity
permission_status
available_range
source_devices
```

示例指标 ID：

- `heart_rate`
- `resting_heart_rate`
- `heart_rate_variability`
- `sleep_duration`
- `sleep_stage`
- `step_count`
- `active_energy`
- `workouts`
- `vo2_max`
- `respiratory_rate`
- `blood_oxygen`
- `body_weight`
- `mindful_minutes`
- `ecg`

## 派生特征层

Agent 不应直接分析原始样本。App 应先生成结构化特征：

- 7 日均值
- 30 日均值
- 90 日趋势
- 个人基线
- 周环比变化
- 基线偏离
- 异常点
- 波动性
- 缺失数据窗口
- 恢复评分
- 睡眠债
- 运动负荷
- 心率恢复
- 相关性候选
- 好状态日和差状态日样本

## 数据组合包

### Recovery Pack 恢复组合

指标：

- HRV
- 静息心率
- 睡眠时长
- 睡眠规律性
- 运动负荷
- 活动能量

回答：

- 我最近恢复得好吗？
- 运动是不是太多了？
- 为什么这周状态差？

### Sleep Pack 睡眠组合

指标：

- 睡眠阶段
- 睡眠时长
- 入睡和醒来时间
- 夜间心率
- 呼吸频率
- 血氧，可用时加入

回答：

- 昨晚睡得怎么样？
- 为什么我睡不好？
- 睡眠影响心脏状态吗？

### Heart Pack 心脏组合

指标：

- 心率
- 静息心率
- HRV
- 步行心率
- 心率恢复
- ECG，可用时加入

回答：

- 最近心脏状态稳定吗？
- 最近心率为什么偏高？
- 最近心律稳定吗？

### Training Load Pack 运动负荷组合

指标：

- 运动记录
- 活动能量
- 运动分钟数
- 心率区间
- 步数
- HRV
- 静息心率

回答：

- 运动是不是太多了？
- 运动后恢复好吗？
- 运动对睡眠有帮助吗？

### Anomaly Pack 异常组合

指标：

- 所有已授权核心指标
- 个人基线
- 缺失数据
- 设备来源质量

回答：

- 最近有什么异常？
- 我该关注哪个指标？

### Weekly Review Pack 周期复盘组合

指标：

- 睡眠
- 心率
- HRV
- 运动
- 活动
- 异常
- ECG 事件，可用时加入

回答：

- 这周健康状态总结
- 下周我应该关注什么？

## ECG Episode 模型

每次 ECG 都应抽象为事件对象：

```text
ecg_id
start_time
end_time
apple_classification
average_heart_rate
sampling_frequency
voltage_measurements_reference
signal_quality_score
rhythm_stability_score
waveform_features
context_before
context_after
symptom_tags
episode_summary
```

ECG 波形和高级分析属于高度敏感健康数据，必须谨慎处理。

## ECG 特征层

可自研的 ECG 特征：

- 信号质量
- 噪声水平
- 基线漂移
- RR 间期序列
- 节律规律性
- P 波观察
- QRS 观察
- T 波观察
- QT / QTc 估计
- 心搏分类
- 与历史 ECG 对比

所有输出都应表达为“观察点”，不能表达为诊断。

## ECG 上下文窗口

ECG 事件解释应拉取事件前后的健康上下文：

| 时间窗口 | 数据 | 目的 |
| --- | --- | --- |
| 前 24 小时 | 睡眠、运动、HRV、心率、血氧 | 找背景因素 |
| 前 2 小时 | 心率、活动、症状、咖啡因或饮酒标签 | 找直接上下文 |
| ECG 期间 | 波形、心率、信号质量 | 分析事件本体 |
| 后 2 小时 | 心率和症状状态 | 看事件是否持续 |
| 后 24 小时 | HRV、睡眠、静息心率 | 看后续影响 |

## ECG 增强问题

不依赖 ECG，但有 ECG 时增强：

- 最近心脏状态稳定吗？
- 为什么我最近容易心慌？
- 运动后心脏恢复好吗？
- 睡眠差会影响心脏状态吗？
- 最近心率为什么偏高？

必须有 ECG 才能回答：

- 解读我最新一次心电
- 这次 ECG 和上次有什么不同？
- 为什么这次 ECG 不可判读？
- 这次心电的信号质量怎么样？
- 最近几次 ECG 有什么变化？

## iOS 数据服务模块

建议模块拆分：

```text
HealthKit/
  HealthKitPermissionManager.swift
  HealthDataStore.swift
  HealthMetricQueryService.swift
  ECGQueryService.swift

Agent/
  AgentClient.swift
  UISchemaModels.swift
  InsightQuestionModels.swift
  HealthContextBuilder.swift

Renderer/
  DynamicInsightPageView.swift
  HealthBlockRenderer.swift
  ComponentRegistry.swift

Models/
  HealthMetric.swift
  DerivedInsight.swift
  ECGEpisode.swift
  UserPreference.swift
```

## MVP 数据优先级

第一版优先支持：

- 睡眠
- HRV
- 静息心率
- 心率
- 活动能量
- 运动记录
- 步数
- 呼吸频率，可用时加入
- 血氧，可用时加入
- ECG，可用时加入

即使没有 ECG，App 也必须依然有日常价值。
