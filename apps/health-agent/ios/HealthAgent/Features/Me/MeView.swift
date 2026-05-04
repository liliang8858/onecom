import SwiftUI

struct MeView: View {
    var body: some View {
        List {
            Section("开始") {
                NavigationLink {
                    OnboardingView()
                } label: {
                    Label("重新生成我的健康首页", systemImage: "sparkles")
                }
            }

            Section("数据与隐私") {
                Label("HealthKit 权限", systemImage: "heart.text.square")
                Label("数据来源", systemImage: "externaldrive")
                Label("删除分析历史", systemImage: "trash")
            }
            Section("个性化") {
                Label("洞察按钮管理", systemImage: "square.grid.2x2")
                Label("UI 偏好", systemImage: "slider.horizontal.3")
                Label("非诊断提醒", systemImage: "checkmark.seal")
            }
        }
        .navigationTitle("我的")
    }
}
