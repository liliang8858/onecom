import SwiftUI

struct ConfidenceBadge: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "checkmark.seal.fill")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(HAColor.recoveryGreen.opacity(0.14))
            .foregroundStyle(HAColor.primaryGreen)
            .clipShape(Capsule())
    }
}
