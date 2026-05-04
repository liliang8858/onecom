import Foundation

final class HealthMetricQueryService {
    private let store: HealthDataStore

    init(store: HealthDataStore = MockHealthDataStore()) {
        self.store = store
    }

    func recoverySeries() async -> [HealthMetricSample] {
        await store.fetchMetricSeries(metricID: "heart_rate_variability", range: .month)
    }

    func sleepSeries() async -> [HealthMetricSample] {
        await store.fetchMetricSeries(metricID: "sleep_duration", range: .month)
    }

    func restingHeartRateSeries() async -> [HealthMetricSample] {
        await store.fetchMetricSeries(metricID: "resting_heart_rate", range: .month)
    }
}
