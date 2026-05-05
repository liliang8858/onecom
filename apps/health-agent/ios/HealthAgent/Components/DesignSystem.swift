import SwiftUI

enum HAColor {
    static let appBackground = Color(red: 0.961, green: 0.976, blue: 0.957)
    static let cardBackground = Color.white.opacity(0.92)
    static let primaryText = Color(red: 0.094, green: 0.129, blue: 0.114)
    static let secondaryText = Color(red: 0.294, green: 0.353, blue: 0.322)
    static let primaryGreen = Color(red: 0.184, green: 0.490, blue: 0.408)
    static let recoveryGreen = Color(red: 0.259, green: 0.722, blue: 0.514)
    static let ecgRed = Color(red: 0.851, green: 0.373, blue: 0.349)
    static let sleepPurple = Color(red: 0.431, green: 0.482, blue: 0.851)
    static let workoutAmber = Color(red: 0.882, green: 0.639, blue: 0.239)
    static let border = Color(red: 0.866, green: 0.906, blue: 0.882)
}

enum HASpacing {
    static let page: CGFloat = 20
    static let card: CGFloat = 16
    static let section: CGFloat = 24
}

struct HACard<Content: View>: View {
    var padding: CGFloat = HASpacing.card
    var background: Color = HAColor.cardBackground
    private let content: Content

    init(
        padding: CGFloat = HASpacing.card,
        background: Color = HAColor.cardBackground,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.background = background
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(HAColor.border.opacity(0.8), lineWidth: 1)
            }
    }
}

struct SectionHeader: View {
    let title: String
    var actionTitle: String?

    var body: some View {
        HStack {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(HAColor.primaryText)
            Spacer()
            if let actionTitle {
                Text(actionTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(HAColor.primaryGreen)
            }
        }
    }
}
