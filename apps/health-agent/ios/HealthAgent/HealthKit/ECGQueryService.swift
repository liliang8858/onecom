import Foundation

final class ECGQueryService {
    private let store: HealthDataStore

    init(store: HealthDataStore = MockHealthDataStore()) {
        self.store = store
    }

    func latestEpisode() async -> ECGEpisode? {
        await store.fetchLatestECG()
    }

    func contextWindow(for episode: ECGEpisode) async -> ECGContextWindow {
        ECGContextWindow(
            episodeID: episode.id,
            before24h: ["睡眠 6h12m", "HRV 32ms", "静息心率 58bpm"],
            after24h: ["恢复仍偏弱", "夜间心率略高"],
            confidence: "中"
        )
    }
}

struct ECGContextWindow: Codable, Hashable {
    let episodeID: String
    let before24h: [String]
    let after24h: [String]
    let confidence: String
}
