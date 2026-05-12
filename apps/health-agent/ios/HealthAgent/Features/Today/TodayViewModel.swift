import Foundation
import SwiftUI

// ==========================================================================
// MARK: - Today View Model (PRD v3.0 §5, §10)
// ==========================================================================

@MainActor
final class TodayViewModel: ObservableObject {

    // MARK: - State

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var healthContext: HealthContext?
    @Published var schema: UISchema?
    @Published var coldStartDayIndex: Int = 0
    @Published var showColdStartBanner: Bool = true

    // MARK: - Dependencies

    private let agent: AgentClient
    private let contextBuilder: HealthContextBuilder

    // MARK: - Init

    init(
        agent: AgentClient = MockAgentClient.shared,
        contextBuilder: HealthContextBuilder = HealthContextBuilder()
    ) {
        self.agent = agent
        self.contextBuilder = contextBuilder
    }

    // MARK: - Public Interface

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            let context = try await contextBuilder.buildTodayContext()
            self.healthContext = context

            let fetchedSchema = try await agent.fetchCanvasSchema(
                intent: .dailyCheck,
                contextMode: .morningBrief,
                agencyMode: .agentGuided
            )
            self.schema = fetchedSchema

            // 更新冷启动天数
            updateColdStartState()

        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        await load()
    }

    // MARK: - Derived Properties

    var todayMetrics: [HealthMetric] {
        (agent as? MockAgentClient)?.todayMetrics ?? []
    }

    var insightQuestions: [InsightQuestion] {
        (agent as? MockAgentClient)?.insightQuestions ?? []
    }

    var personalizationReason: String {
        if coldStartDayIndex == 0 {
            return "初始设置中…"
        }
        let domains = todayMetrics.map(\.label).joined(separator: ", ")
        return "根据你的 \(domains) 习惯生成"
    }

    var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 · EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: Date()) + " · Apple Health 已同步"
    }

    // MARK: - Actions

    func completeAction(_ id: String) {
        Task {
            let _ = await agent.reportActionCompletion(
                actionId: id,
                completed: true,
                metadata: nil
            )
        }
    }

    func submitFeedback(blockId: String, category: FeedbackCategory) {
        Task {
            let submission = FeedbackSubmission(
                blockId: blockId,
                category: category,
                screenId: "today"
            )
            let _ = await agent.submitFeedback(submission)
        }
    }

    // MARK: - Private

    private func updateColdStartState() {
        // TODO(#2): 从 UserDefaults 读取实际使用天数
        let defaults = UserDefaults.standard
        let dayKey = "health_agent_first_launch_date"
        if let firstLaunch = defaults.object(forKey: dayKey) as? Date {
            let days = Calendar.current.dateComponents([.day], from: firstLaunch, to: Date()).day ?? 0
            coldStartDayIndex = min(days, 7)
            showColdStartBanner = days < 7
        } else {
            coldStartDayIndex = 0
            showColdStartBanner = true
            defaults.set(Date(), forKey: key)
        }
    }
}