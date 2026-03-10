import XCTest
@testable import FPVGarage

final class RepositoryTests: XCTestCase {
    var service: FileStorageService!

    override func setUp() {
        super.setUp()
        service = FileStorageService()
    }

    override func tearDown() {
        let base = service.storageBaseURL
        for f in ["aircraft.json", "batteries.json", "flight_records.json", "parts.json"] {
            try? FileManager.default.removeItem(at: base.appendingPathComponent(f))
        }
        super.tearDown()
    }

    // MARK: - AircraftRepository

    func testAircraftRepoSaveAndLoad() {
        let repo = AircraftRepository(storage: service)
        let items = [Aircraft(name: "D1"), Aircraft(name: "D2")]
        repo.save(items)

        let loaded = repo.loadAll()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].name, "D1")
    }

    func testAircraftRepoEmptyLoad() {
        let repo = AircraftRepository(storage: service)
        try? FileManager.default.removeItem(at: service.storageBaseURL.appendingPathComponent("aircraft.json"))
        let loaded = repo.loadAll()
        XCTAssertTrue(loaded.isEmpty)
    }

    // MARK: - BatteryRepository

    func testBatteryRepoSaveAndLoad() {
        let repo = BatteryRepository(storage: service)
        repo.save([Battery(name: "Tattu")])

        let loaded = repo.loadAll()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].name, "Tattu")
    }

    func testBatteryRepoEmptyLoad() {
        let repo = BatteryRepository(storage: service)
        try? FileManager.default.removeItem(at: service.storageBaseURL.appendingPathComponent("batteries.json"))
        XCTAssertTrue(repo.loadAll().isEmpty)
    }

    // MARK: - FlightRepository

    func testFlightRepoSaveAndLoad() {
        let repo = FlightRepository(storage: service)
        repo.save([FlightRecord(aircraftId: UUID(), startAt: Date(), durationSeconds: 300)])

        let loaded = repo.loadAll()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].durationSeconds, 300)
    }

    func testFlightRepoEmptyLoad() {
        let repo = FlightRepository(storage: service)
        try? FileManager.default.removeItem(at: service.storageBaseURL.appendingPathComponent("flight_records.json"))
        XCTAssertTrue(repo.loadAll().isEmpty)
    }

    // MARK: - PartRepository

    func testPartRepoSaveAndLoad() {
        let repo = PartRepository(storage: service)
        repo.save([Part(name: "Motor", category: .motor, quantity: 4)])

        let loaded = repo.loadAll()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].name, "Motor")
    }

    func testPartRepoEmptyLoad() {
        let repo = PartRepository(storage: service)
        try? FileManager.default.removeItem(at: service.storageBaseURL.appendingPathComponent("parts.json"))
        XCTAssertTrue(repo.loadAll().isEmpty)
    }

    // MARK: - ImageRepository

    func testImageRepoSaveAndRetrieve() {
        let repo = ImageRepository(storage: service)
        let id = UUID()
        let data = Data([0xFF, 0xD8, 0xFF, 0xE0])

        let fileName = repo.saveImage(aircraftId: id, imageData: data)
        XCTAssertNotNil(fileName)
        XCTAssertTrue(fileName!.hasSuffix(".jpg"))

        let url = repo.imageURL(aircraftId: id, fileName: fileName)
        XCTAssertNotNil(url)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url!.path))

        repo.deleteImage(fileName: fileName)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url!.path))
    }

    func testImageRepoDeleteNilFileName() {
        let repo = ImageRepository(storage: service)
        repo.deleteImage(fileName: nil)
    }

    func testImageRepoURLNilFileName() {
        let repo = ImageRepository(storage: service)
        XCTAssertNil(repo.imageURL(aircraftId: UUID(), fileName: nil))
    }

    func testImageRepoURLNonExistentFile() {
        let repo = ImageRepository(storage: service)
        XCTAssertNil(repo.imageURL(aircraftId: UUID(), fileName: "nonexistent.jpg"))
    }
}
