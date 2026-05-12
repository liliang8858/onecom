import SwiftUI

// MARK: - Cold Start Banner (PRD v3.0 §5)
// Day 1-7 诚实说明 + 即时个性化

struct ColdStartBanner: View {
    let dayIndex: Int  // 0-based
    @Binding var focusSelections: [HealthDomain]

    @State private var showBanner = true

    var body: some View {
        Group {
            if shouldShowBanner, showBanner {
                HACard(padding: 14, background: HAColor.cardBackground) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lightbulb")
                                .font(.callout)
                                .foregroundStyle(HAColor.primaryGreen)

                            Text("我还在了解你")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(HAColor.primaryText)
                        }

                        Text(bannerMessage)
                            .font(.body)
                            .foregroundStyle(HAColor.secondaryText)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(3)

                        if dayIndex == 0, focusSelections.isEmpty {
                            Text("请先选择你的关注方向")
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(HAColor.primaryGreen)
                        }

                        Button("知道了") {
                            withAnimation { showBanner = false }
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(HAColor.primaryGreen)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Day 2-7 gentle reminder
            if dayIndex > 0 && dayIndex <= 6 && !focusSelections.isEmpty && showBanner && !hasEnoughData {
                HACard(padding: 12, background: HAColor.primaryGreen.opacity(0.06)) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(HAColor.primaryGreen)
                        Text("再给我几天数据，就能为你提供更个性化的建议")
                            .font(.caption)
                            .foregroundStyle(HAColor.secondaryText)
                        Spacer()
                        Button("知道了") {
                            showBanner = false
                        }
                        .font(.caption2)
                        .foregroundStyle(HAColor.primaryGreen)
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Derived Properties

    private var hasEnoughData: Bool { false /* 由 HealthContextBuilder 判断 */ }

    private var shouldShowBanner: Bool {
        dayIndex <= 6  // Day 1-7
    }

    private var bannerMessage: String {
        switch dayIndex {
        case 0:
            if focusSelections.isEmpty {
                return "请先选择你最关注的健康方向，我会为你生成个性化的今日健康摘要。你的选择越明确，推荐越精准。"
            }
            return "好的，我已记录你的健康关注方向。接下来几天的数据将帮助我建立你的个人基线，现在展示的内容基于通用健康规律。"
        case 1...3:
            return "感谢你的使用！我正在根据你的健康数据建立个人基线。现在展示的洞察基于通用规律，几天后会更贴合你的实际情况。"
        case 4...6:
            return "数据越来越丰富了！你的个人基线正在建立中，很快就能看到更贴合你的健康洞察。"
        default:
            return ""
        }
    }
}

struct ColdStartBanner_Previews: PreviewProvider {
    static var previews: some View {
        ColdStartBanner(dayIndex: 0, focusSelections: .constant([]))
            .padding()
            .previewLayout(.sizeThatFits)

        ColdStartBanner(dayIndex: 3, focusSelections: .constant([.sleep, .recovery]))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}