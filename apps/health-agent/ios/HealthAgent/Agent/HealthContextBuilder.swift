import Foundation

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

    func buildTodayContext(userTwin: UserTwin = .default) async -> HealthContext {
        permissionManager.refreshPermissionSummary()
        async let snapshot = store.fetchDailySnapshot()
        async let ecg = store.fetchLatestECG()
        return await HealthContext(
            snapshot: snapshot,
            permissionSummary: permissionManager.summary,
            latestECG: ecg,
            userTwin: userTwin,
            sessionId: UUID().uuidString,
            appOpenTime: Date(),
            localTimezone: TimeZone.current.identifier
        )
    }
}
