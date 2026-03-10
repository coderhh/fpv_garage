import XCTest
@testable import FPVGarage

final class FileStorageServiceTests: XCTestCase {
    var service: FileStorageService!
    private let testFile = "test_\(UUID().uuidString).json"

    override func setUp() {
        super.setUp()
        service = FileStorageService()
    }

    override func tearDown() {
        let url = service.storageBaseURL.appendingPathComponent(testFile)
        try? FileManager.default.removeItem(at: url)
        super.tearDown()
    }

    func testStorageBaseURLNotEmpty() {
        XCTAssertFalse(service.storageBaseURL.path.isEmpty)
    }

    func testLocalBaseURLContainsDocuments() {
        XCTAssertTrue(service.localBaseURL.path.contains("FPVGarage"))
    }

    func testAircraftImagesURLCreated() {
        let url = service.aircraftImagesURL
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(url.path.contains("aircraft_images"))
    }

    func testEnsureDirectoryCreatesNew() {
        let dir = service.storageBaseURL.appendingPathComponent("test_dir_\(UUID().uuidString)")
        service.ensureDirectory(dir)
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir.path))
        try? FileManager.default.removeItem(at: dir)
    }

    func testEnsureDirectoryExisting() {
        service.ensureDirectory(service.storageBaseURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: service.storageBaseURL.path))
    }

    func testSaveAndLoad() {
        let items = [Aircraft(name: "TestA"), Aircraft(name: "TestB")]
        service.save(items, to: testFile)

        let loaded: [Aircraft]? = service.load([Aircraft].self, from: testFile)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, 2)
        XCTAssertEqual(loaded?[0].name, "TestA")
    }

    func testLoadNonExistentReturnsNil() {
        let result: [Aircraft]? = service.load([Aircraft].self, from: "nonexistent_\(UUID()).json")
        XCTAssertNil(result)
    }

    func testSaveEmptyArray() {
        let empty: [Battery] = []
        service.save(empty, to: testFile)

        let loaded: [Battery]? = service.load([Battery].self, from: testFile)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, 0)
    }

    func testSaveOverwrites() {
        service.save([Part(name: "Old", category: .frame)], to: testFile)
        service.save([Part(name: "New", category: .motor)], to: testFile)

        let loaded: [Part]? = service.load([Part].self, from: testFile)
        XCTAssertEqual(loaded?.count, 1)
        XCTAssertEqual(loaded?[0].name, "New")
    }

    func testSaveBatteries() {
        service.save([Battery(name: "B1", capacityMah: 1300)], to: testFile)
        let loaded: [Battery]? = service.load([Battery].self, from: testFile)
        XCTAssertEqual(loaded?[0].capacityMah, 1300)
    }

    func testSaveFlightRecords() {
        let f = FlightRecord(aircraftId: UUID(), startAt: Date(), durationSeconds: 480)
        service.save([f], to: testFile)
        let loaded: [FlightRecord]? = service.load([FlightRecord].self, from: testFile)
        XCTAssertEqual(loaded?[0].durationSeconds, 480)
    }

    func testSaveParts() {
        let p = Part(name: "Motor", category: .motor, quantity: 4)
        service.save([p], to: testFile)
        let loaded: [Part]? = service.load([Part].self, from: testFile)
        XCTAssertEqual(loaded?[0].quantity, 4)
    }
}
