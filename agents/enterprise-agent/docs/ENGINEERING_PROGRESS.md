# Enterprise Agent 工程进度

更新时间：2026-05-30

本文档记录工程实现状态。它和 `COURSE_PROGRESS.md` 配套使用，用于在新会话中恢复上下文。

## 当前状态

项目已完成课程化实现的第 04 章：配置与环境变量基础。

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

## 现有遗留状态

- 第一章工程入口统一为 `src/enterprise_agent/`。
- `evaluation/`、`k8s/`、`monitoring/`、`prompts/`、`tests/integration/`、`tests/e2e/` 等目录暂不创建，后续章节需要时再按课程进度创建。
- LLM 网关从第 06 章开始。本阶段只保留 `mock-chat` 作为默认模型名称，不接入真实 API。
- 配置加载函数读取系统环境变量或测试传入的 mapping，不直接解析 `.env` 文件。

## 当前验证命令

```powershell
cd E:\onecom\agents\enterprise-agent
python -m pytest
```

当前结果：

```text
17 passed
```

## 下一步工程任务

第 05 章实现日志与错误信息基础：

- 新增日志配置函数，建议放在 `src/enterprise_agent/foundation/logging.py` 或同阶段合适模块。
- 使用 `AppConfig.log_level` 控制日志级别。
- 保持错误消息短、具体、可测试。
- 新增单元测试覆盖日志级别应用和非法输入提示。
