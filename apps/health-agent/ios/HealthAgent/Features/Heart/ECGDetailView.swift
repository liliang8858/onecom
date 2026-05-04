import SwiftUI

struct ECGDetailView: View {
    let episode: ECGEpisode

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HASpacing.section) {
                HACard {
                    VStack(alignment: .leading, spacing: 18) {
                        Label("本次 ECG 可分析", systemImage: "checkmark.circle.fill")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(HAColor.primaryGreen)

                        HStack(spacing: 16) {
                            ECGSummaryColumn(title: "主要观察", value: episode.rhythmSummary)
                            Divider()
                            ECGSummaryColumn(title: "平均心率", value: episode.averageHeartRate)
                            Divider()
                            ECGSummaryColumn(title: "信号质量", value: episode.quality)
                        }

                        Text(episode.note)
                            .font(.footnote)
                            .foregroundStyle(HAColor.secondaryText)
                    }
                }

                HACard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("ECG 波形")
                                .font(.headline)
                            Spacer()
                            Text("25 mm/s · 10 mm/mV")
                                .font(.caption)
                                .foregroundStyle(HAColor.secondaryText)
                        }
                        ECGWaveformView()
                            .frame(height: 150)
                    }
                }

                TrendChartBlock(title: "RR 间期", subtitle: "平均 731 ms，波动较平稳", values: [720, 738, 714, 731, 744, 729, 718, 735, 728], colorName: "heart")

                HACard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("相关背景")
                            .font(.headline)
                        MetricDeltaGrid(metrics: [
                            HealthMetric(id: "sleep", label: "昨晚睡眠", value: "6h12m", detail: "略低", status: .down, colorName: "sleep"),
                            HealthMetric(id: "hrv", label: "HRV", value: "32 ms", detail: "略低", status: .down, colorName: "recovery"),
                            HealthMetric(id: "rhr", label: "静息心率", value: "58 bpm", detail: "略高", status: .up, colorName: "heart"),
                            HealthMetric(id: "quality", label: "质量", value: "良好", detail: "干扰少", status: .normal, colorName: "recovery")
                        ])
                    }
                }

                SuggestedQuestionBar(questions: ["和上次 ECG 对比", "查看前 24 小时", "记录症状"])
            }
            .padding(.horizontal, HASpacing.page)
            .padding(.bottom, 28)
        }
        .background(HAColor.appBackground.ignoresSafeArea())
        .navigationTitle("解读最新一次 ECG")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ECGSummaryColumn: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(HAColor.secondaryText)
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(HAColor.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
