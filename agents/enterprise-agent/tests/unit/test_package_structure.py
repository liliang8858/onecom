import enterprise_agent
from enterprise_agent.foundation import CORE_MODULES, ModuleInfo, find_module, get_module_names


def test_top_level_package_exports_public_setup_api():
    assert enterprise_agent.__all__ == ["ProjectInfo", "get_project_info"]


def test_foundation_package_exposes_learning_module_map():
    assert get_module_names() == ("foundation", "llm", "agents", "tools")
    assert all(isinstance(module, ModuleInfo) for module in CORE_MODULES)


def test_find_module_returns_known_module_or_none():
    llm = find_module("llm")

    assert llm is not None
    assert llm.first_chapter == 6
    assert "模型调用" in llm.purpose
    assert find_module("missing") is None

