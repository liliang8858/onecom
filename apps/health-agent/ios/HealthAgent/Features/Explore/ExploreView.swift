import SwiftUI

struct ExploreView: View {
    private let prompts = [
        ("运动对睡眠有帮助吗？", "对比运动日和非运动日"),
        ("状态好的日子有什么共同点？", "提取可复制模式"),
        ("工作日和周末有什么不同？", "观察生活节奏影响"),
        ("我该关注哪个指标？", "按变化和偏好排序")
    ]

    var body: some View {
        List {
            Section("探索关系") {
                ForEach(prompts, id: \.0) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.0)
                            .font(.headline)
                        Text(item.1)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("探索")
    }
}
