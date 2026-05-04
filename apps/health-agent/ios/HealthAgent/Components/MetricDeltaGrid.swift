import SwiftUI

struct MetricDeltaGrid: View {
    let metrics: [HealthMetric]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(metrics) { metric in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(metric.label)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(HAColor.secondaryText)
                        Spacer()
                        Circle()
                            .fill(metric.color)
                            .frame(width: 8, height: 8)
                    }
                    Text(metric.value)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(HAColor.primaryText)
                    Text(metric.detail)
                        .font(.caption)
                        .foregroundStyle(HAColor.secondaryText)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(metric.color.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }
}
