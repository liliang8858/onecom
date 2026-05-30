# 第 02 章：Python 包结构与导入路径

## 1. 本章交付物

本章结束时，项目会新增一个 `foundation` 子包，并用测试保护导入边界。

你需要理解三件事：

- 源码为什么放在 `src/enterprise_agent/`。
- 顶层包入口应该公开什么。
- 子包入口如何提供稳定的短导入路径。

本章仍然不写大模型逻辑。包结构如果不清楚，后面的 LLM、Agent、工具、RAG 和记忆模块都会变得难以维护。

## 1.1 完成态

完成本章时，你应该能指着三处代码说明它们的边界：

- `src/enterprise_agent/__init__.py`：顶层包入口。
- `src/enterprise_agent/foundation/__init__.py`：子包入口。
- `src/enterprise_agent/foundation/package_map.py`：具体实现模块。

如果你只能记住文件名，但说不出谁对外公开、谁放内部实现，本章还没真正完成。

## 2. 为什么使用 src layout

当前源码结构是：

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

它的好处是：测试会像真实使用者一样导入包，而不是误导入当前目录中的同名文件。教学项目越早暴露导入路径问题，后面越少返工。

## 3. 包和模块的边界

在 Python 里，包含 `__init__.py` 的目录可以作为包使用。

例如：

```text
src/enterprise_agent/__init__.py
```

让外部可以导入：

```python
import enterprise_agent
```

再例如：

```text
src/enterprise_agent/foundation/__init__.py
```

让外部可以导入：

```python
from enterprise_agent import foundation
```

`__init__.py` 不只是占位文件。它也是这个包对外公开内容的入口。

## 4. 关键术语

| 术语 | 在本章里的意思 |
|------|----------------|
| 顶层包入口 | `enterprise_agent/__init__.py` 暴露的公开 API |
| 子包入口 | 子包自己的 `__init__.py`，例如 `foundation/__init__.py` |
| 内部模块 | 放具体实现的文件，例如 `package_map.py` |
| 公开 API | 外部代码被允许依赖的对象和导入路径 |

## 5. 顶层包入口

打开：

```text
src/enterprise_agent/__init__.py
```

你会看到：

```python
from .project import ProjectInfo, get_project_info

__all__ = ["ProjectInfo", "get_project_info"]
```

这表示顶层包只公开两个对象：

- `ProjectInfo`
- `get_project_info`

所以测试里可以写：

```python
from enterprise_agent import get_project_info
```

顶层入口不要急着放很多东西。公开 API 越大，后续重构成本越高。

## 6. 子包入口

本章新增：

```text
src/enterprise_agent/foundation/
```

它用于放工程基础阶段的辅助代码。

打开：

```text
src/enterprise_agent/foundation/__init__.py
```

核心代码是：

```python
from .package_map import CORE_MODULES, ModuleInfo, find_module, get_module_names

__all__ = ["CORE_MODULES", "ModuleInfo", "find_module", "get_module_names"]
```

这样外部可以写：

```python
from enterprise_agent.foundation import get_module_names
```

而不需要写：

```python
from enterprise_agent.foundation.package_map import get_module_names
```

子包入口的价值是给外部一个稳定、简短的访问路径。内部文件以后可以调整，外部导入方式尽量不变。

## 7. ModuleInfo 是什么

打开：

```text
src/enterprise_agent/foundation/package_map.py
```

核心对象是：

```python
@dataclass(frozen=True)
class ModuleInfo:
    name: str
    purpose: str
    first_chapter: int
```

它描述课程中的一个模块：

- `name`：模块名。
- `purpose`：模块负责什么。
- `first_chapter`：从第几章开始出现。

这是一个小而完整的教学例子。它能同时练习 dataclass、tuple、查找函数、子包导出和单元测试。

## 8. 相对导入

在包内部，推荐使用相对导入：

```python
from .package_map import get_module_names
```

`.` 表示当前包。

也可以写绝对导入：

```python
from enterprise_agent.foundation.package_map import get_module_names
```

但在包内部，相对导入更短，也更清楚地表达“这是同一包里的模块”。

## 9. 测试解读

本章测试文件是：

```text
tests/unit/test_package_structure.py
```

它保护三类边界。

第一类：顶层包入口只公开当前需要的 API。

```python
assert enterprise_agent.__all__ == ["ProjectInfo", "get_project_info"]
```

第二类：子包入口可以正常导入模块地图。

```python
assert get_module_names() == ("foundation", "llm", "agents", "tools")
```

第三类：查找函数能处理存在和不存在的模块。

```python
assert find_module("missing") is None
```

这些测试用来防止导入边界在后续章节中被悄悄破坏。

## 10. 设计规则

新增模块时，先问三个问题：

- 这个对象是不是外部经常需要？
- 它是不是足够稳定？
- 放到顶层入口后，会不会让包入口变得混乱？

如果答案不确定，就先留在子包里。公开 API 应该慢一点扩张。

## 11. 读者自测

不看正文，尝试回答下面 5 个问题：

1. 为什么顶层包入口不应该塞进所有模块？
2. 子包入口解决了什么问题？
3. `__all__` 在这里保护的是什么边界？
4. `find_module("missing") is None` 为什么值得测试？
5. 新增 `llm` 子包时，哪些对象应该留在内部模块？

能回答这些问题，才说明你不是只会照着写导入语句。

## 12. 练习

1. 在 `CORE_MODULES` 中新增一个模块：`api`。
2. 设置它的 `first_chapter` 为 `31`。
3. 更新测试，让 `get_module_names()` 包含 `api`。
4. 写一个测试，断言 `find_module("api")` 能返回 `ModuleInfo`。
5. 再写一个测试，断言 `find_module("unknown") is None`。

练习目标是熟悉“先定义边界，再用测试保护边界”。

## 13. 验收标准

完成本章后，你应该能独立解释：

- 什么是 `src layout`。
- `enterprise_agent/__init__.py` 负责什么。
- `enterprise_agent/foundation/__init__.py` 负责什么。
- 为什么顶层公开 API 要克制。
- 为什么测试要覆盖导入路径。

验收命令：

```powershell
python -m pytest
```

## 14. 学习反馈

读完并完成练习后，记录 3 句话：

1. 哪个导入路径你已经理解？
2. 哪个文件的职责还容易混淆？
3. 如果后续模块越来越多，你会用什么规则决定是否公开 API？

这些反馈会影响第 03 章测试命名和测试拆分的讲解力度。

## 15. 下一章

第 03 章会讲测试驱动的开发节奏。

你会学习如何先写失败测试，如何拆分断言，以及如何从 pytest 的失败信息里定位问题。
