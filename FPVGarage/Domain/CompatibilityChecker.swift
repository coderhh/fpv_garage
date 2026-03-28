import Foundation

struct CompatibilityChecker {

    private static let nominalCellVoltage = 3.7

    /// Check all applicable compatibility rules for an aircraft and optional battery.
    static func check(aircraft: Aircraft, battery: Battery?) -> [CompatibilityWarning] {
        var warnings: [CompatibilityWarning] = []
        if let w = checkKvVoltageRange(aircraft: aircraft, battery: battery) {
            warnings.append(w)
        }
        // Rules 1 (ESC current), 3 (C-rating), 4 (ESC/FC protocol) require
        // structured data not yet on the model. Framework is ready; add checks
        // when fields are added.
        return warnings
    }

    // MARK: - Rule 2: KV x Voltage RPM Range

    /// For a 5-inch quad, motor KV x battery voltage should be roughly 18,000–24,000 RPM.
    /// Ranges are scaled by frame size.
    private static func checkKvVoltageRange(aircraft: Aircraft, battery: Battery?) -> CompatibilityWarning? {
        guard let kv = aircraft.motorKv else { return nil }
        let cells = aircraft.batteryCellCount ?? battery?.cells
        guard let cells, cells > 0 else { return nil }

        let voltage = Double(cells) * nominalCellVoltage
        let rpm = Double(kv) * voltage

        let (low, high) = rpmRange(for: aircraft.frameSizeInch)

        if rpm < low {
            return CompatibilityWarning(
                rule: "kv_voltage_range",
                level: .warning,
                detail: String(localized: "Motor RPM (\(Int(rpm))) is below the typical range (\(Int(low))–\(Int(high))) for this frame size. Consider higher KV motors or more battery cells.")
            )
        }
        if rpm > high {
            return CompatibilityWarning(
                rule: "kv_voltage_range",
                level: .warning,
                detail: String(localized: "Motor RPM (\(Int(rpm))) exceeds the typical range (\(Int(low))–\(Int(high))) for this frame size. Consider lower KV motors or fewer battery cells.")
            )
        }
        return nil
    }

    /// RPM range adjusted by frame size. Defaults to 5-inch range.
    private static func rpmRange(for frameSizeInch: Double?) -> (low: Double, high: Double) {
        guard let size = frameSizeInch else {
            return (18_000, 24_000) // default: 5-inch
        }
        // Smaller frames tolerate higher RPM; larger frames need lower RPM
        switch size {
        case ..<3.0:
            return (24_000, 36_000)
        case 3.0..<4.0:
            return (20_000, 30_000)
        case 4.0..<6.0:
            return (18_000, 24_000)
        case 6.0..<8.0:
            return (14_000, 20_000)
        default:
            return (10_000, 16_000)
        }
    }
}
