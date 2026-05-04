import Foundation

final class MockHealthDataStore: HealthDataStore {
    func fetchDailySnapshot() async -> DailyHealthSnapshot {
        .mock
    }

    func fetchMetricSeries(metricID: String, range: HealthTimeRange) async -> [HealthMetricSample] {
        let values: [Double]
        switch metricID {
        case "sleep_duration":
            values = [7.2, 7.0, 6.8, 7.4, 6.4, 6.1, 6.2, 6.0, 5.8, 6.3, 6.1]
        case "resting_heart_rate":
            values = [54, 55, 55, 56, 58, 58, 59, 58, 57, 58, 59]
        default:
            values = [58, 61, 59, 55, 52, 49, 47, 46, 44, 43, 41, 39]
        }

        return values.enumerated().map { index, value in
            HealthMetricSample(id: "\(metricID)-\(index)", dateLabel: "D-\(values.count - index)", value: value)
        }
    }

    func fetchLatestECG() async -> ECGEpisode? {
        MockAgentClient.shared.latestECG
    }
}
