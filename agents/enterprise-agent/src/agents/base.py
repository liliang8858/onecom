"""Agent 基类 — 定义 Agent 生命周期与核心接口"""

from abc import ABC, abstractmethod
from typing import Any, AsyncIterator, Optional


class AgentState:
    """Agent 运行时状态"""
    def __init__(self):
        self.messages: list[dict[str, Any]] = []
        self.tool_results: list[dict[str, Any]] = []
        self.memory_context: dict[str, Any] = {}
        self.iteration: int = 0


class BaseAgent(ABC):
    """所有 Agent 的抽象基类。

    子类需实现:
      - _build_system_prompt() → str
      - _think(state) → AgentAction
      - _observe(state, result) → AgentObservation
    """

    def __init__(self, name: str, config: Optional[dict[str, Any]] = None):
        self.name = name
        self.config = config or {}
        self.state = AgentState()

    @abstractmethod
    def _build_system_prompt(self) -> str: ...

    @abstractmethod
    async def _think(self, state: AgentState) -> "AgentAction": ...

    @abstractmethod
    async def _observe(
        self, state: AgentState, result: "AgentActionResult"
    ) -> "AgentObservation": ...

    async def run(self, task: str) -> AsyncIterator[str]:
        """执行 Agent 主循环: Think → Act → Observe → Repeat"""
        raise NotImplementedError("Subclasses must implement run()")


class AgentAction:
    """Agent 决策输出的动作"""
    def __init__(
        self,
        thought: str,
        action_type: str,
        action_input: dict[str, Any],
        tool_name: Optional[str] = None,
    ):
        self.thought = thought
        self.action_type = action_type  # "tool_call" | "respond" | "delegate"
        self.action_input = action_input
        self.tool_name = tool_name


class AgentActionResult:
    """工具调用结果"""
    def __init__(self, success: bool, data: Any, error: Optional[str] = None):
        self.success = success
        self.data = data
        self.error = error


class AgentObservation:
    """Agent 观察后的反思/下一步决策"""
    def __init__(
        self,
        reflection: str,
        should_continue: bool,
        final_answer: Optional[str] = None,
    ):
        self.reflection = reflection
        self.should_continue = should_continue
        self.final_answer = final_answer
