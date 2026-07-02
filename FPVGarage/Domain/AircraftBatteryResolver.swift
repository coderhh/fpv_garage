import Foundation

enum AircraftBatteryResolver {
    /// Resolves the battery associated with an aircraft.
    ///
    /// There is no direct aircraft->battery link in the data model, so the
    /// battery from the aircraft's most recent flight record is the only real
    /// association. Returns nil when the aircraft has no flight that logged a
    /// battery, or when that battery no longer exists.
    static func mostRecentBattery(
        for aircraft: Aircraft,
        flightRecords: [FlightRecord],
        batteries: [Battery]
    ) -> Battery? {
        let batteryId = flightRecords
            .filter { $0.aircraftId == aircraft.id && !$0.batteryIds.isEmpty }
            .sorted { $0.startAt > $1.startAt }
            .first?
            .batteryIds.first
        guard let batteryId else { return nil }
        return batteries.first { $0.id == batteryId }
    }
}
