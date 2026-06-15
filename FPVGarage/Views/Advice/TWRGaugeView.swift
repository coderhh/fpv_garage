import SwiftUI

struct TWRGaugeView: View {
    let result: ThrustToWeightResult

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Thrust-to-Weight (推重比)")
                    .font(.headline)
                Spacer()
                tierBadge
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.2f", result.ratio))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(tierColor)
                Text("x")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(result.flightStyle.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.secondary.opacity(0.15))
                    .clipShape(Capsule())
            }

            gaugeBar

            HStack(spacing: 4) {
                Image(systemName: confidenceIcon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(result.confidence.confidenceLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var tierBadge: some View {
        Text(result.tier.displayName)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(tierColor)
            .clipShape(Capsule())
    }

    private var gaugeBar: some View {
        let thresholds = result.flightStyle.twrThresholds
        let maxRatio = thresholds.ideal * 1.3
        let progress = min(result.ratio / maxRatio, 1.0)

        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.secondary.opacity(0.15))
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 4)
                    .fill(tierColor)
                    .frame(width: geo.size.width * progress, height: 8)
            }
        }
        .frame(height: 8)
    }

    private var tierColor: Color {
        switch result.tier {
        case .underpowered: return .red
        case .adequate:     return .orange
        case .good:         return .yellow
        case .ideal:        return .green
        }
    }

    private var confidenceIcon: String {
        switch result.confidence {
        case .measured:  return "checkmark.seal"
        case .specSheet: return "doc.text"
        case .estimated: return "questionmark.circle"
        }
    }
}
