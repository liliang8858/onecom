import SwiftUI

struct TodayView: View {
    private let agent = MockAgentClient.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HASpacing.section) {
                header
                    .padding(.horizontal, HASpacing.page)
                    .padding(.top, 12)

                TodayHealthHeroCard()
                    .padding(.horizontal, HASpacing.page)

                agentDiscovery
                    .padding(.horizontal, HASpacing.page)

                todayModules
                    .padding(.horizontal, HASpacing.page)

                continueExplore
                    .padding(.horizontal, HASpacing.page)

                healthInput
                    .padding(.horizontal, HASpacing.page)
                    .padding(.bottom, 28)
            }
        }
        .background(HAColor.appBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("今日")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(HAColor.primaryText)
                Text("5 月 18 日 · Apple Health 已同步")
                    .font(.subheadline)
                    .foregroundStyle(HAColor.secondaryText)
            }
            Spacer()
            Image(systemName: "chart.bar.fill")
                .font(.headline)
                .foregroundStyle(HAColor.primaryGreen)
                .frame(width: 44, height: 44)
                .background(HAColor.primaryGreen.opacity(0.10))
                .clipShape(Circle())
        }
    }

    private var agentDiscovery: some View {
        HACard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Agent 发现", actionTitle: "查看")
                discoveryRow(icon: "bed.double.fill", title: "睡眠减少", body: "昨晚睡眠比平时少 1 小时 12 分钟，深睡和 REM 占比偏低。", color: HAColor.sleepPurple)
                Divider()
                discoveryRow(icon: "figure.run", title: "运动负荷上升", body: "过去 7 天运动负荷比上周上升 32%，建议关注恢复与放松。", color: HAColor.workoutAmber)
            }
        }
    }

    private func discoveryRow(icon: String, title: String, body: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(color)
                .frame(width: 42, height: 42)
                .background(color.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(HAColor.primaryText)
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(HAColor.secondaryText)
                    .lineSpacing(3)
            }
        }
    }

    private var todayModules: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "今日模块")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(agent.todayMetrics) { metric in
                    HACard(padding: 14) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(metric.label)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(HAColor.secondaryText)
                            Text(metric.value)
                                .font(.title.weight(.bold))
                                .foregroundStyle(HAColor.primaryText)
                            Text(metric.detail)
                                .font(.caption)
                                .foregroundStyle(HAColor.secondaryText)
                            LineChart(values: [2, 4, 3, 5, 4, 6, 5], color: metric.color)
                                .frame(height: 42)
                        }
                    }
                }
            }
        }
    }

    private var continueExplore: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "继续探索")
            VStack(spacing: 12) {
                ForEach(agent.insightQuestions) { question in
                    InsightButtonCard(question: question)
                }
            }
        }
    }

    private var healthInput: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundStyle(HAColor.primaryGreen)
                .frame(width: 38, height: 38)
                .background(HAColor.primaryGreen.opacity(0.10))
                .clipShape(Circle())
            Text("问问你的健康数据...")
                .font(.body)
                .foregroundStyle(HAColor.secondaryText)
            Spacer()
            Image(systemName: "arrow.up")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(HAColor.primaryGreen)
                .clipShape(Circle())
        }
        .padding(12)
        .background(.white)
        .clipShape(Capsule())
        .overlay {
            Capsule().stroke(HAColor.border, lineWidth: 1)
        }
    }
}
