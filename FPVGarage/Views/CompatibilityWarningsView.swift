import SwiftUI

struct CompatibilityWarningsView: View {
    let warnings: [CompatibilityWarning]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Compatibility")
                .font(.headline)
            ForEach(warnings) { warning in
                HStack(alignment: .top, spacing: 8) {
                    warningIcon(for: warning.level)
                    Text(warning.detail)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func warningIcon(for level: CompatibilityWarningLevel) -> some View {
        switch level {
        case .error:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        case .warning:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        case .info:
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.blue)
        }
    }
}
