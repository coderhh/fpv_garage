import Foundation
import CryptoKit

struct ConfigHashCalculator {
    static func hash(aircraft: Aircraft, battery: Battery?) -> String {
        var input = ""
        input += "\(aircraft.motorKv ?? 0):"
        input += "\(aircraft.motorThrustGrams ?? 0):"
        input += "\(aircraft.allUpWeightGrams ?? 0):"
        input += "\(aircraft.flightStyle?.rawValue ?? ""):"
        input += "\(aircraft.frameSizeInch ?? 0):"
        input += "\(aircraft.propSize ?? ""):"
        input += "\(aircraft.batteryCellCount ?? battery?.cells ?? 0):"
        input += "\(battery?.capacityMah ?? 0)"

        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
