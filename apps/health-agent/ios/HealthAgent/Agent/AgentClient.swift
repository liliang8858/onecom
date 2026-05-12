import Foundation

// MARK: - AgentClient Protocol (PRD v3.0 §14)
// 定义云端 Agent 的客户端协议，由 MockAgentClient 和未来真实实现共同遵守

protocol AgentClient {
    // MARK: Schema 获取
    /// 获取个性化画布 Schema
    func fetchCanvasSchema(
        intent: HealthIntent,
        contextMode: ContextMode,
        agencyMode: AgencyMode
    ) async throws -> UISchema

    /// 对话问答，返回动态分析页 Schema
    func chat(
        query: String,
        context: HealthContext
    ) async throws -> UISchema

    // MARK: 记忆管理
    /// 获取活跃记忆
    func fetchActiveMemories() async throws -> [MemoryRecord]

    /// 获取待确认记忆
    func fetchPendingConfirmations() async throws -> [MemoryRecord]

    /// 提交记忆反馈
    func submitMemoryFeedback(
        memoryId: String,
        verdict: MemoryVerdict,
        note: String?
    ) async throws -> MemoryRecord

    /// 删除记忆
    func deleteMemory(id: String) async throws

    // MARK: 反馈
    /// 提交 UI 反馈
    func submitFeedback(_ feedback: FeedbackSubmission) async throws -> FeedbackResponse

    // MARK: 行动效果追踪
    /// 提交行动完成状态
    func reportActionCompletion(
        actionId: String,
        completed: Bool,
        metadata: [String: AnyCodable]?
    ) async throws

    // MARK: 变更日志
    /// 获取变更日志
    func fetchChangeLog() async throws -> [ChangeLogEntry]
}

// MARK: - Agent Error

enum AgentError: Error, LocalizedError {
    case networkError(underlying: Error)
    case schemaValidationError(reason: String)
    case unauthorized
    case rateLimited(retryAfter: TimeInterval)
    case internalError(code: String)

    var errorDescription: String? {
        switch self {
        case .networkError: return "网络连接失败，请检查网络后重试"
        case .schemaValidationError(let reason): return "数据格式异常：\(reason)"
        case .unauthorized: return "授权已过期，请重新登录"
        case .rateLimited(let retryAfter): return "请求过于频繁，请\(Int(retryAfter))秒后重试"
        case .internalError(let code): return "服务暂时不可用（\(code)）"
        }
    }
}

// MARK: - Health Context (传给 Agent 的上下文)

struct HealthContext: Codable {
    let snapshot: DailyHealthSnapshot
    let permissionSummary: HealthPermissionSummary
    let latestECG: ECGEpisode?
    let userTwin: UserTwin
    let sessionId: String
    let appOpenTime: Date
    let localTimezone: String
}