import SwiftUI

// MARK: - RR Interval Chart View (new in v3.0)

struct RRIntervalChartView: View {
    let cfg: ECGWaveformConfig

    var body: some View {
        HACard(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("RR 间期")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(HAColor.primaryText)

                Text("采样率: \(Int(cfg.samplingRate)) Hz")
                    .font(.caption2)
                    .foregroundStyle(HAColor.secondaryText)

                if let samples = cfg.voltageSamples, !samples.isEmpty {
                    RRIntervalChart(samples: samples)
                        .frame(height: 120)
                } else {
                    PlaceholderView(text: "等待 ECG 数据")
                        .frame(height: 120)
                }
            }
        }
    }
}

struct RRIntervalChart: View {
    let samples: [Double]

    var body: some View {
        GeometryReader { geo in
            Path { path in
                guard samples.count > 1 else { return }
                let stepX = geo.size.width / CGFloat(samples.count - 1)
                let maxVal = samples.max() ?? 1
                let minVal = samples.min() ?? 0
                let range = maxVal - minVal > 0 ? maxVal - minVal : 1

                for (i, val) in samples.enumerated() {
                    let x = CGFloat(i) * stepX
                    let y = geo.size.height * (1 - CGFloat((val - minVal) / range))
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(HAColor.ecgRed, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
    }
}

struct RRIntervalChartView_Previews: PreviewProvider {
    static var previews: some View {
        RRIntervalChartView(cfg: ECGWaveformConfig(id: "rr1", voltageSamples: (0..<200).map { _ in Double.random(in: 0.3...1.2) }, samplingRate: 500, leadType: "II"))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}