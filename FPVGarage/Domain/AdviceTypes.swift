import Foundation

struct ThrustToWeightResult {
    let ratio: Double
    let tier: TWRTier
    let flightStyle: FlightStyle
    let confidence: ThrustDataSource
}

struct CompatibilityWarning: Identifiable {
    /// Stable identity: each rule produces at most one warning, so the rule name
    /// is a stable id across view redraws (avoids regenerating UUIDs every render).
    var id: String { rule }
    let rule: String
    let level: CompatibilityWarningLevel
    let detail: String

    init(rule: String, level: CompatibilityWarningLevel, detail: String) {
        self.rule = rule
        self.level = level
        self.detail = detail
    }
}
