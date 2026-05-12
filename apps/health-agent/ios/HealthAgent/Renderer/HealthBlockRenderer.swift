import SwiftUI

// MARK: - Health Block Renderer (PRD v3.0 §10)
// 渲染 UISchema.blocks 中的所有 block 类型

struct HealthBlockRenderer: View {
    let block: UIBlock
    @Binding var agencyMode: AgencyMode
    @Binding var feedbackEnabled: Bool

    var body: some View {
        switch block.type {
        case .insightSummary:
            if let cfg = decodeConfig(block, as: InsightSummaryConfig.self) {
                renderInsightSummary(cfg)
            }
        case .metricDeltaGrid:
            if let cfg = decodeConfig(block, as: MetricDeltaGridConfig.self) {
                MetricDeltaGrid(metrics: cfg.metrics)
            }
        case .trendChart:
            if let cfg = decodeConfig(block, as: TrendChartConfig.self) {
                TrendChartBlock(title: cfg.title, subtitle: cfg.subtitle, values: cfg.values, colorName: cfg.colorName)
            }
        case .multiMetricTimeline:
            if let cfg = decodeConfig(block, as: MultiMetricTimelineConfig.self) {
                MultiMetricTimeline(title: cfg.title, rows: cfg.rows)
            }
        case .anomalyList:
            if let cfg = decodeConfig(block, as: AnomalyListConfig.self) {
                AnomalyListBlock(anomalies: cfg.anomalies)
            }
        case .suggestedQuestions:
            if let cfg = decodeConfig(block, as: SuggestedQuestionsConfig.self) {
                SuggestedQuestionBar(questions: cfg.questions)
            }
        case .ecgEpisodeCard:
            if let cfg = decodeConfig(block, as: ECGEpisodeConfig.self) {
                ECGEpisodeCard(episode: cfg.episode)
            }
        case .ecgWaveform:
            if let cfg = decodeConfig(block, as: ECGWaveformConfig.self) {
                ECGWaveformView(cfg: cfg)
            }
        case .ecgQuality:
            if let cfg = decodeConfig(block, as: ECGQualityConfig.self) {
                ECGQualityCard(cfg: cfg)
            }
        case .rrIntervalChart:
            if let cfg = decodeConfig(block, as: ECGWaveformConfig.self) {
                RRIntervalChartView(cfg: cfg)
            }
        case .ecgContextTimeline:
            if let cfg = decodeConfig(block, as: ECGWaveformConfig.self) {
                ECGContextTimelineView(cfg: cfg)
            }
        case .actionPlanCard:
            if let cfg = decodeConfig(block, as: ActionPlanConfig.self) {
                ActionPlanCard(actions: cfg.actions)
            }
        case .progressTracker:
            if let cfg = decodeConfig(block, as: ProgressTrackerConfig.self) {
                ProgressTrackerView(cfg: cfg)
            }
        case .feedbackBar:
            if let cfg = decodeConfig(block, as: FeedbackBarConfig.self) {
                FeedbackBar(
                    blockId: block.blockId,
                    screenId: "dynamic",
                    enabledFeedbackTypes: FeedbackCategory.allCases
                ) { _ in }
            }
        case .whyShownReason:
            if let cfg = decodeConfig(block, as: WhyShownReasonConfig.self) {
                WhyThisCard(reason: cfg.reason)
            }
        case .separatorSpacer:
            Divider().padding(.vertical, 8)
        }
    }

    // MARK: - WhyThisCard wrapper

    private func renderInsightSummary(_ config: InsightSummaryConfig) -> some View {
        HACard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(config.title, systemImage: config.tone == "attention" ? "sparkles" : "checkmark.seal.fill")
                        .font(.headline)
                        .foregroundStyle(config.tone == "attention" ? HAColor.workoutAmber : HAColor.primaryGreen)
                    Spacer()
                    ConfidenceBadge.Legacy(text: "非诊断")
                }
                Text(config.summary)
                    .font(.body)
                    .foregroundStyle(HAColor.secondaryText)
                    .lineSpacing(5)
            }
            .padding(14)
        }
    }

    // MARK: - Generic config decoder

    private func decodeConfig<T: Decodable>(_ block: UIBlock, as type: T.Type) -> T? {
        do {
            let data = try JSONSerialization.data(withJSONObject: block.dataPayload)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Failed to decode config for block \(block.blockId): \(error)")
            return nil
        }
    }
}

// MARK: - Suggested Question Bar

struct SuggestedQuestionBar: View {
    let questions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("下一步探索")
                .font(.headline)
                .foregroundStyle(HAColor.primaryText)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(questions, id: \.self) { question in
                        Text(question)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(HAColor.primaryGreen.opacity(0.10))
                            .foregroundStyle(HAColor.primaryGreen)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

struct HealthBlockRenderer_Previews: PreviewProvider {
    static var previews: some View {
        HealthBlockRenderer(
            block: .insightSummary(InsightSummaryConfig(
                id: "preview",
                title: "测试摘要",
                summary: "这是一个预览摘要内容，用于验证渲染效果。",
                tone: "attention"
            )),
            agencyMode: .constant(.agentGuided),
            feedbackEnabled: .constant(true)
        )
        .padding()
    }
}