import Foundation

enum FlightStyle: String, Codable, CaseIterable, Hashable {
    case freestyle
    case racing
    case cinematic
    case longRange
    case whoop

    var displayName: String {
        switch self {
        case .freestyle:  return String(localized: "Freestyle")
        case .racing:     return String(localized: "Racing")
        case .cinematic:  return String(localized: "Cinematic")
        case .longRange:  return String(localized: "Long Range")
        case .whoop:      return String(localized: "Whoop")
        }
    }

    // TWR tier thresholds: (adequate, good, ideal)
    var twrThresholds: (adequate: Double, good: Double, ideal: Double) {
        switch self {
        case .freestyle:  return (4.0, 5.5, 8.0)
        case .racing:     return (6.0, 8.0, 10.0)
        case .cinematic:  return (3.0, 4.5, 6.0)
        case .longRange:  return (2.5, 3.5, 5.0)
        case .whoop:      return (2.0, 3.0, 4.0)
        }
    }

    func twrTier(for ratio: Double) -> TWRTier {
        let t = twrThresholds
        if ratio >= t.ideal    { return .ideal }
        if ratio >= t.good     { return .good }
        if ratio >= t.adequate { return .adequate }
        return .underpowered
    }
}

enum PilotSkillLevel: String, Codable, CaseIterable, Hashable {
    case beginner
    case intermediate
    case advanced

    var displayName: String {
        switch self {
        case .beginner:     return String(localized: "Beginner")
        case .intermediate: return String(localized: "Intermediate")
        case .advanced:     return String(localized: "Advanced")
        }
    }
}

enum ThrustDataSource: String, Codable, CaseIterable, Hashable {
    case measured
    case specSheet
    case estimated

    var displayName: String {
        switch self {
        case .measured:   return String(localized: "Measured (Thrust Stand)")
        case .specSheet:  return String(localized: "Spec Sheet")
        case .estimated:  return String(localized: "Estimated")
        }
    }

    var confidenceLabel: String {
        switch self {
        case .measured:   return String(localized: "High confidence")
        case .specSheet:  return String(localized: "Medium confidence (±15–20%)")
        case .estimated:  return String(localized: "Low confidence (estimated)")
        }
    }
}

enum TWRTier: String, Codable, Hashable {
    case underpowered
    case adequate
    case good
    case ideal

    var displayName: String {
        switch self {
        case .underpowered: return String(localized: "Under-powered")
        case .adequate:     return String(localized: "Adequate")
        case .good:         return String(localized: "Good")
        case .ideal:        return String(localized: "Ideal")
        }
    }
}

enum CompatibilityWarningLevel: String, Codable, Hashable {
    case error
    case warning
    case info
}
