import SwiftUI

// MARK: - Update Log Entry View
// 分身页：展示系统根据反馈做了什么

struct ChangeLogEntryView: View {
    let entry: ChangeLogEntry

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconName)
                .font(.caption)
                .foregroundStyle(entryTint)
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.detail)
                    .font(.subheadline)
                    .foregroundStyle(HAColor.primaryText)

                Text(entry.timestamp, style: .date)
                    .font(.caption2)
                    .foregroundStyle(HAColor.secondaryText)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }

    private var iconName: String {
        switch entry.action {
        case .confirmed, .feedbackApplied: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .autoAdjusted: return "gearshape.fill"
        case .deprecated: return "trash.fill"
        case .created: return "plus.circle.fill"
        }
    }

    private var entryTint: Color {
        switch entry.action {
        case .confirmed, .feedbackApplied, .autoAdjusted: return HAColor.primaryGreen
        case .rejected, .deprecated: return HAColor.border
        case .created: return HAColor.workoutAmber
        }
    }
}

struct ChangeLogEntryView_Previews: PreviewProvider {
    static var previews: some View {
        ChangeLogEntryView(entry: ChangeLogEntry(
            id: "cl-1",
            timestamp: Date().addingTimeInterval(-3600),
            action: .feedbackApplied,
            detail: "健康解释已改为简洁模式"
        ))
    }
}