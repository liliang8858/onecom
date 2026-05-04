import Foundation
import Combine

#if canImport(HealthKit)
import HealthKit
#endif

enum HealthPermissionState: String, Codable {
    case notDetermined = "未请求"
    case partial = "部分授权"
    case ready = "已授权"
    case unavailable = "不可用"
}

struct HealthPermissionSummary: Codable, Hashable {
    let state: HealthPermissionState
    let granted: [String]
    let missing: [String]

    static let mock = HealthPermissionSummary(
        state: .partial,
        granted: ["睡眠", "心率", "静息心率", "运动"],
        missing: ["HRV", "ECG", "血氧"]
    )
}

final class HealthKitPermissionManager: ObservableObject {
    @Published private(set) var summary: HealthPermissionSummary = .mock

    var isHealthDataAvailable: Bool {
        #if canImport(HealthKit)
        return HKHealthStore.isHealthDataAvailable()
        #else
        return false
        #endif
    }

    func refreshPermissionSummary() {
        guard isHealthDataAvailable else {
            summary = HealthPermissionSummary(state: .unavailable, granted: [], missing: ["HealthKit"])
            return
        }

        // 真实权限读取应在接入 HealthKit target 后实现。
        // MVP 阶段保持 mock summary，避免无权限环境下阻塞 UI 开发。
        summary = .mock
    }

    func requestRecoveryPermissions() async -> HealthPermissionSummary {
        // 真实实现需要请求 HRV、静息心率、睡眠、运动等读取权限。
        summary = HealthPermissionSummary(
            state: .ready,
            granted: ["睡眠", "心率", "静息心率", "HRV", "运动"],
            missing: ["ECG", "血氧"]
        )
        return summary
    }
}
