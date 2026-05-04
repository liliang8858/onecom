import SwiftUI

struct MultiMetricTimeline: View {
    let title: String
    let rows: [TimelineRow]

    var body: some View {
        HACard {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(HAColor.primaryText)

                VStack(spacing: 14) {
                    ForEach(rows) { row in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(color(for: row.status))
                                    .frame(width: 12, height: 12)
                                Rectangle()
                                    .fill(HAColor.border)
                                    .frame(width: 2, height: 36)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(row.day)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(HAColor.secondaryText)
                                Text(row.primary)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(HAColor.primaryText)
                                Text(row.secondary)
                                    .font(.caption)
                                    .foregroundStyle(HAColor.secondaryText)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private func color(for status: MetricStatus) -> Color {
        switch status {
        case .up: return HAColor.ecgRed
        case .down, .attention: return HAColor.workoutAmber
        case .missing: return HAColor.secondaryText
        case .normal: return HAColor.recoveryGreen
        }
    }
}
