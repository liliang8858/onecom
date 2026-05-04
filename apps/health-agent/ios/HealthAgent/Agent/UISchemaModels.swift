import Foundation

struct HealthPageSchema: Identifiable, Codable {
    var id: String { screenID }
    let schemaVersion: String
    let screenID: String
    let title: String
    let timeRange: String
    let style: String
    let safetyLevel: String
    let blocks: [HealthUIBlock]
}

enum HealthUIBlock: Identifiable, Codable {
    case insightSummary(InsightSummaryConfig)
    case metricDeltaGrid(MetricDeltaGridConfig)
    case trendChart(TrendChartConfig)
    case multiMetricTimeline(MultiMetricTimelineConfig)
    case anomalyList(AnomalyListConfig)
    case suggestedQuestions(SuggestedQuestionsConfig)
    case ecgEpisode(ECGEpisodeConfig)
    case dataSource(DataSourceConfig)

    var id: String {
        switch self {
        case .insightSummary(let config): return config.id
        case .metricDeltaGrid(let config): return config.id
        case .trendChart(let config): return config.id
        case .multiMetricTimeline(let config): return config.id
        case .anomalyList(let config): return config.id
        case .suggestedQuestions(let config): return config.id
        case .ecgEpisode(let config): return config.id
        case .dataSource(let config): return config.id
        }
    }
}

struct InsightSummaryConfig: Codable {
    let id: String
    let title: String
    let summary: String
    let tone: String
}

struct MetricDeltaGridConfig: Codable {
    let id: String
    let metrics: [HealthMetric]
}

struct TrendChartConfig: Codable {
    let id: String
    let title: String
    let subtitle: String
    let values: [Double]
    let colorName: String
}

struct MultiMetricTimelineConfig: Codable {
    let id: String
    let title: String
    let rows: [TimelineRow]
}

struct TimelineRow: Identifiable, Codable, Hashable {
    let id: String
    let day: String
    let primary: String
    let secondary: String
    let status: MetricStatus
}

struct AnomalyListConfig: Codable {
    let id: String
    let anomalies: [DerivedInsight]
}

struct SuggestedQuestionsConfig: Codable {
    let id: String
    let questions: [String]
}

struct ECGEpisodeConfig: Codable {
    let id: String
    let episode: ECGEpisode
}

struct DataSourceConfig: Codable {
    let id: String
    let text: String
}
