# 第 05 章：日志与错误信息

## 1. 本章交付物

本章会新增一个日志基础模块：

```text
src/enterprise_agent/foundation/logging.py
```

它提供两个公开函数：

```python
configure_logging()
format_error_message()
```

本章结束时，项目应该能做到：

- 根据 `AppConfig.log_level` 配置项目 logger。
- 用统一格式输出日志。
- 避免重复配置导致同一条日志输出多次。
- 用短、具体、可测试的错误消息表达问题。
- 用单元测试覆盖日志行为和错误消息。

## 1.1 完成态

完成本章时，你应该能指着一条日志说明它的完整路径：

```text
AppConfig.log_level -> configure_logging() -> logging.Logger -> StreamHandler -> 格式化输出
```

如果只知道“用了 logging”，但说不清日志级别从哪里来、handler 在哪里配置、错误消息如何被测试，本章还没有完成。

## 2. 为什么需要正式日志

初学时常用 `print()` 看程序发生了什么。它适合临时调试，不适合正式工程。

正式日志至少要解决四个问题：

- 能按级别过滤，例如只看 `WARNING` 以上。
- 能看出日志来自哪个 logger。
- 能在测试里捕获输出并断言。
- 能在后续接入监控、追踪和 API 服务。

第 05 章先做最小版本。我们不引入外部日志库，只使用 Python 标准库 `logging`。

## 3. 本章在工程基础阶段的位置

前四章已经完成：

- 工程能运行。
- 包结构清楚。
- 测试节奏稳定。
- 配置可以管理。

第 05 章把配置用到日志上。它也是进入 LLM 网关前的最后一类基础能力：程序出错或运行异常时，必须能留下清楚信号。

## 4. 关键术语

| 术语 | 在本章里的意思 |
|------|----------------|
| logger | 日志对象，负责发出日志事件 |
| handler | 日志处理器，决定日志输出到哪里 |
| formatter | 日志格式器，决定一条日志长什么样 |
| log level | 日志级别，例如 `INFO`、`WARNING`、`ERROR` |
| propagation | 日志是否继续传给父 logger |

## 5. configure_logging

核心函数是：

```python
def configure_logging(
    config: AppConfig,
    logger_name: str = DEFAULT_LOGGER_NAME,
    stream: TextIO | None = None,
) -> logging.Logger:
```

它做五件事：

1. 从 `config.log_level` 读取日志级别。
2. 校验日志级别是否在允许范围内。
3. 获取指定名称的 logger。
4. 配置一个 `StreamHandler`。
5. 关闭向 root logger 的传播。

`stream` 参数主要服务测试。测试可以传入 `io.StringIO()`，捕获日志内容并做断言。

## 6. 日志格式

本章使用的日志格式是：

```python
LOG_FORMAT = "%(levelname)s:%(name)s:%(message)s"
```

输出示例：

```text
WARNING:enterprise_agent.tests.warning:visible
```

这个格式很短，但包含三类必要信息：

- `WARNING`：级别。
- `enterprise_agent.tests.warning`：来源。
- `visible`：消息。

后续进入监控和追踪章节时，可以在这个基础上扩展 request id、latency、token count 和 cost。

## 7. 为什么要替换已有 handler

`configure_logging()` 会清空当前 logger 的旧 handler，再挂上新的 handler。

原因是测试和开发中可能多次调用配置函数。如果不清理旧 handler，同一条日志可能被输出多次。

本章的目标是教学清晰，所以选择一个确定行为：每次调用后，logger 只保留本次配置出来的 handler。

## 8. format_error_message

错误消息也要有统一风格。

本章新增：

```python
def format_error_message(field: str, problem: str) -> str:
```

示例：

```python
format_error_message("token_budget", "must be greater than 0")
```

返回：

```text
token_budget must be greater than 0
```

这条规则很简单：字段名 + 问题描述。它避免两类坏消息：

- 太含糊：`invalid value`
- 太冗长：把调用栈、建议、背景解释都塞进异常消息

错误消息的目标是让调用者立刻知道哪个字段出了什么问题。

## 9. 测试解读

测试文件是：

```text
tests/unit/test_logging_basics.py
```

它覆盖六个场景：

- `WARNING` 级别会隐藏 `INFO`，保留 `WARNING`。
- 重复调用 `configure_logging()` 不会让日志重复输出。
- 手动构造非法 `AppConfig(log_level="VERBOSE")` 会被拒绝。
- 项目 logger 不继续向 root logger 传播。
- `format_error_message()` 输出短而稳定的错误消息。
- 空字段名和空问题描述会被拒绝。

这些测试共同保护一个目标：日志和错误消息必须可预测。

## 10. 为什么不直接上结构化日志

真实生产系统常会使用 JSON 日志、OpenTelemetry、LangSmith 或 Langfuse。

第 05 章暂时不引入这些工具。原因是本阶段要先理解最小边界：

- 日志级别如何生效。
- logger 和 handler 如何配合。
- 日志输出如何被测试捕获。
- 错误消息如何保持短、具体、稳定。

等项目进入 API、监控、追踪和评估章节，再引入结构化日志更自然。

## 11. 读者自测

不看正文，尝试回答下面 5 个问题：

1. `print()` 和 `logging` 在工程里最大的区别是什么？
2. `AppConfig.log_level` 如何影响 logger 行为？
3. 为什么重复配置 logger 可能导致同一条日志出现多次？
4. 为什么要设置 `logger.propagate = False`？
5. 一个好的错误消息最少应该包含哪两类信息？

答不上来的地方，回到 `logging.py` 和测试文件对照阅读。

## 12. 练习

1. 把日志格式改成包含时间，例如增加 `%(asctime)s`。
2. 更新测试，验证输出中仍然包含 level、logger name 和 message。
3. 新增一个测试：`format_error_message(" default_model ", " must not be empty ")` 应自动清理两边空格。
4. 新增一个测试：`configure_logging(AppConfig(log_level="debug"))` 能把 logger 级别设为 `DEBUG`。
5. 改回当前实现，确认所有测试通过。

练习重点是理解日志格式、日志级别和测试捕获之间的关系。

## 13. 验收标准

完成本章后，你应该能独立解释：

- `configure_logging()` 做了哪几步。
- 为什么日志级别来自 `AppConfig`。
- 为什么测试里要传 `io.StringIO()`。
- 为什么错误消息也要写测试。
- 当前日志方案和生产级结构化日志之间还差什么。

验收命令：

```powershell
python -m pytest
```

第 05 章完成时应看到：

```text
23 passed
```

## 14. 学习反馈

完成本章后，记录 3 句话：

1. 哪个日志概念最容易混淆？
2. 哪个测试最能说明日志行为？
3. 后续进入 LLM 调用时，你希望日志记录哪些信息？

这些反馈会影响第 06 章 LLM 请求和响应对象的讲解方式。

## 15. 下一章

第 06 章会进入 LLM 调用基础。

你会学习如何定义 `Message`、`LLMRequest` 和 `LLMResponse`，先把模型调用的数据边界讲清楚，再接入 Mock 客户端。
