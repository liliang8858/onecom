import SwiftUI

// MARK: - Today View (Updated for PRD v3.0)
// Today Health Home — integrates PersonalizationBadge, AgencyToggle, ColdStartBanner, FeedbackBar

struct TodayView: View {
    @StateObject private var viewModel = TodayViewModel()
    @State private var agencyMode: AgencyMode = .agentGuided
    @State private var focusSelections: [HealthDomain] = []

    private let agent = MockAgentClient.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HASpacing.section) {
                // === Header ===
                header
                    .padding(.horizontal, HASpacing.page)
                    .padding(.top, 12)

                // === Cold Start Banner (Day 1-7) ===
                if viewModel.showColdStartBanner {
                    ColdStartBanner(
                        dayIndex: viewModel.coldStartDayIndex,
                        focusSelections: $focusSelections
                    )
                    .padding(.horizontal, HASpacing.page)
                }

                // === Hero Card ===
                TodayHealthHeroCard()
                    .padding(.horizontal, HASpacing.page)
                    .padding(.top: viewModel.showColdStartBanner ? 8 : 0)

                // === Personalization Badge ===
                PersonalizationBadge(
                    reason: viewModel.personalizationReason,
                    icon: "sparkles"
                )
                .padding(.horizontal, HASpacing.page)
                .padding(.top, 4)

                // === Agency Toggle ===
                AgencyToggle(mode: $agencyMode)
                    .padding(.horizontal, HASpacing.page)
                    .padding(.top, viewModel.showColdStartBanner ? 8 : 4)

                // === Today Modules (代理/探索模式) ===
                Group {
                    if agencyMode == .agentGuided {
                        guidedModules
                    } else {
                        exploreModules
                    }
                }
                .padding(.horizontal, HASpacing.page)

                // === Agent Discovery ===
                agentDiscovery
                    .padding(.horizontal, HASpacing.page)

                // === Continue Explore with WhyThisCard ===
                continueExplore
                    .padding(.horizontal, HASpacing.page)

                // === Today Action Plan ===
                if agencyMode == .agentGuided {
                    ActionPlanCard(actions: [
                        HealthAction(
                            id: "walk-1",
                            title: "午后散步 10 分钟",
                            detail: "轻度有氧，有助于下午精力恢复",
                            reason: "你过去这类行动完成率较高，且有助于下午能量恢复",
                            difficulty: .easy,
                            estimatedDuration: 600,
                            suggestedTime: nil,
                            meta: nil
                        ),
                        HealthAction(
                            id: "sleep-1",
                            title: "晚上 22:40 开始睡前放松",
                            detail: "远离屏幕，进行深呼吸练习",
                            reason: "你睡眠少于 6.5 小时后，次日 HRV 更容易下降",
                            difficulty: .easy,
                            estimatedDuration: 600,
                            suggestedTime: nil,
                            meta: nil
                        )
                    ])
                    .padding(.horizontal, HASpacing.page)
                }

                // === Health Input Prompt ===
                healthInput
                    .padding(.horizontal, HASpacing.page)
                    .padding(.bottom, 28)
            }
        }
        .background(HAColor.appBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("今日")
    }

    // MARK: - Computed Properties (delegated to ViewModel)

    private var personalizationReason: String { viewModel.personalizationReason }
    private var todayDateString: String { viewModel.todayDateString }

    // MARK: - Subviews

    @ViewBuilder
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("今日")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(HAColor.primaryText)
                Text(todayDateString)
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

    // 代理模式：简洁结论 + 行动
    @ViewBuilder
    private var guidedModules: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "今日要点")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(agent.todayMetrics.prefix(2)) { metric in
                    HACard(padding: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(metric.label)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(HAColor.secondaryText)
                            Text(metric.value)
                                .font(.title.weight(.bold))
                                .foregroundStyle(HAColor.primaryText)
                            Text(metric.detail)
                                .font(.caption)
                                .foregroundStyle(HAColor.secondaryText)
                        }
                    }
                }
            }
        }
    }

    // 探索模式：更多数据 + 图表
    @ViewBuilder
    private var exploreModules: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "数据总览")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(agent.todayMetrics) { metric in
                    HACard(padding: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(metric.label)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(HAColor.secondaryText)
                            Text(metric.value)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(HAColor.primaryText)
                            Text(metric.detail)
                                .font(.caption)
                                .foregroundStyle(HAColor.secondaryText)
                            LineChart(values: [2, 4, 3, 5, 4, 6, 5], color: metric.color)
                                .frame(height: 36)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var agentDiscovery: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Agent 发现", actionTitle: "查看全部")
            discoveryRow(
                icon: "bed.double.fill",
                title: "睡眠减少",
                body: "昨晚睡眠比平时少 1 小时 12 分钟，深睡和 REM 占比偏低。",
                color: HAColor.sleepPurple
            )
            Divider()
            discoveryRow(
                icon: "figure.run",
                title: "运动负荷上升",
                body: "过去 7 天运动负荷比上周上升 32%，建议关注恢复与放松。",
                color: HAColor.workoutAmber
            )
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

    @ViewBuilder
    private var continueExplore: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "继续探索")
            WhyThisCard(
                reason: "推荐此项的原因：你过去 7 天睡眠不足与该指标下降高度相关。",
                detail: "该判断基于你过去 21 天的睡眠和运动数据，相关系数 0.68。",
                onExpand: {}
            )
            .padding(.vertical, 4)
            VStack(spacing: 12) {
                ForEach(agent.insightQuestions) { question in
                    InsightButtonCard(question: question)
                }
            }
        }
    }

    @ViewBuilder
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

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 · EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: Date()) + " · Apple Health 已同步"
    }
}

// MARK: - Compact Action Card for Guided Mode

private struct ActionCardCompact: View {
    let action: HealthAction

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(HAColor.primaryGreen)
                Text(action.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HAColor.primaryText)
            }
            Text(action.reason)
                .font(.caption2)
                .foregroundStyle(HAColor.secondaryText)
                .lineLimit(2)
        }
        .padding(10)
        .background(HAColor.primaryGreen.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct TodayView_Previews: PreviewProvider {
    static var previews: some View {
        TodayView()
    }
}