# 第 03 章：测试驱动的开发节奏

## 1. 本章交付物

本章会新增一个小函数：

```python
format_chapter_title(number: int, title: str) -> str
```

同时新增一组测试，覆盖正常输入、边界输入和错误输入。

本章目标是训练一种节奏：

```text
写一个失败测试 -> 写最少实现 -> 跑测试 -> 整理代码
```

## 1.1 完成态

完成本章时，你应该能做到：

- 新增一个失败测试，并能解释它为什么失败。
- 写最少代码让测试通过。
- 用多个测试分别覆盖正常输入、边界输入和错误输入。
- 根据 pytest 输出定位失败原因。

如果只是把最终代码抄出来，但没有经历失败测试，本章的训练没有完成。

## 2. 为什么先练测试节奏

企业级 Agent 会不断增长。后续会有模型调用、工具执行、RAG、记忆、编排和 API。每一层都会引入新的失败方式。

如果没有测试节奏，复杂度会很快失控。你会变成“改完以后手工试一下”，但手工试不可能覆盖所有旧行为。

本章用一个很小的函数练习测试驱动开发。函数小，反馈快，适合建立习惯。

## 3. 本章在前四章中的位置

前两章已经解决：

- 工程可以运行。
- 包结构和导入路径清楚。

第 03 章解决第三个问题：每次修改后，如何知道旧功能没有坏。

第 04 章的配置对象会继续使用这个节奏：先用测试描述规则，再补实现。

## 4. 要实现的行为

函数输入章节编号和标题，输出统一格式：

```python
format_chapter_title(3, "测试驱动的开发节奏")
```

返回：

```text
第 03 章：测试驱动的开发节奏
```

规则包括：

- 单位数章节号要补 0。
- 两位数章节号保持原样。
- 标题前后的空格要清理。
- 章节号必须大于 0。
- 标题不能为空。

这些规则足够小，但已经包含正常路径和异常路径。

## 5. 关键术语

| 术语 | 在本章里的意思 |
|------|----------------|
| Red | 先写测试，让它因为功能缺失而失败 |
| Green | 写最少实现，让测试通过 |
| Refactor | 在测试保护下整理代码 |
| 边界输入 | 接近规则边缘的输入，例如 `0`、空标题、带空格标题 |
| 失败信息 | pytest 给出的定位线索，不是噪音 |

## 6. TDD 最小循环

TDD 可以先记成：

```text
Red -> Green -> Refactor
```

- Red：先写一个会失败的测试。
- Green：写刚好够用的代码让测试通过。
- Refactor：在测试保护下整理代码。

重点是控制步长。一次只前进一步，并马上知道结果。

## 7. 第一个测试

测试文件是：

```text
tests/unit/test_testing_rhythm.py
```

第一个测试可以这样写：

```python
def test_format_chapter_title_pads_single_digit_number():
    assert format_chapter_title(3, "测试驱动的开发节奏") == "第 03 章：测试驱动的开发节奏"
```

这条测试只描述一条规则：单位数章节号要补 0。

如果函数还不存在，pytest 会失败。这个失败是有价值的，因为它说明需求已经被测试表达出来了。

## 8. 刚好够用的实现

实现文件是：

```text
src/enterprise_agent/foundation/chapter_titles.py
```

最小实现可以是：

```python
def format_chapter_title(number: int, title: str) -> str:
    return f"第 {number:02d} 章：{title}"
```

`{number:02d}` 的意思是：把整数格式化成至少 2 位，不够时前面补 `0`。

这时第一个测试应该通过。接下来再逐步补充更多规则。

## 9. 把规则拆成多个测试

不要把所有场景写进一个大测试。一个测试最好只保护一条重要规则。

本章测试拆成五类：

- `test_format_chapter_title_pads_single_digit_number`
- `test_format_chapter_title_keeps_two_digit_number`
- `test_format_chapter_title_strips_extra_spaces`
- `test_format_chapter_title_rejects_invalid_number`
- `test_format_chapter_title_rejects_empty_title`

这样失败信息会更清楚。哪条测试失败，就知道哪条规则退化。

## 10. 测试异常

错误输入也要测试。

例如章节号为 `0`：

```python
with pytest.raises(ValueError, match="greater than 0"):
    format_chapter_title(0, "无效章节")
```

这里验证两件事：

- 会抛出 `ValueError`。
- 错误消息里包含 `greater than 0`。

错误消息也值得测试。企业级工程需要让使用者知道为什么失败，而不是只看到一个模糊异常。

## 11. 最终实现

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

它体现了三个习惯：

- 先拒绝非法输入。
- 再清理用户输入。
- 最后返回稳定格式。

## 12. 怎么读 pytest 失败信息

当测试失败时，先看三件事：

- 哪个测试失败。
- 哪一行断言失败。
- 实际值和期望值差在哪里。

例如把期望值写成：

```python
"第 3 章：测试驱动的开发节奏"
```

pytest 会显示实际返回的是：

```text
第 03 章：测试驱动的开发节奏
```

这时不要急着改实现。先判断是测试期望错了，还是代码行为错了。

## 13. 测试命名

好的测试名应该像一句规格说明。

例如：

```python
test_format_chapter_title_pads_single_digit_number
```

它回答了三个问题：

- 测哪个函数。
- 在什么场景下。
- 期望什么行为。

不要写成：

```python
test_title
```

这种名字不能帮助你在失败时快速定位问题。

## 14. 读者自测

不看正文，尝试回答下面 5 个问题：

1. 为什么第一个测试应该先失败？
2. 一个测试为什么最好只覆盖一条规则？
3. `pytest.raises` 比只看程序报错多验证了什么？
4. 好测试名要回答哪三个问题？
5. 看到 pytest 红字时，最先看哪三处信息？

答不上来时，先回到测试文件，不要急着改实现。

## 15. 练习

1. 新增测试：`format_chapter_title(35, "Docker 与部署前检查")` 应返回 `第 35 章：Docker 与部署前检查`。
2. 新增测试：标题中间的空格不要被删除，例如 `"配置 与 环境变量"` 应保持中间空格。
3. 把异常测试中的 `0` 改成 `-1`，确认仍然通过。
4. 故意把实现里的 `{number:02d}` 改成 `{number}`，运行测试，观察失败信息。
5. 改回正确实现，让测试重新通过。

## 16. 验收标准

完成本章后，你应该能独立解释：

- 什么是 Red、Green、Refactor。
- 为什么测试要拆小。
- `pytest.raises` 做什么。
- 为什么错误消息也要测试。
- 如何根据 pytest 失败信息定位问题。

验收命令：

```powershell
python -m pytest
```

第 03 章完成时应看到：

```text
9 passed
```

完成后续章节后，测试数量会增加。只要全部通过，就说明当前仓库处于可继续开发状态。

## 17. 学习反馈

完成本章后，记录 3 句话：

1. 哪个测试名最容易让你理解规则？
2. 哪次失败信息最有帮助？
3. 写异常测试时，你最容易漏掉什么？

这些反馈会影响第 04 章配置校验测试的讲解方式。

## 18. 下一章

第 04 章会讲配置与环境变量基础。

你会学习如何设计配置对象、如何读取环境变量、如何校验非法配置，以及如何用测试保护这些规则。
