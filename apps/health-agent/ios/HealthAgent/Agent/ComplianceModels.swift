import Foundation

// MARK: - Safety & Compliance Models (PRD v3.0 §13)

// ============================================================
// Safety Level Actions
// ============================================================

struct SafetyPolicy {
    /// Minimum SafetyLevel that triggers "must be visible" constraint,
    /// regardless of user personalization preferences.
    static let minimumDisplayLevel: SafetyLevel = .elevated

    /// Maps SafetyLevel to display strategy.
    static func displayStrategy(for level: SafetyLevel, isAnxietyProne: Bool) -> DisplayStrategy {
        switch level {
        case .info:
            return isAnxietyProne ? .brief : .normal
        case .advisory:
            return .normal
        case .monitoring:
            return isAnxietyProne ? .reassuring : .normal
        case .elevated:
            return .reassuring
        case .critical:
            return .mandatoryAlert
        }
    }

    /// Whether this level can be hidden by user preference "don't show this again"
    static func canBeHidden(_ level: SafetyLevel) -> Bool {
        level.rawValue < SafetyLevel.elevated.rawValue
    }
}

enum DisplayStrategy: String, Codable {
    /// Normal display with full detail
    case normal
    /// Brief, calm language, reduced density
    case brief
    /// Reassuring framing: acknowledge concern → explain → suggest action
    case reassuring
    /// Force display: full-screen alert card, non-dismissable without action
    case mandatoryAlert
}

// ============================================================
// Non-Diagnostic Disclaimer
// ============================================================

struct NonDiagnosticDisclaimer {
    static let standard = """
        以上内容基于您的健康数据和记录生成，用于健康管理参考，\
        不构成医疗诊断或诊疗建议。如持续不适或出现胸痛、胸闷、\
        呼吸困难等症状，请及时就医。
        """

    /// Context-specific variants
    static func forECG() -> String {
        "心电解读基于设备采集数据，仅供参考。如有不适，请及时咨询专业医生。"
    }

    static func forAnomaly() -> String {
        "异常检测结果基于个人基线对比，不代表确诊。如有疑虑，建议复查确认。"
    }

    static func forRecovery() -> String {
        "恢复评估基于近期训练与睡眠数据，属于趋势参考。如有持续疲劳，建议咨询医生。"
    }
}

// ============================================================
// Escalation Thresholds
// ============================================================

struct EscalationThreshold {
    /// Heart rate (bpm) above which ELEVATED is triggered
    static let hrElevated: Double = 120.0
    /// Heart rate (bpm) above which CRITICAL is triggered
    static let hrCritical: Double = 150.0
    /// HRV (ms) below which ELEVATED is triggered
    static let hrvElevated: Double = 25.0
    /// Resting HR (bpm) sustained above threshold days
    static let rhrSustainedDays: Int = 4

    /// Check if a metric reading should trigger safety escalation
    static func evaluateMetric(_ metricId: String, value: Double, userBaseline: Double?) -> SafetyLevel {
        switch metricId {
        case "heart_rate":
            if value >= hrCritical { return .critical }
            if value >= hrElevated { return .elevated }
            if let baseline = userBaseline, value > baseline * 1.3 {
                return .monitoring
            }
        case "resting_heart_rate":
            if let baseline = userBaseline, value > baseline * 1.15 {
                return .elevated
            }
        case "heart_rate_variability":
            if value < 20 { return .elevated }
            if let baseline = userBaseline, value < baseline * 0.6 {
                return .elevated
            }
        case "blood_oxygen":
            if value < 90 { return .critical }
            if value < 94 { return .elevated }
        default:
            break
        }
        return .info
    }
}

// ============================================================
// Actionable Check Result (used after safety evaluation)
// ============================================================

struct SafetyCheckResult {
    let safetyLevel: SafetyLevel
    let displayStrategy: DisplayStrategy
    let requiresDisclaimer: Bool
    let canBeHidden: Bool
    let escalationRequired: Bool
    let disclaimer: String?

    init(safetyLevel: SafetyLevel, isAnxietyProne: Bool, metricId: String? = nil) {
        self.safetyLevel = safetyLevel
        self.displayStrategy = SafetyPolicy.displayStrategy(for: safetyLevel, isAnxietyProne: isAnxietyProne)
        self.requiresDisclaimer = safetyLevel.disclaimerRequired
        self.canBeHidden = SafetyPolicy.canBeHidden(safetyLevel)
        self.escalationRequired = safetyLevel.requiresEscalation
        self.disclaimer = requiresDisclaimer ? Self.chooseDisclaimer(metricId: metricId) : nil
    }

    private static func chooseDisclaimer(metricId: String?) -> String {
        guard let metricId = metricId else { return NonDiagnosticDisclaimer.standard }
        switch metricId {
        case "ecg": return NonDiagnosticDisclaimer.forECG()
        case "anomaly": return NonDiagnosticDisclaimer.forAnomaly()
        case "recovery": return NonDiagnosticDisclaimer.forRecovery()
        default: return NonDiagnosticDisclaimer.standard
        }
    }
}