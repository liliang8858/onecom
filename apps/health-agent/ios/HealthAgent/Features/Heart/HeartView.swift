import SwiftUI

struct HeartView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HASpacing.section) {
                Text("心脏")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(HAColor.primaryText)
                    .padding(.top, 16)

                NavigationLink(destination: ECGDetailView(episode: MockAgentClient.shared.latestECG)) {
                    ECGEpisodeCard(episode: MockAgentClient.shared.latestECG)
                }
                .buttonStyle(.plain)

                TrendChartBlock(title: "静息心率", subtitle: "近 7 天略高于个人基线", values: [54, 55, 55, 56, 58, 58, 59, 58], colorName: "heart")

                NavigationLink(destination: DynamicInsightPageView(schema: MockAgentClient.shared.heartSchema())) {
                    HACard {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("最近心脏状态稳定吗？")
                                    .font(.headline)
                                    .foregroundStyle(HAColor.primaryText)
                                Text("连续指标 + ECG 补充证据")
                                    .font(.subheadline)
                                    .foregroundStyle(HAColor.secondaryText)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(HAColor.secondaryText)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, HASpacing.page)
            .padding(.bottom, 28)
        }
        .background(HAColor.appBackground.ignoresSafeArea())
    }
}
