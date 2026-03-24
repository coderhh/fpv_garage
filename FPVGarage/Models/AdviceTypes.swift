import Foundation

// MARK: - Enums

enum FlightStyle: String, Codable, CaseIterable, Hashable {
    case freestyle
    case racing
    case cinematic
    case longRange
    case whoop

    var displayName: String {
        switch self {
        case .freestyle: return String(localized: "Freestyle")
        case .racing: return String(localized: "Racing")
        case .cinematic: return String(localized: "Cinematic")
        case .longRange: return String(localized: "Long Range")
        case .whoop: return String(localized: "Whoop")
        }
    }
}

enum PilotSkillLevel: String, Codable, CaseIterable, Hashable {
    case beginner
    case intermediate
    case advanced

    var displayName: String {
        switch self {
        case .beginner: return String(localized: "Beginner")
        case .intermediate: return String(localized: "Intermediate")
        case .advanced: return String(localized: "Advanced")
        }
    }
}

enum ThrustDataSource: String, Codable, CaseIterable, Hashable {
    case measured
    case specSheet
    case estimated

    var displayName: String {
        switch self {
        case .measured: return String(localized: "Measured")
        case .specSheet: return String(localized: "Spec Sheet")
        case .estimated: return String(localized: "Estimated")
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
        case .underpowered: return String(localized: "Underpowered")
        case .adequate: return String(localized: "Adequate")
        case .good: return String(localized: "Good")
        case .ideal: return String(localized: "Ideal")
        }
    }
}

enum CompatibilityWarningLevel: String, Codable, Hashable {
    case error
    case warning
    case info
}

// MARK: - Value Types

struct ThrustToWeightResult: Codable, Equatable, Hashable {
    var ratio: Double
    var tier: TWRTier
    var flightStyle: FlightStyle
    var confidence: ThrustDataSource
    var calculatedAt: Date
}

struct CompatibilityWarning: Codable, Equatable, Hashable, Identifiable {
    var id: UUID
    var rule: String
    var level: CompatibilityWarningLevel
    var detail: String

    init(
        id: UUID = UUID(),
        rule: String,
        level: CompatibilityWarningLevel,
        detail: String
    ) {
        self.id = id
        self.rule = rule
        self.level = level
        self.detail = detail
    }
}
