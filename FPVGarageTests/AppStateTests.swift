import XCTest
@testable import FPVGarage

final class AppStateTests: XCTestCase {
    var appState: AppState!
    var aircraftRepo: MockAircraftRepository!
    var batteryRepo: MockBatteryRepository!
    var flightRepo: MockFlightRepository!
    var partRepo: MockPartRepository!
    var imageStorage: MockImageStorage!

    override func setUp() {
        super.setUp()
        aircraftRepo = MockAircraftRepository()
        batteryRepo = MockBatteryRepository()
        flightRepo = MockFlightRepository()
        partRepo = MockPartRepository()
        imageStorage = MockImageStorage()
        appState = AppState(
            aircraftRepo: aircraftRepo,
            batteryRepo: batteryRepo,
            flightRepo: flightRepo,
            partRepo: partRepo,
            imageStorage: imageStorage
        )
    }

    // MARK: - Aircraft CRUD

    func testAddAircraft() {
        appState.addAircraft(Aircraft(name: "Drone"))
        XCTAssertEqual(appState.aircraft.count, 1)
        XCTAssertEqual(aircraftRepo.items.count, 1)
    }

    func testUpdateAircraft() {
        var a = Aircraft(name: "Old")
        appState.addAircraft(a)
        a.name = "New"
        appState.updateAircraft(a)
        XCTAssertEqual(appState.aircraft.first?.name, "New")
        XCTAssertEqual(aircraftRepo.items.first?.name, "New")
    }

    func testUpdateAircraftNotFound() {
        appState.updateAircraft(Aircraft(name: "Ghost"))
        XCTAssertTrue(appState.aircraft.isEmpty)
    }

    func testFindAircraft() {
        let id = UUID()
        appState.addAircraft(Aircraft(id: id, name: "Find Me"))
        XCTAssertNotNil(appState.findAircraft(by: id))
        XCTAssertNil(appState.findAircraft(by: UUID()))
    }

    func testDeleteAircraftWithParts() {
        let a = Aircraft(name: "Drone", imageFileName: "img.jpg")
        appState.addAircraft(a)
        appState.addPart(Part(name: "Motor", category: .motor, sourceAircraftId: a.id))
        appState.addPart(Part(name: "Frame", category: .frame, sourceAircraftId: a.id))
        appState.addPart(Part(name: "Loose", category: .esc))

        appState.deleteAircraftWithParts(a)

        XCTAssertTrue(appState.aircraft.isEmpty)
        XCTAssertEqual(appState.parts.count, 1)
        XCTAssertEqual(appState.parts.first?.name, "Loose")
        XCTAssertTrue(imageStorage.deletedFiles.contains("img.jpg"))
    }

    func testDeleteAircraftKeepParts() {
        let a = Aircraft(name: "Drone", imageFileName: "img.jpg")
        appState.addAircraft(a)
        appState.addPart(Part(name: "Motor", category: .motor, sourceAircraftId: a.id))

        appState.deleteAircraftKeepParts(a)

        XCTAssertTrue(appState.aircraft.isEmpty)
        XCTAssertEqual(appState.parts.count, 1)
        XCTAssertNil(appState.parts.first?.sourceAircraftId)
        XCTAssertTrue(imageStorage.deletedFiles.contains("img.jpg"))
    }

    func testDeleteAircraftNoImage() {
        let a = Aircraft(name: "Drone")
        appState.addAircraft(a)
        appState.deleteAircraftWithParts(a)
        XCTAssertTrue(imageStorage.deletedFiles.isEmpty)
    }

    // MARK: - Battery CRUD

    func testAddBattery() {
        appState.addBattery(Battery(name: "Tattu"))
        XCTAssertEqual(appState.batteries.count, 1)
        XCTAssertEqual(batteryRepo.items.count, 1)
    }

    func testUpdateBattery() {
        var b = Battery(name: "Old")
        appState.addBattery(b)
        b.name = "Updated"
        appState.updateBattery(b)
        XCTAssertEqual(appState.batteries.first?.name, "Updated")
    }

    func testUpdateBatteryNotFound() {
        appState.updateBattery(Battery(name: "Ghost"))
        XCTAssertTrue(appState.batteries.isEmpty)
    }

    func testDeleteBattery() {
        let b = Battery(name: "Delete Me")
        appState.addBattery(b)
        appState.deleteBattery(b)
        XCTAssertTrue(appState.batteries.isEmpty)
        XCTAssertTrue(batteryRepo.items.isEmpty)
    }

    func testFindBatteries() {
        let id1 = UUID(), id2 = UUID()
        appState.addBattery(Battery(id: id1, name: "B1"))
        appState.addBattery(Battery(id: id2, name: "B2"))
        appState.addBattery(Battery(name: "B3"))

        let found = appState.findBatteries(by: [id1, id2])
        XCTAssertEqual(found.count, 2)
    }

    func testFindBatteriesEmpty() {
        XCTAssertTrue(appState.findBatteries(by: [UUID()]).isEmpty)
    }

    // MARK: - Flight CRUD

    func testAddFlight() {
        appState.addFlight(FlightRecord(aircraftId: UUID(), startAt: Date(), durationSeconds: 300))
        XCTAssertEqual(appState.flightRecords.count, 1)
        XCTAssertEqual(flightRepo.items.count, 1)
    }

    func testUpdateFlight() {
        var f = FlightRecord(aircraftId: UUID(), startAt: Date(), durationSeconds: 300)
        appState.addFlight(f)
        f.durationSeconds = 600
        appState.updateFlight(f)
        XCTAssertEqual(appState.flightRecords.first?.durationSeconds, 600)
    }

    func testUpdateFlightNotFound() {
        appState.updateFlight(FlightRecord(aircraftId: UUID(), startAt: Date(), durationSeconds: 300))
        XCTAssertTrue(appState.flightRecords.isEmpty)
    }

    func testDeleteFlight() {
        let f = FlightRecord(aircraftId: UUID(), startAt: Date(), durationSeconds: 300)
        appState.addFlight(f)
        appState.deleteFlight(f)
        XCTAssertTrue(appState.flightRecords.isEmpty)
    }

    // MARK: - Part CRUD

    func testAddPart() {
        appState.addPart(Part(name: "Frame", category: .frame))
        XCTAssertEqual(appState.parts.count, 1)
        XCTAssertEqual(partRepo.items.count, 1)
    }

    func testUpdatePart() {
        var p = Part(name: "Old", category: .frame)
        appState.addPart(p)
        p.name = "New"
        appState.updatePart(p)
        XCTAssertEqual(appState.parts.first?.name, "New")
    }

    func testUpdatePartNotFound() {
        appState.updatePart(Part(name: "Ghost", category: .frame))
        XCTAssertTrue(appState.parts.isEmpty)
    }

    func testDeletePart() {
        let p = Part(name: "Delete Me", category: .motor)
        appState.addPart(p)
        appState.deletePart(p)
        XCTAssertTrue(appState.parts.isEmpty)
    }

    // MARK: - SyncParts

    func testSyncPartsFromSetup() {
        let a = Aircraft(name: "Drone", setup: AircraftSetup(frame: "Apex", motor: "2306", esc: "35A"))
        appState.syncParts(for: a)
        XCTAssertEqual(appState.parts.count, 3)
        XCTAssertTrue(appState.parts.allSatisfy { $0.sourceAircraftId == a.id })
    }

    func testSyncPartsEmptySetup() {
        appState.syncParts(for: Aircraft(name: "Drone"))
        XCTAssertTrue(appState.parts.isEmpty)
    }

    func testSyncPartsNilSetup() {
        appState.syncParts(for: Aircraft(name: "Drone", setup: nil))
        XCTAssertTrue(appState.parts.isEmpty)
    }

    func testSyncPartsReplacesExisting() {
        let a = Aircraft(name: "Drone", setup: AircraftSetup(frame: "Apex"))
        appState.syncParts(for: a)
        XCTAssertEqual(appState.parts.count, 1)

        var updated = a
        updated.setup = AircraftSetup(frame: "New Frame", motor: "New Motor")
        appState.syncParts(for: updated)
        XCTAssertEqual(appState.parts.count, 2)
    }

    func testSyncPartsFullSetup() {
        let a = Aircraft(name: "Full", setup: AircraftSetup(
            frame: "F", motor: "M", esc: "E", flightController: "FC",
            camera: "C", vtx: "V", receiver: "R", propeller: "P", other: "O"
        ))
        appState.syncParts(for: a)
        XCTAssertEqual(appState.parts.count, 9)
    }

    func testSyncPartsWhitespaceIgnored() {
        let a = Aircraft(name: "Drone", setup: AircraftSetup(frame: "  ", motor: ""))
        appState.syncParts(for: a)
        XCTAssertTrue(appState.parts.isEmpty)
    }

    func testSyncPartsDoesNotAffectOtherAircraft() {
        let a1 = Aircraft(name: "A1", setup: AircraftSetup(frame: "F1"))
        let a2 = Aircraft(name: "A2", setup: AircraftSetup(frame: "F2"))
        appState.syncParts(for: a1)
        appState.syncParts(for: a2)
        XCTAssertEqual(appState.parts.count, 2)

        appState.syncParts(for: a1)
        XCTAssertEqual(appState.parts.count, 2)
    }

    // MARK: - Seed Test Data

    func testSeedTestData() {
        appState.seedTestData()
        XCTAssertEqual(appState.aircraft.count, 2)
        XCTAssertEqual(appState.batteries.count, 3)
        XCTAssertEqual(appState.flightRecords.count, 5)
        XCTAssertFalse(appState.parts.isEmpty)
    }

    // MARK: - LoadAll

    func testLoadAllReadsFromRepos() {
        aircraftRepo.items = [Aircraft(name: "Preloaded")]
        batteryRepo.items = [Battery(name: "B1")]
        flightRepo.items = [FlightRecord(aircraftId: UUID(), startAt: Date(), durationSeconds: 100)]
        partRepo.items = [Part(name: "P1", category: .frame)]

        appState.loadAll()

        XCTAssertEqual(appState.aircraft.count, 1)
        XCTAssertEqual(appState.batteries.count, 1)
        XCTAssertEqual(appState.flightRecords.count, 1)
        XCTAssertEqual(appState.parts.count, 1)
    }

    func testLoadAllEmptyRepos() {
        appState.addAircraft(Aircraft(name: "A"))
        aircraftRepo.items = []
        appState.loadAll()
        XCTAssertTrue(appState.aircraft.isEmpty)
    }
}
