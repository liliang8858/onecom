import SwiftUI

struct AnomalyListBlock: View {
    let anomalies: [DerivedInsight]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(anomalies) { anomaly in
                HACard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(anomaly.title)
                                .font(.headline)
                                .foregroundStyle(HAColor.primaryText)
                            Spacer()
                            Text(anomaly.severity)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(HAColor.workoutAmber.opacity(0.14))
                                .foregroundStyle(HAColor.workoutAmber)
                                .clipShape(Capsule())
                        }
                        Text(anomaly.summary)
                            .font(.subheadline)
                            .foregroundStyle(HAColor.secondaryText)
                        HStack {
                            ForEach(anomaly.relatedMetrics, id: \.self) { metric in
                                Text(metric)
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(HAColor.primaryGreen.opacity(0.10))
                                    .foregroundStyle(HAColor.primaryGreen)
                                    .clipShape(Capsule())
                            }
                            Spacer()
                            Text("查看原因")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(HAColor.primaryGreen)
                        }
                    }
                }
            }
        }
    }
}
