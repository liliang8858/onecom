import Foundation

final class MockAgentClient {
    static let shared = MockAgentClient()

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

    func schema(for screenID: String) -> HealthPageSchema {
        switch screenID {
        case "sleep_last_night": return sleepSchema()
        case "heart_status": return heartSchema()
        case "anomaly_center": return anomalySchema()
        default: return recoverySchema()
        }
    }

    func recoverySchema() -> HealthPageSchema {
        HealthPageSchema(
            schemaVersion: "1.0",
            screenID: "recovery_status_30d",
            title: "我最近恢复得好吗？",
            timeRange: "过去 30 天",
            style: "insight_first",
            safetyLevel: "non_diagnostic",
            blocks: [
                .insightSummary(InsightSummaryConfig(id: "summary", title: "恢复状态偏弱", summary: "过去 7 天你的 HRV 下降，静息心率略高，同时睡眠时间减少。主要建议是降低高强度训练，优先补足睡眠。", tone: "attention")),
                .metricDeltaGrid(MetricDeltaGridConfig(id: "metrics", metrics: [
                    HealthMetric(id: "hrv", label: "HRV", value: "-12%", detail: "低于 30 日基线", status: .down, colorName: "recovery"),
                    HealthMetric(id: "rhr", label: "静息心率", value: "+4 bpm", detail: "连续 4 天略高", status: .up, colorName: "heart"),
                    HealthMetric(id: "sleep", label: "睡眠", value: "-42m", detail: "比平时少", status: .down, colorName: "sleep"),
                    HealthMetric(id: "load", label: "运动负荷", value: "+32%", detail: "本周上升", status: .up, colorName: "workout")
                ])),
                .trendChart(TrendChartConfig(id: "hrv-trend", title: "HRV 30 天趋势", subtitle: "最近 7 天低于个人基线", values: [58, 61, 59, 55, 52, 49, 47, 46, 44, 43, 41, 39], colorName: "recovery")),
                .multiMetricTimeline(MultiMetricTimelineConfig(id: "timeline", title: "近 7 天恢复线索", rows: [
                    TimelineRow(id: "mon", day: "周一", primary: "睡眠 7h10m", secondary: "HRV 正常", status: .normal),
                    TimelineRow(id: "wed", day: "周三", primary: "高强度运动", secondary: "HRV 开始下降", status: .attention),
                    TimelineRow(id: "fri", day: "周五", primary: "睡眠 5h48m", secondary: "静息心率偏高", status: .up)
                ])),
                .suggestedQuestions(SuggestedQuestionsConfig(id: "next", questions: ["只看睡眠因素", "加入运动负荷分析", "和状态好的日子对比"])),
                .dataSource(DataSourceConfig(id: "source", text: "数据来自 Apple Health。本页不构成医学诊断。"))
            ]
        )
    }

    func sleepSchema() -> HealthPageSchema {
        HealthPageSchema(
            schemaVersion: "1.0",
            screenID: "sleep_last_night",
            title: "昨晚睡得怎么样？",
            timeRange: "昨晚",
            style: "insight_first",
            safetyLevel: "non_diagnostic",
            blocks: [
                .insightSummary(InsightSummaryConfig(id: "summary", title: "睡眠偏短", summary: "昨晚睡眠 6h12m，比平时少 42 分钟。深睡和 REM 占比偏低，夜间心率略高。", tone: "attention")),
                .metricDeltaGrid(MetricDeltaGridConfig(id: "metrics", metrics: [
                    HealthMetric(id: "duration", label: "总睡眠", value: "6h12m", detail: "少 42m", status: .down, colorName: "sleep"),
                    HealthMetric(id: "deep", label: "深睡", value: "48m", detail: "偏低", status: .attention, colorName: "sleep"),
                    HealthMetric(id: "nightHR", label: "夜间心率", value: "58 bpm", detail: "略高", status: .up, colorName: "heart"),
                    HealthMetric(id: "resp", label: "呼吸", value: "16/min", detail: "平稳", status: .normal, colorName: "recovery")
                ])),
                .trendChart(TrendChartConfig(id: "sleep-trend", title: "过去 14 天睡眠", subtitle: "本周整体低于平时", values: [7.2, 7.0, 6.8, 7.4, 6.4, 6.1, 6.2, 6.0, 5.8, 6.3, 6.1], colorName: "sleep")),
                .suggestedQuestions(SuggestedQuestionsConfig(id: "next", questions: ["看夜间心率", "和前 7 天对比", "睡眠影响恢复吗？"])),
                .dataSource(DataSourceConfig(id: "source", text: "睡眠分析依赖 Apple Health 授权数据，缺失数据会降低置信度。"))
            ]
        )
    }

    func heartSchema() -> HealthPageSchema {
        HealthPageSchema(
            schemaVersion: "1.0",
            screenID: "heart_status",
            title: "最近心脏状态稳定吗？",
            timeRange: "过去 30 天",
            style: "evidence_first",
            safetyLevel: "non_diagnostic",
            blocks: [
                .insightSummary(InsightSummaryConfig(id: "summary", title: "整体平稳，有轻微变化", summary: "最近静息心率略高，HRV 略低。昨日 22:14 有一次 ECG，可作为本次回看的补充证据。", tone: "normal")),
                .ecgEpisode(ECGEpisodeConfig(id: "ecg", episode: latestECG)),
                .trendChart(TrendChartConfig(id: "heart-trend", title: "静息心率趋势", subtitle: "近 7 天略高于个人基线", values: [54, 55, 55, 56, 58, 58, 59, 58, 57, 58, 59], colorName: "heart")),
                .suggestedQuestions(SuggestedQuestionsConfig(id: "next", questions: ["解读 ECG", "查看睡眠影响", "运动后恢复好吗？"])),
                .dataSource(DataSourceConfig(id: "source", text: "心脏状态分析不构成医学诊断。如持续不适，建议咨询医生。"))
            ]
        )
    }

    func anomalySchema() -> HealthPageSchema {
        HealthPageSchema(
            schemaVersion: "1.0",
            screenID: "anomaly_center",
            title: "最近有什么异常？",
            timeRange: "过去 14 天",
            style: "list",
            safetyLevel: "non_diagnostic",
            blocks: [
                .insightSummary(InsightSummaryConfig(id: "summary", title: "发现 3 个值得关注的变化", summary: "这些变化按个人基线、持续时间和数据完整度排序。", tone: "attention")),
                .anomalyList(AnomalyListConfig(id: "anomalies", anomalies: [
                    DerivedInsight(id: "rhr", title: "静息心率连续 4 天偏高", summary: "可能相关：睡眠减少、运动负荷增加。", severity: "建议查看", relatedMetrics: ["心率", "睡眠"]),
                    DerivedInsight(id: "hrv", title: "HRV 低于 30 天基线", summary: "可能提示恢复压力上升。", severity: "轻微变化", relatedMetrics: ["HRV", "恢复"]),
                    DerivedInsight(id: "night", title: "昨晚夜间心率偏高", summary: "建议结合睡眠结构和晚间活动回看。", severity: "建议查看", relatedMetrics: ["睡眠", "心率"])
                ])),
                .suggestedQuestions(SuggestedQuestionsConfig(id: "next", questions: ["查看恢复状态", "只看心脏相关", "生成本周报告"])),
                .dataSource(DataSourceConfig(id: "source", text: "异常检测基于个人基线，不代表医学诊断。"))
            ]
        )
    }
}
