# 第 04 章：配置与环境变量基础

## 1. 本章交付物

本章会新增一个运行配置模块：

```text
src/enterprise_agent/foundation/config.py
```

它提供两个公开对象：

```python
AppConfig
load_app_config()
```

本章结束时，项目应该能做到：

- 有一组安全默认配置。
- 可以用环境变量覆盖默认值。
- 能在启动阶段拒绝非法配置。
- 测试不需要修改真实系统环境。
- `.env.example` 能说明项目需要哪些配置项。

## 1.1 完成态

完成本章时，你应该能指着一个配置值说明它的完整路径：

```text
默认值 -> 环境变量覆盖 -> 类型转换 -> 合法性校验 -> AppConfig 字段
```

如果只知道“配置从环境变量来”，但说不清每一步在哪里发生，本章还没完成。

## 2. 为什么需要配置对象

初学时很容易把配置直接写在函数里：

```python
model = "mock-chat"
token_budget = 100000
```

这在演示阶段很方便，但真实项目会很快出问题：

- 本地、测试、生产环境需要不同配置。
- 模型名、日志级别、预算不能散落在各处。
- 错误配置应该尽早暴露。
- 测试需要构造不同配置，但不能污染真实电脑环境。

配置对象的作用是把这些运行参数集中起来，形成一个清楚、可测试、可复用的入口。

## 3. 本章在前四章中的位置

第 04 章把前三章的能力合在一起：

- 第 01 章：工程能运行。
- 第 02 章：配置代码放进正确的包。
- 第 03 章：先用测试描述规则。

配置模块是前四章的第一次小整合。它虽然不调用模型，但后续 LLM 网关、日志、API 和部署都会依赖它。

## 4. 配置字段

本章配置字段如下：

| 字段 | 默认值 | 环境变量 |
|------|--------|----------|
| `app_name` | `enterprise-agent` | `ENTERPRISE_AGENT_APP_NAME` |
| `environment` | `development` | `ENTERPRISE_AGENT_ENV` |
| `log_level` | `INFO` | `ENTERPRISE_AGENT_LOG_LEVEL` |
| `default_model` | `mock-chat` | `ENTERPRISE_AGENT_DEFAULT_MODEL` |
| `token_budget` | `100000` | `ENTERPRISE_AGENT_TOKEN_BUDGET` |

这些字段覆盖了企业 Agent 项目最常见的运行参数：应用名、环境、日志级别、默认模型和 token 预算。

## 5. 关键术语

| 术语 | 在本章里的意思 |
|------|----------------|
| 默认配置 | 没有外部输入时也能让本地运行的安全值 |
| 环境变量 | 由运行环境提供的字符串配置 |
| 配置对象 | 程序内部使用的结构化配置，本章是 `AppConfig` |
| 配置校验 | 把错误配置挡在启动阶段 |
| `.env.example` | 配置说明文件，不存秘密 |

## 6. AppConfig

核心对象是：

```python
@dataclass(frozen=True)
class AppConfig:
    app_name: str = DEFAULT_APP_NAME
    environment: str = DEFAULT_ENVIRONMENT
    log_level: str = DEFAULT_LOG_LEVEL
    default_model: str = DEFAULT_MODEL
    token_budget: int = DEFAULT_TOKEN_BUDGET
```

`frozen=True` 表示配置对象创建后不应该被修改。

这能减少一种常见问题：程序运行过程中，某个函数偷偷改了全局配置，导致后续行为不可预测。

## 7. load_app_config

加载函数是：

```python
def load_app_config(environ: Mapping[str, str] | None = None) -> AppConfig:
```

它支持两种使用方式。

生产代码直接读真实环境变量：

```python
config = load_app_config()
```

测试代码传入字典：

```python
config = load_app_config(
    {
        "ENTERPRISE_AGENT_ENV": "test",
        "ENTERPRISE_AGENT_LOG_LEVEL": "debug",
    }
)
```

这个设计让测试保持干净。测试不需要修改操作系统环境变量，也不依赖开发者电脑上的真实配置。

## 8. 默认值

没有传入环境变量时：

```python
config = load_app_config({})
```

会得到：

```python
AppConfig(
    app_name="enterprise-agent",
    environment="development",
    log_level="INFO",
    default_model="mock-chat",
    token_budget=100_000,
)
```

默认值的原则是：

- 本地可运行。
- 不需要真实 API Key。
- 不触发外部服务。
- 后续章节可以平滑替换。

`mock-chat` 只是 Mock LLM 客户端的占位名称，不代表已经接入真实模型。

## 9. 环境变量覆盖

当环境变量存在时，它会覆盖默认值：

```python
config = load_app_config(
    {
        "ENTERPRISE_AGENT_APP_NAME": "training-agent",
        "ENTERPRISE_AGENT_ENV": "test",
        "ENTERPRISE_AGENT_LOG_LEVEL": "debug",
        "ENTERPRISE_AGENT_DEFAULT_MODEL": "mock-fast",
        "ENTERPRISE_AGENT_TOKEN_BUDGET": "2500",
    }
)
```

结果中：

```python
config.environment == "test"
config.log_level == "DEBUG"
config.token_budget == 2500
```

两个细节需要注意：

- `environment` 会转成小写。
- `log_level` 会转成大写。

这样用户写 `debug` 或 `DEBUG`，程序都能得到稳定的 `DEBUG`。

## 10. 配置校验

配置读取后还必须校验。

允许的环境是：

```python
ALLOWED_ENVIRONMENTS = ("development", "test", "production")
```

允许的日志级别是：

```python
ALLOWED_LOG_LEVELS = ("DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL")
```

如果传入未知环境：

```python
load_app_config({"ENTERPRISE_AGENT_ENV": "staging"})
```

会抛出：

```text
ValueError: ENTERPRISE_AGENT_ENV must be one of: development, test, production
```

如果 token 预算不是整数：

```python
load_app_config({"ENTERPRISE_AGENT_TOKEN_BUDGET": "many"})
```

会抛出：

```text
ValueError: ENTERPRISE_AGENT_TOKEN_BUDGET must be an integer
```

配置错误越早暴露，排查成本越低。不要等到 Agent 已经开始执行任务，才发现预算或环境名写错。

## 11. `.env.example`

本章更新了：

```text
.env.example
```

内容如下：

```text
ENTERPRISE_AGENT_APP_NAME=enterprise-agent
ENTERPRISE_AGENT_ENV=development
ENTERPRISE_AGENT_LOG_LEVEL=INFO
ENTERPRISE_AGENT_DEFAULT_MODEL=mock-chat
ENTERPRISE_AGENT_TOKEN_BUDGET=100000
```

`.env.example` 不是秘密文件。它的作用是告诉开发者和部署人员：

- 项目需要哪些配置项。
- 每个配置项的名字是什么。
- 本地实验可以从哪些默认值开始。

真正的 `.env`、API Key、密码和生产密钥不能提交到仓库。

本章代码只读取真实环境变量，不直接解析 `.env` 文件。等后续进入 API 或部署章节，再决定是否引入专门的配置库。

## 12. 测试解读

测试文件是：

```text
tests/unit/test_config_basics.py
```

它覆盖八个场景：

- 没有环境变量时使用安全默认值。
- 环境变量可以覆盖默认值。
- 文本配置不能为空。
- 环境名必须在允许范围内。
- 日志级别必须在允许范围内。
- token 预算必须是整数。
- token 预算不能是空字符串。
- token 预算必须大于 0。

这些测试共同保护一个目标：配置错误要尽早、清楚、可复现地暴露出来。

## 13. 为什么暂时不用 Pydantic Settings

真实项目里，Pydantic Settings 是常见选择。但第 04 章暂时不用它。

原因是本阶段要先理解配置的基本边界：

- 默认值从哪里来。
- 环境变量如何覆盖默认值。
- 字符串如何转换成整数。
- 非法配置在哪里被拒绝。
- 测试如何覆盖这些规则。

等项目进入 API、部署或更复杂的多环境管理时，再引入配置框架会更自然。

## 14. 读者自测

不看正文，尝试回答下面 5 个问题：

1. `load_app_config({})` 和 `load_app_config()` 有什么区别？
2. 为什么测试里传字典比修改系统环境变量更好？
3. `token_budget` 为什么需要从字符串转成整数？
4. 为什么未知环境要在加载配置时直接报错？
5. `.env.example` 能提交，真实 `.env` 为什么不能提交？

能回答这些问题，才说明你理解了配置边界。

## 15. 练习

1. 新增配置字段 `request_timeout_seconds`，默认值为 `30`。
2. 为它设计环境变量名：`ENTERPRISE_AGENT_REQUEST_TIMEOUT_SECONDS`。
3. 写测试验证默认值。
4. 写测试验证环境变量可以覆盖默认值。
5. 写测试验证 `0` 或负数会被拒绝。

练习时先写失败测试，再补最少实现。

## 16. 验收标准

完成本章后，你应该能独立解释：

- `AppConfig` 每个字段的用途。
- `load_app_config({})` 和 `load_app_config()` 的区别。
- 为什么测试里传字典比直接改系统环境更清楚。
- `.env.example` 为什么可以提交。
- `.env` 为什么不应该提交。

验收命令：

```powershell
python -m pytest
```

第 04 章完成时应看到：

```text
17 passed
```

## 17. 学习反馈

完成本章后，记录 3 句话：

1. 哪个配置字段你已经能完整解释？
2. 哪类非法配置最容易漏测？
3. 如果以后引入 Pydantic Settings，你希望它替你解决什么问题？

这些反馈会影响第 05 章日志配置和错误消息的讲解方式。

## 18. 下一章

第 05 章会讲日志与错误信息。

你会学习如何根据配置设置日志级别，如何写清楚的错误消息，以及如何用测试防止错误信息退化。
