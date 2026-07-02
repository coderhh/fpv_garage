import XCTest
@testable import FPVGarage

final class AircraftBatteryResolverTests: XCTestCase {

    private let now = Date()
    private func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: now)!
    }

    // MARK: - Resolution

    func testNilWhenNoFlights() {
        let a = Aircraft(name: "Quad")
        let result = AircraftBatteryResolver.mostRecentBattery(for: a, flightRecords: [], batteries: [])
        XCTAssertNil(result)
    }

    func testNilWhenAircraftHasNoFlights() {
        let a = Aircraft(name: "Quad")
        let other = Aircraft(name: "Other")
        let battery = Battery(name: "6S")
        let flight = FlightRecord(aircraftId: other.id, batteryIds: [battery.id], startAt: now, durationSeconds: 100)
        let result = AircraftBatteryResolver.mostRecentBattery(for: a, flightRecords: [flight], batteries: [battery])
        XCTAssertNil(result)
    }

    func testResolvesBatteryFromFlight() {
        let a = Aircraft(name: "Quad")
        let battery = Battery(name: "6S 1300")
        let flight = FlightRecord(aircraftId: a.id, batteryIds: [battery.id], startAt: now, durationSeconds: 100)
        let result = AircraftBatteryResolver.mostRecentBattery(for: a, flightRecords: [flight], batteries: [battery])
        XCTAssertEqual(result?.id, battery.id)
    }

    func testResolvesMostRecentFlightBattery() {
        let a = Aircraft(name: "Quad")
        let oldBattery = Battery(name: "Old")
        let newBattery = Battery(name: "New")
        let oldFlight = FlightRecord(aircraftId: a.id, batteryIds: [oldBattery.id], startAt: daysAgo(5), durationSeconds: 100)
        let newFlight = FlightRecord(aircraftId: a.id, batteryIds: [newBattery.id], startAt: daysAgo(1), durationSeconds: 100)
        // Order in array intentionally not chronological.
        let result = AircraftBatteryResolver.mostRecentBattery(
            for: a,
            flightRecords: [oldFlight, newFlight],
            batteries: [oldBattery, newBattery]
        )
        XCTAssertEqual(result?.id, newBattery.id)
    }

    func testSkipsFlightsWithNoBattery() {
        let a = Aircraft(name: "Quad")
        let battery = Battery(name: "6S")
        // Most recent flight logged no battery; should fall back to the earlier one.
        let withBattery = FlightRecord(aircraftId: a.id, batteryIds: [battery.id], startAt: daysAgo(3), durationSeconds: 100)
        let noBattery = FlightRecord(aircraftId: a.id, batteryIds: [], startAt: daysAgo(1), durationSeconds: 100)
        let result = AircraftBatteryResolver.mostRecentBattery(
            for: a,
            flightRecords: [withBattery, noBattery],
            batteries: [battery]
        )
        XCTAssertEqual(result?.id, battery.id)
    }

    func testNilWhenBatteryDeleted() {
        let a = Aircraft(name: "Quad")
        let missingId = UUID()
        let flight = FlightRecord(aircraftId: a.id, batteryIds: [missingId], startAt: now, durationSeconds: 100)
        // Battery referenced by the flight no longer exists in the store.
        let result = AircraftBatteryResolver.mostRecentBattery(for: a, flightRecords: [flight], batteries: [])
        XCTAssertNil(result)
    }

    func testIgnoresOtherAircraftFlights() {
        let a = Aircraft(name: "Quad")
        let other = Aircraft(name: "Other")
        let myBattery = Battery(name: "Mine")
        let otherBattery = Battery(name: "Theirs")
        let myFlight = FlightRecord(aircraftId: a.id, batteryIds: [myBattery.id], startAt: daysAgo(5), durationSeconds: 100)
        // Other aircraft's flight is more recent but must be ignored.
        let otherFlight = FlightRecord(aircraftId: other.id, batteryIds: [otherBattery.id], startAt: daysAgo(1), durationSeconds: 100)
        let result = AircraftBatteryResolver.mostRecentBattery(
            for: a,
            flightRecords: [myFlight, otherFlight],
            batteries: [myBattery, otherBattery]
        )
        XCTAssertEqual(result?.id, myBattery.id)
    }

    // MARK: - End-to-end: the resolved battery is the one used for compatibility checks

    func testResolvedBatteryDrivesCRatingCheck() {
        // Aircraft's own flight used a weak battery (low C-rating) → warning expected.
        let weakBattery = Battery(name: "Weak", capacityMah: 1300, cRating: 25)
        // An unrelated, strong battery exists in the store and must NOT be used.
        let strongUnrelated = Battery(name: "Strong", capacityMah: 1300, cRating: 100)
        let a = Aircraft(name: "Quad", motorMaxCurrentAmps: 15)
        let flight = FlightRecord(aircraftId: a.id, batteryIds: [weakBattery.id], startAt: Date(), durationSeconds: 100)

        let resolved = AircraftBatteryResolver.mostRecentBattery(
            for: a,
            flightRecords: [flight],
            batteries: [strongUnrelated, weakBattery]
        )
        XCTAssertEqual(resolved?.id, weakBattery.id)

        let warnings = CompatibilityChecker.check(aircraft: a, linkedBattery: resolved)
        XCTAssertTrue(warnings.contains { $0.rule == "Battery C-Rating" })
    }

    func testUnrelatedBatteryDoesNotLeakIntoCheck() {
        // Aircraft has no flights, so no battery is resolved even though a weak
        // battery exists in the store → no false C-rating warning.
        let weakUnrelated = Battery(name: "Weak", capacityMah: 1300, cRating: 25)
        let a = Aircraft(name: "Quad", motorMaxCurrentAmps: 15)

        let resolved = AircraftBatteryResolver.mostRecentBattery(
            for: a,
            flightRecords: [],
            batteries: [weakUnrelated]
        )
        XCTAssertNil(resolved)

        let warnings = CompatibilityChecker.check(aircraft: a, linkedBattery: resolved)
        XCTAssertFalse(warnings.contains { $0.rule == "Battery C-Rating" })
    }
}
