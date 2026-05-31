# Enterprise Agent 工程进度

更新时间：2026-05-30

本文档记录工程实现状态。它和 `COURSE_PROGRESS.md` 配套使用，用于在新会话中恢复上下文。

## 当前状态

项目已完成课程化实现的第 07 章：MockLLMClient：不用 API Key 学模型调用。

## 已完成

- 新增 `pyproject.toml`，定义 Python 包、开发依赖和 pytest 配置。
- 新增 `src/enterprise_agent/` 包，作为后续正式实现入口。
- 新增 `ProjectInfo` 和 `get_project_info()`，用于第 01 章 smoke test。
- 新增 `tests/unit/test_project_setup.py`，验证项目包可以被测试环境正确导入。
- 新增课程进度文档 `docs/COURSE_PROGRESS.md`。
- 新增工程进度文档 `docs/ENGINEERING_PROGRESS.md`。
- 更新根 `.gitignore`，忽略 Python editable install 生成的 `*.egg-info/`、`.pytest_cache/` 和 `.venv/`。
- 新增 `src/enterprise_agent/foundation/` 子包，用于工程基础阶段教学示例。
- 新增 `ModuleInfo`、`CORE_MODULES`、`get_module_names()`、`find_module()`，演示子模块、子包入口和公开 API。
- 新增 `tests/unit/test_package_structure.py`，验证顶层包入口、子包导入和模块查找。
- 新增第 02 章学习文档 `docs/lessons/02-package-structure.md`。
- 新增 `src/enterprise_agent/foundation/chapter_titles.py`，实现 `format_chapter_title()`。
- 更新 `src/enterprise_agent/foundation/__init__.py`，导出 `format_chapter_title()`。
- 新增 `tests/unit/test_testing_rhythm.py`，覆盖章节号补零、两位数保留、标题清理和非法输入异常。
- 新增第 03 章学习文档 `docs/lessons/03-testing-rhythm.md`。
- 新增 `src/enterprise_agent/foundation/config.py`，实现 `AppConfig` 和 `load_app_config()`。
- 更新 `src/enterprise_agent/foundation/__init__.py`，导出 `AppConfig` 和 `load_app_config()`。
- 更新 `.env.example`，列出第 04 章配置项并说明 `.env` 边界。
- 新增 `tests/unit/test_config_basics.py`，覆盖配置默认值、环境变量覆盖、空值、枚举错误和 token 预算错误。
- 新增第 04 章学习文档 `docs/lessons/04-config-env.md`。
- 新增 `src/enterprise_agent/foundation/logging.py`，实现 `configure_logging()` 和 `format_error_message()`。
- 更新 `src/enterprise_agent/foundation/__init__.py`，导出日志配置和错误消息 helper。
- 新增 `tests/unit/test_logging_basics.py`，覆盖日志级别、handler 替换、propagation 和错误消息格式。
- 新增第 05 章学习文档 `docs/lessons/05-logging-errors.md`。
- 新增 `src/enterprise_agent/llm/` 子包，作为 LLM 调用边界入口。
- 新增 `src/enterprise_agent/llm/messages.py`，实现 `Message`、`LLMRequest`、`LLMResponse`。
- `Message` 覆盖角色白名单、内容清理、可选 `name` 和 `to_dict()`。
- `LLMRequest` 覆盖模型名、消息 tuple、temperature、输出上限、metadata、`prompt_text` 和 `to_payload()`。
- `LLMResponse` 覆盖 assistant 响应、token usage、finish reason、raw id 和 `usage()`。
- 新增 `tests/unit/test_llm_messages.py`，覆盖消息规范化、非法角色、空请求、参数范围、响应角色和 token 统计。
- 新增第 06 章学习文档 `docs/lessons/06-llm-call-shape.md`。
- 新增第 06 章高密度教程图片资产 `docs/lessons/assets/06-llm-call-shape/`。
- 新增 `scripts/generate_lesson06_assets.py`，用 UTF-8 Python 脚本和 CJK 字体稳定生成第 06 章图片，避免 Windows shell 中文乱码。
- 新增 `src/enterprise_agent/llm/clients.py`，实现 `BaseLLMClient` 和 `MockLLMClient`。
- `BaseLLMClient` 定义异步客户端边界 `complete(request: LLMRequest) -> LLMResponse`。
- `MockLLMClient` 返回稳定 assistant 响应、固定 token usage、`finish_reason` 和递增 `raw_id`。
- `MockLLMClient.calls` 以只读 tuple 暴露调用历史，便于后续 Agent 测试验证请求传递。
- 更新 `src/enterprise_agent/llm/__init__.py`，导出客户端边界。
- 新增 `tests/unit/test_mock_llm_client.py`，覆盖抽象边界、稳定响应、调用历史、raw id 递增、非法请求和非法配置。
- 新增第 07 章学习文档 `docs/lessons/07-mock-llm-client.md`。
- 新增第 07 章高密度教程图片资产 `docs/lessons/assets/07-mock-llm-client/`。
- 新增 `scripts/generate_lesson07_assets.py`，复用第 06 章图表组件生成稳定中文教程图。

## 现有遗留状态

- 第一章工程入口统一为 `src/enterprise_agent/`。
- `evaluation/`、`k8s/`、`monitoring/`、`prompts/`、`tests/integration/`、`tests/e2e/` 等目录暂不创建，后续章节需要时再按课程进度创建。
- LLM 网关边界已从第 06 章开始建立。本阶段只保留 `mock-chat` 作为默认模型名称，不接入真实 API。
- 第 07 章只实现 Mock 客户端，不实现真实 SDK、真实 API Key、供应商鉴权、超时重试、限流和成本计算。
- 配置加载函数读取系统环境变量或测试传入的 mapping，不直接解析 `.env` 文件。

## 当前验证命令

```powershell
cd E:\onecom\agents\enterprise-agent
python -m pytest
```

当前结果：

```text
36 passed
```

## 下一步工程任务

第 08 章实现真实模型客户端边界：

- 设计 OpenAI-compatible 客户端边界或同等真实客户端占位。
- 引入可注入 transport / fake transport，先测试边界，不依赖真实 API Key。
- 明确超时配置、重试次数、供应商错误归一化和响应解析。
- 保持输出统一为 `LLMResponse`，避免业务层依赖供应商原始 JSON。
