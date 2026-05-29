# 第 03 章：测试驱动的开发节奏

## 1. 本章学习目标

学完本章后，你应该能做到：

- 解释什么是“先写测试，再写实现”。
- 能把一个小需求拆成多个断言。
- 能读懂 pytest 的失败信息。
- 能使用 `pytest.raises` 测试异常。
- 能判断一个测试名称是否足够清楚。

本章仍然不进入 LLM 和 Agent。我们先练一件更基础但非常关键的事：让代码在小步验证中长出来。

## 2. 本章要实现什么

我们要实现一个小函数：

```python
format_chapter_title(number: int, title: str) -> str
```

它负责把章节编号和标题格式化成课程统一样式。

例如：

```python
format_chapter_title(3, "测试驱动的开发节奏")
```

应该返回：

```text
第 03 章：测试驱动的开发节奏
```

这个功能看起来很小，但它正好适合练 TDD，因为它有清楚的输入、输出和边界条件。

## 3. TDD 的最小循环

TDD 可以先记成三个词：

```text
Red -> Green -> Refactor
```

它们的意思是：

- Red：先写一个失败测试。
- Green：写最少的代码让测试通过。
- Refactor：在测试保护下整理代码。

不要把 TDD 想成复杂仪式。它最朴素的价值是：每次只前进一步，而且知道这一步有没有踩空。

## 4. 先写第一个测试

本章测试文件是：

```text
tests/unit/test_testing_rhythm.py
```

第一个测试是：

```python
def test_format_chapter_title_pads_single_digit_number():
    assert format_chapter_title(3, "测试驱动的开发节奏") == "第 03 章：测试驱动的开发节奏"
```

这个测试说明了一个具体规则：

> 单位数章节号要补 0。

如果函数还没实现，pytest 会失败。这个失败不是坏事，它是在告诉我们：需求已经被测试描述出来了，但代码还没跟上。

## 5. 再写刚好够用的实现

实现文件是：

```text
src/enterprise_agent/foundation/chapter_titles.py
```

核心代码是：

```python
def format_chapter_title(number: int, title: str) -> str:
    return f"第 {number:02d} 章：{title}"
```

这已经能让第一个测试通过。

注意这里的格式：

```python
{number:02d}
```

意思是：把整数格式化成至少 2 位，不够时前面补 `0`。

## 6. 把需求拆成多个断言

一个测试只覆盖一个重要行为。不要把所有情况都塞进一个大测试里。

本章把需求拆成了五个测试：

```python
def test_format_chapter_title_pads_single_digit_number():
```

验证：`3` 应该变成 `03`。

```python
def test_format_chapter_title_keeps_two_digit_number():
```

验证：`12` 还是 `12`。

```python
def test_format_chapter_title_strips_extra_spaces():
```

验证：标题前后的空格会被清理。

```python
def test_format_chapter_title_rejects_invalid_number():
```

验证：章节号不能小于 1。

```python
def test_format_chapter_title_rejects_empty_title():
```

验证：标题不能为空。

这五个测试像五个小灯泡。哪一个灭了，我们就知道是哪条规则坏了。

## 7. 测试异常

有些需求不是“返回什么”，而是“遇到坏输入时要拒绝”。

例如章节号为 `0`：

```python
with pytest.raises(ValueError, match="greater than 0"):
    format_chapter_title(0, "无效章节")
```

这里有两个重点：

- `pytest.raises(ValueError)`：期望这里抛出 `ValueError`。
- `match="greater than 0"`：错误消息里应该包含这段文字。

为什么要检查错误消息？

因为好的错误消息会帮助使用者定位问题。企业级工程不是只要程序“爆掉”就行，还要让人知道为什么爆掉。

## 8. 最终实现

当前实现是：

```python
def format_chapter_title(number: int, title: str) -> str:
    if number < 1:
        raise ValueError("chapter number must be greater than 0")

    clean_title = title.strip()
    if not clean_title:
        raise ValueError("chapter title must not be empty")

    return f"第 {number:02d} 章：{clean_title}"
```

这段代码很短，但它已经包含了三个工程习惯：

- 先处理非法输入。
- 对用户输入做清理。
- 返回稳定格式。

## 9. 怎么读 pytest 失败信息

如果你把期望值故意改错，比如：

```python
assert format_chapter_title(3, "测试驱动的开发节奏") == "第 3 章：测试驱动的开发节奏"
```

pytest 会告诉你实际值和期望值不同。

你要重点看三件事：

- 哪个测试失败了。
- 哪一行失败了。
- 左右两边的值有什么差异。

初学者常见问题是看到一屏红字就慌。其实多数时候，只需要先看最靠近底部的失败断言。

## 10. 好测试名称长什么样

测试名称应该像一句小规格说明。

比如：

```python
test_format_chapter_title_pads_single_digit_number
```

它比下面这种名字更好：

```python
test_title
```

好测试名称要回答三个问题：

- 测什么函数？
- 在什么场景下？
- 期望什么行为？

后续 Agent 工程会越来越复杂，测试名称会成为你回头理解系统的路标。

## 11. 本章练习

请完成以下练习：

1. 新增一个测试：`format_chapter_title(35, "Docker 与部署前检查")` 应返回 `第 35 章：Docker 与部署前检查`。
2. 新增一个测试：标题中间的空格不要被删除，例如 `"配置 与 环境变量"` 应保持中间空格。
3. 把 `format_chapter_title(0, "...")` 改成 `format_chapter_title(-1, "...")`，确认异常测试仍然通过。
4. 故意把实现里的 `{number:02d}` 改成 `{number}`，运行测试，观察失败信息。
5. 改回正确实现，让测试重新通过。

## 12. 本章验收标准

完成本章后，你需要能独立做到：

- 运行 `python -m pytest`。
- 解释 `test_testing_rhythm.py` 中每个测试的目的。
- 解释 `pytest.raises` 的作用。
- 解释为什么测试要拆小。
- 修改一个测试期望值，并根据失败信息定位问题。

当前验收命令：

```powershell
python -m pytest
```

应该看到：

```text
9 passed
```

## 13. 下一章预告

第 04 章会讲配置与环境变量基础。

你会学习：

- 为什么不要把配置写死在业务代码里。
- 如何设计一个简单配置对象。
- 如何给配置提供默认值。
- 如何写 `.env.example` 给学员和部署人员参考。

