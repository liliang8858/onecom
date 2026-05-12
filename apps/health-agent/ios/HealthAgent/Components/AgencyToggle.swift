import SwiftUI

// MARK: - Agency Toggle (PRD v3.0 §9)
// 页面级常驻切换，不放在设置页

struct AgencyToggle: View {
    @Binding var mode: AgencyMode

    var body: some View {
        HStack(spacing: 4) {
            Button(action: { mode = .agentGuided }) {
                Label("帮我总结", systemImage: mode == .agentGuided ? "checkmark.circle.fill" : "circle")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(mode == .agentGuided ? HAColor.primaryGreen : HAColor.border.opacity(0.3))
                    .foregroundStyle(mode == .agentGuided ? .white : HAColor.secondaryText)
                    .clipShape(Capsule())
            }
            Button(action: { mode = .selfExplore }) {
                Label("自己看", systemImage: mode == .selfExplore ? "checkmark.circle.fill" : "circle")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(mode == .selfExplore ? HAColor.primaryGreen : HAColor.border.opacity(0.3))
                    .foregroundStyle(mode == .selfExplore ? .white : HAColor.secondaryText)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
}

struct AgencyToggle_Previews: PreviewProvider {
    struct Wrapper: View {
        @State var mode: AgencyMode = .agentGuided
        var body: some View {
            AgencyToggle(mode: $mode)
                .padding()
        }
    }
    static var previews: some View {
        Wrapper()
    }
}