"""Small package map for chapter 02 import-path examples."""

from dataclasses import dataclass


@dataclass(frozen=True)
class ModuleInfo:
    """Describe one learning module in the project package."""

    name: str
    purpose: str
    first_chapter: int


CORE_MODULES: tuple[ModuleInfo, ...] = (
    ModuleInfo(
        name="foundation",
        purpose="工程基础、包结构、导入路径和测试习惯",
        first_chapter=1,
    ),
    ModuleInfo(
        name="llm",
        purpose="统一模型调用、Mock 客户端、路由和成本统计",
        first_chapter=6,
    ),
    ModuleInfo(
        name="agents",
        purpose="Agent 状态、动作、观察和 ReAct 循环",
        first_chapter=13,
    ),
    ModuleInfo(
        name="tools",
        purpose="企业工具基类、注册表、参数校验和错误处理",
        first_chapter=15,
    ),
)


def get_module_names() -> tuple[str, ...]:
    """Return module names in learning order."""

    return tuple(module.name for module in CORE_MODULES)


def find_module(name: str) -> ModuleInfo | None:
    """Find a module by package name."""

    for module in CORE_MODULES:
        if module.name == name:
            return module
    return None

