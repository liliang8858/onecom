import SwiftUI

// MARK: - Learning Card (PRD v3.0 §4.4)
// 展示正在观察的模式

struct LearningCard: View {
    let memory: MemoryRecord

    var body: some View {
        HACard(padding: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "hourglass")
                    .font(.headline)
                    .foregroundStyle(HAColor.workoutAmber)
                    .frame(width: 28, height: 28)
                    .background(HAColor.workoutAmber.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("正在观察")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(HAColor.workoutAmber)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(HAColor.workoutAmber.opacity(0.12))
                            .clipShape(Capsule())

                        Spacer()

                        Text("已观察 \(memory.observationCount) 次")
                            .font(.caption2)
                            .foregroundStyle(HAColor.secondaryText)
                    }

                    Text(memory.patternDescription)
                        .font(.subheadline)
                        .foregroundStyle(HAColor.primaryText)
                        .lineLimit(3)

                    if let reason = memory.whyShownReason {
                        Text(reason)
                            .font(.footnote)
                            .foregroundStyle(HAColor.secondaryText)
                            .lineLimit(2)
                    }

                    HStack {
                        ProgressView(value: Float(min(memory.observationCount, 7)) / 7.0)
                            .tint(HAColor.workoutAmber)
                            .frame(height: 4)

                        Text("\(min(memory.observationCount, 7))/7")
                            .font(.caption2)
                            .foregroundStyle(HAColor.secondaryText)
                    }
                }
            }
        }
    }
}

struct LearningCard_Previews: PreviewProvider {
    static var previews: some View {
        LearningCard(memory: MemoryRecord(
            id: "learning-1",
            type: .correlation,
            patternDescription: "睡眠少于 6.5 小时后，次日静息心率可能偏高。",
            evidenceSummary: "过去 21 天中 14 天符合该模式",
            affectedMetrics: ["sleep_duration", "resting_heart_rate"],
            confidenceScore: 0.72,
            observationCount: 14,
            firstObservedAt: Date().addingTimeInterval(-604800),
            lastSeenAt: Date().addingTimeInterval(-86400),
            status: .observing,
            userFeedback: nil,
            changeLog: [],
            relatedAnomalies: []
        ))
        .padding()
        .previewLayout(.sizeThatFits)
    }
}