import Foundation

struct ThrustToWeightResult {
    let ratio: Double
    let tier: TWRTier
    let flightStyle: FlightStyle
    let confidence: ThrustDataSource
}

struct CompatibilityWarning: Identifiable {
    let id: UUID
    let rule: String
    let level: CompatibilityWarningLevel
    let detail: String

    init(rule: String, level: CompatibilityWarningLevel, detail: String) {
        self.id = UUID()
        self.rule = rule
        self.level = level
        self.detail = detail
    }
}
