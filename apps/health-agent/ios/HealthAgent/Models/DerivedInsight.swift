import Foundation

// MARK: - HealthAction (PRD v3.0 §4.3)
// 具体到时间、方式、难度

struct HealthAction: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let reason: String       // "为什么是你，为什么是今天"
    let difficulty: ActionDifficulty
    let estimatedDuration: TimeInterval?  // 秒
    let suggestedTime: Date?
    let meta: HealthActionMeta?

    enum ActionDifficulty: String, Codable, Hashable {
        case easy       // < 5 min
        case moderate   // 5-30 min
        case hard       // > 30 min or requires special conditions
    }
}

struct HealthActionMeta: Codable, Hashable {
    let completionRate: Double?       // 历史完成率
    let lastCompletedAt: Date?
    let streak: Int?                  // 连续完成次数
    let relatedMetrics: [String]?     // 受影响的指标
}

// MARK: - DerivedDailySnapshot (派生指标聚合)

struct DerivedDailySnapshot: Codable, Hashable {
    let date: Date
    let metrics: [String: MetricSnapshot]
    let recoveryScore: Double?        // 0-100
    let sleepScore: Double?           // 0-100
    let cardiacScore: Double?         // 0-100
    let activityScore: Double?        // 0-100
    let anomalyCount: Int
    let ecgCount: Int
    let dataCompleteness: Double      // 0-1.0，数据完整度

    subscript(metricId: String) -> MetricSnapshot? {
        metrics[metricId]
    }
}

struct MetricSnapshot: Codable, Hashable {
    let metricId: String
    let value: Double
    let unit: String
    let status: MetricStatus
    let deviationFromBaseline: Double?   // % from personal baseline
    let trend7d: TrendDirection?
    let trend30d: TrendDirection?

    enum TrendDirection: String, Codable, Hashable {
        case improving
        case stable
        case declining
        case fluctuating
    }
}

// MARK: - Derived Features (PRD v3.0 §16, §8.2)
// 派生特征层 — Agent 不应直接分析原始样本

struct DerivedInsight: Codable, Hashable, Identifiable {
    let id: String
    let title: String               // "静息心率连续 4 天偏高"
    let summary: String             // 原因说明
    let severity: InsightSeverity
    let relatedMetrics: [String]
    let affectedDateRange: DateRange?
    let confidenceScore: Double     // 0-1
    let sourceMetrics: [String: Double]?  // 原始指标值记录
    let suggestedActions: [HealthAction]?
    let isEcgRelated: Bool
    let wasConfirmedByUser: Bool?

    enum InsightSeverity: String, Codable, Hashable {
        case info
        case attention      // 建议查看
        case warning        // 需要注意
        case highAttention  // 建议立即关注
    }
}

struct DateRange: Codable, Hashable {
    let start: Date
    let end: Date
}

// MARK: - Health Need Scorer (PRD v3.0 §8.2)
// 决定"该不该展示"，不受用户偏好影响

struct HealthNeedScore: Codable, Hashable {
    let score: Double                              // 0-1
    let clinicalRelevance: Double                  // 0-1
    let deviationFromBaseline: Double              // 0-1
    let persistenceScore: Double                   // 0-1 持续时长
    let riskLevelScore: Double                     // 0-1 风险等级
    let actionabilityScore: Double                 // 0-1 可行动性

    var requiresDisplay: Bool { score > 0.4 }
}

// MARK: - Experience Fit Scorer (PRD v3.0 §8.5)

struct ExperienceFitScore: Codable, Hashable {
    let score: Double
    let userInterest: Double          // 0-1
    let preferredFormatMatch: Double  // 0-1
    let attentionContextMatch: Double // 0-1
    let emotionalTolerance: Double    // 0-1
    let noveltyWithoutFatigue: Double // 0-1
}

// MARK: - Sorting Result (moved to Agent layer due to BlockType dependency)
// See Agent/SortingEngine for the actual sorted result type.