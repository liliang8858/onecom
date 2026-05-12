import Foundation

// MARK: - Memory System (PRD v3.0 §7)
// Models the full memory lifecycle: Signal → Candidate → Pending → Confirmed → Adjusted/Deprecated

// ============================================================
// Memory Record
// ============================================================

struct MemoryRecord: Codable, Identifiable, Hashable {
    let id: String
    let type: MemoryType
    let patternDescription: String       // Human-readable description
    let evidenceSummary: String          // Source data summary
    let affectedMetrics: [String]        // Which HealthMetric ids are involved
    let confidenceScore: Double          // 0.0 - 1.0
    let observationCount: Int            // How many times pattern observed
    let firstObservedAt: Date
    var lastSeenAt: Date
    var status: MemoryStatus
    var userFeedback: MemoryFeedback?
    var changeLog: [ChangeLogEntry]
    var relatedAnomalies: [String]       // IDs of related DerivedInsight records

    // Computed
    var isConfirmed: Bool { status == .confirmed }
    var isActive: Bool { status == .confirmed || status == .adjusted }
    var ageInDays: Int { Calendar.current.dateComponents([.day], from: firstObservedAt, to: Date()).day ?? 0 }
}

enum MemoryType: String, Codable, Hashable {
    case correlation       // Pattern between two metrics (sleep ↔ HRV)
    case trend             // Directional change over time
    case anomaly           // Repeated anomaly pattern
    case response          // Response to action (post-exercise HR recovery)
    case preference        // Learned user preference
    case riskSignature     // Health risk pattern signature
}

enum MemoryStatus: String, Codable, Hashable {
    /// System detected signal, collecting evidence
    case observing
    /// Enough evidence to present to user for validation
    case candidate
    /// Awaiting explicit user confirmation
    case pendingConfirm
    /// User confirmed — participates in UI sorting
    case confirmed
    /// User confirmed but feedback changed presentation
    case adjusted
    /// Low confidence or invalidated by new data
    case deprecated

    // MARK: Display Info

    var displayTitle: String {
        switch self {
        case .observing: return "observing".localized
        case .candidate: return "candidate".localized
        case .pendingConfirm: return "pending_confirm".localized
        case .confirmed: return "confirmed".localized
        case .adjusted: return "adjusted".localized
        case .deprecated: return "deprecated".localized
        }
    }

    var participatesInSorting: Bool {
        switch self {
        case .confirmed, .adjusted: return true
        default: return false
        }
    }

    var isTerminal: Bool {
        switch self {
        case .deprecated: return true
        default: return false
        }
    }

    var nextStates: [MemoryStatus] {
        switch self {
        case .observing: return [.candidate, .deprecated]
        case .candidate: return [.pendingConfirm, .deprecated]
        case .pendingConfirm: return [.confirmed, .deprecated]
        case .confirmed: return [.adjusted, .deprecated]
        case .adjusted: return [.confirmed, .deprecated]
        case .deprecated: return []
        }
    }
}

// MARK: - Feedback on Memories

struct MemoryFeedback: Codable, Hashable {
    let verdict: MemoryVerdict
    let givenAt: Date
    let note: String?
}

enum MemoryVerdict: String, Codable, Hashable {
    case accurate
    case inaccurate
    case deferLater
    case remove
}

// MARK: - Change Log Entry

struct ChangeLogEntry: Codable, Identifiable, Hashable {
    let id: String
    let timestamp: Date
    let action: ChangeAction
    let detail: String

    enum ChangeAction: String, Codable, Hashable {
        case confirmed
        case rejected
        case feedbackApplied
        case autoAdjusted
        case deprecated
        case created
    }
}

// MARK: - Feedback Record (in UserBehavior)

struct FeedbackRecord: Codable, Hashable {
    let timestamp: Date
    let blockId: String?
    let feedbackType: String  // "helpful", "inaccurate", "too_complex", "skip", "action_complete", "action_failed"
    let metadata: [String: AnyCodable]?
}

// MARK: - Memory Engine Operations

protocol MemoryEngine {
    /// Add raw health signal candidates for pattern detection
    func ingestSignals(_ signals: [HealthSignal]) async

    /// Evaluate candidate memories against evidence thresholds
    func evaluateCandidates() async -> [MemoryRecord]

    /// Promote a candidate to pending confirmation
    func requestConfirmation(for memoryId: String) async -> Bool

    /// Process user feedback on a memory
    func processFeedback(memoryId: String, verdict: MemoryVerdict, note: String?) async -> MemoryRecord

    /// Retrieve active memories for UI rendering
    func activeMemories() async -> [MemoryRecord]

    /// Retrieve pending confirmation memories
    func pendingConfirmations() async -> [MemoryRecord]

    /// Retrieve all change log entries
    func changeLog() async -> [ChangeLogEntry]
}

// MARK: - Stub Implementation

final class MemoryEngineStub: MemoryEngine {
    private var memories: [MemoryRecord] = []

    func ingestSignals(_ signals: [HealthSignal]) async {
        // Offline pipeline stub
    }

    func evaluateCandidates() async -> [MemoryRecord] {
        []
    }

    func requestConfirmation(for memoryId: String) async -> Bool {
        false
    }

    func processFeedback(memoryId: String, verdict: MemoryVerdict, note: String?) async -> MemoryRecord {
        // Return empty stub
        MemoryRecord(
            id: memoryId,
            type: .correlation,
            patternDescription: "",
            evidenceSummary: "",
            affectedMetrics: [],
            confidenceScore: 0,
            observationCount: 0,
            firstObservedAt: Date(),
            lastSeenAt: Date(),
            status: .candidate,
            userFeedback: nil,
            changeLog: [],
            relatedAnomalies: []
        )
    }

    func activeMemories() async -> [MemoryRecord] {
        memories.filter { $0.isActive }
    }

    func pendingConfirmations() async -> [MemoryRecord] {
        memories.filter { $0.status == .pendingConfirm }
    }

    func changeLog() async -> [ChangeLogEntry] {
        memories.flatMap { $0.changeLog }
    }
}

// MARK: - Health Signal (raw input to memory pipeline)

struct HealthSignal: Codable {
    let metricId: String
    let value: Double
    let timestamp: Date
    let context: SignalContext
}

enum SignalContext: String, Codable {
    case dailySnapshot
    case workout
    case sleep
    case ecgEvent
    case manualInput
}