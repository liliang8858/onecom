import SwiftUI

// MARK: - Personalization Badge (PRD v3.0 §11)
// 告知页面已按用户关注点编排

struct PersonalizationBadge: View {
    let reason: String?
    let icon: String

    init(reason: String? = nil, icon: String = "sparkles") {
        self.reason = reason
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            if let reason = reason {
                Text(reason)
                    .font(.caption2)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(HAColor.primaryGreen)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(HAColor.primaryGreen.opacity(0.10))
        .clipShape(Capsule())
    }
}

struct PersonalizationBadge_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 16) {
            PersonalizationBadge(reason: "根据你的睡眠关注生成")
                .padding()

            PersonalizationBadge(icon: "heart.fill")
                .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}