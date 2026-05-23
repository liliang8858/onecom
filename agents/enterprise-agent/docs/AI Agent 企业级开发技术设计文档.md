# AI Agent 企业级开发技术设计文档

> **文档版本：** v1.0  
> **撰写角色：** AI Agent 开发高级经理  
> **适用范围：** 企业 AI Agent 系统从零到生产的全生命周期  
> **更新日期：** 2026-05-22

---

## 目录

1. [文档概述与架构总览](#1-文档概述与架构总览)
2. [阶段一：系统入门 — 打好 Agent 开发基础](#2-阶段一系统入门)
3. [阶段二：核心开发 — 掌握主流开发框架](#3-阶段二核心开发)
4. [阶段三：企业进阶 — 构建智能体核心能力](#4-阶段三企业进阶)
5. [阶段四：项目落地 — 从开发到上线运维](#5-阶段四项目落地)
6. [技术选型矩阵](#6-技术选型矩阵)
7. [安全与合规设计](#7-安全与合规设计)
8. [附录](#8-附录)

---

## 1. 文档概述与架构总览

### 1.1 设计目标

本文档旨在为团队提供一套标准化、可落地的 AI Agent 系统开发规范，覆盖从基础能力建设到企业级生产部署的完整路径，确保：

- **可扩展性**：架构支持从单 Agent 到多 Agent 协作的平滑演进
- **可观测性**：全链路追踪、评估与监控覆盖 100%
- **工程质量**：遵循生产级代码标准，具备完整的 CI/CD 流水线
- **成本可控**：Token 消耗、推理延迟与资源成本纳入 SLA 管理

### 1.2 整体技术架构图

```
┌─────────────────────────────────────────────────────────────┐
│                      用户接入层                              │
│         Web / API / Slack / 企业微信 / 钉钉                  │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                   Agent 编排层 (LangGraph)                   │
│    Planner → Task Decomposer → Tool Router → Synthesizer    │
└──────┬──────────────┬──────────────┬───────────────┬────────┘
       │              │              │               │
┌──────▼──────┐ ┌─────▼──────┐ ┌───▼────────┐ ┌───▼────────┐
│  LLM 调用层  │ │  记忆系统   │ │  工具层     │ │  RAG 系统   │
│ GPT/Claude/ │ │ 短期/长期   │ │ API/代码/  │ │ 检索+重排+  │
│ Qwen/本地化 │ │ 向量/图谱   │ │ 搜索/DB    │ │ 生成融合    │
└─────────────┘ └────────────┘ └────────────┘ └────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│              基础设施层 (Docker / Kubernetes)                 │
│        LangSmith 追踪 | Prometheus 监控 | ELK 日志           │
└─────────────────────────────────────────────────────────────┘
```

### 1.3 四阶段里程碑

| 阶段 | 目标 | 核心交付物 | 周期 |
|------|------|-----------|------|
| 阶段一：系统入门 | 建立 Agent 开发基础 | 基础能力 Demo | 2~3 周 |
| 阶段二：核心开发 | 掌握主流框架 | 可用原型系统 | 4~6 周 |
| 阶段三：企业进阶 | 构建核心智能能力 | 企业级 Agent | 4~6 周 |
| 阶段四：项目落地 | 生产上线与运维 | 生产系统 | 2~4 周 |

---

## 2. 阶段一：系统入门

> **目标**：夯实 Agent 开发四大基础能力，避免在高阶框架上"空中建楼"

### 2.1 大模型调用实战

#### 2.1.1 统一调用接口设计

所有 LLM 调用须通过统一网关封装，禁止在业务代码中硬编码 API Key 或直接裸调 SDK。

```python
# llm_gateway.py — 统一 LLM 调用网关
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Optional, AsyncIterator
import asyncio, tiktoken

@dataclass
class LLMConfig:
    provider: str          # "openai" | "anthropic" | "qwen" | "local"
    model: str
    temperature: float = 0.7
    max_tokens: int = 2048
    timeout: int = 30
    retry_times: int = 3

@dataclass  
class LLMResponse:
    content: str
    prompt_tokens: int
    completion_tokens: int
    latency_ms: float
    model: str

class BaseLLMClient(ABC):
    def __init__(self, config: LLMConfig):
        self.config = config

    @abstractmethod
    async def chat(self, messages: list[dict]) -> LLMResponse:
        pass

    @abstractmethod
    async def stream_chat(self, messages: list[dict]) -> AsyncIterator[str]:
        pass

class OpenAIClient(BaseLLMClient):
    """OpenAI / Azure OpenAI 统一客户端"""
    async def chat(self, messages: list[dict]) -> LLMResponse:
        import time
        from openai import AsyncOpenAI
        client = AsyncOpenAI()  # Key 从环境变量读取
        start = time.time()
        for attempt in range(self.config.retry_times):
            try:
                resp = await client.chat.completions.create(
                    model=self.config.model,
                    messages=messages,
                    temperature=self.config.temperature,
                    max_tokens=self.config.max_tokens,
                )
                return LLMResponse(
                    content=resp.choices[0].message.content,
                    prompt_tokens=resp.usage.prompt_tokens,
                    completion_tokens=resp.usage.completion_tokens,
                    latency_ms=(time.time() - start) * 1000,
                    model=self.config.model,
                )
            except Exception as e:
                if attempt == self.config.retry_times - 1:
                    raise
                await asyncio.sleep(2 ** attempt)  # 指数退避
```

#### 2.1.2 多模型路由策略

```python
class LLMRouter:
    """根据任务类型、成本预算、延迟 SLA 自动路由到最合适的模型"""
    
    ROUTING_RULES = {
        "simple_qa":       {"provider": "openai",    "model": "gpt-4o-mini"},
        "complex_reason":  {"provider": "anthropic", "model": "claude-sonnet-4-20250514"},
        "code_gen":        {"provider": "openai",    "model": "gpt-4o"},
        "chinese_nlp":     {"provider": "qwen",      "model": "qwen-max"},
        "sensitive_data":  {"provider": "local",     "model": "qwen2.5-72b"},  # 数据不出域
    }
    
    def route(self, task_type: str, budget_usd: float) -> LLMConfig:
        rule = self.ROUTING_RULES.get(task_type, self.ROUTING_RULES["simple_qa"])
        return LLMConfig(**rule)
```

#### 2.1.3 Token 成本管控

| 模型 | 输入成本 | 输出成本 | 适用场景 |
|------|---------|---------|---------|
| GPT-4o-mini | $0.15/1M | $0.60/1M | 简单分类、摘要 |
| GPT-4o | $2.5/1M | $10/1M | 复杂推理、代码 |
| Claude Sonnet | $3/1M | $15/1M | 长文档、分析 |
| Qwen-Max | ¥0.04/1K | ¥0.12/1K | 中文场景 |
| 本地部署 | GPU 摊销 | GPU 摊销 | 敏感数据 |

> **硬性规则**：单次 Agent 调用链总 Token 预算上限设为 **100K**，超出触发熔断。

---

### 2.2 开源模型部署

#### 2.2.1 部署方案对比

| 方案 | 适用规模 | 推理框架 | 显存需求 | 推荐场景 |
|------|---------|---------|---------|---------|
| vLLM | 生产级 | PagedAttention | 4×A100 | 高并发 API 服务 |
| Ollama | 开发调试 | llama.cpp | 单卡 24GB | 本地开发 |
| TGI | 企业级 | Rust+Flash Attn | 2×A100 | HuggingFace 生态 |
| SGLang | 高性能 | RadixAttention | 4×H100 | 复杂推理链 |

#### 2.2.2 vLLM 生产部署配置

```yaml
# vllm-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: qwen2-72b-vllm
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: vllm
        image: vllm/vllm-openai:latest
        args:
          - "--model=/models/Qwen2.5-72B-Instruct"
          - "--tensor-parallel-size=4"
          - "--max-model-len=32768"
          - "--gpu-memory-utilization=0.92"
          - "--enable-prefix-caching"          # KV Cache 复用，降低重复 Prompt 成本
          - "--max-num-seqs=256"
          - "--served-model-name=qwen2.5-72b"
        resources:
          limits:
            nvidia.com/gpu: "4"
            memory: "200Gi"
        volumeMounts:
        - name: model-storage
          mountPath: /models
```

#### 2.2.3 量化策略选择

```
模型精度选择决策树：

延迟要求 < 500ms？
├── 是 → 显存充足(>80GB)？
│         ├── 是 → FP16 全精度（最高质量）
│         └── 否 → AWQ INT4（质量损失 < 2%，显存减半）
└── 否 → 批量离线任务？
          ├── 是 → GPTQ INT8（速度与质量平衡）
          └── 否 → GGUF Q4_K_M（CPU 友好，Ollama 适用）
```

---

### 2.3 Agent 基础原理

#### 2.3.1 ReAct 模式标准实现

```python
class ReActAgent:
    """
    ReAct = Reasoning + Acting
    核心循环：Thought → Action → Observation → Thought ...
    """
    MAX_ITERATIONS = 10  # 防止无限循环
    
    def __init__(self, llm: BaseLLMClient, tools: list):
        self.llm = llm
        self.tools = {t.name: t for t in tools}
    
    async def run(self, user_query: str) -> str:
        scratchpad = []
        
        for i in range(self.MAX_ITERATIONS):
            # 1. 思考：让 LLM 决定下一步
            thought_prompt = self._build_prompt(user_query, scratchpad)
            response = await self.llm.chat(thought_prompt)
            
            # 2. 解析 Action
            action = self._parse_action(response.content)
            
            # 3. 终止条件
            if action.type == "FINISH":
                return action.answer
            
            # 4. 执行工具
            tool = self.tools.get(action.tool_name)
            if not tool:
                observation = f"错误：工具 {action.tool_name} 不存在"
            else:
                observation = await tool.execute(action.tool_input)
            
            # 5. 记录到 scratchpad
            scratchpad.append({
                "thought": response.content,
                "action": action,
                "observation": observation,
            })
        
        return "已达最大迭代次数，任务未完成"
```

#### 2.3.2 Agent 决策模式对比

| 模式 | 描述 | 优点 | 缺点 | 适用场景 |
|------|------|------|------|---------|
| ReAct | 交替推理与行动 | 可解释性强 | 延迟高 | 通用任务 |
| Plan-and-Execute | 先规划后执行 | 并行效率高 | 规划失败影响大 | 复杂多步任务 |
| Reflexion | 带自我反思 | 错误恢复能力强 | Token 消耗大 | 高准确率要求 |
| LATS | 树搜索+反思 | 探索性强 | 极高成本 | 难题攻坚 |

---

### 2.4 Prompt 工程规范

#### 2.4.1 企业级 Prompt 模板标准

```python
SYSTEM_PROMPT_TEMPLATE = """
# 角色定义
你是 {role_name}，{role_description}

# 能力边界
你具备以下能力：
{capabilities}

你不应该做以下事情：
{constraints}

# 输出规范
- 语言：{output_language}
- 格式：{output_format}
- 长度限制：{max_length}

# 可用工具
{tools_description}

# 思考框架
在回答前，请按以下步骤思考：
1. 理解用户意图
2. 确认所需信息是否充分
3. 选择最优解决路径
4. 验证输出是否符合约束

# 当前上下文
{context}
"""

class PromptBuilder:
    """结构化 Prompt 构建器，确保一致性"""
    
    def build_cot_prompt(self, task: str) -> str:
        """思维链（Chain of Thought）Prompt"""
        return f"""请解决以下任务，并展示完整的思考过程：

任务：{task}

请按照以下格式回答：
<thinking>
[在这里写出你的分步思考过程]
</thinking>

<answer>
[最终答案]
</answer>"""

    def build_few_shot_prompt(self, task: str, examples: list[dict]) -> str:
        """少样本（Few-Shot）Prompt"""
        examples_text = "\n\n".join([
            f"示例 {i+1}:\n输入：{e['input']}\n输出：{e['output']}"
            for i, e in enumerate(examples)
        ])
        return f"{examples_text}\n\n现在请处理：\n输入：{task}\n输出："
```

#### 2.4.2 Prompt 版本管理规范

```
prompt_registry/
├── v1/
│   ├── system_qa.txt          # 问答系统 Prompt
│   ├── code_review.txt        # 代码审查 Prompt  
│   └── data_analysis.txt      # 数据分析 Prompt
├── v2/                        # 迭代优化版本
└── experiments/               # A/B 测试版本
    ├── exp_001_cot/
    └── exp_002_few_shot/
```

> **规范**：所有生产 Prompt 变更须经过 A/B 测试，在测试集上准确率提升 ≥ 2% 方可发布。

---

## 3. 阶段二：核心开发

> **目标**：熟练掌握 LangChain 1.0、LangGraph、Agentic RAG 及工具集成，构建可运行原型

### 3.1 LangChain 1.0 核心架构

#### 3.1.1 LCEL（LangChain Expression Language）管道设计

```python
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser, JsonOutputParser
from langchain_openai import ChatOpenAI
from langchain_core.runnables import RunnableParallel, RunnablePassthrough

# 基础 Chain
llm = ChatOpenAI(model="gpt-4o", temperature=0)

# 1. 简单问答链
qa_chain = (
    ChatPromptTemplate.from_template("请回答：{question}")
    | llm
    | StrOutputParser()
)

# 2. 并行处理链（同时执行多个子任务）
parallel_chain = RunnableParallel(
    summary=ChatPromptTemplate.from_template("请总结：{text}") | llm | StrOutputParser(),
    keywords=ChatPromptTemplate.from_template("提取关键词（JSON格式）：{text}") | llm | JsonOutputParser(),
    sentiment=ChatPromptTemplate.from_template("分析情感（正面/负面/中立）：{text}") | llm | StrOutputParser(),
)

# 3. 带路由的条件链
from langchain_core.runnables import RunnableBranch

routing_chain = RunnableBranch(
    (lambda x: "代码" in x["question"], code_chain),
    (lambda x: "数据" in x["question"], analysis_chain),
    default_chain,  # 默认链
)
```

#### 3.1.2 LangChain 组件规范

```python
# 自定义工具规范
from langchain_core.tools import tool
from pydantic import BaseModel, Field

class DatabaseQueryInput(BaseModel):
    """数据库查询工具的输入 Schema，Pydantic 严格校验"""
    sql: str = Field(description="要执行的 SQL 查询语句，只允许 SELECT")
    database: str = Field(description="目标数据库名称", default="production")
    limit: int = Field(description="返回行数上限", default=100, le=1000)

@tool("database_query", args_schema=DatabaseQueryInput)
async def database_query(sql: str, database: str, limit: int) -> str:
    """安全地执行数据库只读查询，返回结果的 JSON 字符串"""
    # 安全检查：禁止非 SELECT 语句
    if not sql.strip().upper().startswith("SELECT"):
        return "错误：只允许 SELECT 查询"
    
    # 注入防护：使用参数化查询
    # ... 实际数据库连接逻辑
    return json.dumps(results, ensure_ascii=False)
```

---

### 3.2 LangGraph 实战设计

#### 3.2.1 状态图设计原则

LangGraph 的核心是**有状态的图计算**，适合需要循环、分支、人机协作的复杂 Agent。

```python
from langgraph.graph import StateGraph, END
from typing import TypedDict, Annotated
import operator

# 1. 定义全局状态 Schema（强类型）
class AgentState(TypedDict):
    messages: Annotated[list, operator.add]   # 消息历史（自动追加）
    user_query: str
    plan: list[str]                            # 任务计划
    current_step: int
    tool_results: dict
    final_answer: str
    error_count: int                           # 错误计数，用于熔断

# 2. 定义节点函数（每个节点是纯函数）
async def planner_node(state: AgentState) -> dict:
    """规划节点：分解用户任务为子步骤"""
    plan = await llm.plan(state["user_query"])
    return {"plan": plan, "current_step": 0}

async def executor_node(state: AgentState) -> dict:
    """执行节点：执行当前步骤"""
    current_task = state["plan"][state["current_step"]]
    result = await execute_task(current_task)
    return {
        "tool_results": {**state["tool_results"], current_task: result},
        "current_step": state["current_step"] + 1,
    }

async def validator_node(state: AgentState) -> dict:
    """验证节点：检查执行结果质量"""
    is_valid = await validate_result(state["tool_results"])
    if not is_valid:
        return {"error_count": state["error_count"] + 1}
    return {}

async def synthesizer_node(state: AgentState) -> dict:
    """综合节点：整合所有结果，生成最终答案"""
    answer = await synthesize(state["tool_results"], state["user_query"])
    return {"final_answer": answer}

# 3. 路由函数（决定下一个节点）
def should_continue(state: AgentState) -> str:
    if state["error_count"] >= 3:
        return "error_handler"           # 熔断
    if state["current_step"] >= len(state["plan"]):
        return "synthesizer"             # 所有步骤完成
    return "executor"                    # 继续执行

# 4. 构建图
workflow = StateGraph(AgentState)

workflow.add_node("planner",      planner_node)
workflow.add_node("executor",     executor_node)
workflow.add_node("validator",    validator_node)
workflow.add_node("synthesizer",  synthesizer_node)
workflow.add_node("error_handler", error_handler_node)

workflow.set_entry_point("planner")
workflow.add_edge("planner",   "executor")
workflow.add_edge("executor",  "validator")
workflow.add_conditional_edges("validator", should_continue)
workflow.add_edge("synthesizer", END)

agent = workflow.compile(checkpointer=MemorySaver())  # 开启持久化
```

#### 3.2.2 人机协作（Human-in-the-Loop）设计

```python
# 在敏感操作前暂停，等待人工审批
from langgraph.graph import interrupt

async def approval_gate_node(state: AgentState) -> dict:
    """高风险操作前的人工审批节点"""
    if state["risk_level"] == "HIGH":
        # 暂停图执行，返回给前端等待审批
        human_decision = interrupt({
            "message": "检测到高风险操作，请审批",
            "operation": state["pending_operation"],
            "risk_reason": state["risk_reason"],
        })
        if human_decision["approved"]:
            return {"approved": True}
        else:
            return {"approved": False, "cancel_reason": human_decision["reason"]}
    return {"approved": True}  # 低风险直接通过
```

---

### 3.3 Agentic RAG 架构设计

#### 3.3.1 RAG 模式进化路径

```
基础 RAG          →    高级 RAG          →    Agentic RAG
─────────────────────────────────────────────────────────
朴素检索+生成      →    重排+过滤+压缩    →    Agent 控制检索策略
固定查询           →    查询改写          →    自适应多轮检索
单一数据源         →    混合检索          →    多数据源智能路由
```

#### 3.3.2 Agentic RAG 完整实现

```python
class AgenticRAGSystem:
    """
    Agentic RAG：Agent 主动控制检索过程
    核心能力：
    - 查询分解与改写
    - 自适应检索策略选择
    - 检索结果质量评估
    - 迭代式信息补充
    """
    
    def __init__(self, vector_store, bm25_index, llm):
        self.vector_store = vector_store      # 语义检索
        self.bm25_index = bm25_index          # 关键词检索
        self.llm = llm
        self.reranker = CrossEncoderReranker()
    
    async def retrieve_with_reflection(
        self, 
        query: str, 
        max_iterations: int = 3
    ) -> list[Document]:
        """带自我反思的迭代检索"""
        
        all_docs = []
        current_query = query
        
        for iteration in range(max_iterations):
            # 1. 查询改写（第一轮不改写）
            if iteration > 0:
                current_query = await self._rewrite_query(
                    original=query,
                    retrieved_docs=all_docs,
                    missing_info=missing_info,
                )
            
            # 2. 混合检索
            semantic_docs = await self.vector_store.similarity_search(
                current_query, k=10
            )
            keyword_docs = await self.bm25_index.search(current_query, k=10)
            
            # 3. 融合与重排（RRF + Cross-Encoder）
            merged = self._reciprocal_rank_fusion(semantic_docs, keyword_docs)
            reranked = await self.reranker.rerank(current_query, merged, top_k=5)
            all_docs.extend(reranked)
            
            # 4. 评估是否信息充分
            sufficiency = await self._assess_sufficiency(query, all_docs)
            if sufficiency.is_sufficient:
                break
            missing_info = sufficiency.missing_aspects
        
        # 5. 去重与压缩
        return await self._deduplicate_and_compress(all_docs, query)
    
    async def _assess_sufficiency(self, query: str, docs: list) -> SufficiencyResult:
        """评估检索到的文档是否足以回答问题"""
        prompt = f"""
        用户问题：{query}
        已检索文档摘要：{self._summarize_docs(docs)}
        
        请评估：
        1. 当前文档能否完整回答问题？（是/否）
        2. 如果不能，缺少哪些方面的信息？
        
        以 JSON 格式返回：{{"is_sufficient": bool, "missing_aspects": [str]}}
        """
        result = await self.llm.chat([{"role": "user", "content": prompt}])
        return SufficiencyResult(**json.loads(result.content))
```

---

### 3.4 工具调用与集成规范

#### 3.4.1 企业工具库标准设计

```python
# tools/base.py — 工具基类（所有工具必须继承）
from abc import ABC, abstractmethod
from dataclasses import dataclass
import logging, asyncio

@dataclass
class ToolResult:
    success: bool
    data: any
    error: str = ""
    execution_time_ms: float = 0.0

class EnterpriseBaseTool(ABC):
    """企业工具基类，内置安全校验、限流、日志"""
    
    # 子类必须声明
    name: str
    description: str
    rate_limit_per_minute: int = 60
    
    def __init_subclass__(cls):
        assert hasattr(cls, 'name'), f"{cls.__name__} 必须声明 name"
        assert hasattr(cls, 'description'), f"{cls.__name__} 必须声明 description"
    
    @abstractmethod
    async def _execute(self, **kwargs) -> any:
        """子类实现具体逻辑"""
        pass
    
    async def run(self, **kwargs) -> ToolResult:
        """统一执行入口，包含安全防护"""
        import time
        
        # 限流检查
        if not await self._check_rate_limit():
            return ToolResult(success=False, error="调用频率超限，请稍后重试")
        
        # 参数校验
        validated = self._validate_inputs(kwargs)
        if not validated.ok:
            return ToolResult(success=False, error=validated.error)
        
        start = time.time()
        try:
            result = await asyncio.wait_for(
                self._execute(**kwargs), 
                timeout=30.0
            )
            return ToolResult(
                success=True, 
                data=result,
                execution_time_ms=(time.time() - start) * 1000,
            )
        except asyncio.TimeoutError:
            return ToolResult(success=False, error="工具执行超时（30s）")
        except Exception as e:
            logging.error(f"Tool {self.name} error: {e}", exc_info=True)
            return ToolResult(success=False, error=str(e))

# 工具注册表
TOOL_REGISTRY: dict[str, EnterpriseBaseTool] = {}

def register_tool(tool_class):
    """装饰器：自动注册工具"""
    instance = tool_class()
    TOOL_REGISTRY[instance.name] = instance
    return tool_class
```

#### 3.4.2 标准工具集清单

| 工具类别 | 工具名 | 用途 | 安全级别 |
|---------|--------|------|---------|
| **搜索** | web_search | 实时网络搜索 | LOW |
| **数据库** | sql_query | 只读 SQL 查询 | MEDIUM |
| **代码** | code_executor | 沙箱 Python 执行 | HIGH |
| **文件** | file_reader | 读取授权文件 | MEDIUM |
| **API** | http_request | 调用外部 API | HIGH |
| **计算** | calculator | 精确数学计算 | LOW |
| **邮件** | email_sender | 发送邮件通知 | HIGH |
| **图表** | chart_generator | 生成数据可视化 | LOW |

---

## 4. 阶段三：企业进阶

> **目标**：构建具备企业级能力的 Agent 系统：长期记忆、上下文工程、高级 RAG、多智能体协作

### 4.1 智能体记忆系统设计

#### 4.1.1 记忆分层架构

```
┌─────────────────────────────────────────────────────┐
│                  Agent 记忆体系                      │
├─────────────┬───────────────┬───────────────────────┤
│  工作记忆    │   情景记忆     │       语义记忆         │
│ (In-Context)│  (Episodic)   │      (Semantic)        │
│             │               │                        │
│ 当前对话     │ 历史对话摘要   │ 用户偏好/领域知识        │
│ 执行状态     │ 任务执行记录   │ 实体关系图谱             │
│ 临时计算     │ 错误与反思     │ 持久化业务规则           │
│             │               │                        │
│ Token 窗口  │ 向量数据库     │ 图数据库/向量DB         │
│ 生命周期:    │ 生命周期:      │ 生命周期:               │
│ 单次会话     │ 数周~数月      │ 永久                   │
└─────────────┴───────────────┴───────────────────────┘
```

#### 4.1.2 记忆管理核心代码

```python
class AgentMemorySystem:
    """三层记忆系统统一管理"""
    
    def __init__(self, vector_db, graph_db, redis_client):
        self.vector_db = vector_db          # Pinecone / Weaviate / Qdrant
        self.graph_db = graph_db            # Neo4j
        self.redis = redis_client           # 短期缓存
        self.summarizer = ConversationSummarizer()
    
    # ===== 工作记忆（短期）=====
    
    def get_working_memory(self, session_id: str, max_tokens: int = 4000) -> list:
        """获取当前会话上下文，自动截断至 Token 限制"""
        messages = self.redis.lrange(f"session:{session_id}", 0, -1)
        # 从最新消息开始，向前取直到 Token 用尽
        return self._truncate_to_token_limit(messages, max_tokens)
    
    async def add_to_working_memory(self, session_id: str, message: dict):
        """添加消息，超过阈值自动触发摘要压缩"""
        self.redis.rpush(f"session:{session_id}", json.dumps(message))
        self.redis.expire(f"session:{session_id}", 3600)  # 1小时 TTL
        
        # 消息超过 20 条时压缩
        if self.redis.llen(f"session:{session_id}") > 20:
            await self._compress_to_episodic(session_id)
    
    # ===== 情景记忆（中期）=====
    
    async def _compress_to_episodic(self, session_id: str):
        """将工作记忆压缩为摘要存入向量DB"""
        messages = self.redis.lrange(f"session:{session_id}", 0, -1)
        summary = await self.summarizer.summarize(messages)
        
        # 存入向量数据库
        await self.vector_db.upsert(
            id=f"episode:{session_id}:{int(time.time())}",
            values=await self._embed(summary),
            metadata={
                "session_id": session_id,
                "timestamp": time.time(),
                "summary": summary,
                "type": "episode",
            }
        )
        
        # 清空工作记忆的旧消息
        self.redis.ltrim(f"session:{session_id}", -5, -1)  # 只保留最近 5 条
    
    async def recall_episodes(self, query: str, user_id: str, top_k: int = 3) -> list:
        """语义检索相关历史情节"""
        query_embedding = await self._embed(query)
        results = await self.vector_db.query(
            vector=query_embedding,
            top_k=top_k,
            filter={"user_id": user_id, "type": "episode"},
        )
        return [r.metadata["summary"] for r in results]
    
    # ===== 语义记忆（长期）=====
    
    async def update_user_profile(self, user_id: str, interaction: dict):
        """从交互中提取并更新用户画像"""
        extracted = await self._extract_preferences(interaction)
        
        # 写入图数据库
        await self.graph_db.run("""
            MERGE (u:User {id: $user_id})
            SET u.preferences = $preferences,
                u.updated_at = timestamp()
            WITH u
            UNWIND $entities as entity
            MERGE (e:Entity {name: entity.name, type: entity.type})
            MERGE (u)-[:KNOWS]->(e)
        """, user_id=user_id, 
            preferences=extracted.preferences,
            entities=extracted.entities)
```

---

### 4.2 上下文工程（Context Engineering）

#### 4.2.1 上下文窗口管理策略

```python
class ContextWindowManager:
    """
    精确管理 LLM 上下文窗口，最大化有效信息密度
    遵循 Harness 方法论：结构化、动态、可追溯
    """
    
    CONTEXT_BUDGET = {
        "system_prompt":     0.15,   # 系统提示 15%
        "memory_retrieval":  0.20,   # 记忆检索 20%
        "rag_documents":     0.35,   # RAG 文档 35%
        "conversation":      0.20,   # 对话历史 20%
        "current_query":     0.05,   # 当前问题 5%
        "output_reserve":    0.05,   # 输出预留 5%
    }
    
    def build_context(
        self,
        system_prompt: str,
        user_query: str,
        retrieved_docs: list,
        conversation_history: list,
        memory_summaries: list,
        total_token_limit: int = 128000,
    ) -> list[dict]:
        
        budgets = {k: int(v * total_token_limit) 
                   for k, v in self.CONTEXT_BUDGET.items()}
        
        # 1. 系统提示（最高优先级）
        system = self._truncate(system_prompt, budgets["system_prompt"])
        
        # 2. 记忆摘要（注入到 system 结尾）
        memory_text = self._format_memories(memory_summaries, budgets["memory_retrieval"])
        
        # 3. RAG 文档（重排后按相关性截断）
        docs_text = self._format_docs(retrieved_docs, budgets["rag_documents"])
        
        # 4. 对话历史（从最近往前截断）
        history = self._truncate_history(conversation_history, budgets["conversation"])
        
        # 5. 组装 messages
        messages = [
            {"role": "system", "content": f"{system}\n\n## 用户记忆\n{memory_text}"},
        ]
        
        if docs_text:
            messages.append({
                "role": "user",
                "content": f"## 参考文档\n{docs_text}"
            })
            messages.append({"role": "assistant", "content": "已读取参考文档。"})
        
        messages.extend(history)
        messages.append({"role": "user", "content": user_query})
        
        return messages
```

#### 4.2.2 上下文压缩技术

| 技术 | 压缩比 | 质量损失 | 适用场景 |
|------|-------|---------|---------|
| 滑动窗口 | 50% | 低（丢弃旧信息） | 实时对话 |
| 摘要压缩 | 80% | 中 | 长对话历史 |
| 选择性保留 | 60% | 低 | 任务相关对话 |
| 层次压缩 | 90% | 中 | 超长文档处理 |
| Prompt 压缩（LLMLingua） | 70% | 低 | 检索文档压缩 |

---

### 4.3 RAG 进阶与优化

#### 4.3.1 混合检索架构

```python
class HybridRetriever:
    """
    混合检索 = 语义检索 + 关键词检索 + 结构化检索
    使用 RRF (Reciprocal Rank Fusion) 融合
    """
    
    async def retrieve(self, query: str, k: int = 20) -> list[Document]:
        # 并行执行三路检索
        semantic, keyword, structured = await asyncio.gather(
            self._semantic_search(query, k),      # 向量相似度
            self._bm25_search(query, k),          # BM25 关键词
            self._structured_filter(query, k),    # 元数据过滤
        )
        
        # RRF 融合（k=60 是经验最优值）
        scores = {}
        for rank, doc in enumerate(semantic):
            scores[doc.id] = scores.get(doc.id, 0) + 1/(60 + rank)
        for rank, doc in enumerate(keyword):
            scores[doc.id] = scores.get(doc.id, 0) + 1/(60 + rank)
        for rank, doc in enumerate(structured):
            scores[doc.id] = scores.get(doc.id, 0) + 1/(60 + rank)
        
        # 按融合分数排序，取 top-k
        all_docs = {d.id: d for d in semantic + keyword + structured}
        sorted_ids = sorted(scores, key=scores.get, reverse=True)[:k]
        return [all_docs[id] for id in sorted_ids]
```

#### 4.3.2 RAG 优化全景图

```
索引优化阶段：
├── 分块策略：语义分块（而非固定长度）
├── 多粒度索引：段落级 + 文档级双索引
├── 假设性问题增强（HyDE）
└── 元数据丰富化：自动打标签

检索优化阶段：
├── 查询改写（Query Rewriting）
├── 查询扩展（HyDE / Multi-Query）  
├── 混合检索（Semantic + BM25）
└── 检索质量评估（RAGAS 指标）

后处理阶段：
├── Cross-Encoder 重排序
├── 冗余去除（MMR 最大边际相关）
├── LLM 过滤（相关性判断）
└── 上下文压缩（LLMLingua-2）
```

#### 4.3.3 RAG 评估指标体系（RAGAS）

```python
from ragas import evaluate
from ragas.metrics import (
    faithfulness,           # 忠实度：答案是否基于文档
    answer_relevancy,       # 相关性：答案是否回答了问题
    context_precision,      # 精确率：检索文档是否相关
    context_recall,         # 召回率：关键信息是否被检索到
)

# 自动化评估流水线
async def evaluate_rag_pipeline(test_dataset):
    results = evaluate(
        dataset=test_dataset,
        metrics=[faithfulness, answer_relevancy, context_precision, context_recall],
    )
    
    # SLA 门限：所有指标 >= 0.8 才允许发布
    thresholds = {
        "faithfulness": 0.85,
        "answer_relevancy": 0.80,
        "context_precision": 0.75,
        "context_recall": 0.80,
    }
    
    failures = [m for m, threshold in thresholds.items() 
                if results[m] < threshold]
    
    if failures:
        raise ValueError(f"RAG 质量未达标: {failures}")
    
    return results
```

---

### 4.4 多智能体协作框架

#### 4.4.1 多 Agent 协作模式

```
┌─────────────────────────────────────────────────────┐
│                  Orchestrator Agent                  │
│              (任务分解 & 结果整合)                    │
└────┬──────────┬──────────┬──────────┬───────────────┘
     │          │          │          │
     ▼          ▼          ▼          ▼
┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
│Research │ │ Coding  │ │Analysis │ │ Writer  │
│ Agent   │ │ Agent   │ │ Agent   │ │ Agent   │
│         │ │         │ │         │ │         │
│网络搜索  │ │代码生成  │ │数据分析  │ │报告撰写  │
│文档检索  │ │代码执行  │ │图表生成  │ │格式输出  │
└─────────┘ └─────────┘ └─────────┘ └─────────┘
```

#### 4.4.2 多 Agent 通信协议

```python
from dataclasses import dataclass
from enum import Enum
import uuid

class MessageType(Enum):
    TASK_ASSIGN   = "task_assign"    # 分配任务
    TASK_RESULT   = "task_result"    # 返回结果
    REQUEST_HELP  = "request_help"   # 请求协助
    STATUS_UPDATE = "status_update"  # 进度更新
    ERROR         = "error"          # 错误报告

@dataclass
class AgentMessage:
    """Agent 间通信的标准消息格式"""
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    from_agent: str = ""
    to_agent: str = ""
    type: MessageType = MessageType.TASK_ASSIGN
    content: dict = field(default_factory=dict)
    priority: int = 5                # 1-10，10最高
    timeout_seconds: int = 120
    timestamp: float = field(default_factory=time.time)
    parent_task_id: str = ""         # 追溯任务链

class MultiAgentOrchestrator:
    """多 Agent 编排器"""
    
    def __init__(self, agents: dict[str, BaseAgent]):
        self.agents = agents
        self.message_queue = asyncio.PriorityQueue()
        self.task_tracker = {}
    
    async def execute_complex_task(self, task: str) -> str:
        """编排多个 Agent 协作完成复杂任务"""
        
        # 1. 任务分解
        subtasks = await self.agents["planner"].decompose(task)
        
        # 2. 构建依赖图（DAG）
        dag = self._build_dependency_dag(subtasks)
        
        # 3. 并行执行无依赖的任务
        results = {}
        for batch in dag.topological_batches():
            batch_tasks = [
                self._dispatch_to_agent(subtask, results)
                for subtask in batch
            ]
            batch_results = await asyncio.gather(*batch_tasks)
            results.update(dict(zip(batch, batch_results)))
        
        # 4. 综合所有结果
        return await self.agents["synthesizer"].synthesize(task, results)
    
    async def _dispatch_to_agent(
        self, subtask: SubTask, context: dict
    ) -> str:
        """将子任务路由到最合适的 Agent"""
        # 基于任务类型和 Agent 能力匹配
        best_agent = self._match_agent(subtask.required_skills)
        
        message = AgentMessage(
            from_agent="orchestrator",
            to_agent=best_agent.name,
            type=MessageType.TASK_ASSIGN,
            content={"task": subtask.description, "context": context},
            priority=subtask.priority,
        )
        
        return await best_agent.handle_message(message)
```

---

## 5. 阶段四：项目落地

> **目标**：将 Agent 系统安全、稳定地部署到生产环境，建立完整的监控与运维体系

### 5.1 容器化部署（Docker / Kubernetes）

#### 5.1.1 多阶段 Docker 构建

```dockerfile
# Dockerfile — 生产级多阶段构建
FROM python:3.12-slim AS builder
WORKDIR /app

# 安全：非 root 用户
RUN groupadd -r agent && useradd -r -g agent agent

# 依赖安装（利用 Docker 缓存层）
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

FROM python:3.12-slim AS runtime
WORKDIR /app

# 仅复制运行时依赖
COPY --from=builder /root/.local /root/.local
COPY --from=builder /app /app
COPY src/ ./src/

# 安全配置
RUN chown -R agent:agent /app
USER agent
ENV PATH=/root/.local/bin:$PATH

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s \
    CMD curl -f http://localhost:8000/health || exit 1

EXPOSE 8000
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

#### 5.1.2 Kubernetes 生产部署配置

```yaml
# k8s/agent-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ai-agent-service
  namespace: production
  labels:
    app: ai-agent
    version: v1.2.0
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0          # 零停机更新
  selector:
    matchLabels:
      app: ai-agent
  template:
    spec:
      containers:
      - name: agent
        image: registry.company.com/ai-agent:v1.2.0
        ports:
        - containerPort: 8000
        env:
        - name: OPENAI_API_KEY
          valueFrom:
            secretKeyRef:        # 绝不在代码或 ConfigMap 中存储密钥
              name: llm-secrets
              key: openai-api-key
        resources:
          requests:
            memory: "2Gi"
            cpu: "1000m"
          limits:
            memory: "4Gi"
            cpu: "2000m"
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8000
          initialDelaySeconds: 60
          periodSeconds: 30
      affinity:
        podAntiAffinity:
          requiredDuringScheduling:
            - labelSelector:
                matchLabels:
                  app: ai-agent
              topologyKey: kubernetes.io/hostname   # 跨节点分散
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ai-agent-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ai-agent-service
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second   # 基于业务指标扩缩容
      target:
        type: AverageValue
        averageValue: "100"
```

---

### 5.2 追踪评估（LangSmith）

#### 5.2.1 全链路追踪配置

```python
# tracing/setup.py
from langsmith import Client, traceable
import os

# 全局追踪配置
os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_PROJECT"] = "production-agent-v1"
os.environ["LANGCHAIN_ENDPOINT"] = "https://api.smith.langchain.com"

langsmith_client = Client()

# 自定义追踪装饰器
def agent_trace(name: str, tags: list[str] = None):
    """业务层追踪装饰器"""
    def decorator(func):
        @traceable(
            name=name,
            tags=tags or [],
            metadata={"env": os.getenv("APP_ENV", "production")},
        )
        async def wrapper(*args, **kwargs):
            return await func(*args, **kwargs)
        return wrapper
    return decorator

# 使用示例
@agent_trace(name="customer_service_agent", tags=["customer_service", "rag"])
async def handle_customer_query(query: str, user_id: str) -> str:
    # Agent 逻辑
    ...
```

#### 5.2.2 自动化评估流水线

```python
# evaluation/pipeline.py
class AutoEvaluationPipeline:
    """生产环境自动化质量评估"""
    
    def __init__(self):
        self.langsmith = Client()
        self.evaluators = [
            self._evaluate_correctness,
            self._evaluate_faithfulness,
            self._evaluate_toxicity,
            self._evaluate_latency,
        ]
    
    async def run_daily_evaluation(self):
        """每日自动从生产日志中抽样评估"""
        
        # 1. 从 LangSmith 获取昨日生产数据（随机抽样 5%）
        runs = self.langsmith.list_runs(
            project_name="production-agent-v1",
            start_time=yesterday(),
            filter='and(gt(total_tokens, 0), eq(error, null))',
            limit=500,
        )
        
        # 2. 并行评估
        results = await asyncio.gather(*[
            self._evaluate_run(run) for run in runs
        ])
        
        # 3. 聚合指标
        metrics = self._aggregate_metrics(results)
        
        # 4. 质量告警
        if metrics["correctness"] < 0.85:
            await self._send_alert(
                severity="HIGH",
                message=f"正确率下降至 {metrics['correctness']:.2%}，低于阈值 85%",
                metrics=metrics,
            )
        
        # 5. 生成日报
        return self._generate_daily_report(metrics)
    
    async def _evaluate_correctness(self, run) -> float:
        """使用 LLM 评估答案正确性（LLM-as-Judge）"""
        prompt = f"""
        问题：{run.inputs['query']}
        Agent 答案：{run.outputs['answer']}
        参考答案：{run.reference_output}
        
        请评分（0-1），并给出理由。只返回 JSON：
        {{"score": float, "reason": str}}
        """
        result = await evaluator_llm.chat([{"role": "user", "content": prompt}])
        return json.loads(result.content)["score"]
```

---

### 5.3 性能优化与监控

#### 5.3.1 Prometheus 监控指标设计

```python
# monitoring/metrics.py
from prometheus_client import Counter, Histogram, Gauge, start_http_server

# 业务指标
AGENT_REQUESTS_TOTAL = Counter(
    'agent_requests_total',
    'Agent 总请求数',
    ['agent_type', 'status', 'model']
)

AGENT_LATENCY_SECONDS = Histogram(
    'agent_latency_seconds',
    'Agent 端到端延迟',
    ['agent_type'],
    buckets=[0.5, 1, 2, 5, 10, 30, 60]  # 定义 SLA 分位桶
)

LLM_TOKENS_TOTAL = Counter(
    'llm_tokens_total',
    'LLM Token 消耗',
    ['model', 'type']  # type: prompt/completion
)

LLM_COST_USD = Counter(
    'llm_cost_usd_total',
    'LLM 美元成本',
    ['model']
)

ACTIVE_SESSIONS = Gauge(
    'agent_active_sessions',
    '当前活跃会话数'
)

MEMORY_RETRIEVAL_LATENCY = Histogram(
    'memory_retrieval_latency_seconds',
    '记忆检索延迟',
    ['memory_type']  # working/episodic/semantic
)

# 中间件注入
class MetricsMiddleware:
    async def __call__(self, request, call_next):
        start = time.time()
        try:
            response = await call_next(request)
            AGENT_REQUESTS_TOTAL.labels(
                agent_type=request.headers.get("X-Agent-Type", "default"),
                status="success",
                model=request.headers.get("X-Model", "unknown")
            ).inc()
            return response
        except Exception as e:
            AGENT_REQUESTS_TOTAL.labels(status="error").inc()
            raise
        finally:
            AGENT_LATENCY_SECONDS.labels(
                agent_type=request.headers.get("X-Agent-Type", "default")
            ).observe(time.time() - start)
```

#### 5.3.2 SLA 定义与告警规则

```yaml
# prometheus/alert_rules.yaml
groups:
- name: ai_agent_sla
  rules:
  
  # P99 延迟告警
  - alert: AgentHighLatency
    expr: histogram_quantile(0.99, agent_latency_seconds) > 10
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Agent P99 延迟超过 10 秒"
      
  # 错误率告警
  - alert: AgentHighErrorRate
    expr: rate(agent_requests_total{status="error"}[5m]) / rate(agent_requests_total[5m]) > 0.05
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "Agent 错误率超过 5%"
      
  # Token 成本告警（每小时超 $50）
  - alert: HighLLMCost
    expr: increase(llm_cost_usd_total[1h]) > 50
    labels:
      severity: warning
    annotations:
      summary: "过去 1 小时 LLM 成本超过 $50"
```

#### 5.3.3 性能优化清单

```
Layer 1 — LLM 层优化：
✅ Prompt 缓存（相同前缀复用 KV Cache）
✅ 流式输出（减少 TTFT 感知）
✅ 批量推理（合并同类请求）
✅ 模型降级（简单任务用小模型）
✅ 投机解码（Speculative Decoding）

Layer 2 — 检索层优化：
✅ 向量索引预热（HNSW 参数调优）
✅ 检索结果缓存（Redis TTL 策略）
✅ 异步并行检索
✅ 索引分片（按领域/时间分区）

Layer 3 — 应用层优化：
✅ 连接池复用（DB、Redis、HTTP）
✅ 异步非阻塞架构（asyncio）
✅ 计算结果缓存（相同 query+context 命中率分析）
✅ CDN 静态资源加速

Layer 4 — 基础设施优化：
✅ HPA 基于 QPS 自动扩容
✅ 多区域部署（就近接入）
✅ GPU 时间片共享（MIG 分区）
```

---

### 5.4 企业级项目实战规范

#### 5.4.1 项目上线检查清单（Launch Checklist）

```
□ 功能完整性
  □ 核心功能 100% 覆盖，边缘 case 处理完毕
  □ 人工测试集正确率 ≥ 90%
  □ RAGAS 评估四项指标均 ≥ 0.80

□ 性能指标
  □ P50 延迟 < 2s，P99 < 10s
  □ 并发 100 QPS 下错误率 < 1%
  □ 单次调用 Token 成本 < $0.05

□ 安全合规
  □ API Key 全部迁移至 Secret Manager
  □ 敏感数据脱敏处理已验证
  □ 注入攻击防护（Prompt Injection）已测试
  □ PII 过滤器已启用并测试

□ 可观测性
  □ LangSmith 追踪覆盖率 100%
  □ Prometheus 指标全部接入 Grafana
  □ 告警规则已配置并 oncall 验证
  □ 错误日志接入 ELK，告警邮件已测试

□ 容灾能力
  □ 主力模型不可用时，降级方案已测试
  □ 数据库主从切换已验证（< 30s）
  □ 灰度发布策略已就绪（5% → 20% → 100%）
  □ 回滚流程已演练（< 5min）

□ 文档与培训
  □ API 文档已发布（OpenAPI 3.0）
  □ 运维 Runbook 已完成
  □ 团队 oncall 培训已完成
```

#### 5.4.2 灰度发布策略

```python
# 基于 feature flag 的灰度控制
class GradualRollout:
    ROLLOUT_STAGES = [
        {"name": "canary",     "percentage": 5,   "duration_hours": 24},
        {"name": "early",      "percentage": 20,  "duration_hours": 48},
        {"name": "majority",   "percentage": 50,  "duration_hours": 48},
        {"name": "full",       "percentage": 100, "duration_hours": 0},
    ]
    
    def should_use_new_version(self, user_id: str) -> bool:
        current_stage = self._get_current_stage()
        # 基于 user_id hash 确保同一用户体验一致
        user_hash = int(hashlib.md5(user_id.encode()).hexdigest(), 16) % 100
        return user_hash < current_stage["percentage"]
```

---

## 6. 技术选型矩阵

| 组件 | 推荐选型 | 备选方案 | 选型理由 |
|------|---------|---------|---------|
| **编排框架** | LangGraph | CrewAI, AutoGen | 状态图更适合企业复杂流程 |
| **向量数据库** | Qdrant | Pinecone, Weaviate | 开源可私有化，性能强 |
| **关键词检索** | Elasticsearch | OpenSearch | 成熟生态，BM25 + 过滤 |
| **重排模型** | BGE-Reranker-v2 | Cohere Rerank | 中文效果最佳，可本地化 |
| **嵌入模型** | text-embedding-3-large | BGE-M3 | 通用场景首选 |
| **缓存** | Redis 7 | Memcached | 支持向量相似缓存 |
| **消息队列** | Kafka | RabbitMQ | 高吞吐，适合 Agent 任务队列 |
| **追踪** | LangSmith | Langfuse（开源） | 与 LangChain 深度集成 |
| **监控** | Prometheus + Grafana | Datadog | 开源成本低，定制性强 |
| **CI/CD** | GitHub Actions + ArgoCD | Jenkins | GitOps 最佳实践 |

---

## 7. 安全与合规设计

### 7.1 Prompt Injection 防护

```python
class PromptInjectionDefender:
    """防止恶意用户通过 Prompt 注入攻击绕过系统限制"""
    
    INJECTION_PATTERNS = [
        r"ignore (all |previous |above )?instructions",
        r"you are now (a |an )?.*(?:without|ignore|bypass)",
        r"(pretend|act|roleplay|simulate) (you are|as if)",
        r"system prompt|jailbreak|DAN|do anything now",
    ]
    
    def scan(self, user_input: str) -> ScanResult:
        for pattern in self.INJECTION_PATTERNS:
            if re.search(pattern, user_input, re.IGNORECASE):
                return ScanResult(
                    is_safe=False,
                    threat_type="prompt_injection",
                    matched_pattern=pattern,
                )
        return ScanResult(is_safe=True)
```

### 7.2 数据安全分级

| 级别 | 数据类型 | 处理规范 |
|------|---------|---------|
| L1 公开 | 公开文档、FAQ | 可送外部 API |
| L2 内部 | 业务数据、报告 | 需脱敏后送 API |
| L3 机密 | 财务、客户 PII | 只允许本地模型 |
| L4 绝密 | 战略规划、源码 | 完全隔离，人工处理 |

---

## 8. 附录

### 8.1 项目目录结构规范

```
project/
├── src/
│   ├── agents/          # Agent 实现
│   │   ├── base.py
│   │   ├── react_agent.py
│   │   └── multi_agent/
│   ├── tools/           # 工具库
│   ├── memory/          # 记忆系统
│   ├── rag/             # RAG 系统
│   ├── llm/             # LLM 网关
│   └── api/             # FastAPI 接口
├── evaluation/          # 评估脚本
├── prompts/             # Prompt 版本管理
├── k8s/                 # K8s 配置
├── monitoring/          # 监控配置
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── docs/
└── scripts/
```

### 8.2 关键参考资料

- LangChain 官方文档：https://docs.langchain.com
- LangGraph 文档：https://langchain-ai.github.io/langgraph/
- LangSmith 文档：https://docs.smith.langchain.com
- RAGAS 评估框架：https://docs.ragas.io
- vLLM 部署指南：https://docs.vllm.ai

---

*文档持续更新中。如有问题，请联系 AI Agent 开发团队。*