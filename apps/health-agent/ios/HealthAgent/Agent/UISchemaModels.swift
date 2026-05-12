import Foundation

// ==========================================================================
// MARK: - UI Schema (PRD v3.0 §10)
// ==========================================================================

// ==========================================================================
// MARK: - Block Type
// ==========================================================================

enum BlockType: String, Codable {
    case insightSummary
    case metricDeltaGrid
    case trendChart
    case multiMetricTimeline
    case anomalyList
    case suggestedQuestions
    case ecgEpisodeCard
    case ecgWaveform
    case ecgQuality
    case rrIntervalChart
    case ecgContextTimeline
    case actionPlanCard
    case progressTracker
    case feedbackBar
    case separatorSpacer
    case whyShownReason
}

// ==========================================================================
// MARK: - UIBlock Extensions
// ==========================================================================

extension UIBlock {
    /// Convenience: create a why-shown reason block
    static func whyShownReason(_ reason: String) -> UIBlock {
        UIBlock(
            blockId: UUID().uuidString,
            type: .whyShownReason,
            priority: 50,
            healthNeedScore: 0,
            experienceFitScore: 0,
            safetyLevel: .info,
            dataPayload: ["reason": AnyCodable(reason)],
            whyShownReason: reason,
            feedbackEnabled: false,
            expandable: true,
            agencyVariant: nil
        )
    }

    /// Convenience: create a feedback bar block
    static func feedbackBar(_ id: String, enabled: Bool = true, types: [String]? = nil) -> UIBlock {
        UIBlock(
            blockId: id,
            type: .feedbackBar,
            priority: 100,
            healthNeedScore: 0,
            experienceFitScore: 0.8,
            safetyLevel: .info,
            dataPayload: ["feedback_types": types.map { AnyCodable($0) } ?? AnyCodable(["helpful", "inaccurate", "too_complex", "skip"])],
            whyShownReason: nil,
            feedbackEnabled: enabled,
            expandable: false,
            agencyVariant: nil
        )
    }

    /// Convenience: create a data source footer block
    static func dataSource(_ id: String, text: String) -> UIBlock {
        UIBlock(
            blockId: id,
            type: .separatorSpacer,
            priority: 200,
            healthNeedScore: 0,
            experienceFitScore: 0,
            safetyLevel: .info,
            dataPayload: ["text": AnyCodable(text)],
            whyShownReason: nil,
            feedbackEnabled: false,
            expandable: false,
            agencyVariant: nil
        )
    }
}

// ==========================================================================
// MARK: - Block Type
// ==========================================================================

struct MetricDeltaGridConfig: Codable {
    let id: String
    let metrics: [HealthMetric]
}

struct TrendChartConfig: Codable {
    let id: String
    let title: String
    let subtitle: String?
    let values: [Double]
    let colorName: String
    let unit: String?
    let range: String?
}

struct MultiMetricTimelineConfig: Codable {
    let id: String
    let title: String?
    let rows: [TimelineRow]
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

struct ECGWaveformConfig: Codable {
    let id: String
    let voltageSamples: [Double]?
    let samplingRate: Double
    let leadType: String
}

struct ECGQualityConfig: Codable {
    let id: String
    let signalQualityScore: Double
    let noiseLevel: Double?
    let baselineWander: String?
}

struct ActionPlanConfig: Codable {
    let id: String
    let actions: [HealthAction]
    let style: String  // "compact" | "detailed"
}

struct ProgressTrackerConfig: Codable {
    let id: String
    let metric: String
    let current: Double
    let target: Double
    let unit: String
}

struct FeedbackBarConfig: Codable {
    let id: String
    let enabled: Bool
    let feedbackTypes: [String]
}

struct DataSourceConfig: Codable {
    let id: String
    let text: String
}

struct TimelineRow: Codable, Identifiable {
    let id: String
    let day: String
    let primary: String
    let secondary: String?
    let status: MetricStatus
}

struct WhyShownReasonConfig: Codable {
    let reason: String
}

// ==========================================================================
// MARK: - AnyCodable (type-erased Codable)
// ==========================================================================

struct AnyCodable: Codable {
    let value: Any

    init<T: Codable>(_ value: T) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(String.self)  { self.value = v; return }
        if let v = try? container.decode(Int.self)    { self.value = v; return }
        if let v = try? container.decode(Double.self) { self.value = v; return }
        if let v = try? container.decode(Bool.self)   { self.value = v; return }
        if let v = try? container.decode([AnyCodable].self) { self.value = v.map(\.value); return }
        if let v = try? container.decode([String: AnyCodable].self) { self.value = v.mapValues(\.value); return }
        throw DecodingError.typeMismatch(AnyCodable.self, .init(codingPath: decoder.codingPath, debugDescription: "Unknown"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as String:  try container.encode(v)
        case let v as Int:    try container.encode(v)
        case let v as Double: try container.encode(v)
        case let v as Bool:   try container.encode(v)
        default: throw EncodingError.invalidValue(value, .init(codingPath: encoder.codingPath, debugDescription: "Unsupported"))
        }
    }
}