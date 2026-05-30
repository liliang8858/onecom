# 第 04 章：配置与环境变量基础

## 1. 本章学习目标

学完本章后，你应该能做到：

- 解释为什么配置不应该散落在业务代码里。
- 能区分默认配置、环境变量和运行时配置对象。
- 能写一个简单、可测试的配置加载函数。
- 能为非法配置写单元测试。
- 能读懂 `.env.example` 的作用和边界。

本章仍然不调用真实大模型。我们先解决一个更基础的问题：程序如何知道自己运行在哪个环境、使用哪个默认模型、允许消耗多少 token。

## 2. 为什么需要配置对象

初学时很容易把配置直接写在函数里：

```python
model = "mock-chat"
token_budget = 100000
```

这样短期看很方便，但项目一旦进入真实环境就会遇到问题：

- 本地、测试、生产环境需要不同配置。
- API、日志、预算、模型名称不能到处复制。
- 错误配置应该在启动时被发现，而不是运行一半才出错。
- 测试需要替换配置，但不应该污染真实系统环境。

所以本章新增一个配置对象：

```python
AppConfig
```

它把当前阶段需要的配置集中起来，让后续章节可以稳定复用。

## 3. 本章要实现什么

新增文件：

```text
src/enterprise_agent/foundation/config.py
```

新增公开 API：

```python
AppConfig
load_app_config()
```

配置字段包括：

| 字段 | 默认值 | 环境变量 |
|------|--------|----------|
| `app_name` | `enterprise-agent` | `ENTERPRISE_AGENT_APP_NAME` |
| `environment` | `development` | `ENTERPRISE_AGENT_ENV` |
| `log_level` | `INFO` | `ENTERPRISE_AGENT_LOG_LEVEL` |
| `default_model` | `mock-chat` | `ENTERPRISE_AGENT_DEFAULT_MODEL` |
| `token_budget` | `100000` | `ENTERPRISE_AGENT_TOKEN_BUDGET` |

这些字段都很朴素，但已经覆盖了企业 Agent 项目中最常见的配置类型：名称、环境、日志级别、模型选择和预算。

## 4. 配置对象

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

这里使用 `frozen=True`，表示配置对象创建后不应该被随意修改。

这不是为了炫技，而是为了减少一种常见问题：程序运行过程中，某个函数偷偷改了全局配置，导致后面的行为不可预测。

## 5. 从环境变量加载配置

本章的加载函数是：

```python
def load_app_config(environ: Mapping[str, str] | None = None) -> AppConfig:
```

它有两个使用方式。

生产代码可以直接读取系统环境变量：

```python
config = load_app_config()
```

测试代码可以传入一个字典：

```python
config = load_app_config(
    {
        "ENTERPRISE_AGENT_ENV": "test",
        "ENTERPRISE_AGENT_LOG_LEVEL": "debug",
    }
)
```

这个设计很重要：测试不需要真的修改电脑上的环境变量，就能验证不同配置场景。

## 6. 默认值

如果没有传入任何环境变量：

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

所以默认模型叫 `mock-chat`，它只是后续 Mock LLM 客户端的占位名称。

## 7. 环境变量覆盖

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

注意两个细节：

- `environment` 会转成小写。
- `log_level` 会转成大写。

这可以降低配置输入的脆弱性。用户写 `debug` 或 `DEBUG`，程序都能得到稳定的 `DEBUG`。

## 8. 配置校验

配置不是“读出来就算成功”。读出来以后还要检查是否合法。

本章约束如下：

```python
ALLOWED_ENVIRONMENTS = ("development", "test", "production")
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

配置校验越靠近启动阶段，系统越容易排查。不要等到 Agent 已经开始执行任务，才发现预算配置写错了。

## 9. `.env.example` 的作用

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

- 这个项目需要哪些配置项。
- 每个配置项长什么样。
- 本地实验可以从哪些默认值开始。

真正的 `.env`、API Key、密码和生产密钥不应该提交到仓库。

本章代码只读取真实环境变量，不直接解析 `.env` 文件。等后续进入 API 或部署章节，再决定是否引入专门的配置库。

## 10. 本章测试

测试文件是：

```text
tests/unit/test_config_basics.py
```

它覆盖八个场景：

```python
test_load_app_config_uses_safe_defaults
```

验证没有环境变量时使用安全默认值。

```python
test_load_app_config_reads_environment_overrides
```

验证环境变量可以覆盖默认值。

```python
test_load_app_config_rejects_empty_text_value
```

验证文本配置不能为空。

```python
test_load_app_config_rejects_unknown_environment
```

验证环境名必须在允许范围内。

```python
test_load_app_config_rejects_unknown_log_level
```

验证日志级别必须在允许范围内。

```python
test_load_app_config_rejects_non_integer_token_budget
```

验证 token 预算必须是整数。

```python
test_load_app_config_rejects_empty_token_budget
```

验证 token 预算不能是空字符串。

```python
test_load_app_config_rejects_non_positive_token_budget
```

验证 token 预算必须大于 0。

## 11. 为什么不直接用 Pydantic Settings

真实项目里，Pydantic Settings 是常见选择。但本课程第 04 章暂时不用它。

原因是本阶段目标不是学习配置框架，而是先理解配置的基本边界：

- 默认值从哪里来。
- 环境变量如何覆盖默认值。
- 字符串如何转换成整数。
- 非法配置在哪里被拒绝。
- 测试如何覆盖这些规则。

等项目进入 API、部署或更复杂的多环境管理时，再引入配置框架会更自然。

## 12. 本章练习

请完成以下练习：

1. 新增一个配置字段 `request_timeout_seconds`，默认值为 `30`。
2. 为它设计环境变量名：`ENTERPRISE_AGENT_REQUEST_TIMEOUT_SECONDS`。
3. 写测试验证默认值。
4. 写测试验证环境变量可以覆盖默认值。
5. 写测试验证 `0` 或负数会被拒绝。

练习时不要先改很多代码。先写一个失败测试，再补最少实现。

## 13. 本章验收标准

完成本章后，你需要能独立做到：

- 运行 `python -m pytest`。
- 解释 `AppConfig` 每个字段的用途。
- 解释 `load_app_config({})` 和 `load_app_config()` 的区别。
- 解释为什么测试里传字典比直接改系统环境更清楚。
- 解释 `.env.example` 为什么可以提交，而 `.env` 不应该提交。

当前验收命令：

```powershell
python -m pytest
```

应该看到：

```text
17 passed
```

## 14. 下一章预告

第 05 章会讲日志与错误信息。

你会学习：

- 为什么不要用 `print()` 当正式日志。
- 如何根据配置设置日志级别。
- 如何写对人有帮助的错误消息。
- 如何让测试验证错误信息没有退化。
