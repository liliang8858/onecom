import SwiftUI

// MARK: - ECG Waveform View (Updated for PRD v3.0)
// 支持真实 voltage 数据渲染，兼容 stub 模式

struct ECGWaveformView: View {
    let cfg: ECGWaveformConfig

    var body: some View {
        HACard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("心电波形")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(HAColor.primaryText)
                    Spacer()
                    Text(cfg.leadType)
                        .font(.caption2)
                        .foregroundStyle(HAColor.secondaryText)
                    Text("\(Int(cfg.samplingRate))Hz")
                        .font(.caption2)
                        .foregroundStyle(HAColor.secondaryText)
                }

                if let samples = cfg.voltageSamples, !samples.isEmpty {
                    ECGWaveformPath(samples: samples)
                        .stroke(HAColor.ecgRed, style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                        .frame(height: 140)
                        .background(GridBackground(rows: 5, columns: 20))
                } else {
                    Image("ECGWaveformSample")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 140)
                        .opacity(0.5)
                }
            }
        }
    }
}

struct ECGWaveformPath: Shape {
    let samples: [Double]

    func path(in rect: CGRect) -> Path {
        Path { path in
            guard samples.count > 1 else { return }
            let stepX = rect.width / CGFloat(samples.count - 1)
            let maxVal = samples.max() ?? 1
            let minVal = samples.min() ?? -1
            let range = (maxVal - minVal) > 0 ? (maxVal - minVal) : 1
            let midY = rect.midY

            for (i, val) in samples.enumerated() {
                let x = CGFloat(i) * stepX
                let normalizedVal = (val - (maxVal + minVal) / 2) / (range / 2)
                let y = midY - CGFloat(normalizedVal) * rect.height * 0.4
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
    }
}

struct GridBackground: View {
    let rows: Int
    let columns: Int

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<rows, id: \.self) { row in
                Path { path in
                    let y = geo.size.height * CGFloat(row + 1) / CGFloat(rows + 1)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
                .stroke(HAColor.border.opacity(0.15), lineWidth: 0.5)
            }
            ForEach(0..<columns, id: \.self) { col in
                Path { path in
                    let x = geo.size.width * CGFloat(col + 1) / CGFloat(columns + 1)
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
                .stroke(HAColor.border.opacity(0.15), lineWidth: 0.5)
            }
        }
    }
}

struct ECGWaveformView_Previews: PreviewProvider {
    static var previews: some View {
        ECGWaveformView(cfg: ECGWaveformConfig(
            id: "ecg-wf",
            voltageSamples: (0..<500).map { i in sin(Double(i) * 0.05) * 0.5 + Double.random(in: -0.05...0.05) },
            samplingRate: 500,
            leadType: "Lead II"
        ))
        .padding()
        .previewLayout(.sizeThatFits)
    }
}