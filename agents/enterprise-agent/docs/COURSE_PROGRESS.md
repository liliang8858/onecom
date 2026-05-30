# Enterprise Agent 课程进度

更新时间：2026-05-30

本文档用于记录学习文档推进状态。新会话开始时，先阅读本文档和 `ENGINEERING_PROGRESS.md`，即可继续上次进度。

## 课程目标

让有一点 Python 基础的学员可以按章节从零实现一个企业级 AI Agent 工程。每一章同时包含概念、代码、练习和验收方式。

## 教学拆分原则

- 每一课只引入 1 到 2 个核心概念。
- 每一课都必须有可运行代码、测试或命令行验收。
- 先用 `Mock` 和内存实现讲清楚边界，再逐步替换为真实模型、数据库和服务。
- 每个大阶段结束时，都要有一个可演示的小系统，而不是只有零散代码。

## 大阶段规划

| 阶段 | 名称 | 目标 | 状态 |
|------|------|------|------|
| A | 工程基础与学习方法 | 建立可安装、可测试、可继续扩展的工程基线 | 进行中 |
| B | LLM 调用与 Prompt 基础 | 学会封装模型调用、管理消息、控制成本和输出格式 | 未开始 |
| C | 单 Agent 核心能力 | 实现 ReAct 循环、工具调用、错误处理和简单任务执行 | 未开始 |
| D | 知识、记忆与上下文 | 实现文档检索、RAG、短期记忆和上下文预算 | 未开始 |
| E | 企业化编排与生产落地 | 引入 LangGraph、API、评估、监控、安全和部署 | 未开始 |

## 细分章节规划

| 章节 | 标题 | 阶段 | 状态 | 对应工程内容 |
|------|------|------|------|--------------|
| 01 | 工程启动与开发环境 | A | 已完成 | `pyproject.toml`、`src/enterprise_agent/`、pytest smoke test |
| 02 | Python 包结构与导入路径 | A | 已完成 | 包目录、`__init__.py`、模块导入练习 |
| 03 | 测试驱动的开发节奏 | A | 已完成 | pytest 断言、失败用例、测试命名规范 |
| 04 | 配置与环境变量基础 | A | 已完成 | `.env.example`、`AppConfig`、默认值、环境变量覆盖 |
| 05 | 日志与错误信息 | A | 已完成 | `configure_logging()`、`format_error_message()`、日志级别和错误消息测试 |
| 06 | LLM 调用长什么样 | B | 未开始 | `Message`、`LLMRequest`、`LLMResponse` |
| 07 | MockLLMClient：不用 API Key 学模型调用 | B | 未开始 | `BaseLLMClient`、`MockLLMClient`、异步测试 |
| 08 | 真实模型客户端边界 | B | 未开始 | OpenAI-compatible client 接口占位、超时、重试 |
| 09 | 多模型路由入门 | B | 未开始 | `LLMRouter`、任务类型、模型选择 |
| 10 | Token 与成本统计 | B | 未开始 | token 估算、调用成本、预算限制 |
| 11 | Prompt 模板基础 | B | 未开始 | prompt 文件、变量渲染、版本字段 |
| 12 | 结构化输出与 JSON 校验 | B | 未开始 | Pydantic schema、解析失败处理 |
| 13 | Agent 是什么：状态、动作、观察 | C | 未开始 | `AgentState`、`AgentAction`、`AgentObservation` |
| 14 | ReAct 循环第一版 | C | 未开始 | Thought/Action/Observation、最大迭代次数 |
| 15 | 工具函数到企业工具 | C | 未开始 | `ToolResult`、`BaseTool`、参数校验 |
| 16 | 工具注册表与工具选择 | C | 未开始 | `ToolRegistry`、按名称查找工具 |
| 17 | 第一个可用 Agent：计算器助手 | C | 未开始 | calculator tool、ReActAgent 集成测试 |
| 18 | Agent 错误处理与熔断 | C | 未开始 | 未知工具、工具异常、循环保护 |
| 19 | 对话历史与 scratchpad | C | 未开始 | 消息历史、执行轨迹、最终回答 |
| 20 | 文档对象与文本切分 | D | 未开始 | `Document`、chunk、metadata |
| 21 | 关键词检索 BM25 简化版 | D | 未开始 | in-memory keyword retriever |
| 22 | 向量检索概念与 MockEmbedding | D | 未开始 | embedding 接口、in-memory vector store |
| 23 | 混合检索与 RRF | D | 未开始 | semantic + keyword 融合排序 |
| 24 | RAG 回答链路 | D | 未开始 | retrieve -> build context -> answer |
| 25 | RAG 质量测试 | D | 未开始 | 小型测试集、命中率、引用检查 |
| 26 | 工作记忆：当前会话上下文 | D | 未开始 | working memory、历史裁剪 |
| 27 | 情景记忆：对话摘要 | D | 未开始 | episode summary、内存存储 |
| 28 | 上下文预算管理 | D | 未开始 | token budget、信息优先级 |
| 29 | LangGraph 状态图入门 | E | 未开始 | planner/executor/synthesizer 最小图 |
| 30 | 人工审批与高风险操作 | E | 未开始 | approval gate、暂停与继续 |
| 31 | FastAPI 对外服务 | E | 未开始 | `/health`、`/chat`、请求响应模型 |
| 32 | 评估流水线入门 | E | 未开始 | eval cases、正确性评分占位 |
| 33 | 指标、日志与追踪 | E | 未开始 | latency、token、cost、request count |
| 34 | Prompt Injection 与数据分级 | E | 未开始 | scanner、L1-L4 数据策略 |
| 35 | Docker 与部署前检查 | E | 未开始 | Dockerfile、launch checklist |

## 当前学习进度

- 当前章节：第 05 章，日志与错误信息，已完成。
- 当前学习文档：`docs/lessons/05-logging-errors.md`。
- 学员完成本章后，应能解释 logger、handler、formatter、日志级别、propagation 和可测试错误消息。

## 下一步

下一章进入第 06 章：LLM 调用长什么样。

第 06 章建议交付：

- 定义 `Message`、`LLMRequest`、`LLMResponse` 等基础数据对象。
- 先用数据结构讲清楚模型调用边界，不接入真实 API。
- 为请求、响应和消息角色写单元测试。
- 继续保持错误消息短、具体、可测试。
