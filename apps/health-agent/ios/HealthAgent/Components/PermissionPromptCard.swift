import SwiftUI

struct PermissionPromptCard: View {
    let summary: HealthPermissionSummary

    var body: some View {
        HACard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("数据权限", systemImage: "lock.shield.fill")
                        .font(.headline)
                        .foregroundStyle(HAColor.primaryGreen)
                    Spacer()
                    Text(summary.state.rawValue)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(HAColor.primaryGreen.opacity(0.10))
                        .foregroundStyle(HAColor.primaryGreen)
                        .clipShape(Capsule())
                }

                if !summary.missing.isEmpty {
                    Text("补充授权后，可以生成更完整的恢复、心脏和 ECG 增强分析。")
                        .font(.subheadline)
                        .foregroundStyle(HAColor.secondaryText)
                }

                HStack {
                    tagGroup(title: "已授权", items: summary.granted, color: HAColor.recoveryGreen)
                    Spacer(minLength: 12)
                    tagGroup(title: "待授权", items: summary.missing, color: HAColor.workoutAmber)
                }
            }
        }
    }

    private func tagGroup(title: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(HAColor.secondaryText)
            FlowTags(items: items, color: color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FlowTags: View {
    let items: [String]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items.prefix(4), id: \.self) { item in
                Text(item)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(color.opacity(0.12))
                    .foregroundStyle(color)
                    .clipShape(Capsule())
            }
        }
    }
}
