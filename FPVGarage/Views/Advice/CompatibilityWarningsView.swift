import SwiftUI

struct CompatibilityWarningsView: View {
    let warnings: [CompatibilityWarning]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Compatibility")
                .font(.headline)

            if warnings.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("No issues detected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } else {
                ForEach(warnings) { warning in
                    warningRow(warning)
                }
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func warningRow(_ warning: CompatibilityWarning) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconName(for: warning.level))
                .foregroundStyle(color(for: warning.level))
                .font(.subheadline)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(warning.rule)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(warning.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }

    private func iconName(for level: CompatibilityWarningLevel) -> String {
        switch level {
        case .error:   return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info:    return "info.circle.fill"
        }
    }

    private func color(for level: CompatibilityWarningLevel) -> Color {
        switch level {
        case .error:   return .red
        case .warning: return .orange
        case .info:    return .blue
        }
    }
}
