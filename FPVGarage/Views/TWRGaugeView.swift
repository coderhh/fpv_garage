import SwiftUI

struct TWRGaugeView: View {
    let result: ThrustToWeightResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Thrust-to-Weight Ratio")
                .font(.headline)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(String(format: "%.1f", result.ratio))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(tierColor)
                Text(": 1")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Spacer()
                tierBadge
            }

            twrBar

            HStack {
                Label(result.confidence.displayName, systemImage: confidenceIcon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(result.flightStyle.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var tierBadge: some View {
        Text(result.tier.displayName)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(tierColor.opacity(0.15))
            .foregroundStyle(tierColor)
            .clipShape(Capsule())
    }

    private var twrBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(.quaternary)
                    .frame(height: 8)

                // Fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(tierColor)
                    .frame(width: barWidth(in: geo.size.width), height: 8)
            }
        }
        .frame(height: 8)
    }

    private func barWidth(in totalWidth: CGFloat) -> CGFloat {
        // Scale: 0 to 15 TWR maps to 0% to 100% of bar
        let fraction = min(result.ratio / 15.0, 1.0)
        return max(totalWidth * fraction, 4)
    }

    private var tierColor: Color {
        switch result.tier {
        case .underpowered: return .red
        case .adequate:     return .orange
        case .good:         return .green
        case .ideal:        return .blue
        }
    }

    private var confidenceIcon: String {
        switch result.confidence {
        case .measured:  return "checkmark.seal.fill"
        case .specSheet: return "doc.text"
        case .estimated: return "questionmark.circle"
        }
    }
}
