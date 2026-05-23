# Enterprise Agent — 企业级 AI Agent 课程化工程

> **文档版本**: v1.1 | **更新日期**: 2026-05-24 | **架构阶段**: 课程化实现中

---

## 项目定位

Enterprise Agent 是一个 **企业级 AI Agent 系统课程化工程项目**。目标是让学员一边学习文档，一边按章节实现可运行代码，最终完成从零到生产级 Agent 工程的完整路径。

它不是一次性 Demo，也不是只读设计文档。每一章都应同时交付：

- 学习目标
- 背景概念
- 工程代码
- 单元测试
- 学员练习
- 验收标准
- 进度记录

### 核心理念

| 原则 | 说明 |
|------|------|
| **可扩展** | 架构原生支持单 Agent 到多 Agent 协作的平滑演进 |
| **可观测** | 全链路追踪、评估与监控覆盖率 100% |
| **工程化** | 生产级代码标准，完整 CI/CD 流水线 |
| **成本可控** | Token 消耗、推理延迟与资源成本纳入 SLA |

---

## 当前进度

当前已完成第 01 章：工程启动与开发环境。

进度记录维护在：

| 文件 | 作用 |
|------|------|
| [docs/COURSE_PROGRESS.md](docs/COURSE_PROGRESS.md) | 学习章节进度、当前章节、下一章计划 |
| [docs/ENGINEERING_PROGRESS.md](docs/ENGINEERING_PROGRESS.md) | 工程实现进度、已完成代码、遗留状态 |
| [docs/lessons/01-project-setup.md](docs/lessons/01-project-setup.md) | 第 01 章学习文档 |

新会话继续推进时，先阅读 `COURSE_PROGRESS.md` 和 `ENGINEERING_PROGRESS.md`，再进入下一章。

---

## 教学拆分原则

本课程面向有一点 Python 基础的学员。章节拆分遵循以下原则：

- 每一课只引入 1 到 2 个核心概念。
- 每一课都要有可运行代码、测试或命令行验收。
- 先用 `Mock` 和内存实现讲清楚边界，再逐步替换为真实模型、数据库和服务。
- 每个大阶段结束时，都要有一个可演示的小系统。

## 大阶段规划

| 阶段 | 名称 | 目标 | 状态 |
|------|------|------|------|
| A | 工程基础与学习方法 | 建立可安装、可测试、可继续扩展的工程基线 | 进行中 |
| B | LLM 调用与 Prompt 基础 | 学会封装模型调用、管理消息、控制成本和输出格式 | 未开始 |
| C | 单 Agent 核心能力 | 实现 ReAct 循环、工具调用、错误处理和简单任务执行 | 未开始 |
| D | 知识、记忆与上下文 | 实现文档检索、RAG、短期记忆和上下文预算 | 未开始 |
| E | 企业化编排与生产落地 | 引入 LangGraph、API、评估、监控、安全和部署 | 未开始 |

## 学习章节大纲

| 章节 | 标题 | 阶段 | 状态 | 工程交付 |
|------|------|------|------|----------|
| 01 | 工程启动与开发环境 | A | 已完成 | `pyproject.toml`、`src/enterprise_agent/`、pytest smoke test |
| 02 | Python 包结构与导入路径 | A | 未开始 | 包目录、`__init__.py`、模块导入练习 |
| 03 | 测试驱动的开发节奏 | A | 未开始 | pytest 断言、失败用例、测试命名规范 |
| 04 | 配置与环境变量基础 | A | 未开始 | `.env.example`、配置对象、默认值 |
| 05 | 日志与错误信息 | A | 未开始 | logging 基础、错误消息约定 |
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

---

## 已完成章节

### 第 01 章：工程启动与开发环境

学习文档：[docs/lessons/01-project-setup.md](docs/lessons/01-project-setup.md)

已完成内容：

- 建立 Python 包配置：[pyproject.toml](pyproject.toml)
- 统一源码入口：`src/enterprise_agent/`
- 新增项目元信息对象：`ProjectInfo`
- 新增 smoke test：`tests/unit/test_project_setup.py`
- 清理旧的 `src/agents/` 骨架，避免学员看到两个源码入口
- 清理第一阶段不需要的空占位目录

验收命令：

```powershell
python -m pytest
```

当前结果：

```text
1 passed
```

---

## 四阶段演进路线

```text
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ 阶段一    │ -> │ 阶段二    │ -> │ 阶段三    │ -> │ 阶段四    │
│ 系统入门  │    │ 核心开发  │    │ 企业进阶  │    │ 项目落地  │
│          │    │          │    │          │    │          │
│ LLM 基础 │    │ LangChain│    │ 长期记忆 │    │ K8s 部署 │
│ Prompt   │    │ LangGraph│   │ 上下文   │    │ 灰度发布 │
│ 工具调用 │    │ Agent RAG│   │ 高级 RAG │    │ 监控告警 │
│ 记忆系统 │    │ 工具集成 │    │ 多 Agent │    │ 安全合规 │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
```

---

## 整体架构

```text
┌─────────────────────────────────────────────────────────────┐
│                      用户接入层                              │
│         Web / API / Slack / 企业微信 / 钉钉                  │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                   Agent 编排层 (LangGraph)                   │
│    Planner -> Task Decomposer -> Tool Router -> Synthesizer  │
└──────┬──────────────┬──────────────┬───────────────┬────────┘
       │              │              │               │
┌──────▼──────┐ ┌─────▼──────┐ ┌─────▼──────┐ ┌──────▼──────┐
│  LLM 调用层 │ │  记忆系统  │ │   工具层   │ │   RAG 系统  │
│ GPT/Claude/ │ │ 短期/长期  │ │ API/代码/  │ │ 检索+重排+  │
│ Qwen/本地化 │ │ 向量/图谱  │ │ 搜索/DB    │ │ 生成融合    │
└─────────────┘ └────────────┘ └────────────┘ └─────────────┘
```

---

## 技术选型矩阵

| 组件 | 推荐选型 | 备选方案 | 选型理由 |
|------|---------|---------|---------|
| **编排框架** | LangGraph | CrewAI, AutoGen | 状态图更适合企业复杂流程 |
| **向量数据库** | Qdrant | Pinecone, Weaviate | 开源可私有化，性能强 |
| **关键词检索** | Elasticsearch | OpenSearch | 成熟生态，BM25 + 过滤 |
| **重排模型** | BGE-Reranker-v2 | Cohere Rerank | 中文效果最佳，可本地化 |
| **嵌入模型** | text-embedding-3-large | BGE-M3 | 通用场景首选 |
| **缓存** | Redis 7 | Memcached | 支持向量相似缓存 |
| **消息队列** | Kafka | RabbitMQ | 高吞吐，适合 Agent 任务队列 |
| **追踪** | LangSmith | Langfuse | 与 LangChain 深度集成 |
| **监控** | Prometheus + Grafana | Datadog | 开源成本低，定制性强 |
| **CI/CD** | GitHub Actions + ArgoCD | Jenkins | GitOps 最佳实践 |
| **API 框架** | FastAPI | Flask | 异步优先，自动 OpenAPI |
| **LLM 推理** | vLLM | TGI | 高吞吐本地推理 |

---

## 当前项目骨架

```text
enterprise-agent/
├── pyproject.toml
├── src/
│   └── enterprise_agent/
│       ├── __init__.py
│       └── project.py
├── tests/
│   └── unit/
│       └── test_project_setup.py
├── docs/
│   ├── AI Agent 企业级开发技术设计文档.md
│   ├── COURSE_PROGRESS.md
│   ├── ENGINEERING_PROGRESS.md
│   └── lessons/
│       └── 01-project-setup.md
└── README.md
```

后续章节需要哪个模块，就在哪一章创建对应目录。这样可以让学员看到工程是如何一步步长出来的。

---

## 安全设计

### Prompt Injection 防护

内置注入检测引擎，对用户输入进行模式扫描：ignore instructions、jailbreak、DAN 等攻击模式自动拦截。

### 数据安全分级

| 等级 | 数据类型 | 处理规范 |
|------|---------|---------|
| L1 公开 | 公开文档、FAQ | 可送外部 API |
| L2 内部 | 业务数据、报表 | 脱敏后送 API |
| L3 机密 | 财务、客户 PII | 仅允许本地模型 |
| L4 绝密 | 战略规划、源码 | 完全隔离，人工处理 |

---

## 快速开始

当前第 01 章可运行命令：

```powershell
cd E:\onecom\agents\enterprise-agent
python -m pip install -e ".[dev]"
python -m pytest
```

后续 API、评估和部署命令会在对应章节实现后再加入。

---

## 相关文档

| 文档 | 说明 |
|------|------|
| [AI Agent 企业级开发技术设计文档 v1.0](docs/AI Agent 企业级开发技术设计文档.md) | 完整架构设计与实现指南 |
| [课程进度](docs/COURSE_PROGRESS.md) | 大阶段、细分章节状态和下一步 |
| [工程进度](docs/ENGINEERING_PROGRESS.md) | 工程实现状态和验证命令 |
| [第 01 章：工程启动与开发环境](docs/lessons/01-project-setup.md) | 当前已完成章节 |

---

## 附录：关键参考资源

- LangChain: https://docs.langchain.com
- LangGraph: https://langchain-ai.github.io/langgraph/
- LangSmith: https://docs.smith.langchain.com
- RAGAS 评估框架: https://docs.ragas.io
- vLLM 部署指南: https://docs.vllm.ai
