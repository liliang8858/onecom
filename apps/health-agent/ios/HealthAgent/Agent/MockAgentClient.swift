import Foundation

// MARK: - MockAgentClient v3.0
// 生成符合 PRD v3.0 Schema 规范的 UISchema

final class MockAgentClient: AgentClient {
    static let shared = MockAgentClient()

    // MARK: - Today Metrics

    let todayMetrics: [HealthMetric] = [
        HealthMetric(id: "sleep", label: "睡眠", value: "6h12m", detail: "比平时少 42m", status: .down, colorName: "sleep"),
        HealthMetric(id: "heart", label: "心脏", value: "稳定", detail: "静息心率 +3", status: .normal, colorName: "heart"),
        HealthMetric(id: "recovery", label: "恢复", value: "偏弱", detail: "Recovery 62", status: .attention, colorName: "recovery"),
        HealthMetric(id: "workout", label: "运动", value: "偏高", detail: "负荷 128", status: .up, colorName: "workout")
    ]

    let insightQuestions: [InsightQuestion] = [
        InsightQuestion(id: "recovery", title: "我最近恢复得好吗？", subtitle: "HRV 下降 · 静息心率略高", category: "恢复", priority: 0.94, isECGEnhanced: false, screenID: "recovery_status_30d"),
        InsightQuestion(id: "sleep", title: "昨晚睡得怎么样？", subtitle: "睡眠 6h12m · 夜间心率偏高", category: "睡眠", priority: 0.89, isECGEnhanced: false, screenID: "sleep_last_night"),
        InsightQuestion(id: "heart", title: "最近心脏状态稳定吗？", subtitle: "有 1 次 ECG 可作为补充证据", category: "心脏", priority: 0.86, isECGEnhanced: true, screenID: "heart_status"),
        InsightQuestion(id: "anomaly", title: "最近有什么异常？", subtitle: "发现 3 个值得关注的变化", category: "异常", priority: 0.83, isECGEnhanced: false, screenID: "anomaly_center")
    ]

    let latestECG = ECGEpisode(
        id: "latest_ecg",
        recordedAt: "昨日 22:14",
        quality: "良好",
        rhythmSummary: "节律整体稳定",
        averageHeartRate: "82 bpm",
        classification: "可分析",
        note: "这不是医学诊断，但可以帮助你回看当时状态。"
    )

    // MARK: AgentClient Protocol

    func fetchCanvasSchema(intent: HealthIntent, contextMode: ContextMode, agencyMode: AgencyMode) async throws -> UISchema {
        switch intent {
        case .dailyCheck: return todaySchema()
        case .recoveryAnalysis: return recoverySchema()
        case .sleepAnalysis: return sleepSchema()
        case .heartStatus: return heartSchema()
        case .anomalyReview: return anomalySchema()
        case .ecgInterpretation: return ecgSchema()
        case .weeklyReview: return weeklySchema()
        default: return todaySchema()
        }
    }

    func chat(query: String, context: HealthContext) async throws -> UISchema {
        return dynamicAnalysisSchema(query: query)
    }

    func fetchActiveMemories() async throws -> [MemoryRecord] {
        return []
    }

    func fetchPendingConfirmations() async throws -> [MemoryRecord] {
        return []
    }

    func submitMemoryFeedback(memoryId: String, verdict: MemoryVerdict, note: String?) async throws -> MemoryRecord {
        throw AgentError.internalError(code: "not_implemented")
    }

    func deleteMemory(id: String) async throws {}

    func submitFeedback(_ feedback: FeedbackSubmission) async throws -> FeedbackResponse {
        return FeedbackResponse(
            acknowledged: true,
            appliedChange: "反馈已记录",
            nextAdjustment: .init(type: "depth", direction: "reduce", description: "降低解释深度")
        )
    }

    func reportActionCompletion(actionId: String, completed: Bool, metadata: [String: AnyCodable]?) async throws {}

    func fetchChangeLog() async throws -> [ChangeLogEntry] {
        return []
    }

    // MARK: - Schema Generators

    func todaySchema() -> UISchema {
        UISchema(
            id: "today_20250508",
            schemaVersion: "3.0",
            screen: .today,
            userIntent: .dailyCheck,
            layout: .insightFirst,
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            contextMode: .morningBrief,
            availableAttention: .high,
            agencyMode: .agentGuided,
            healthPriorityPolicy: .healthNeedOverPreference,
            emotionalFraming: .calmActionable,
            explanationContract: .brief,
            personalizationReason: "根据你过去 14 天的睡眠关注生成",
            personalizationFactors: ["sleep_focus", "recovery_monitoring"],
            minSafetyLevelShown: .info,
            blocks: [
                .insightSummary(InsightSummaryConfig(
                    id: "summary",
                    title: "恢复偏弱",
                    summary: "过去 7 天你的 HRV 下降 18%，静息心率略高，同时睡眠时间减少。主要建议是降低高强度训练，优先补足睡眠。",
                    tone: "attention"
                )),
                .metricDeltaGrid(MetricDeltaGridConfig(
                    id: "metrics",
                    metrics: [
                        HealthMetric(id: "hrv", label: "HRV", value: "-12%", detail: "低于 30 日基线", status: .down, colorName: "recovery"),
                        HealthMetric(id: "rhr", label: "静息心率", value: "+4 bpm", detail: "连续 4 天略高", status: .up, colorName: "heart"),
                        HealthMetric(id: "sleep", label: "睡眠", value: "-42m", detail: "比平时少", status: .down, colorName: "sleep"),
                        HealthMetric(id: "load", label: "运动负荷", value: "+32%", detail: "本周上升", status: .up, colorName: "workout")
                    ]
                )),
                .whyShownReason(reason: "最近 7 天睡眠不足与该指标下降高度相关，基于 21 天数据，相关系数 0.68"),
                .actionPlanCard(ActionPlanConfig(
                    id: "actions-today",
                    actions: [
                        HealthAction(
                            id: "walk-1",
                            title: "午后散步 10 分钟",
                            detail: "轻度有氧，有助于下午精力恢复",
                            reason: "你过去这类行动完成率较高 (68%)，且有助于下午能量恢复",
                            difficulty: .easy,
                            estimatedDuration: 600,
                            suggestedTime: Date().addingTimeInterval(10800),
                            meta: HealthActionMeta(completionRate: 0.68, lastCompletedAt: nil, streak: 3, relatedMetrics: ["active_energy"])
                        ),
                        HealthAction(
                            id: "sleep-1",
                            title: "晚上 22:40 开始睡前放松",
                            detail: "远离屏幕，进行深呼吸练习",
                            reason: "你睡眠少于 6.5 小时后，次日 HRV 更容易下降",
                            difficulty: .easy,
                            estimatedDuration: 600,
                            suggestedTime: nil,
                            meta: nil
                        )
                    ],
                    style: "compact"
                )),
                .feedbackBar("block-summary"),
                .dataSource("source", text: "数据来自 Apple Health。本页不构成医学诊断。")
            ]
        )
    }

    func recoverySchema() -> UISchema {
        UISchema(
            id: "recovery_30d",
            schemaVersion: "3.0",
            screen: .insight,
            userIntent: .recoveryAnalysis,
            layout: .insightFirst,
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            contextMode: .deepDive,
            availableAttention: .medium,
            agencyMode: .agentGuided,
            healthPriorityPolicy: .healthNeedOverPreference,
            emotionalFraming: .directEvidence,
            explanationContract: .evidenceFirst,
            personalizationReason: "基于你的恢复关注偏好和历史数据",
            personalizationFactors: ["recovery_focus", "hrv_trend"],
            minSafetyLevelShown: .info,
            blocks: [
                .insightSummary(InsightSummaryConfig(
                    id: "summary",
                    title: "恢复状态偏弱",
                    summary: "过去 7 天你的 HRV 下降，静息心率略高，同时睡眠时间减少。主要建议是降低高强度训练，优先补足睡眠。",
                    tone: "attention"
                )),
                .metricDeltaGrid(MetricDeltaGridConfig(
                    id: "metrics",
                    metrics: [
                        HealthMetric(id: "hrv", label: "HRV", value: "-12%", detail: "低于 30 日基线", status: .down, colorName: "recovery"),
                        HealthMetric(id: "rhr", label: "静息心率", value: "+4 bpm", detail: "连续 4 天略高", status: .up, colorName: "heart"),
                        HealthMetric(id: "sleep", label: "睡眠", value: "-42m", detail: "比平时少", status: .down, colorName: "sleep"),
                        HealthMetric(id: "load", label: "运动负荷", value: "+32%", detail: "本周上升", status: .up, colorName: "workout")
                    ]
                )),
                .trendChart(TrendChartConfig(
                    id: "hrv-trend",
                    title: "HRV 30 天趋势",
                    subtitle: "最近 7 天低于个人基线",
                    values: [58, 61, 59, 55, 52, 49, 47, 46, 44, 43, 41, 39],
                    colorName: "recovery",
                    unit: "ms",
                    range: "30d"
                )),
                .multiMetricTimeline(MultiMetricTimelineConfig(
                    id: "timeline",
                    title: "近 7 天恢复线索",
                    rows: [
                        TimelineRow(id: "mon", day: "周一", primary: "睡眠 7h10m", secondary: "HRV 正常", status: .normal),
                        TimelineRow(id: "wed", day: "周三", primary: "高强度运动", secondary: "HRV 开始下降", status: .attention),
                        TimelineRow(id: "fri", day: "周五", primary: "睡眠 5h48m", secondary: "静息心率偏高", status: .up)
                    ]
                )),
                .suggestedQuestions(SuggestedQuestionsConfig(id: "next", questions: ["只看睡眠因素", "加入运动负荷分析", "和状态好的日子对比"])),
                .feedbackBar("block-recovery"),
                .dataSource("source", text: "数据来自 Apple Health。本页不构成医学诊断。")
            ]
        )
    }

    func sleepSchema() -> UISchema {
        UISchema(
            id: "sleep_last_night",
            schemaVersion: "3.0",
            screen: .insight,
            userIntent: .sleepAnalysis,
            layout: .insightFirst,
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            contextMode: .deepDive,
            availableAttention: .medium,
            agencyMode: .agentGuided,
            healthPriorityPolicy: .balanced,
            emotionalFraming: .reassuring,
            explanationContract: .balanced,
            personalizationReason: "基于你的睡眠关注偏好",
            personalizationFactors: ["sleep_focus"],
            minSafetyLevelShown: .info,
            blocks: [
                .insightSummary(InsightSummaryConfig(
                    id: "summary",
                    title: "睡眠偏短",
                    summary: "昨晚睡眠 6h12m，比平时少 42 分钟。深睡和 REM 占比偏低，夜间心率略高。",
                    tone: "attention"
                )),
                .metricDeltaGrid(MetricDeltaGridConfig(
                    id: "metrics",
                    metrics: [
                        HealthMetric(id: "duration", label: "总睡眠", value: "6h12m", detail: "少 42m", status: .down, colorName: "sleep"),
                        HealthMetric(id: "deep", label: "深睡", value: "48m", detail: "偏低", status: .attention, colorName: "sleep"),
                        HealthMetric(id: "nightHR", label: "夜间心率", value: "58 bpm", detail: "略高", status: .up, colorName: "heart"),
                        HealthMetric(id: "resp", label: "呼吸", value: "16/min", detail: "平稳", status: .normal, colorName: "recovery")
                    ]
                )),
                .trendChart(TrendChartConfig(
                    id: "sleep-trend",
                    title: "过去 14 天睡眠",
                    subtitle: "本周整体低于平时",
                    values: [7.2, 7.0, 6.8, 7.4, 6.4, 6.1, 6.2, 6.0, 5.8, 6.3, 6.1],
                    colorName: "sleep",
                    unit: "小时",
                    range: "14d"
                )),
                .actionPlanCard(ActionPlanConfig(
                    id: "actions-sleep",
                    actions: [
                        HealthAction(
                            id: "sleep-early-1",
                            title: "今晚提前 30 分钟上床",
                            detail: "设定 23:00 闹钟提醒",
                            reason: "你提前入睡时次日 HRV 平均提升 8%",
                            difficulty: .easy,
                            estimatedDuration: 1800,
                            suggestedTime: Date(),
                            meta: HealthActionMeta(completionRate: 0.55, lastCompletedAt: nil, streak: 1, relatedMetrics: ["sleep_duration"])
                        )
                    ],
                    style: "detailed"
                )),
                .feedbackBar("block-sleep"),
                .dataSource("source", text: "睡眠分析依赖 Apple Health 授权数据，缺失数据会降低置信度。")
            ]
        )
    }

    func heartSchema() -> UISchema {
        UISchema(
            id: "heart_status",
            schemaVersion: "3.0",
            screen: .insight,
            userIntent: .heartStatus,
            layout: .evidenceFirst,
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            contextMode: .deepDive,
            availableAttention: .high,
            agencyMode: .agentGuided,
            healthPriorityPolicy: .healthNeedOverPreference,
            emotionalFraming: .reassuring,
            explanationContract: .evidenceFirst,
            personalizationReason: "基于你的心脏关注偏好和最新 ECG 数据",
            personalizationFactors: ["heart_focus", "ecg_available"],
            minSafetyLevelShown: .info,
            blocks: [
                .insightSummary(InsightSummaryConfig(
                    id: "summary",
                    title: "整体平稳，有轻微变化",
                    summary: "最近静息心率略高，HRV 略低。昨日 22:14 有一次 ECG，可作为本次回看的补充证据。",
                    tone: "normal"
                )),
                .ecgEpisodeCard(ECGEpisodeConfig(id: "ecg", episode: latestECG)),
                .trendChart(TrendChartConfig(
                    id: "heart-trend",
                    title: "静息心率趋势",
                    subtitle: "近 7 天略高于个人基线",
                    values: [54, 55, 55, 56, 58, 58, 59, 58, 57, 58, 59],
                    colorName: "heart",
                    unit: "bpm",
                    range: "30d"
                )),
                .suggestedQuestions(SuggestedQuestionsConfig(
                    id: "next",
                    questions: ["解读 ECG", "查看睡眠影响", "运动后恢复好吗？"]
                )),
                .feedbackBar("block-heart"),
                .dataSource("source", text: "心脏状态分析不构成医学诊断。如持续不适，建议咨询医生。")
            ]
        )
    }

    func anomalySchema() -> UISchema {
        UISchema(
            id: "anomaly_center",
            schemaVersion: "3.0",
            screen: .insight,
            userIntent: .anomalyReview,
            layout: .list,
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            contextMode: .deepDive,
            availableAttention: .high,
            agencyMode: .agentGuided,
            healthPriorityPolicy: .healthNeedOverPreference,
            emotionalFraming: .calmActionable,
            explanationContract: .balanced,
            personalizationReason: "异常检测基于个人基线变化",
            personalizationFactors: ["anomaly_detection", "multi_metric_correlation"],
            minSafetyLevelShown: .info,
            blocks: [
                .insightSummary(InsightSummaryConfig(
                    id: "summary",
                    title: "发现 3 个值得关注的变化",
                    summary: "这些变化按个人基线、持续时间和数据完整度排序。",
                    tone: "attention"
                )),
                .anomalyList(AnomalyListConfig(
                    id: "anomalies",
                    anomalies: [
                        DerivedInsight(
                            id: "rhr",
                            title: "静息心率连续 4 天偏高",
                            summary: "可能相关：睡眠减少、运动负荷增加。",
                            severity: .warning,
                            relatedMetrics: ["rhr", "sleep_duration", "workout_load"],
                            affectedDateRange: nil,
                            confidenceScore: 0.82,
                            sourceMetrics: ["resting_heart_rate": 67.0, "baseline": 62.0],
                            suggestedActions: [
                                HealthAction(
                                    id: "check-rhr-1",
                                    title: "早晨静息复测",
                                    detail: "醒来后静坐 1 分钟测量",
                                    reason: "确认是否为持续性偏高",
                                    difficulty: .easy,
                                    estimatedDuration: 60,
                                    suggestedTime: nil,
                                    meta: nil
                                )
                            ],
                            isEcgRelated: false,
                            wasConfirmedByUser: nil
                        ),
                        DerivedInsight(
                            id: "hrv",
                            title: "HRV 低于 30 天基线",
                            summary: "可能提示恢复压力上升。",
                            severity: .attention,
                            relatedMetrics: ["hrv", "recovery_score"],
                            affectedDateRange: nil,
                            confidenceScore: 0.75,
                            sourceMetrics: ["hrv": 42.0, "baseline": 52.0],
                            suggestedActions: nil,
                            isEcgRelated: false,
                            wasConfirmedByUser: nil
                        ),
                        DerivedInsight(
                            id: "night",
                            title: "昨晚夜间心率偏高",
                            summary: "建议结合睡眠结构和晚间活动回看。",
                            severity: .attention,
                            relatedMetrics: ["night_hr", "sleep_quality"],
                            affectedDateRange: nil,
                            confidenceScore: 0.68,
                            sourceMetrics: ["night_hr": 62.0, "resting_hr": 58.0],
                            suggestedActions: nil,
                            isEcgRelated: false,
                            wasConfirmedByUser: nil
                        )
                    ]
                )),
                .suggestedQuestions(SuggestedQuestionsConfig(
                    id: "next",
                    questions: ["查看恢复状态", "只看心脏相关", "生成本周报告"]
                )),
                .feedbackBar("block-anomaly"),
                .dataSource("source", text: "异常检测基于个人基线，不代表医学诊断。")
            ]
        )
    }

    func ecgSchema() -> UISchema {
        UISchema(
            id: "ecg_latest",
            schemaVersion: "3.0",
            screen: .dynamicAnalysis,
            userIntent: .ecgInterpretation,
            layout: .evidenceFirst,
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            contextMode: .deepDive,
            availableAttention: .high,
            agencyMode: .selfExplore,
            healthPriorityPolicy: .balanced,
            emotionalFraming: .reassuring,
            explanationContract: .evidenceFirst,
            personalizationReason: "最新 ECG 可用，提供心脏补充证据",
            personalizationFactors: ["ecg_available", "heart_focus"],
            minSafetyLevelShown: .info,
            blocks: [
                .insightSummary(InsightSummaryConfig(
                    id: "ecg-summary",
                    title: "最近一次心电：节律整体稳定",
                    summary: latestECG.note,
                    tone: "normal"
                )),
                .ecgEpisodeCard(ECGEpisodeConfig(id: "ecg", episode: latestECG)),
                .ecgWaveform(ECGWaveformConfig(
                    id: "ecg-waveform",
                    voltageSamples: (0..<500).map { i in
                        sin(Double(i) * 0.05) * 0.5 + Double.random(in: -0.05...0.05)
                    },
                    samplingRate: 500,
                    leadType: "Lead II"
                )),
                .ecgQuality(ECGQualityConfig(
                    id: "ecg-quality",
                    signalQualityScore: 0.85,
                    noiseLevel: 0.12,
                    baselineWander: "轻微"
                )),
                .feedbackBar("block-ecg"),
                .dataSource("source", text: "心电解读基于设备采集数据，仅供参考。")
            ]
        )
    }

    func weeklySchema() -> UISchema {
        UISchema(
            id: "weekly_review",
            schemaVersion: "3.0",
            screen: .insight,
            userIntent: .weeklyReview,
            layout: .summaryFirst,
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            contextMode: .deepDive,
            availableAttention: .medium,
            agencyMode: .agentGuided,
            healthPriorityPolicy: .balanced,
            emotionalFraming: .calmActionable,
            explanationContract: .balanced,
            personalizationReason: "每周综合回顾",
            personalizationFactors: ["weekly_review", "multi_domain"],
            minSafetyLevelShown: .info,
            blocks: [
                .insightSummary(InsightSummaryConfig(
                    id: "weekly-summary",
                    title: "本周恢复较上周下降 18%",
                    summary: "可能原因：1) 睡眠时长减少；2) HRV 持续偏低；3) 压力负荷升高。建议接下来 3 天降低训练强度，并观察睡眠恢复情况。",
                    tone: "attention"
                )),
                .metricDeltaGrid(MetricDeltaGridConfig(
                    id: "weekly-metrics",
                    metrics: [
                        HealthMetric(id: "sleep-week", label: "平均睡眠", value: "6h12m", detail: "↓ vs 上周", status: .down, colorName: "sleep"),
                        HealthMetric(id: "load-week", label: "运动负荷", value: "+32%", detail: "↑ vs 上周", status: .up, colorName: "workout"),
                        HealthMetric(id: "hrv-week", label: "HRV", value: "-12%", detail: "↓ vs 基线", status: .down, colorName: "recovery"),
                        HealthMetric(id: "ecg-count", label: "ECG 次数", value: "2", detail: "vs 上周 1", status: .normal, colorName: "heart")
                    ]
                )),
                .feedbackBar("block-weekly"),
                .dataSource("source", text: "数据来自 Apple Health。")
            ]
        )
    }

    func dynamicAnalysisSchema(query: String) -> UISchema {
        UISchema(
            id: "dynamic_\(UUID().uuidString.prefix(8))",
            schemaVersion: "3.0",
            screen: .dynamicAnalysis,
            userIntent: .customQuery,
            layout: .evidenceFirst,
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            contextMode: .deepDive,
            availableAttention: .high,
            agencyMode: .selfExplore,
            healthPriorityPolicy: .balanced,
            emotionalFraming: .directEvidence,
            explanationContract: .evidenceFirst,
            personalizationReason: nil,
            personalizationFactors: [],
            minSafetyLevelShown: .info,
            blocks: [
                .insightSummary(InsightSummaryConfig(
                    id: "dynamic-summary",
                    title: "动态分析：\(query)",
                    summary: "这是一个基于当前数据的动态分析结果。",
                    tone: "normal"
                )),
                .suggestedQuestions(SuggestedQuestionsConfig(
                    id: "refinements",
                    questions: ["只看工作日的情况", "和上个月对比", "给我制定改善计划"]
                )),
                .feedbackBar("block-dynamic")
            ]
        )
    }
}
}

// MARK: - Stub conformance

extension AgentError: Error {}