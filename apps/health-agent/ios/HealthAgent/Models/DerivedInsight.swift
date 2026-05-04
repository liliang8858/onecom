import Foundation

struct DerivedInsight: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let summary: String
    let severity: String
    let relatedMetrics: [String]
}

struct InsightQuestion: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let category: String
    let priority: Double
    let isECGEnhanced: Bool
    let screenID: String
}
