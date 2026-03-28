import XCTest
@testable import FPVGarage

final class FleetContextBuilderTests: XCTestCase {

    private func makeAircraft(
        name: String = "Test Quad",
        flightStyle: FlightStyle? = .freestyle,
        pilotSkillLevel: PilotSkillLevel? = .intermediate,
        frameSizeInch: Double? = 5.0,
        motorModel: String? = "T-Motor F60",
        motorKv: Int? = 1950,
        propSize: String? = "51466",
        remark: String? = "Some private note",
        latitude: Double? = nil,
        longitude: Double? = nil
    ) -> Aircraft {
        Aircraft(
            name: name,
            remark: remark,
            flightStyle: flightStyle,
            pilotSkillLevel: pilotSkillLevel,
            frameSizeInch: frameSizeInch,
            motorModel: motorModel,
            motorKv: motorKv,
            propSize: propSize
        )
    }

    // MARK: - Basic Build

    func testBuildIncludesAllowlistedFields() {
        let aircraft = makeAircraft()
        let twr = ThrustToWeightResult(
            ratio: 6.5,
            tier: .good,
            flightStyle: .freestyle,
            confidence: .measured,
            calculatedAt: Date()
        )
        let warnings = [
            CompatibilityWarning(rule: "kv_voltage", level: .warning, detail: "RPM out of range")
        ]
        let partCounts = ["motor": 4, "propeller": 8]

        let dto = FleetContextBuilder.build(
            aircraft: aircraft,
            battery: Battery(name: "Test", capacityMah: 1300, cells: 6),
            twrResult: twr,
            compatWarnings: warnings,
            partCountsByCategory: partCounts
        )

        XCTAssertEqual(dto.aircraftName, "Test Quad")
        XCTAssertEqual(dto.flightStyle, .freestyle)
        XCTAssertEqual(dto.pilotSkillLevel, .intermediate)
        XCTAssertEqual(dto.frameSizeInch, 5.0)
        XCTAssertEqual(dto.motorModel, "T-Motor F60")
        XCTAssertEqual(dto.motorKv, 1950)
        XCTAssertEqual(dto.propSize, "51466")
        XCTAssertEqual(dto.twrRatio, 6.5)
        XCTAssertEqual(dto.twrTier, .good)
        XCTAssertEqual(dto.batteryCells, 6)
        XCTAssertEqual(dto.batteryCapacityMah, 1300)
        XCTAssertEqual(dto.partCountsByCategory, ["motor": 4, "propeller": 8])
        XCTAssertEqual(dto.compatibilityWarningSummary, ["RPM out of range"])
    }

    // MARK: - Privacy: Never includes GPS, remarks, photos

    func testNeverIncludesRemarks() {
        let aircraft = makeAircraft(remark: "Super secret remark")
        let dto = FleetContextBuilder.build(
            aircraft: aircraft,
            battery: nil,
            twrResult: nil,
            compatWarnings: [],
            partCountsByCategory: [:]
        )

        // FleetContextDTO has no remark field — verify it doesn't appear in encoded JSON
        let data = try! JSONEncoder().encode(dto)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertFalse(json.contains("secret"))
        XCTAssertFalse(json.contains("remark"))
    }

    func testNeverIncludesImageFileName() {
        let aircraft = Aircraft(name: "Test", imageFileName: "secret_photo.jpg")
        let dto = FleetContextBuilder.build(
            aircraft: aircraft,
            battery: nil,
            twrResult: nil,
            compatWarnings: [],
            partCountsByCategory: [:]
        )

        let data = try! JSONEncoder().encode(dto)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertFalse(json.contains("secret_photo"))
        XCTAssertFalse(json.contains("imageFileName"))
    }

    // MARK: - Nil optional fields

    func testNilFieldsProduceNilInDTO() {
        let aircraft = Aircraft(name: "Bare")
        let dto = FleetContextBuilder.build(
            aircraft: aircraft,
            battery: nil,
            twrResult: nil,
            compatWarnings: [],
            partCountsByCategory: [:]
        )

        XCTAssertEqual(dto.aircraftName, "Bare")
        XCTAssertNil(dto.flightStyle)
        XCTAssertNil(dto.pilotSkillLevel)
        XCTAssertNil(dto.frameSizeInch)
        XCTAssertNil(dto.motorModel)
        XCTAssertNil(dto.motorKv)
        XCTAssertNil(dto.propSize)
        XCTAssertNil(dto.twrRatio)
        XCTAssertNil(dto.twrTier)
        XCTAssertNil(dto.batteryCells)
        XCTAssertNil(dto.batteryCapacityMah)
        XCTAssertTrue(dto.partCountsByCategory.isEmpty)
        XCTAssertTrue(dto.compatibilityWarningSummary.isEmpty)
    }

    // MARK: - Battery cell fallback

    func testBatteryCellsFallbackFromBattery() {
        let aircraft = Aircraft(name: "Test")
        let battery = Battery(name: "B1", cells: 4)
        let dto = FleetContextBuilder.build(
            aircraft: aircraft,
            battery: battery,
            twrResult: nil,
            compatWarnings: [],
            partCountsByCategory: [:]
        )

        XCTAssertEqual(dto.batteryCells, 4)
    }

    func testAircraftCellCountOverridesBattery() {
        let aircraft = Aircraft(name: "Test", batteryCellCount: 6)
        let battery = Battery(name: "B1", cells: 4)
        let dto = FleetContextBuilder.build(
            aircraft: aircraft,
            battery: battery,
            twrResult: nil,
            compatWarnings: [],
            partCountsByCategory: [:]
        )

        XCTAssertEqual(dto.batteryCells, 6)
    }

    // MARK: - Locale

    func testDeviceLocaleIsPopulated() {
        let dto = FleetContextBuilder.build(
            aircraft: Aircraft(name: "Test"),
            battery: nil,
            twrResult: nil,
            compatWarnings: [],
            partCountsByCategory: [:]
        )
        XCTAssertFalse(dto.deviceLocale.isEmpty)
    }
}
