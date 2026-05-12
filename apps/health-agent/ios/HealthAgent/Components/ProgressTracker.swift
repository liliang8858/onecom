import SwiftUI

// MARK: - Progress Tracker View (new in v3.0)
// 某个指标的进度追踪（当前值 vs 目标值）

struct ProgressTrackerView: View {
    let cfg: ProgressTrackerConfig

    private var progress: Double {
        guard cfg.target != 0 else { return 0 }
        return min(cfg.current / cfg.target, 1.0)
    }

    private var isOnTrack: Bool {
        progress >= 0.7
    }

    var body: some View {
        HACard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(cfg.metric)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(HAColor.primaryText)
                    Spacer()
                    Text("\(String(format: "%.0f", cfg.current)) / \(String(format: "%.0f", cfg.target)) \(cfg.unit)")
                        .font(.subheadline)
                        .foregroundStyle(isOnTrack ? HAColor.primaryGreen : HAColor.workoutAmber)
                }

                // Circular progress
                ZStack {
                    Circle()
                        .stroke(HAColor.border.opacity(0.3), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            isOnTrack ? HAColor.primaryGreen : HAColor.workoutAmber,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(progress * 100))%")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(isOnTrack ? HAColor.primaryGreen : HAColor.workoutAmber)
                }
                .frame(width: 80, height: 80)
                .padding(.vertical, 4)

                // Timeline dots
                TimelineDots(progress: progress)
            }
        }
    }
}

private struct TimelineDots: View {
    let progress: Double
    let totalDots = 14

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalDots, id: \.self) { i in
                Circle()
                    .fill(
                        CGFloat(i + 1) / CGFloat(totalDots) <= progress
                        ? HAColor.primaryGreen
                        : HAColor.border.opacity(0.3)
                    )
                    .frame(width: 6, height: 6)
            }
        }
    }
}

struct ProgressTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressTrackerView(cfg: ProgressTrackerConfig(
            id: "pt-1",
            metric: "月度运动",
            current: 12,
            target: 16,
            unit: "次"
        ))
        .padding()
        .previewLayout(.sizeThatFits)
    }
}