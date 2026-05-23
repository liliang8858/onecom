# 第 02 章：Python 包结构与导入路径

## 1. 本章学习目标

学完本章后，你应该能做到：

- 解释为什么源码放在 `src/enterprise_agent/` 下。
- 解释 `__init__.py` 的作用。
- 区分“包入口导入”和“子模块导入”。
- 知道什么内容适合放进包入口公开，什么内容应该留在子模块里。
- 能为一个新子包添加代码和测试。

本章仍然不调用大模型。我们先把 Python 包结构讲清楚，因为后续 LLM、Agent、Tool、RAG 和记忆系统都会依赖这个结构。

## 2. 为什么使用 src 布局

当前源码目录是：

```text
src/
└── enterprise_agent/
    ├── __init__.py
    ├── project.py
    └── foundation/
        ├── __init__.py
        └── package_map.py
```

这叫 `src layout`。

它的好处是：测试必须像真实用户一样导入已安装的包，而不是误打误撞导入当前目录里的某个同名文件。对教学项目来说，这能让学员更早暴露导入路径问题。

## 3. 什么是包

在 Python 里，一个目录只要包含 `__init__.py`，就可以被当成包使用。

例如：

```text
src/enterprise_agent/__init__.py
```

让我们可以这样导入：

```python
import enterprise_agent
```

再例如：

```text
src/enterprise_agent/foundation/__init__.py
```

让我们可以这样导入：

```python
from enterprise_agent import foundation
```

## 4. 包入口应该放什么

打开：

```text
src/enterprise_agent/__init__.py
```

你会看到：

```python
from .project import ProjectInfo, get_project_info

__all__ = ["ProjectInfo", "get_project_info"]
```

这表示顶层包只公开第一章需要的最小 API：

- `ProjectInfo`
- `get_project_info`

所以测试里可以写：

```python
from enterprise_agent import get_project_info
```

不要把所有内部模块都塞进顶层入口。顶层入口越大，后续越难维护。

## 5. 子包应该放什么

本章新增了：

```text
src/enterprise_agent/foundation/
```

这个子包用于放工程基础阶段的教学辅助代码。

其中：

```text
package_map.py
```

定义了一个很小的课程模块地图：

```python
@dataclass(frozen=True)
class ModuleInfo:
    name: str
    purpose: str
    first_chapter: int
```

它描述一个模块：

- 模块名是什么
- 模块负责什么
- 从第几章开始出现

## 6. 子包入口的作用

打开：

```text
src/enterprise_agent/foundation/__init__.py
```

你会看到：

```python
from .package_map import CORE_MODULES, ModuleInfo, find_module, get_module_names

__all__ = ["CORE_MODULES", "ModuleInfo", "find_module", "get_module_names"]
```

这表示使用者可以这样导入：

```python
from enterprise_agent.foundation import get_module_names
```

而不需要这样写：

```python
from enterprise_agent.foundation.package_map import get_module_names
```

这就是子包入口的价值：对外提供更稳定、更短的导入路径。

## 7. 什么时候使用相对导入

在包内部，推荐使用相对导入。

例如：

```python
from .package_map import get_module_names
```

这里的 `.` 表示“当前包”。

如果在 `enterprise_agent/foundation/__init__.py` 中写绝对导入，也可以工作：

```python
from enterprise_agent.foundation.package_map import get_module_names
```

但在包内部，相对导入更简洁，也更能表达“这是同一个包里的模块”。

## 8. 本章测试

本章新增：

```text
tests/unit/test_package_structure.py
```

测试分三类：

第一类：验证顶层包入口只公开当前需要的 API。

```python
assert enterprise_agent.__all__ == ["ProjectInfo", "get_project_info"]
```

第二类：验证子包能正常导入课程模块地图。

```python
assert get_module_names() == ("foundation", "llm", "agents", "tools")
```

第三类：验证查找函数能处理存在和不存在的模块。

```python
assert find_module("missing") is None
```

## 9. 常见问题

### 9.1 为什么不把 foundation 也放到顶层 __all__

因为顶层 API 要克制。

`enterprise_agent` 是整个包的入口，只应该放最稳定、最常用的对象。`foundation` 是一个子包，使用者可以显式导入：

```python
from enterprise_agent.foundation import get_module_names
```

这样边界更清楚。

### 9.2 为什么测试 __all__

`__all__` 是公开 API 清单。测试它可以提醒我们：不要无意中把内部对象暴露给学员或外部使用者。

### 9.3 为什么现在就写 ModuleInfo

它不是业务功能，而是教学用例。它足够小，但能同时讲清楚：

- dataclass
- 子模块
- 子包入口
- tuple 返回值
- `None` 的处理
- 单元测试

## 10. 本章练习

请完成以下练习：

1. 在 `CORE_MODULES` 中新增一个模块：`api`。
2. 设置它的 `first_chapter` 为 `31`。
3. 更新测试，让 `get_module_names()` 包含 `api`。
4. 写一个测试，断言 `find_module("api")` 能返回 `ModuleInfo`。
5. 再写一个测试，断言 `find_module("unknown") is None`。

## 11. 本章验收标准

完成本章后，你需要能独立解释：

- `src/enterprise_agent/` 是什么。
- `enterprise_agent/__init__.py` 做什么。
- `enterprise_agent/foundation/__init__.py` 做什么。
- 什么是顶层公开 API。
- 为什么子包可以有自己的公开 API。
- 为什么测试要覆盖导入路径。

验收命令：

```powershell
python -m pytest
```

应该看到所有测试通过。

## 12. 下一章预告

第 03 章会讲测试驱动的开发节奏。

你会学习：

- 如何先写失败测试。
- 如何读懂 pytest 的失败信息。
- 如何把一个需求拆成多个断言。
- 如何命名单元测试，让测试本身成为文档。

