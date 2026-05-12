import SwiftUI

// MARK: - ECG Context Timeline (new in v3.0)
// ECG 前后上下文时间线

struct ECGContextTimelineView: View {
    let cfg: ECGWaveformConfig

    var body: some View {
        HACard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("心脏事件上下文")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(HAColor.primaryText)

                HStack(spacing: 0) {
                    TimelineBlock(title: "前 24h", values: Array(repeating: 0, count: 24), color: HAColor.sleepPurple)
                    Divider().frame(height: 40)
                    TimelineBlock(title: "前 2h", values: Array(repeating: 0, count: 4), color: HAColor.workoutAmber)
                    Divider().frame(height: 40)
                    TimelineBlock(title: "ECG", values: cfg.voltageSamples ?? [], color: HAColor.ecgRed)
                    Divider().frame(height: 40)
                    TimelineBlock(title: "后 2h", values: Array(repeating: 0, count: 4), color: HAColor.recoveryGreen)
                    Divider().frame(height: 40)
                    TimelineBlock(title: "后 24h", values: Array(repeating: 0, count: 24), color: HAColor.primaryGreen)
                }
            }
        }
    }
}

struct TimelineBlock: View {
    let title: String
    let values: [Double]
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(HAColor.secondaryText)

            if values.isEmpty {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 30)
            } else {
                GeometryReader { geo in
                    HStack(alignment: .bottom, spacing: 1) {
                        ForEach(Array(values.enumerated()), id: \.offset) { _, val in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(color.opacity(0.7))
                                .frame(
                                    width: max(2, geo.size.width / CGFloat(values.count) - 1),
                                    height: max(4, CGFloat(val) * geo.size.height)
                                )
                                .alignmentGuide(.bottom) { _ in 0 }
                        }
                    }
                }
                .frame(height: 30)
            }
        }
        .frame(minWidth: 40)
    }
}

struct ECGContextTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        ECGContextTimelineView(cfg: ECGWaveformConfig(id: "ctx1", voltageSamples: (0..<50).map { _ in Double.random(in: 0...1) }, samplingRate: 500, leadType: "II"))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}