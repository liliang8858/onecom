import SwiftUI

// MARK: - Confirm Card (请求确认记忆准确性)

struct ConfirmCard: View {
    let memory: MemoryRecord
    let onConfirm: (MemoryVerdict) -> Void

    var body: some View {
        HACard(padding: 14, background: HAColor.primaryGreen.opacity(0.06)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(HAColor.workoutAmber)

                    Text("我发现了一个可能与你有关的模式")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(HAColor.primaryText)
                }

                Text(memory.patternDescription)
                    .font(.body)
                    .foregroundStyle(HAColor.primaryText)

                HStack {
                    ConfidenceBadge(confidence: memory.confidenceScore)
                    Spacer()
                    Text("数据来源：\(memory.evidenceSummary)")
                        .font(.footnote)
                        .foregroundStyle(HAColor.secondaryText)
                }

                Divider()

                HStack(spacing: 10) {
                    Button(action: { onConfirm(.accurate) }) {
                        Label("准确 ✓", systemImage: "checkmark.circle.fill")
                            .font(.caption2.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(HAColor.primaryGreen)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }

                    Button(action: { onConfirm(.inaccurate) }) {
                        Label("不准确", systemImage: "xmark.circle.fill")
                            .font(.caption2.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(HAColor.border.opacity(0.3))
                            .foregroundStyle(HAColor.secondaryText)
                            .clipShape(Capsule())
                    }

                    Button(action: { onConfirm(.deferLater) }) {
                        Label("先记着", systemImage: "clock")
                            .font(.caption2.weight(.semibold))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(HAColor.border.opacity(0.2))
                            .foregroundStyle(HAColor.secondaryText)
                            .clipShape(Capsule())
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
}

struct ConfirmCard_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmCard(memory: MemoryRecord(
            id: "confirm-1",
            type: .correlation,
            patternDescription: "睡眠少于 6.5 小时时，次日 HRV 通常下降 15-20%。数据来源：过去 14 天。置信度 72%。",
            evidenceSummary: "过去 14 天；Apple Health",
            affectedMetrics: ["sleep_duration", "hrv"],
            confidenceScore: 0.72,
            observationCount: 10,
            firstObservedAt: Date().addingTimeInterval(-604800),
            lastSeenAt: Date(),
            status: .candidate,
            userFeedback: nil,
            changeLog: [],
            relatedAnomalies: []
        ), onConfirm: { _ in })
        .padding()
        .previewLayout(.sizeThatFits)
    }
}