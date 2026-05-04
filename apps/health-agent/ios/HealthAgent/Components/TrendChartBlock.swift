import SwiftUI

struct TrendChartBlock: View {
    let title: String
    let subtitle: String
    let values: [Double]
    let colorName: String

    var body: some View {
        HACard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(HAColor.primaryText)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(HAColor.secondaryText)
                    }
                    Spacer()
                }

                LineChart(values: values, color: color)
                    .frame(height: 132)
            }
        }
    }

    private var color: Color {
        switch colorName {
        case "sleep": return HAColor.sleepPurple
        case "heart": return HAColor.ecgRed
        case "workout": return HAColor.workoutAmber
        default: return HAColor.recoveryGreen
        }
    }
}

struct LineChart: View {
    let values: [Double]
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let points = normalizedPoints(in: proxy.size)
            ZStack {
                VStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { _ in
                        Rectangle()
                            .fill(HAColor.border.opacity(0.6))
                            .frame(height: 1)
                        Spacer()
                    }
                }
                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                        .position(point)
                }
            }
        }
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard let minValue = values.min(), let maxValue = values.max(), values.count > 1 else { return [] }
        let range = max(maxValue - minValue, 1)
        return values.enumerated().map { index, value in
            let x = CGFloat(index) / CGFloat(values.count - 1) * size.width
            let y = size.height - CGFloat((value - minValue) / range) * size.height
            return CGPoint(x: x, y: y)
        }
    }
}
