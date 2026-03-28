import Foundation

struct FleetContextBuilder {
    /// Build a FleetContextDTO from allowlisted fields only.
    /// Never includes GPS, remarks, photos, or PII.
    static func build(
        aircraft: Aircraft,
        battery: Battery?,
        twrResult: ThrustToWeightResult?,
        compatWarnings: [CompatibilityWarning],
        partCountsByCategory: [String: Int]
    ) -> FleetContextDTO {
        FleetContextDTO(
            aircraftName: aircraft.name,
            flightStyle: aircraft.flightStyle,
            pilotSkillLevel: aircraft.pilotSkillLevel,
            frameSizeInch: aircraft.frameSizeInch,
            motorModel: aircraft.motorModel,
            motorKv: aircraft.motorKv,
            propSize: aircraft.propSize,
            twrRatio: twrResult?.ratio,
            twrTier: twrResult?.tier,
            batteryCells: aircraft.batteryCellCount ?? battery?.cells,
            batteryCapacityMah: battery?.capacityMah,
            partCountsByCategory: partCountsByCategory,
            compatibilityWarningSummary: compatWarnings.map { $0.detail },
            deviceLocale: Locale.current.language.languageCode?.identifier ?? "en"
        )
    }
}
