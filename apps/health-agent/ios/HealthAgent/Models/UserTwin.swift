import Foundation

// MARK: - User Twin Model (PRD v3.0 §6)
// Five-layer persona that drives personalization, sorting, and safety.

struct UserTwin: Codable, Hashable {
    let healthFocus: HealthFocus
    let preference: UserPreference
    let behavior: UserBehavior
    let goals: [ActiveGoal]
    let risk: RiskProfile
    let memoryStats: MemoryStatistics

    // Singleton for MVP — in production, fetched from backend
    static var `default`: UserTwin {
        UserTwin(
            healthFocus: .default,
            preference: .default,
            behavior: .default,
            goals: [],
            risk: .default,
            memoryStats: .default
        )
    }

    /// Check if user is flagged as anxiety-prone
    var isAnxietyProne: Bool {
        preference.anxietyProne || behavior.anxietyScore > 0.6
    }
}

// MARK: - Layer 1: Health Focus

struct HealthFocus: Codable, Hashable {
    let domainWeights: [HealthDomain: Double]
    let confidence: FocusConfidence
    let dataAgeDays: Int

    static let `default` = HealthFocus(
        domainWeights: [.sleep: 0.45, .recovery: 0.30, .heart: 0.25],
        confidence: .medium,
        dataAgeDays: 0
    )
}

enum HealthDomain: String, Codable, Hashable {
    case sleep
    case recovery
    case heart
    case activity
    case nutrition
    case mentalHealth
    case ecg
    case anomaly
}

enum FocusConfidence: String, Codable, Hashable {
    case low       // < 7 days data
    case medium    // 7-21 days
    case high      // > 21 days with confirmed patterns
}

// MARK: - Layer 2: User Preference

struct UserPreference: Codable, Hashable {
    var explanationDepth: ExplanationDepth
    var actionPreference: ActionPreference
    var uiPreference: UIPreference
    var notificationTolerance: NotificationTolerance
    var anxietyProne: Bool
    var preferredSummaryTime: SummaryTime
    var agencyDefault: AgencyMode
    var chartRangeDays: Int  // preferred lookback for charts

    static let `default` = UserPreference(
        explanationDepth: .moderate,
        actionPreference: .smallSteps,
        uiPreference: .summaryFirst,
        notificationTolerance: .low,
        anxietyProne: false,
        preferredSummaryTime: .morning,
        agencyDefault: .agentGuided,
        chartRangeDays: 14
    )
}

enum ExplanationDepth: String, Codable, Hashable {
    case brief        // One sentence
    case moderate     // Short paragraph + key data
    case detailed     // Full evidence chain + sources
}

enum ActionPreference: String, Codable, Hashable {
    case smallSteps   // 1-2 small actions
    case structured   // Structured plan with timeline
    case exploratory  // Try different things
}

enum UIPreference: String, Codable, Hashable {
    case summaryFirst    // Lead with conclusion
    case dataFirst       // Lead with charts
    case evidenceFirst   // Lead with evidence chain
}

enum NotificationTolerance: String, Codable, Hashable {
    case high    // Frequent nudges
    case medium  // Daily summary only
    case low     // Only critical alerts
    case none    // No proactive notifications
}

enum SummaryTime: String, Codable, Hashable {
    case morning
    case evening
    case flexible
}

// MARK: - Layer 3: Behavior (learned from interaction)

struct UserBehavior: Codable, Hashable {
    var clickThroughRates: [String: Double]  // cardType -> rate
    var actionCompletionRates: [String: Double]  // actionType -> rate
    var fatigueCounts: [String: Int]  // alertType -> dismiss count
    var detailPreferenceScore: Double  // 0.0-1.0, how often expand details
    var anxietyScore: Double           // 0.0-1.0, inferred anxiety level
    var agencyPreferenceRatio: Double  // % of time in agent-guided mode
    var feedbackHistory: [FeedbackRecord]
    var searchQueries: [String]

    static let `default` = UserBehavior(
        clickThroughRates: [:],
        actionCompletionRates: [:],
        fatigueCounts: [:],
        detailPreferenceScore: 0.5,
        anxietyScore: 0.3,
        agencyPreferenceRatio: 0.7,
        feedbackHistory: [],
        searchQueries: []
    )
}

// MARK: - Layer 4: Goals

struct ActiveGoal: Codable, Hashable, Identifiable {
    let id: String
    let type: GoalType
    let target: GoalTarget
    let createdAt: Date
    var progress: Double  // 0.0-1.0
    var lastUpdated: Date

    enum GoalType: String, Codable, Hashable {
        case improveSleep
        case reduceFatigue
        case stabilizeHeartRate
        case improveHRV
        case increaseActivity
        case manageStress
        case custom(String)
    }

    enum GoalTarget: Codable, Hashable {
        case metricThreshold(metric: String, value: Double, direction: Direction)
        case behaviorFrequency(action: String, timesPerWeek: Int)

        enum Direction: String, Codable, Hashable {
            case increase
            case decrease
            case maintain
        }
    }
}

// MARK: - Layer 5: Risk Profile

struct RiskProfile: Codable, Hashable {
    var sensitivity: SensitivityLevel
    var flaggedConditions: [FlaggedCondition]
    var requiresEscalation: Bool
    var lastEscalationAt: Date?
    var monitoredMetrics: [String: MetricThreshold]

    static let `default` = RiskProfile(
        sensitivity: .low,
        flaggedConditions: [],
        requiresEscalation: false,
        lastEscalationAt: nil,
        monitoredMetrics: [:]
    )
}

enum SensitivityLevel: String, Codable, Hashable {
    case low
    case medium
    case high
    case clinical
}

struct FlaggedCondition: Codable, Hashable, Identifiable {
    let id: String
    let type: String
    let severity: SafetyLevel
    let firstDetected: Date
    var confirmedByUser: Bool
    var lastSeen: Date
}

struct MetricThreshold: Codable, Hashable {
    let metricId: String
    let normalRange: ClosedRange<Double>
    let userBaseline: Double
    let alertDeviationPercent: Double  // e.g. 20 = alert if 20% from baseline
}

// MARK: - Memory Statistics

struct MemoryStatistics: Codable, Hashable {
    var totalMemories: Int
    var confirmedCount: Int
    var observingCount: Int
    var candidateCount: Int
    var deprecatedCount: Int
    var meanConfidence: Double
    var lastUpdateDate: Date

    static let `default` = MemoryStatistics(
        totalMemories: 0,
        confirmedCount: 0,
        observingCount: 0,
        candidateCount: 0,
        deprecatedCount: 0,
        meanConfidence: 0.0,
        lastUpdateDate: Date()
    )
}