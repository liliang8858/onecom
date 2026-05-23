# Agents — 云端 AI Agent 系统

gents/ 是 OneCom Monorepo 的 **云端系统线**，与 pps/（iOS 客户端线）平起平坐。

每个子目录是一个独立的 AI Agent 项目，拥有自己的设计文档、源码和部署管线。

---

## 当前项目

| 项目 | 路径 | 定位 | 状态 |
|------|------|------|------|
| Enterprise Agent | enterprise-agent/ | 企业级 AI Agent 万能模板 | 设计完成，待实现 |

---

## 新增 Agent 项目

1. 在 gents/ 下创建 <agent-name>/ 目录
2. 包含项目 README.md 和技术设计文档
3. 按推荐结构组织源码：src/agents/、src/tools/、src/memory/、src/rag/、src/llm/、src/api/
4. 独立 CI/CD 管线（每个 Agent 系统可能有不同的部署目标）

推荐项目骨架参见 enterprise-agent/docs/AI Agent 企业级开发技术设计文档.md §8.1。
