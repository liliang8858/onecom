import Foundation
import SwiftUI

// ==========================================================================
// MARK: - AgencyMode (PRD v3.0 §9)
// ==========================================================================

enum AgencyMode: String, Codable, Hashable {
    /// Agent 主导总结，用户被动接收
    case agentGuided
    /// 用户自主探索，Agent 提供辅助
    case selfExplore
}

// ==========================================================================
// MARK: - ContextMode
// ==========================================================================

enum ContextMode: String, Codable, Hashable {
    /// 早晨简报：信息密度低，聚焦关键指标
    case morningBrief
    /// 深度解读：完整数据链 + 证据
    case deepDive
}

// ==========================================================================
// MARK: - HealthIntent
// ==========================================================================

enum HealthIntent: String, Codable, Hashable {
    case dailyCheck
    case recoveryAnalysis
    case sleepAnalysis
    case heartStatus
    case anomalyReview
    case ecgInterpretation
    case weeklyReview
    case customQuery
}

// ==========================================================================
// MARK: - UISchema (PRD v3.0 §10)
// ==========================================================================

struct UISchema: Codable, Hashable, Identifiable {
    let id: String
    let schemaVersion: String
    let screen: ScreenType
    let userIntent: HealthIntent
    let layout: LayoutType
    let generatedAt: String
    let contextMode: ContextMode
    let availableAttention: AttentionLevel
    let agencyMode: AgencyMode
    let healthPriorityPolicy: PriorityPolicy
    let emotionalFraming: EmotionalFraming
    let explanationContract: ExplanationContract
    let personalizationReason: String?
    let personalizationFactors: [String]
    let minSafetyLevelShown: SafetyLevel
    let blocks: [UIBlock]
}

// ==========================================================================
// MARK: - UIBlock
// ==========================================================================

struct UIBlock: Codable, Hashable, Identifiable {
    let blockId: String
    let type: BlockType
    let priority: Int
    let healthNeedScore: Double
    let experienceFitScore: Double
    let safetyLevel: SafetyLevel
    let dataPayload: [String: AnyCodable]
    let whyShownReason: String?
    let feedbackEnabled: Bool
    let expandable: Bool
    let agencyVariant: AgencyMode?

    enum CodingKeys: String, CodingKey {
        case blockId
        case type
        case priority
        case healthNeedScore
        case experienceFitScore
        case safetyLevel
        case dataPayload
        case whyShownReason
        case feedbackEnabled
        case expandable
        case agencyVariant
    }
}

// ==========================================================================
// MARK: - HealthPageSchema
// ==========================================================================

struct HealthPageSchema: Codable, Identifiable {
    let id: String
    let title: String
    let timeRange: String
    let blocks: [UIBlock]
}

// ==========================================================================
// MARK: - Supporting Enums
// ==========================================================================

enum ScreenType: String, Codable, Hashable {
    case today
    case insight
    case dynamicAnalysis
    case settings
}

enum LayoutType: String, Codable, Hashable {
    case insightFirst
    case dataFirst
    case evidenceFirst
    case summaryFirst
    case list
}

enum AttentionLevel: String, Codable, Hashable {
    case high
    case medium
    case low
}

enum PriorityPolicy: String, Codable, Hashable {
    case healthNeedOverPreference
    case balanced
}

enum EmotionalFraming: String, Codable, Hashable {
    case calmActionable
    case directEvidence
    case reassuring
}

enum ExplanationContract: String, Codable, Hashable {
    case brief
    case balanced
    case evidenceFirst
}