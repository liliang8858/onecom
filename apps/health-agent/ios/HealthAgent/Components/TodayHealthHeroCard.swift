import SwiftUI

struct TodayHealthHeroCard: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Image("TodayHeroBackground")
                .resizable()
                .scaledToFill()
                .overlay(LinearGradient(colors: [.black.opacity(0.10), .black.opacity(0.36)], startPoint: .topTrailing, endPoint: .bottomLeading))

            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("今日身体状态")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.86))
                        Text("偏弱")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("你的身体恢复水平偏低，建议关注睡眠与恢复。")
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.88))
                            .lineSpacing(4)
                    }
                    Spacer()
                    RecoveryRing(score: 62)
                        .frame(width: 118, height: 118)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("主要影响因素")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.70))
                    HStack(spacing: 8) {
                        FactorPill(icon: "moon.fill", title: "睡眠不足")
                        FactorPill(icon: "waveform.path.ecg", title: "HRV 下降")
                        FactorPill(icon: "heart.fill", title: "心率略高")
                    }
                }

                HStack(spacing: 12) {
                    NavigationLink(destination: DynamicInsightPageView(schema: MockAgentClient.shared.recoverySchema())) {
                        Text("查看原因")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.white.opacity(0.18))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(.white.opacity(0.42), lineWidth: 1)
                            }
                    }

                    Button {
                    } label: {
                        Text("今日建议")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.white)
                            .foregroundStyle(HAColor.primaryGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
            .padding(22)
        }
        .frame(height: 354)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
}

private struct RecoveryRing: View {
    let score: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.18), lineWidth: 12)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(HAColor.recoveryGreen, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("Recovery")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
                Text("\(score)")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("/100")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.68))
            }
        }
    }
}

private struct FactorPill: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.white.opacity(0.16))
        .clipShape(Capsule())
    }
}
