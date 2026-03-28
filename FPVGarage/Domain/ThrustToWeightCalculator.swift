import Foundation

struct ThrustToWeightCalculator {

    /// Flight-style-relative TWR tier thresholds.
    /// Returns (adequate, good, ideal) lower bounds; anything below adequate is underpowered.
    private static func thresholds(for style: FlightStyle) -> (adequate: Double, good: Double, ideal: Double) {
        switch style {
        case .freestyle:  return (4.0, 5.5, 8.0)
        case .racing:     return (6.0, 8.0, 10.0)
        case .cinematic:  return (3.0, 4.5, 6.0)
        case .longRange:  return (2.5, 3.5, 5.0)
        case .whoop:      return (2.0, 3.0, 4.0)
        }
    }

    static func tier(ratio: Double, flightStyle: FlightStyle) -> TWRTier {
        let t = thresholds(for: flightStyle)
        if ratio >= t.ideal { return .ideal }
        if ratio >= t.good { return .good }
        if ratio >= t.adequate { return .adequate }
        return .underpowered
    }

    static func calculate(
        motorThrustGrams: Int,
        motorCount: Int = 4,
        allUpWeightGrams: Int,
        flightStyle: FlightStyle,
        thrustDataSource: ThrustDataSource
    ) -> ThrustToWeightResult? {
        guard allUpWeightGrams > 0, motorThrustGrams > 0 else { return nil }
        let ratio = Double(motorThrustGrams * motorCount) / Double(allUpWeightGrams)
        return ThrustToWeightResult(
            ratio: ratio,
            tier: tier(ratio: ratio, flightStyle: flightStyle),
            flightStyle: flightStyle,
            confidence: thrustDataSource,
            calculatedAt: Date()
        )
    }

    /// Convenience: extract fields from Aircraft (+ optional Battery for cell count fallback).
    static func calculate(from aircraft: Aircraft, battery: Battery? = nil) -> ThrustToWeightResult? {
        guard let thrust = aircraft.motorThrustGrams,
              let auw = aircraft.allUpWeightGrams,
              let style = aircraft.flightStyle,
              let source = aircraft.motorThrustDataSource else {
            return nil
        }
        return calculate(
            motorThrustGrams: thrust,
            allUpWeightGrams: auw,
            flightStyle: style,
            thrustDataSource: source
        )
    }
}
