import SwiftUI

struct InsightButtonCard: View {
    let question: InsightQuestion

    var body: some View {
        NavigationLink(destination: DynamicInsightPageView(schema: MockAgentClient.shared.schema(for: question.screenID))) {
            HACard(padding: 14) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.14))
                        Image(systemName: iconName)
                            .font(.headline)
                            .foregroundStyle(iconColor)
                    }
                    .frame(width: 42, height: 42)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(question.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(HAColor.primaryText)
                                .multilineTextAlignment(.leading)
                            if question.isECGEnhanced {
                                Text("ECG")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(HAColor.ecgRed.opacity(0.12))
                                    .foregroundStyle(HAColor.ecgRed)
                                    .clipShape(Capsule())
                            }
                        }
                        Text(question.subtitle)
                            .font(.caption)
                            .foregroundStyle(HAColor.secondaryText)
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(HAColor.secondaryText.opacity(0.55))
                        .padding(.top, 4)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch question.category {
        case "睡眠": return "moon.fill"
        case "心脏": return "heart.fill"
        case "异常": return "sparkles"
        default: return "leaf.fill"
        }
    }

    private var iconColor: Color {
        switch question.category {
        case "睡眠": return HAColor.sleepPurple
        case "心脏": return HAColor.ecgRed
        case "异常": return HAColor.workoutAmber
        default: return HAColor.recoveryGreen
        }
    }
}
