import SwiftUI

struct DynamicInsightPageView: View {
    let schema: HealthPageSchema

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HASpacing.section) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(schema.timeRange)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(HAColor.primaryGreen)
                    Text(schema.title)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(HAColor.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, HASpacing.page)
                .padding(.top, 16)

                VStack(spacing: 16) {
                    ForEach(schema.blocks) { block in
                        HealthBlockRenderer(block: block)
                    }
                }
                .padding(.horizontal, HASpacing.page)
                .padding(.bottom, 28)
            }
        }
        .background(HAColor.appBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}
