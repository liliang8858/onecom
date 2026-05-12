import SwiftUI

// MARK: - Preference Tuner
// 分身页内调教解释风格、提醒偏好

struct PreferenceTuner: View {
    @Binding var preference: UserPreference
    @Binding var anxietyScore: Double

    var body: some View {
        Form {
            Section("解释风格") {
                Picker("详细程度", selection: $preference.explanationDepth) {
                    ForEach(ExplanationDepth.allCases, id: \.self) { depth in
                        Text(depth.displayName).tag(depth)
                    }
                }

                Picker("UI 风格", selection: $preference.uiPreference) {
                    ForEach(UIPreference.allCases, id: \.self) { pref in
                        Text(pref.displayName).tag(pref)
                    }
                }
            }

            Section("提醒偏好") {
                Picker("通知频率", selection: $preference.notificationTolerance) {
                    ForEach(NotificationTolerance.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }

                HStack {
                    Text("敏感度")
                    Slider(value: $anxietyScore, in: 0...1, step: 0.05)
                    Text(anxietyDisplay)
                        .font(.caption)
                        .foregroundStyle(anxietyScore > 0.6 ? HAColor.alertRed : HAColor.primaryText)
                }
            }

            Section("代理偏好") {
                Toggle("默认帮我总结", isOn: Binding(
                    get: { preference.agencyDefault == .agentGuided },
                    set: { preference.agencyDefault = $0 ? .agentGuided : .selfExplore }
                ))

                Picker("图表时间范围", selection: $preference.chartRangeDays) {
                    Text("7 天").tag(7)
                    Text("14 天").tag(14)
                    Text("30 天").tag(30)
                    Text("90 天").tag(90)
                }
            }

            Section("行动风格") {
                Picker("行动建议", selection: $preference.actionPreference) {
                    ForEach(ActionPreference.allCases, id: \.self) { pref in
                        Text(pref.displayName).tag(pref)
                    }
                }
            }
        }
        .navigationTitle("个性化设置")
    }

    private var anxietyDisplay: String {
        switch anxietyScore {
        case 0..<0.3: return "低"
        case 0.3..<0.6: return "中"
        default: return "高"
        }
    }
}

// MARK: - Enum Display Names

extension ExplanationDepth {
    var displayName: String {
        switch self {
        case .brief: return "一句话总结"
        case .moderate: return "适度解释"
        case .detailed: return "给我证据和数据"
        }
    }
}

extension UIPreference {
    var displayName: String {
        switch self {
        case .summaryFirst: return "先看结论"
        case .dataFirst: return "先看图表"
        case .evidenceFirst: return "先看证据"
        }
    }
}

extension NotificationTolerance {
    var displayName: String {
        switch self {
        case .high: return "每日推送"
        case .medium: return "每天一次摘要"
        case .low: return "仅重要变化"
        case .none: return "不推送"
        }
    }
}

extension ActionPreference {
    var displayName: String {
        switch self {
        case .smallSteps: return "小步骤行动"
        case .structured: return "结构化计划"
        case .exploratory: return "探索性建议"
        }
    }
}

struct PreferenceTuner_Previews: PreviewProvider {
    static var previews: some View {
        PreferenceTuner(
            preference: .constant(.default),
            anxietyScore: .constant(0.3)
        )
    }
}