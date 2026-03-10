import XCTest
import UniformTypeIdentifiers
@testable import FPVGarage

final class AllDataDocumentTests: XCTestCase {

    func testReadableContentTypes() {
        XCTAssertEqual(AllDataDocument.readableContentTypes, [.json])
    }

    func testSnapshotInit() {
        let snapshot = AllDataSnapshot(
            aircraft: [Aircraft(name: "A")],
            batteries: [Battery(name: "B")],
            flights: [FlightRecord(aircraftId: UUID(), startAt: Date(), durationSeconds: 100)],
            parts: [Part(name: "P", category: .frame)]
        )
        let doc = AllDataDocument(snapshot: snapshot)
        XCTAssertEqual(doc.snapshot.aircraft.count, 1)
        XCTAssertEqual(doc.snapshot.batteries.count, 1)
        XCTAssertEqual(doc.snapshot.flights.count, 1)
        XCTAssertEqual(doc.snapshot.parts.count, 1)
    }

    func testSnapshotCodableRoundTrip() throws {
        let snapshot = AllDataSnapshot(
            aircraft: [Aircraft(name: "Test")],
            batteries: [Battery(name: "B")],
            flights: [],
            parts: [Part(name: "P", category: .motor)]
        )
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(AllDataSnapshot.self, from: data)

        XCTAssertEqual(decoded.aircraft.count, 1)
        XCTAssertEqual(decoded.aircraft.first?.name, "Test")
        XCTAssertEqual(decoded.batteries.count, 1)
        XCTAssertEqual(decoded.parts.count, 1)
    }

    func testEmptySnapshot() throws {
        let snapshot = AllDataSnapshot(aircraft: [], batteries: [], flights: [], parts: [])
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(AllDataSnapshot.self, from: data)
        XCTAssertTrue(decoded.aircraft.isEmpty)
        XCTAssertTrue(decoded.batteries.isEmpty)
        XCTAssertTrue(decoded.flights.isEmpty)
        XCTAssertTrue(decoded.parts.isEmpty)
    }

    func testSnapshotWithAllData() throws {
        let aId = UUID()
        let bId = UUID()
        let snapshot = AllDataSnapshot(
            aircraft: [Aircraft(id: aId, name: "Drone", setup: AircraftSetup(frame: "F"))],
            batteries: [Battery(id: bId, name: "Tattu", capacityMah: 1300, cells: 6)],
            flights: [FlightRecord(aircraftId: aId, batteryIds: [bId], startAt: Date(),
                                   durationSeconds: 300, address: "Park",
                                   latitude: 39.9, longitude: 116.4)],
            parts: [Part(name: "Frame", category: .frame, sourceAircraftId: aId)]
        )
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(AllDataSnapshot.self, from: data)

        XCTAssertEqual(decoded.aircraft.first?.id, aId)
        XCTAssertEqual(decoded.batteries.first?.id, bId)
        XCTAssertEqual(decoded.flights.first?.aircraftId, aId)
        XCTAssertEqual(decoded.parts.first?.sourceAircraftId, aId)
    }
}
