import SwiftUI

// MARK: - Feedback Bar (PRD v3.0 §12)
// 内容反馈入口，接在所有洞察卡片下方

struct FeedbackBar: View {
    let blockId: String
    let screenId: String
    let enabledFeedbackTypes: [FeedbackCategory]
    let onSubmit: (FeedbackCategory) -> Void

    init(
        blockId: String,
        screenId: String,
        enabledFeedbackTypes: [FeedbackCategory] = [.helpful, .inaccurate, .tooComplex, .skip],
        onSubmit: @escaping (FeedbackCategory) -> Void = { _ in }
    ) {
        self.blockId = blockId
        self.screenId = screenId
        self.enabledFeedbackTypes = enabledFeedbackTypes
        self.onSubmit = onSubmit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            HStack(spacing: 8) {
                Label("反馈", systemImage: "lightbulb")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(HAColor.secondaryText)

                Spacer()

                ForEach(enabledFeedbackTypes, id: \.self) { type in
                    Button(action: { submitFeedback(type) }) {
                        Label(type.label, systemImage: type.icon)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(HAColor.border.opacity(0.2))
                            .foregroundStyle(HAColor.secondaryText)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
        }
    }

    private func submitFeedback(_ category: FeedbackCategory) {
        let submission = FeedbackSubmission(
            blockId: blockId,
            category: category,
            screenId: screenId
        )
        onSubmit(category)

        // FIXME(#12): 接入真实 FeedbackEngine
        Task {
            let _ = await FeedbackEngineStub().submitFeedback(submission)
        }
    }
}

// MARK: - Feedback Category Display Helpers

extension FeedbackCategory {
    var label: String {
        switch self {
        case .helpful: return "有帮助"
        case .inaccurate: return "不准确"
        case .tooComplex: return "太复杂"
        case .skip: return "不想看"
        case .actionCompleted: return "已完成"
        case .actionTooHard: return "太难了"
        case .actionNotSuitable: return "不适合"
        case .actionReplace: return "换一个"
        case .reminderTooMany: return "提醒太多"
        case .reminderUseful: return "提醒有用"
        }
    }

    var icon: String {
        switch self {
        case .helpful: return "hand.thumbsup"
        case .inaccurate: return "xmark.circle"
        case .tooComplex: return "textformat"
        case .skip: return "eye.slash"
        case .actionCompleted: return "checkmark.circle"
        case .actionTooHard: return "figure.walk"
        case .actionNotSuitable: return "xmark"
        case .actionReplace: return "arrow.triangle.2.circlepath"
        case .reminderTooMany: return "bell.slash"
        case .reminderUseful: return "bell.fill"
        }
    }
}

struct FeedbackBar_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackBar(blockId: "test-1", screenId: "today")
            .padding()
            .previewLayout(.sizeThatFits)
    }
}