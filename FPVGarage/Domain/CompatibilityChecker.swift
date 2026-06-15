import Foundation

enum CompatibilityChecker {
    static func check(aircraft: Aircraft, linkedBattery: Battery?) -> [CompatibilityWarning] {
        var warnings: [CompatibilityWarning] = []

        checkESCCurrent(aircraft: aircraft, into: &warnings)
        checkKVVoltage(aircraft: aircraft, linkedBattery: linkedBattery, into: &warnings)
        checkCRating(aircraft: aircraft, linkedBattery: linkedBattery, into: &warnings)

        return warnings
    }

    // Rule 1: ESC continuous current rating must cover per-motor max draw.
    private static func checkESCCurrent(aircraft: Aircraft, into warnings: inout [CompatibilityWarning]) {
        guard let escRating = aircraft.escCurrentRating,
              let motorMax = aircraft.motorMaxCurrentAmps else { return }

        if escRating < motorMax {
            warnings.append(CompatibilityWarning(
                rule: "ESC Current Rating",
                level: .error,
                detail: "ESC is rated \(escRating) A but motor max draw is \(motorMax) A. Undersized ESC will burn out under aggressive flight."
            ))
        }
    }

    // Rule 2: Motor KV × battery voltage should fall within the expected RPM band for the frame size.
    // Reference range [18 000, 24 000] is for 5" quads (per spec §11.3); scaled for other sizes.
    private static func checkKVVoltage(aircraft: Aircraft, linkedBattery: Battery?, into warnings: inout [CompatibilityWarning]) {
        guard let kv = aircraft.motorKv else { return }
        let cells = aircraft.batteryCellCount ?? linkedBattery?.cells
        guard let c = cells, c > 0 else { return }

        let nominalVoltage = Double(c) * 3.7
        let noLoadRPM = Double(kv) * nominalVoltage
        let (minRPM, maxRPM) = kvVoltageRange(for: aircraft.frameSizeInch)

        if noLoadRPM < minRPM || noLoadRPM > maxRPM {
            let frameDesc = aircraft.frameSizeInch.map { String(format: "%.0f\"", $0) } ?? "5\""
            warnings.append(CompatibilityWarning(
                rule: "Motor KV / Voltage",
                level: .warning,
                detail: "\(kv) KV × \(String(format: "%.1f", nominalVoltage)) V = \(Int(noLoadRPM)) RPM (no-load). Recommended range for \(frameDesc): \(Int(minRPM))–\(Int(maxRPM)) RPM."
            ))
        }
    }

    // Rule 3: Battery max continuous discharge must meet total peak motor draw.
    private static func checkCRating(aircraft: Aircraft, linkedBattery: Battery?, into warnings: inout [CompatibilityWarning]) {
        guard let battery = linkedBattery,
              let cRating = battery.cRating,
              let capacityMah = battery.capacityMah,
              let motorMax = aircraft.motorMaxCurrentAmps else { return }

        let maxDischargeAmps = Double(cRating) * Double(capacityMah) / 1000.0
        let totalPeakDraw = Double(motorMax) * 4.0  // 4 motors

        if maxDischargeAmps < totalPeakDraw {
            warnings.append(CompatibilityWarning(
                rule: "Battery C-Rating",
                level: .warning,
                detail: "Battery can supply \(Int(maxDischargeAmps)) A (\(cRating)C × \(capacityMah) mAh) but motors may draw \(Int(totalPeakDraw)) A peak. Risk of pack sag, puffing, or damage."
            ))
        }
    }

    // Expected no-load RPM range by frame size (derived from spec §11.3 default for 5").
    static func kvVoltageRange(for frameSizeInch: Double?) -> (min: Double, max: Double) {
        guard let size = frameSizeInch else { return (18_000, 24_000) }
        switch size {
        case ..<3.0:          return (10_000, 16_000)
        case 3.0..<4.5:      return (14_000, 20_000)
        case 4.5..<6.0:      return (18_000, 24_000)
        case 6.0..<8.0:      return (20_000, 28_000)
        default:              return (22_000, 32_000)
        }
    }
}
