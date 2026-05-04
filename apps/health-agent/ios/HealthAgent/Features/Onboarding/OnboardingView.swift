import SwiftUI

struct OnboardingView: View {
    @State private var selectedFocus: Set<String> = ["睡眠", "恢复", "心脏"]
    private let focusAreas = ["睡眠", "恢复", "心脏", "运动", "压力代理", "ECG", "体重", "整体健康"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HASpacing.section) {
                Text("先让 App 了解你关心什么")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(HAColor.primaryText)
                    .padding(.top, 20)

                Text("Health Agent 会根据你的关注方向渐进式请求 HealthKit 权限，并生成第一批洞察按钮。")
                    .font(.body)
                    .foregroundStyle(HAColor.secondaryText)
                    .lineSpacing(5)

                HACard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("你最想了解什么？")
                            .font(.headline)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(focusAreas, id: \.self) { area in
                                Button {
                                    if selectedFocus.contains(area) {
                                        selectedFocus.remove(area)
                                    } else {
                                        selectedFocus.insert(area)
                                    }
                                } label: {
                                    HStack {
                                        Text(area)
                                        Spacer()
                                        if selectedFocus.contains(area) {
                                            Image(systemName: "checkmark.circle.fill")
                                        }
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .padding(12)
                                    .background(selectedFocus.contains(area) ? HAColor.primaryGreen.opacity(0.12) : HAColor.border.opacity(0.35))
                                    .foregroundStyle(selectedFocus.contains(area) ? HAColor.primaryGreen : HAColor.secondaryText)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                PermissionPromptCard(summary: .mock)

                HACard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("生成第一批洞察按钮")
                            .font(.headline)
                        Text("我最近恢复得好吗？、昨晚睡得怎么样？、最近心脏状态稳定吗？会成为默认入口。")
                            .font(.subheadline)
                            .foregroundStyle(HAColor.secondaryText)
                    }
                }
            }
            .padding(.horizontal, HASpacing.page)
            .padding(.bottom, 28)
        }
        .background(HAColor.appBackground.ignoresSafeArea())
        .navigationTitle("初始化")
        .navigationBarTitleDisplayMode(.inline)
    }
}
