import Foundation

struct UserPreference: Codable, Hashable {
    let defaultDensity: String
    let preferredChartRange: String
    let sleepView: String
    let healthInsightStyle: String
    let heartView: String
    let showMedicalDisclaimer: Bool

    static let `default` = UserPreference(
        defaultDensity: "concise",
        preferredChartRange: "30d",
        sleepView: "timeline",
        healthInsightStyle: "insight_first",
        heartView: "evidence_first",
        showMedicalDisclaimer: true
    )
}
