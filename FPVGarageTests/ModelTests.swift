import XCTest
@testable import FPVGarage

final class ModelTests: XCTestCase {

    // MARK: - AircraftSetup

    func testAircraftSetupEmpty() {
        XCTAssertTrue(AircraftSetup.empty.isEmpty)
    }

    func testAircraftSetupNotEmpty() {
        XCTAssertFalse(AircraftSetup(frame: "Apex").isEmpty)
    }

    func testAircraftSetupWhitespaceIsEmpty() {
        XCTAssertTrue(AircraftSetup(frame: "  ", motor: "").isEmpty)
    }

    func testAircraftSetupAllFieldsNotEmpty() {
        let s = AircraftSetup(frame: "F", motor: "M", esc: "E", flightController: "FC",
                              camera: "C", vtx: "V", receiver: "R", propeller: "P", other: "O")
        XCTAssertFalse(s.isEmpty)
    }

    // MARK: - Aircraft

    func testAircraftSetupOrEmpty() {
        let a = Aircraft(name: "Test")
        XCTAssertTrue(a.setupOrEmpty.isEmpty)

        let b = Aircraft(name: "Test", setup: AircraftSetup(frame: "X"))
        XCTAssertFalse(b.setupOrEmpty.isEmpty)
    }

    func testAircraftDefaultValues() {
        let a = Aircraft(name: "Drone")
        XCTAssertEqual(a.name, "Drone")
        XCTAssertNil(a.model)
        XCTAssertNil(a.imageFileName)
        XCTAssertNil(a.setup)
        XCTAssertNil(a.remark)
        XCTAssertNil(a.flightStyle)
        XCTAssertNil(a.pilotSkillLevel)
        XCTAssertNil(a.frameSizeInch)
        XCTAssertNil(a.motorModel)
        XCTAssertNil(a.motorKv)
        XCTAssertNil(a.motorThrustGrams)
        XCTAssertNil(a.motorThrustDataSource)
        XCTAssertNil(a.propSize)
        XCTAssertNil(a.allUpWeightGrams)
        XCTAssertNil(a.batteryCellCount)
    }

    func testAircraftCodable() throws {
        let original = Aircraft(name: "Test", model: "Custom",
                                setup: AircraftSetup(frame: "F", motor: "M"), remark: "Note")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Aircraft.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testAircraftEquatable() {
        let id = UUID()
        let date = Date()
        let a = Aircraft(id: id, name: "A", createdAt: date, updatedAt: date)
        let b = Aircraft(id: id, name: "A", createdAt: date, updatedAt: date)
        XCTAssertEqual(a, b)
    }

    func testAircraftCodableWithPerformanceData() throws {
        let original = Aircraft(
            name: "Test", model: "Custom",
            setup: AircraftSetup(frame: "F"),
            flightStyle: .freestyle,
            pilotSkillLevel: .advanced,
            frameSizeInch: 5.0,
            motorModel: "T-Motor",
            motorKv: 1950,
            motorThrustGrams: 500,
            motorThrustDataSource: .specSheet,
            propSize: "51466",
            allUpWeightGrams: 650,
            batteryCellCount: 6
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Aircraft.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testAircraftBackwardCompatibility() throws {
        // JSON from before performance data fields existed
        let json = """
        {"id":"00000000-0000-0000-0000-000000000001","name":"Old","createdAt":0,"updatedAt":0}
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let a = try decoder.decode(Aircraft.self, from: Data(json.utf8))
        XCTAssertEqual(a.name, "Old")
        XCTAssertNil(a.flightStyle)
        XCTAssertNil(a.motorKv)
        XCTAssertNil(a.allUpWeightGrams)
    }

    // MARK: - FlightStyle

    func testFlightStyleCodable() throws {
        for style in FlightStyle.allCases {
            let data = try JSONEncoder().encode(style)
            let decoded = try JSONDecoder().decode(FlightStyle.self, from: data)
            XCTAssertEqual(style, decoded)
        }
    }

    func testFlightStyleAllCases() {
        XCTAssertEqual(FlightStyle.allCases.count, 5)
    }

    // MARK: - PilotSkillLevel

    func testPilotSkillLevelCodable() throws {
        for level in PilotSkillLevel.allCases {
            let data = try JSONEncoder().encode(level)
            let decoded = try JSONDecoder().decode(PilotSkillLevel.self, from: data)
            XCTAssertEqual(level, decoded)
        }
    }

    // MARK: - ThrustDataSource

    func testThrustDataSourceCodable() throws {
        for src in ThrustDataSource.allCases {
            let data = try JSONEncoder().encode(src)
            let decoded = try JSONDecoder().decode(ThrustDataSource.self, from: data)
            XCTAssertEqual(src, decoded)
        }
    }

    // MARK: - ThrustToWeightResult

    func testThrustToWeightResultCodable() throws {
        let original = ThrustToWeightResult(ratio: 5.5, tier: .good, flightStyle: .freestyle,
                                            confidence: .measured, calculatedAt: Date())
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ThrustToWeightResult.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - CompatibilityWarning

    func testCompatibilityWarningCodable() throws {
        let original = CompatibilityWarning(rule: "test_rule", level: .warning, detail: "Detail")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CompatibilityWarning.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - BatteryStatus

    func testBatteryStatusDisplayNames() {
        XCTAssertEqual(BatteryStatus.active.displayName, String(localized: "Active"))
        XCTAssertEqual(BatteryStatus.retired.displayName, String(localized: "Retired"))
        XCTAssertEqual(BatteryStatus.damaged.displayName, String(localized: "Damaged"))
    }

    func testBatteryStatusAllCases() {
        XCTAssertEqual(BatteryStatus.allCases.count, 3)
    }

    // MARK: - Battery

    func testBatteryDefaultValues() {
        let b = Battery(name: "Tattu")
        XCTAssertEqual(b.cycles, 0)
        XCTAssertEqual(b.status, .active)
        XCTAssertNil(b.code)
        XCTAssertNil(b.capacityMah)
        XCTAssertNil(b.cells)
    }

    func testBatteryCodable() throws {
        let original = Battery(name: "Tattu", code: "T1", capacityMah: 1300,
                               cells: 6, cycles: 10, status: .active, remark: "Good")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Battery.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - FlightRecord

    func testFlightRecordDefaults() {
        let f = FlightRecord(aircraftId: UUID(), startAt: Date(), durationSeconds: 300)
        XCTAssertTrue(f.batteryIds.isEmpty)
        XCTAssertNil(f.address)
        XCTAssertNil(f.latitude)
        XCTAssertNil(f.longitude)
        XCTAssertNil(f.remark)
    }

    func testFlightRecordCodable() throws {
        let original = FlightRecord(aircraftId: UUID(), batteryIds: [UUID()],
                                    startAt: Date(), durationSeconds: 480,
                                    address: "Park", latitude: 39.9, longitude: 116.4, remark: "Fun")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FlightRecord.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - PartCategory

    func testPartCategoryDisplayNames() {
        XCTAssertEqual(PartCategory.frame.displayName, String(localized: "Frame"))
        XCTAssertEqual(PartCategory.motor.displayName, String(localized: "Motor"))
        XCTAssertEqual(PartCategory.esc.displayName, String(localized: "ESC"))
        XCTAssertEqual(PartCategory.flightController.displayName, String(localized: "Flight Controller"))
        XCTAssertEqual(PartCategory.camera.displayName, String(localized: "Camera"))
        XCTAssertEqual(PartCategory.vtx.displayName, String(localized: "VTX"))
        XCTAssertEqual(PartCategory.receiver.displayName, String(localized: "Receiver"))
        XCTAssertEqual(PartCategory.propeller.displayName, String(localized: "Propeller"))
        XCTAssertEqual(PartCategory.other.displayName, String(localized: "Other"))
    }

    func testPartCategoryAllCases() {
        XCTAssertEqual(PartCategory.allCases.count, 9)
    }

    // MARK: - Part

    func testPartQuantityMinimum() {
        let p = Part(name: "Test", category: .frame, quantity: -5)
        XCTAssertEqual(p.quantity, 1)
    }

    func testPartQuantityZeroBecomesOne() {
        let p = Part(name: "Test", category: .frame, quantity: 0)
        XCTAssertEqual(p.quantity, 1)
    }

    func testPartDefaultValues() {
        let p = Part(name: "Motor", category: .motor)
        XCTAssertEqual(p.quantity, 1)
        XCTAssertNil(p.sourceAircraftId)
        XCTAssertNil(p.remark)
    }

    func testPartCodable() throws {
        let original = Part(name: "Motor", category: .motor, quantity: 4,
                            sourceAircraftId: UUID(), remark: "Spare")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Part.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - AllDataSnapshot

    func testAllDataSnapshotCodable() throws {
        let snapshot = AllDataSnapshot(
            aircraft: [Aircraft(name: "A")],
            batteries: [Battery(name: "B")],
            flights: [FlightRecord(aircraftId: UUID(), startAt: Date(), durationSeconds: 100)],
            parts: [Part(name: "P", category: .frame)]
        )
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(AllDataSnapshot.self, from: data)
        XCTAssertEqual(decoded.aircraft.count, 1)
        XCTAssertEqual(decoded.batteries.count, 1)
        XCTAssertEqual(decoded.flights.count, 1)
        XCTAssertEqual(decoded.parts.count, 1)
    }
}
