import Foundation

// MARK: - LLM Response Types

struct AdviceResponse: Codable, Equatable, Hashable {
    var configSummary: String
    var strengths: [String]
    var improvements: [String]
    var twrComment: String?
    var compatibilityNotes: [String]
    var partSuggestions: [PartSuggestion]?
}

struct PartSuggestion: Codable, Equatable, Hashable, Identifiable {
    var id: UUID
    var name: String
    var reason: String
    var priority: SuggestionPriority
    var hallucinationDisclaimer: Bool

    init(
        id: UUID = UUID(),
        name: String,
        reason: String,
        priority: SuggestionPriority,
        hallucinationDisclaimer: Bool = true
    ) {
        self.id = id
        self.name = name
        self.reason = reason
        self.priority = priority
        self.hallucinationDisclaimer = hallucinationDisclaimer
    }
}

enum SuggestionPriority: String, Codable, Hashable {
    case high, medium, low
}

// MARK: - Fleet Context (allowlisted data sent to LLM)

struct FleetContextDTO: Codable, Equatable, Hashable {
    var aircraftName: String
    var flightStyle: FlightStyle?
    var pilotSkillLevel: PilotSkillLevel?
    var frameSizeInch: Double?
    var motorModel: String?
    var motorKv: Int?
    var propSize: String?
    var twrRatio: Double?
    var twrTier: TWRTier?
    var batteryCells: Int?
    var batteryCapacityMah: Int?
    var partCountsByCategory: [String: Int]
    var compatibilityWarningSummary: [String]
    var deviceLocale: String
}

// MARK: - Advice Session (persisted per aircraft)

struct AdviceSession: Codable, Equatable, Hashable, Identifiable {
    var id: UUID
    var aircraftId: UUID
    var generatedAt: Date
    var configHash: String
    var contextSnapshot: FleetContextDTO
    var thrustToWeightResult: ThrustToWeightResult?
    var compatibilityWarnings: [CompatibilityWarning]
    var response: AdviceResponse

    init(
        id: UUID = UUID(),
        aircraftId: UUID,
        generatedAt: Date = Date(),
        configHash: String,
        contextSnapshot: FleetContextDTO,
        thrustToWeightResult: ThrustToWeightResult? = nil,
        compatibilityWarnings: [CompatibilityWarning] = [],
        response: AdviceResponse
    ) {
        self.id = id
        self.aircraftId = aircraftId
        self.generatedAt = generatedAt
        self.configHash = configHash
        self.contextSnapshot = contextSnapshot
        self.thrustToWeightResult = thrustToWeightResult
        self.compatibilityWarnings = compatibilityWarnings
        self.response = response
    }
}
