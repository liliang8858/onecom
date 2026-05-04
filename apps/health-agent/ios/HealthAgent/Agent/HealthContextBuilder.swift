import Foundation

struct HealthContext: Codable, Hashable {
    let snapshot: DailyHealthSnapshot
    let permissionSummary: HealthPermissionSummary
    let latestECG: ECGEpisode?
    let userPreference: UserPreference
}

final class HealthContextBuilder {
    private let store: HealthDataStore
    private let permissionManager: HealthKitPermissionManager

    init(
        store: HealthDataStore = MockHealthDataStore(),
        permissionManager: HealthKitPermissionManager = HealthKitPermissionManager()
    ) {
        self.store = store
        self.permissionManager = permissionManager
    }

    func buildTodayContext() async -> HealthContext {
        permissionManager.refreshPermissionSummary()
        async let snapshot = store.fetchDailySnapshot()
        async let ecg = store.fetchLatestECG()
        return await HealthContext(
            snapshot: snapshot,
            permissionSummary: permissionManager.summary,
            latestECG: ecg,
            userPreference: .default
        )
    }
}
