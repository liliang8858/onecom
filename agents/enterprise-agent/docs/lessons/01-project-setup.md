# 第 01 章：工程启动与开发环境

## 1. 本章交付物

本章结束时，仓库应该具备一个可继续扩展的 Python 工程基线：

- 项目可以被安装。
- 包 `enterprise_agent` 可以被导入。
- 测试命令可以稳定运行。
- 最小源码和最小测试已经建立。

本章不写 Agent，不调用模型，也不接入任何外部服务。企业级 Agent 的第一步是让工程先站稳。

## 1.1 完成态

完成本章时，你应该能指着两类东西说“第一章完成了”：

- 文件层面：`pyproject.toml`、`src/enterprise_agent/project.py`、`tests/unit/test_project_setup.py` 都存在。
- 行为层面：在项目目录运行 `python -m pytest`，测试通过。

如果只能看懂文字，但跑不通命令，本章还没有完成。

## 2. 为什么先做工程基线

直接调用一次大模型很容易，但那只是演示。企业级工程需要长期迭代，需要多人协作，也需要能够判断每次修改有没有破坏旧能力。

如果没有工程基线，后续会出现三个问题：

- 代码散落成脚本，无法形成稳定包结构。
- 修改后只能手工试，不能自动验证。
- 每个人的运行方式不同，环境问题会反复出现。

本章先建立一个最小闭环：

```text
安装项目 -> 导入包 -> 调用函数 -> 运行测试
```

后面的 LLM、Agent、工具、RAG 和记忆系统，都会接在这个闭环上。

## 3. 前四章路线

前四章是一组工程基础课：

```text
01 工程可运行 -> 02 包结构清楚 -> 03 测试节奏稳定 -> 04 配置可管理
```

第 01 章只解决“能不能跑”。这个问题不解决，后面所有设计都没有落点。

## 4. 当前项目目标

`enterprise-agent` 要逐步实现一个企业级 AI Agent 工程。最终会覆盖：

- 统一 LLM 网关。
- Agent 核心循环。
- 企业工具系统。
- LangGraph 编排。
- RAG 知识检索。
- 短期和长期记忆。
- API、监控、评估、安全和部署。

本章只做底层准备，不提前进入这些复杂模块。

## 5. 目录结构

本章完成后，关键结构是：

```text
enterprise-agent/
├── pyproject.toml
├── src/
│   └── enterprise_agent/
│       ├── __init__.py
│       └── project.py
└── tests/
    └── unit/
        └── test_project_setup.py
```

记住一个规则：正式源码放在 `src/enterprise_agent/` 下，测试放在 `tests/` 下。

## 6. 关键术语

| 术语 | 在本章里的意思 |
|------|----------------|
| 工程基线 | 项目能安装、能导入、能测试的最低可用状态 |
| 源码包 | 放正式 Python 代码的包，本项目是 `enterprise_agent` |
| smoke test | 很小的冒烟测试，用来确认最基本链路没断 |
| editable install | 可编辑安装，修改源码后不需要重新安装包 |

## 7. 安装开发环境

进入项目目录：

```powershell
cd E:\onecom\agents\enterprise-agent
```

创建虚拟环境：

```powershell
python -m venv .venv
```

激活虚拟环境：

```powershell
.\.venv\Scripts\Activate.ps1
```

安装项目和开发依赖：

```powershell
python -m pip install -e ".[dev]"
```

`-e` 表示 editable install。修改 `src/` 下的代码后，不需要重新安装包，测试会直接读取最新代码。

## 8. 运行测试

在项目目录下运行：

```powershell
python -m pytest
```

如果测试通过，说明三件事成立：

- Python 能找到 `enterprise_agent` 包。
- `pyproject.toml` 中的测试配置生效。
- 当前最小工程结构可用。

以后每章都会回到这个命令。它是判断仓库是否还能继续开发的最低标准。

## 9. 代码解读：ProjectInfo

打开：

```text
src/enterprise_agent/project.py
```

核心代码是：

```python
from dataclasses import dataclass


@dataclass(frozen=True)
class ProjectInfo:
    name: str
    version: str
    stage: str
```

`ProjectInfo` 是项目元信息对象。它现在很小，只用于验证包导入和函数调用是否正常。

`frozen=True` 表示对象创建后不能被修改。元信息应该稳定，不应该在运行过程中被随意改掉。

## 10. 测试解读

打开：

```text
tests/unit/test_project_setup.py
```

核心测试是：

```python
from enterprise_agent import get_project_info


def test_project_info_exposes_first_chapter_stage():
    info = get_project_info()

    assert info.name == "enterprise-agent"
    assert info.version == "0.1.0"
    assert info.stage == "chapter-01-project-setup"
```

这条测试验证三件事：

- 顶层包可以导入 `get_project_info`。
- 函数可以被调用。
- 返回值符合预期。

测试很小，但它已经形成了工程闭环。

## 11. 常见问题

### 11.1 找不到 pytest

如果出现 `No module named pytest`，通常是没有安装开发依赖。

重新执行：

```powershell
python -m pip install -e ".[dev]"
```

### 11.2 找不到 enterprise_agent

先确认当前目录是：

```text
E:\onecom\agents\enterprise-agent
```

再确认你使用的是：

```powershell
python -m pytest
```

本项目在 `pyproject.toml` 中配置了：

```toml
pythonpath = ["src"]
```

这会让 pytest 从 `src/` 下查找源码包。

## 12. 读者自测

不看正文，尝试回答下面 4 个问题：

1. 为什么第一章不直接调用大模型？
2. `pyproject.toml` 在测试链路里起什么作用？
3. `ProjectInfo` 为什么足够小，但仍然有价值？
4. `python -m pytest` 通过，最少证明了哪几件事？

答不上来的地方，就是需要回头重读的地方。

## 13. 练习

1. 修改 `ProjectInfo.stage` 的返回值，运行测试，观察失败信息。
2. 把返回值改回 `chapter-01-project-setup`，再次运行测试。
3. 给 `ProjectInfo` 新增 `description` 字段。
4. 更新 `get_project_info()`，返回一个简短说明。
5. 更新测试，断言 `description` 不为空。

练习目标是熟悉“改代码 -> 跑测试 -> 根据结果修正”的节奏。

## 14. 验收标准

完成本章后，你应该能独立解释：

- `pyproject.toml` 在这里负责什么。
- 为什么源码放在 `src/enterprise_agent/` 下。
- 为什么第一章只写一个很小的对象和测试。
- `python -m pytest` 通过代表什么。

## 15. 学习反馈

读完并跑完本章后，记录 3 句话：

1. 哪个命令你已经能独立执行？
2. 哪个概念还不稳？
3. 如果测试失败，你第一步会检查什么？

这些反馈会决定下一章讲包结构时要放慢还是加速。

## 16. 下一章

第 02 章会讲 Python 包结构与导入路径。

你会学习 `__init__.py`、顶层包入口、子包入口，以及为什么公开 API 要克制。
