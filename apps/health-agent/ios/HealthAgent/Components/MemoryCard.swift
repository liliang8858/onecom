import SwiftUI

// MARK: - Memory Card (已确认的记忆)

struct MemoryCard: View {
    let memory: MemoryRecord
    let onAction: (MemoryVerdict) -> Void

    var body: some View {
        HACard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("已确认模式", systemImage: "checkmark.seal.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(HAColor.primaryGreen)

                        Text(memory.patternDescription)
                            .font(.subheadline)
                            .foregroundStyle(HAColor.primaryText)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 8) {
                            ConfidenceBadge(confidence: memory.confidenceScore)
                            Text("置信度")
                                .font(.caption2)
                                .foregroundStyle(HAColor.secondaryText)
                        }
                    }
                    Spacer()

                    VStack(spacing: 4) {
                        Button(action: { onAction(.inaccurate) }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(HAColor.border)
                        }
                        .buttonStyle(.plain)

                        Button(action: { onAction(.remove) }) {
                            Image(systemName: "trash.circle.fill")
                                .font(.caption)
                                .foregroundStyle(HAColor.border)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider()

                HStack {
                    Text("证据来源：")
                        .font(.caption2)
                        .foregroundStyle(HAColor.secondaryText)
                    Text(memory.evidenceSummary)
                        .font(.footnote)
                        .foregroundStyle(HAColor.secondaryText)
                }

                HStack {
                    Text("观察次数：\(memory.observationCount) 次")
                        .font(.caption2)
                        .foregroundStyle(HAColor.secondaryText)
                    Spacer()
                    Text(memory.firstObservedAt, style: .date)
                        .font(.caption2)
                        .foregroundStyle(HAColor.secondaryText)
                }
            }
        }
    }
}

struct MemoryCard_Previews: PreviewProvider {
    static var previews: some View {
        MemoryCard(memory: MemoryRecord(
            id: "mem-1",
            type: .correlation,
            patternDescription: "睡眠少于 6.5 小时时，次日 HRV 通常下降 15-20%。",
            evidenceSummary: "过去 21 天；数据来源 Apple Health",
            affectedMetrics: ["sleep_duration", "hrv"],
            confidenceScore: 0.87,
            observationCount: 21,
            firstObservedAt: Date().addingTimeInterval(-1209600),
            lastSeenAt: Date(),
            status: .confirmed,
            userFeedback: MemoryFeedback(verdict: .accurate, givenAt: Date(), note: nil),
            changeLog: [],
            relatedAnomalies: []
        ), onAction: { _ in })
        .padding()
        .previewLayout(.sizeThatFits)
    }
}