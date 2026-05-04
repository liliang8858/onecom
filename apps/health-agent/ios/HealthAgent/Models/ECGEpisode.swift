import Foundation

struct ECGEpisode: Identifiable, Codable, Hashable {
    let id: String
    let recordedAt: String
    let quality: String
    let rhythmSummary: String
    let averageHeartRate: String
    let classification: String
    let note: String
}
