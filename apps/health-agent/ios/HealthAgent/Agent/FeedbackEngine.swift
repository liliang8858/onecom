import Foundation

// MARK: - Feedback & Behavioral Tracking (PRD v3.0 §12)

// ============================================================
// Explicit Feedback
// ============================================================

enum FeedbackCategory: String, Codable {
    case helpful          // 这个洞察有帮助
    case inaccurate       // 信息不准确
    case tooComplex       // 太复杂，看不懂
    case skip             // 不想看这类内容
    case actionCompleted   // 完成了建议的行动
    case actionTooHard     // 建议的行动太难完成
    case actionNotSuitable  // 行动不适合我
    case actionReplace     // 换一个行动
    case reminderTooMany   // 提醒太多
    case reminderUseful     // 提醒有用
}

struct FeedbackSubmission: Codable {
    let blockId: String
    let category: FeedbackCategory
    let screenId: String
    let timestamp: Date
    let metadata: [String: AnyCodable]?

    init(blockId: String, category: FeedbackCategory, screenId: String, metadata: [String: AnyCodable]? = nil) {
        self.blockId = blockId
        self.category = category
        self.screenId = screenId
        self.timestamp = Date()
        self.metadata = metadata
    }
}

struct FeedbackResponse: Codable {
    let acknowledged: Bool
    let appliedChange: String?
    let nextAdjustment: NextAdjustment?

    struct NextAdjustment: Codable {
        let type: String  // "frequency", "depth", "tone", "format"
        let direction: String  // "reduce", "increase", "change"
        let description: String
    }
}

// ============================================================
// Implicit Behavioral Signals
// ============================================================

enum BehavioralSignal: String, Codable {
    case cardExposure       // 卡片曝光
    case cardStay           // 停留 > 阈值
    case cardExpand         // 展开查看详情
    case cardCollapse       // 折叠
    case cardSkip           // 快速滑过
    case actionTap          // 点击行动按钮
    case actionComplete     // 标记行动完成
    case actionSkip         // 跳过行动
    case detailDrillDown    // 深入查看数据
    case exportTapped       // 点击导出
    case shareTapped        // 点击分享
    case feedbackOpen       // 打开反馈入口
    case feedbackSubmit     // 提交反馈
    case backNavigation     // 返回上一级
    case searchQuery        // 搜索/询问
    case pushDismiss        // 推送被关闭
    case pushOpen           // 推送被打开
}

struct BehavioralEvent: Codable {
    let signal: BehavioralSignal
    let blockId: String?
    let screenId: String
    let timestamp: Date
    let metadata: [String: AnyCodable]?

    init(signal: BehavioralSignal, screenId: String, blockId: String? = nil, metadata: [String: AnyCodable]? = nil) {
        self.signal = signal
        self.blockId = blockId
        self.screenId = screenId
        self.timestamp = Date()
        self.metadata = metadata
    }
}

// ============================================================
// Feedback Processor (Local)
// ============================================================

protocol FeedbackProcessing {
    /// Submit explicit feedback and get immediate UI adjustment
    func submitFeedback(_ feedback: FeedbackSubmission) async -> FeedbackResponse

    /// Log implicit behavioral signal
    func logBehavior(_ event: BehavioralEvent)

    /// Compute behavioral adjustments for given user twin
    func computeBehavioralAdjustments(for twin: UserTwin) -> BehavioralAdjustment
}

struct BehavioralAdjustment {
    let explanationDepthDelta: Double  // -0.1 or +0.1
    let notificationToleranceDelta: Double
    let interestWeightsDelta: [String: Double]
    let actionDifficultyAdjustment: String?  // "easier" | "harder"
    let fatiguePenaltyActive: Bool
}

// ============================================================
// Feedback Analytics (summary for backend sync)
// ============================================================

struct FeedbackSummary: Codable {
    let periodStart: Date
    let periodEnd: Date
    let totalFeedbacks: Int
    let positiveRate: Double
    let inaccuracyRate: Double
    let complexityRate: Double
    let skipRate: Double
    let actionCompletionRate: Double
    let topSkippedBlocks: [String]
    let topHelpfulBlocks: [String]
    let behavioralSignals: [BehavioralSignal: Int]
}

// ============================================================
// Stub Implementation
// ============================================================

final class FeedbackEngineStub: FeedbackProcessing {
    private var feedbackLog: [FeedbackSubmission] = []
    private var behaviorLog: [BehavioralEvent] = []

    func submitFeedback(_ feedback: FeedbackSubmission) async -> FeedbackResponse {
        feedbackLog.append(feedback)

        // Immediate UI adjustment logic
        let change: String?
        switch feedback.category {
        case .tooComplex:
            change = "健康解释已改为简洁模式"
        case .skip:
            change = "此类内容展示频率已降低"
        case .helpful:
            change = "同类内容将优先展示"
        case .inaccurate:
            change = "已记录不准确反馈，将优化数据来源"
        case .actionCompleted:
            change = "类似行动推荐权重已提升"
        case .reminderTooMany:
            change = "提醒频率已降低"
        default:
            change = nil
        }

        return FeedbackResponse(
            acknowledged: true,
            appliedChange: change,
            nextAdjustment: nil
        )
    }

    func logBehavior(_ event: BehavioralEvent) {
        behaviorLog.append(event)
    }

    func computeBehavioralAdjustments(for twin: UserTwin) -> BehavioralAdjustment {
        // Analyze behavior log and produce adjustments
        let deepDiveRate = behaviorLog.filter { $0.signal == .detailDrillDown }.count
        let skipRate = behaviorLog.filter { $0.signal == .cardSkip }.count

        return BehavioralAdjustment(
            explanationDepthDelta: deepDiveRate > 3 ? 0.1 : (skipRate > 5 ? -0.1 : 0),
            notificationToleranceDelta: 0,
            interestWeightsDelta: [:],
            actionDifficultyAdjustment: twin.behavior.actionCompletionRates.values.contains(where: { $0 < 0.3 }) ? "easier" : nil,
            fatiguePenaltyActive: twin.behavior.fatigueCounts.values.contains(where: { $0 > 3 })
        )
    }
}