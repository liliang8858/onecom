import SwiftUI

struct HealthBlockRenderer: View {
    let block: HealthUIBlock

    var body: some View {
        switch block {
        case .insightSummary(let config):
            HACard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label(config.title, systemImage: config.tone == "attention" ? "sparkles" : "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(config.tone == "attention" ? HAColor.workoutAmber : HAColor.primaryGreen)
                        Spacer()
                        ConfidenceBadge(text: "非诊断")
                    }
                    Text(config.summary)
                        .font(.body)
                        .foregroundStyle(HAColor.secondaryText)
                        .lineSpacing(5)
                }
            }

        case .metricDeltaGrid(let config):
            MetricDeltaGrid(metrics: config.metrics)

        case .trendChart(let config):
            TrendChartBlock(title: config.title, subtitle: config.subtitle, values: config.values, colorName: config.colorName)

        case .multiMetricTimeline(let config):
            MultiMetricTimeline(title: config.title, rows: config.rows)

        case .anomalyList(let config):
            AnomalyListBlock(anomalies: config.anomalies)

        case .suggestedQuestions(let config):
            SuggestedQuestionBar(questions: config.questions)

        case .ecgEpisode(let config):
            ECGEpisodeCard(episode: config.episode)

        case .dataSource(let config):
            Text(config.text)
                .font(.footnote)
                .foregroundStyle(HAColor.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
        }
    }
}

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
