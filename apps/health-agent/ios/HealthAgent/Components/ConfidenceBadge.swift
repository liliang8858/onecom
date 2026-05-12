import SwiftUI

// MARK: - Confidence Badge (replaces old implementation)
// ConfidenceBadge now takes a Double 0-1 instead of String

struct ConfidenceBadge: View {
    let confidence: Double  // 0.0 - 1.0
    let label: String?      // optional override

    init(confidence: Double, label: String? = nil) {
        self.confidence = confidence
        self.label = label
    }

    private var displayText: String {
        label ?? confidenceLabel
    }

    private var confidenceLabel: String {
        switch confidence {
        case 0.85...: return "高置信"
        case 0.6...: return "中置信"
        case 0.3...: return "低置信"
        default: return "待验证"
        }
    }

    private var tint: Color {
        switch confidence {
        case 0.85...: return HAColor.primaryGreen
        case 0.6...: return HAColor.workoutAmber
        default: return HAColor.alertRed
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "info.circle")
                .font(.caption2)
            Text(displayText)
                .font(.caption2.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(tint.opacity(0.12))
        .foregroundStyle(tint)
        .clipShape(Capsule())
    }
}

// Keep old initializer compatible
extension ConfidenceBadge {
    // For code that passes a String directly (legacy)
    struct Legacy: View {
        let text: String
        var body: some View {
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .font(.caption2)
                Text(text)
                    .font(.caption2.weight(.semibold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(HAColor.primaryGreen.opacity(0.12))
            .foregroundStyle(HAColor.primaryGreen)
            .clipShape(Capsule())
        }
    }
}

struct ConfidenceBadge_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 16) {
            ConfidenceBadge(confidence: 0.87)
            ConfidenceBadge(confidence: 0.62)
            ConfidenceBadge(confidence: 0.25)
        }
        .padding()
    }
}