import Foundation

protocol HealthDataStore {
    func fetchDailySnapshot() async -> DailyHealthSnapshot
    func fetchMetricSeries(metricID: String, range: HealthTimeRange) async -> [HealthMetricSample]
    func fetchLatestECG() async -> ECGEpisode?
}

enum HealthTimeRange: String, Codable, Hashable {
    case day = "1d"
    case week = "7d"
    case month = "30d"
    case quarter = "90d"
}

struct HealthMetricSample: Identifiable, Codable, Hashable {
    let id: String
    let dateLabel: String
    let value: Double
}

struct DailyHealthSnapshot: Codable, Hashable {
    let recoveryScore: Int
    let sleepDuration: String
    let restingHeartRate: String
    let hrv: String
    let workoutLoad: String
    let summary: String

    static let mock = DailyHealthSnapshot(
        recoveryScore: 62,
        sleepDuration: "6h12m",
        restingHeartRate: "58 bpm",
        hrv: "32 ms",
        workoutLoad: "偏高",
        summary: "睡眠减少、HRV 下降，同时运动负荷上升。"
    )
}
