# Enterprise Agent 工程进度

更新时间：2026-05-24

本文档记录工程实现状态。它和 `COURSE_PROGRESS.md` 配套使用，用于在新会话中恢复上下文。

## 当前状态

项目已完成课程化实现的第 01 章：工程启动与开发环境。

## 已完成

- 新增 `pyproject.toml`，定义 Python 包、开发依赖和 pytest 配置。
- 新增 `src/enterprise_agent/` 包，作为后续正式实现入口。
- 新增 `ProjectInfo` 和 `get_project_info()`，用于第一章 smoke test。
- 新增 `tests/unit/test_project_setup.py`，验证项目包可以被测试环境正确导入。
- 新增课程进度文档 `docs/COURSE_PROGRESS.md`。
- 新增工程进度文档 `docs/ENGINEERING_PROGRESS.md`。
- 更新根 `.gitignore`，忽略 Python editable install 生成的 `*.egg-info/`、`.pytest_cache/` 和 `.venv/`。
- 已运行 `python -m pip install -e ".[dev]"` 安装开发依赖。
- 已运行 `python -m pytest`，结果为 `1 passed`。
- 已清理第一章暂未使用的空占位目录：`evaluation/`、`k8s/`、`monitoring/`、`prompts/`、`scripts/`、`src/api/`、`src/llm/`、`src/memory/`、`src/rag/`、`src/tools/`、`tests/integration/`、`tests/e2e/`。
- 已清理旧骨架目录 `src/agents/`。后续 Agent 代码统一放到 `src/enterprise_agent/agents/`。
- 已清理本地测试缓存：`.pytest_cache/` 和 `__pycache__/`。

## 现有遗留状态

- 第一章工程入口统一为 `src/enterprise_agent/`。
- `evaluation/`、`k8s/`、`monitoring/`、`prompts/`、`scripts/`、`tests/integration/`、`tests/e2e/` 已从第一章基线中移除。后续章节需要时再按课程进度创建。

## 当前验证命令

```powershell
cd agents\enterprise-agent
python -m pytest
```

## 下一步工程任务

第 02 章实现 Python 包结构与导入路径：

- 梳理 `src/enterprise_agent/` 包入口。
- 补充一个小型子模块，让学员理解模块拆分。
- 演示 `from enterprise_agent import ...` 与内部模块导入的区别。
- 增加对应单元测试，覆盖公开 API 导出。

LLM 网关推迟到第 06 章开始。这样基础学员会先掌握 Python 工程和测试节奏，再进入模型调用。
