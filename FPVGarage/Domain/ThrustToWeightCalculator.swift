import Foundation

enum ThrustToWeightCalculator {
    static func calculate(aircraft: Aircraft, linkedBattery: Battery?) -> ThrustToWeightResult? {
        guard
            let thrustGrams = aircraft.motorThrustGrams,
            let auwGrams = aircraft.allUpWeightGrams,
            auwGrams > 0,
            let flightStyle = aircraft.flightStyle
        else { return nil }

        // Assume standard quad (4 motors). Total thrust at rated conditions.
        let totalThrust = Double(thrustGrams) * 4.0
        let ratio = totalThrust / Double(auwGrams)
        let tier = flightStyle.twrTier(for: ratio)
        let confidence = aircraft.motorThrustDataSource ?? .estimated

        return ThrustToWeightResult(
            ratio: ratio,
            tier: tier,
            flightStyle: flightStyle,
            confidence: confidence
        )
    }
}
