import SwiftUI

struct ECGWaveformView: View {
    var body: some View {
        ZStack {
            Image("ECGWaveformSample")
                .resizable()
                .scaledToFill()
                .opacity(0.92)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(HAColor.ecgRed.opacity(0.16), lineWidth: 1)
        }
    }
}
