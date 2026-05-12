import SwiftUI

// MARK: - Action Plan Card (PRD v3.0 §4.3)
// 最多 3 个行动，必须具体到时间、方式、难度

struct ActionPlanCard: View {
    let actions: [HealthAction]
    @State private var completedIds: Set<String> = []
    @State private var feedbackMap: [String: FeedbackCategory?] = [:]

    var body: some View {
        HACard(padding: 14) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundStyle(HAColor.primaryGreen)
                    Text("今日行动")
                        .font(.headline)
                    Spacer()
                    Text("\(actions.count) 项")
                        .font(.caption)
                        .foregroundStyle(HAColor.secondaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(HAColor.primaryGreen.opacity(0.1))
                        .clipShape(Capsule())
                }

                ForEach(actions.prefix(3)) { action in
                    ActionRow(
                        action: action,
                        isCompleted: completedIds.contains(action.id),
                        feedback: feedbackMap[action.id]
                    ) { feedback in
                        handleFeedback(actionId: action.id, feedback: feedback)
                    } onComplete: {
                        completedIds.insert(action.id)
                    }
                }

                if actions.count > 3 {
                    Text("还有 \(actions.count - 3) 项建议…")
                        .font(.caption2)
                        .foregroundStyle(HAColor.secondaryText)
                }
            }
        }
    }

    private func handleFeedback(actionId: String, feedback: FeedbackCategory?) {
        feedbackMap[actionId] = feedback

        // 同步到反馈引擎
        let submission = FeedbackSubmission(
            blockId: "action-\(actionId)",
            category: feedback ?? .actionCompleted,
            screenId: "today",
            metadata: ["actionId": actionId]
        )
        Task {
            let _ = await FeedbackEngineStub().submitFeedback(submission)
        }
    }
}

private struct ActionRow: View {
    let action: HealthAction
    let isCompleted: Bool
    let feedback: FeedbackCategory?
    let onFeedback: (FeedbackCategory?) -> Void
    let onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                // Completion toggle
                Button(action: { onComplete() }) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isCompleted ? HAColor.primaryGreen : HAColor.border)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text(action.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isCompleted ? HAColor.secondaryText : HAColor.primaryText)
                        .strikethrough(isCompleted)

                    Text(action.reason)
                        .font(.caption)
                        .foregroundStyle(HAColor.secondaryText)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        difficultyBadge
                        if let duration = action.estimatedDuration {
                            Text("\(Int(duration / 60)) 分钟")
                                .font(.caption2)
                                .foregroundStyle(HAColor.secondaryText)
                        }
                        if let meta = action.meta, let rate = meta.completionRate {
                            Text("完成率 \(Int(rate * 100))%")
                                .font(.caption2)
                                .foregroundStyle(rate > 0.5 ? HAColor.primaryGreen : HAColor.workoutAmber)
                        }
                    }
                }

                Spacer()

                // Feedback buttons
                if !isCompleted {
                    Menu {
                        Button("太难了") { onFeedback(.actionTooHard) }
                        Button("不适合今天") { onFeedback(.actionNotSuitable) }
                        Button("换一个") { onFeedback(.actionReplace) }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(HAColor.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Feedback indicator
            if let fb = feedback {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                    Text(fb == .actionTooHard ? "已标记为太难 → 将推荐更简单行动" :
                         fb == .actionNotSuitable ? "已记录你的偏好" :
                         "已换行动")
                        .font(.caption2)
                        .foregroundStyle(HAColor.secondaryText)
                }
                .padding(.leading, 24)
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 6)
    }

    private var difficultyBadge: some View {
        let diff = action.difficulty
        return Text(diff == .easy ? "简单" : diff == .moderate ? "适中" : "困难")
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(diff == .easy ? HAColor.primaryGreen.opacity(0.12) :
                        diff == .moderate ? HAColor.workoutAmber.opacity(0.12) :
                        HAColor.alertRed.opacity(0.12))
            .foregroundStyle(diff == .easy ? HAColor.primaryGreen :
                              diff == .moderate ? HAColor.workoutAmber :
                              HAColor.alertRed)
            .clipShape(Capsule())
    }
}

struct ActionPlanCard_Previews: PreviewProvider {
    static var previews: some View {
        ActionPlanCard(actions: [
            HealthAction(
                id: "walk-1",
                title: "午后散步 10 分钟",
                detail: "轻度有氧，有助于下午精力恢复",
                reason: "你过去这类行动完成率较高 (68%)，且有助于下午能量恢复",
                difficulty: .easy,
                estimatedDuration: 600,
                suggestedTime: Date(),
                meta: HealthActionMeta(completionRate: 0.68, lastCompletedAt: nil, streak: 3, relatedMetrics: ["active_energy"])
            ),
            HealthAction(
                id: "sleep-1",
                title: "22:40 开始睡前放松",
                detail: "远离屏幕，进行深呼吸练习",
                reason: "你睡眠少于 6.5 小时后，次日 HRV 更容易下降",
                difficulty: .easy,
                estimatedDuration: 600,
                suggestedTime: nil,
                meta: nil
            )
        ])
        .padding()
        .previewLayout(.sizeThatFits)
    }
}