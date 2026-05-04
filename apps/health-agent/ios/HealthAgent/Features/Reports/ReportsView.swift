import SwiftUI

struct ReportsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HASpacing.section) {
                Text("报告")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(HAColor.primaryText)
                    .padding(.top, 16)

                HACard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("本周健康报告")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(HAColor.primaryText)
                        Text("本周整体偏弱但可恢复。主要变化来自睡眠减少、运动负荷上升和 HRV 下降。")
                            .font(.body)
                            .foregroundStyle(HAColor.secondaryText)
                            .lineSpacing(5)
                        MetricDeltaGrid(metrics: [
                            HealthMetric(id: "sleep", label: "睡眠", value: "-42m", detail: "平均每晚", status: .down, colorName: "sleep"),
                            HealthMetric(id: "load", label: "运动", value: "+32%", detail: "负荷上升", status: .up, colorName: "workout"),
                            HealthMetric(id: "hrv", label: "HRV", value: "-12%", detail: "低于基线", status: .down, colorName: "recovery"),
                            HealthMetric(id: "ecg", label: "ECG", value: "1 次", detail: "补充证据", status: .normal, colorName: "heart")
                        ])
                    }
                }
            }
            .padding(.horizontal, HASpacing.page)
            .padding(.bottom, 28)
        }
        .background(HAColor.appBackground.ignoresSafeArea())
    }
}
