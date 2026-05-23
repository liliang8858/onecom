# Enterprise Agent 课程进度

更新时间：2026-05-24

本文档用于记录学习文档推进状态。新会话开始时，先阅读本文档和 `ENGINEERING_PROGRESS.md`，即可继续上次进度。

## 课程目标

让基础学员可以按章节从零实现一个企业级 AI Agent 工程。每一章同时包含概念、代码、练习和验收方式。

## 章节规划

| 章节 | 标题 | 状态 | 对应工程内容 |
| --- | --- | --- | --- |
| 01 | 工程启动与开发环境 | 已完成 | Python 包、pytest、项目元信息 |
| 02 | 统一 LLM 网关 | 未开始 | LLMConfig、BaseLLMClient、MockLLMClient |
| 03 | Prompt 与 ReAct 基础循环 | 未开始 | BaseAgent、ReActAgent、scratchpad |
| 04 | 企业工具系统 | 未开始 | ToolResult、BaseTool、ToolRegistry |
| 05 | LangGraph 编排 | 未开始 | planner/executor/validator/synthesizer |
| 06 | RAG 与知识库 | 未开始 | Document、检索器、RRF |
| 07 | 记忆系统与上下文工程 | 未开始 | working/episodic/semantic memory |
| 08 | API、评估、监控与安全 | 未开始 | FastAPI、metrics、安全扫描、Docker |

## 当前学习进度

- 当前章节：第 01 章，工程启动与开发环境，已完成。
- 当前学习文档：`docs/lessons/01-project-setup.md`。
- 学员完成本章后，应能安装开发依赖、理解项目目录、运行测试，并解释为什么企业级 Agent 工程需要先建立可验证的项目基线。

## 下一步

下一章进入第 02 章：统一 LLM 网关。第 02 章会先使用 `MockLLMClient`，避免基础学员一开始就被真实 API Key、网络和计费问题阻塞。
