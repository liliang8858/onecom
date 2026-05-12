import SwiftUI

// MARK: - Why This Card (PRD v3.0 §10)
// 解释"为什么给用户看这个" — 每个重要 block 下方

struct WhyThisCard: View {
    let reason: String
    let detail: String?
    let onExpand: (() -> Void)?

    init(reason: String, detail: String? = nil, onExpand: (() -> Void)? = nil) {
        self.reason = reason
        self.detail = detail
        self.onExpand = onExpand
    }

    @State private var expanded = false

    var body: some View {
        HACard(padding: 12, background: HAColor.cardBackground.opacity(0.6)) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundStyle(HAColor.secondaryText.opacity(0.7))
                    .frame(width: 16, height: 16)

                VStack(alignment: .leading, spacing: 4) {
                    Text("为什么给你看这个")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(HAColor.secondaryText)

                    Text(reason)
                        .font(.subheadline)
                        .foregroundStyle(HAColor.primaryText)
                        .lineLimit(expanded ? nil : 2)

                    if let detail = detail, expanded {
                        Text(detail)
                            .font(.footnote)
                            .foregroundStyle(HAColor.secondaryText)
                            .padding(.top, 4)
                    }
                }

                Spacer()

                if onExpand != nil {
                    Button(action: {
                        expanded.toggle()
                        onExpand?()
                    }) {
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(HAColor.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct WhyThisCard_Previews: PreviewProvider {
    static var previews: some View {
        WhyThisCard(
            reason: "过去 7 天睡眠减少与运动负荷上升同步出现",
            detail: "该判断基于你过去 21 天的睡眠和运动数据，相关系数 0.68。",
            onExpand: {}
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}