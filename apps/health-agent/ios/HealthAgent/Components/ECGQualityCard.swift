import SwiftUI

// MARK: - ECG Quality Card (new in v3.0)

struct ECGQualityCard: View {
    let cfg: ECGQualityConfig

    var body: some View {
        HACard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "waveform.path.ecg")
                        .foregroundStyle(HAColor.ecgRed)
                    Text("信号质量")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    QualityBadge(score: cfg.signalQualityScore)
                }

                HStack(spacing: 16) {
                    QualityDetail(label: "信号评分", value: "\(Int(cfg.signalQualityScore * 100))%")
                    if let noise = cfg.noiseLevel {
                        QualityDetail(label: "噪声", value: "\(Int(noise * 100))%")
                    }
                    if let wander = cfg.baselineWander {
                        QualityDetail(label: "基线漂移", value: wander)
                    }
                }
            }
        }
    }
}

private struct QualityBadge: View {
    let score: Double
    var body: some View {
        Text(score >= 0.8 ? "良好" : score >= 0.5 ? "一般" : "较差")
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(score >= 0.8 ? HAColor.primaryGreen.opacity(0.15) : HAColor.alertRed.opacity(0.15))
            .foregroundStyle(score >= 0.8 ? HAColor.primaryGreen : HAColor.alertRed)
            .clipShape(Capsule())
    }
}

private struct QualityDetail: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(HAColor.secondaryText)
            Text(value).font(.subheadline).foregroundStyle(HAColor.primaryText)
        }
    }
}

struct ECGQualityCard_Previews: PreviewProvider {
    static var previews: some View {
        ECGQualityCard(cfg: ECGQualityConfig(id: "q1", signalQualityScore: 0.85, noiseLevel: 0.12, baselineWander: "轻微"))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}