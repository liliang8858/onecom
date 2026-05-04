# Agent 接入说明

当前 Agent 层使用 `MockAgentClient` 驱动 UI。真实服务端接入时保留以下边界：

## Agent 不能做什么

- 不能生成 Swift 代码。
- 不能下发可执行脚本。
- 不能生成任意 UI。
- 不能输出医学诊断结论。

## Agent 应输出什么

Agent 应输出结构化 UI Schema：

```text
HealthPageSchema
  blocks: [HealthUIBlock]
```

App 端只渲染白名单组件：

- `insightSummary`
- `metricDeltaGrid`
- `trendChart`
- `multiMetricTimeline`
- `anomalyList`
- `suggestedQuestions`
- `ecgEpisode`
- `dataSource`

未知组件必须降级处理，不能让 App 崩溃。

## 后续替换点

当前：

```text
MockAgentClient.shared.schema(for:)
```

后续可以替换为：

```text
AgentClient.fetchSchema(questionID:context:)
```

其中 `context` 来自：

```text
HealthContextBuilder.buildTodayContext()
```
