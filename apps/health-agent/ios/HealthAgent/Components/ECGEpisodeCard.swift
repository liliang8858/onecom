import SwiftUI

struct ECGEpisodeCard: View {
    let episode: ECGEpisode

    var body: some View {
        HACard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("ECG 补充证据", systemImage: "waveform.path.ecg")
                        .font(.headline)
                        .foregroundStyle(HAColor.ecgRed)
                    Spacer()
                    Text(episode.recordedAt)
                        .font(.caption)
                        .foregroundStyle(HAColor.secondaryText)
                }

                HStack(spacing: 16) {
                    StatColumn(title: "状态", value: episode.classification)
                    Divider()
                    StatColumn(title: "平均心率", value: episode.averageHeartRate)
                    Divider()
                    StatColumn(title: "信号质量", value: episode.quality)
                }

                ECGWaveformView()
                    .frame(height: 96)

                Text(episode.note)
                    .font(.footnote)
                    .foregroundStyle(HAColor.secondaryText)
                    .padding(.top, 2)
            }
        }
    }
}

private struct StatColumn: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(HAColor.secondaryText)
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(HAColor.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
