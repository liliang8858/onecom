import Foundation

// MARK: - Safety Level (PRD v3.0 §13.1)

enum SafetyLevel: String, Codable, Comparable {
    case info          // 参考信息，无风险
    case advisory      // 生活方式建议
    case monitoring    // 需关注，建议复查
    case elevated      // 明显异常，建议咨询医生
    case critical      // 立即就医

    static func < (lhs: SafetyLevel, rhs: SafetyLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    var requiresEscalation: Bool {
        switch self {
        case .elevated, .critical: return true
        default: return false
        }
    }

    /// 非诊断声明（需要时附加）
    var disclaimerRequired: Bool {
        switch self {
        case .advisory, .monitoring, .elevated, .critical: return true
        default: return false
        }
    }
}