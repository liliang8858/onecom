import SwiftUI

// MARK: - MeView (Updated for PRD v3.0)
// 我的页面 - 承载设备、授权、隐私、导出、数据管理、账号设置

struct MeView: View {
    var body: some View {
        NavigationView {
            List {
                // 分身记忆
                Section("分身记忆") {
                    NavigationLink {
                        TwinView()
                    } label: {
                        Label("健康分身", systemImage: "brain.head.profile")
                            .symbolVariant(.fill)
                    }
                    NavigationLink {
                        // MemoryListView placeholder
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(sampleMemories) { memory in
                                    MemoryCard(memory: memory, onAction: { _ in })
                                }
                            }
                            .padding()
                        }
                        .navigationTitle("记忆管理")
                    } label: {
                        Label("记忆管理", systemImage: "list.bullet.clipboard")
                    }
                }

                // 数据与隐私
                Section("数据与隐私") {
                    NavigationLink {
                        PermissionManagerView()
                    } label: {
                        Label("HealthKit 权限", systemImage: "heart.text.square")
                    }
                    Label("数据来源", systemImage: "externaldrive")
                    Label("导出数据", systemImage: "square.and.arrow.up")
                    Label("删除分析历史", systemImage: "trash")
                        .foregroundStyle(.red)
                }

                // 个性化
                Section("个性化") {
                    NavigationLink {
                        PreferenceTuner(
                            preference: .constant(.default),
                            anxietyScore: .constant(0.3)
                        )
                    } label: {
                        Label("偏好设置", systemImage: "slider.horizontal.3")
                    }
                    Label("洞察按钮管理", systemImage: "square.grid.2x2")
                    Label("UI 风格", systemImage: "paintbrush")
                }

                // 关于
                Section("关于") {
                    NavigationLink {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Health Agent Twin")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("版本 0.1.0 · Build 1")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("一个以 Apple Health 连续健康数据为底座、以 ECG 心电作为关键事件增强证据的智能健康 Agent App。")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                Text("它不是让你更依赖 App，而是让你更理解自己的身体。")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)
                            }
                            .padding()
                        }
                        .navigationTitle("关于")
                    } label: {
                        Label("关于 Health Agent", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("我的")
        }
    }

    // Sample data for preview
    var sampleMemories: [MemoryRecord] {
        [
            MemoryRecord(
                id: "mem-1",
                type: .correlation,
                patternDescription: "睡眠少于 6.5 小时时，次日 HRV 通常下降 15-20%。",
                evidenceSummary: "过去 21 天；Apple Health",
                affectedMetrics: ["sleep_duration", "hrv"],
                confidenceScore: 0.87,
                observationCount: 21,
                firstObservedAt: Date().addingTimeInterval(-1209600),
                lastSeenAt: Date(),
                status: .confirmed,
                userFeedback: MemoryFeedback(verdict: .accurate, givenAt: Date(), note: nil),
                changeLog: [],
                relatedAnomalies: []
            ),
            MemoryRecord(
                id: "mem-2",
                type: .trend,
                patternDescription: "过去 2 周静息心率呈上升趋势。",
                evidenceSummary: "过去 14 天；Apple Health",
                affectedMetrics: ["resting_heart_rate"],
                confidenceScore: 0.65,
                observationCount: 14,
                firstObservedAt: Date().addingTimeInterval(-604800),
                lastSeenAt: Date(),
                status: .observing,
                userFeedback: nil,
                changeLog: [],
                relatedAnomalies: []
            )
        ]
    }
}

// === Permission Manager View ===

struct PermissionManagerView: View {
    @State private var permissions: [PermissionItem] = [
        .init(name: "睡眠分析", granted: true, types: ["睡眠时长", "睡眠阶段"]),
        .init(name: "心率数据", granted: true, types: ["静息心率", "运动心率"]),
        .init(name: "HRV", granted: false, types: ["心率变异性"]),
        .init(name: "ECG", granted: false, types: ["心电记录"]),
        .init(name: "血氧", granted: false, types: ["血氧饱和度"]),
        .init(name: "运动记录", granted: true, types: ["活动能量", "步数"]),
        .init(name: "呼吸频率", granted: false, types: ["呼吸频率"])
    ]

    var body: some View {
        List {
            ForEach($permissions) { $perm in
                HStack {
                    VStack(alignment: .leading) {
                        Text(perm.name)
                            .font(.body)
                        Text(perm.types.joined(separator: "、"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle(isOn: $perm.granted) {
                        Text(perm.granted ? "已授权" : "未授权")
                            .font(.caption)
                            .foregroundStyle(perm.granted ? .green : .secondary)
                    }
                    .toggleStyle(.button)
                }
            }

            Section {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("原始 HealthKit 数据默认留在设备本地。授权仅用于本地分析，不会上传至服务器。")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("HealthKit 权限")
    }

    struct PermissionItem: Identifiable {
        let id = UUID()
        let name: String
        var granted: Bool
        let types: [String]
    }
}

// === Twin View ===

struct TwinView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 健康关注全貌
                VCard(title: "健康关注全貌") {
                    HStack(spacing: 12) {
                        ForEach(["睡眠", "恢复", "心脏", "运动"], id: \.self) { domain in
                            VStack(spacing: 6) {
                                Image(systemName: iconFor(domain))
                                    .font(.title3)
                                    .foregroundStyle(colorFor(domain))
                                Text(domain)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(colorFor(domain).opacity(0.08))
.clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }

            // 已确认模式
                VCard(title: "已确认模式") {
                    Text("睡眠少于 6.5 小时时，次日 HRV 通常下降 15-20%。")
                        .font(.subheadline)
                    HStack {
                        Spacer()
                        Label("置信度 87%", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Spacer()
                        Text("21 天数据 · 已确认")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // 正在观察
                VCard(title: "正在观察") {
                    Text("过去 2 周静息心率呈上升趋势。")
                        .font(.subheadline)
                    HStack {
                        ProgressView(value: 0.4)
                            .tint(.orange)
                        Text("已观察 14/30 天")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Change Log
                VCard(title: "变更记录") {
                    VStack(spacing: 12) {
                        ChangeLogRow(icon: "info.circle", color: .green, text: "健康解释已改为简洁模式", time: "3 天前")
                        ChangeLogRow(icon: "bell.slash", color: .orange, text: "减少夜间心率提醒频率", time: "1 周前")
                        ChangeLogRow(icon: "chart.bar", color: .blue, text: "同类洞察展示频率已降低", time: "2 周前")
                    }
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("健康分身")
    }

    func iconFor(_ domain: String) -> String {
        switch domain {
        case "睡眠": return "moon.fill"
        case "恢复": return "arrow.counterclockwise"
        case "心脏": return "heart.fill"
        case "运动": return "figure.run"
        default: return "questionmark"
        }
    }

    func colorFor(_ domain: String) -> Color {
        switch domain {
        case "睡眠": return .purple
        case "恢复": return .green
        case "心脏": return .red
        case "运动": return .orange
        default: return .gray
        }
    }
}

struct VCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

struct ChangeLogRow: View {
    let icon: String
    let color: Color
    let text: String
    let time: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 18, height: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.subheadline)
                Text(time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct MeView_Previews: PreviewProvider {
    static var previews: some View {
        MeView()
    }
}