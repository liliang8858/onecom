# HealthKit 接入说明

当前 `HealthKit/` 目录已经提供可编译的服务抽象和 Mock 实现，真实 HealthKit 接入时按这个顺序推进：

## 1. 权限

入口文件：

```text
HealthKitPermissionManager.swift
```

第一阶段建议只请求 MVP 需要的数据：

- 睡眠
- 心率
- 静息心率
- HRV
- 运动记录
- 活动能量
- ECG，只在心脏或 ECG 场景需要时请求

不要首次启动就一次性请求所有健康数据。

## 2. 数据读取

入口协议：

```text
HealthDataStore.swift
```

真实实现建议新增：

```text
LiveHealthDataStore.swift
```

并实现：

- `fetchDailySnapshot()`
- `fetchMetricSeries(metricID:range:)`
- `fetchLatestECG()`

## 3. ECG

入口文件：

```text
ECGQueryService.swift
```

ECG 属于低频事件数据，产品中作为增强证据出现。不要把 ECG 作为所有页面的必需数据。

## 4. 隐私边界

- 原始 HealthKit 数据默认留在本地。
- 服务端 Agent 优先接收摘要特征，而不是原始样本。
- ECG 波形如需上传，必须单独说明用途并请求明确授权。
