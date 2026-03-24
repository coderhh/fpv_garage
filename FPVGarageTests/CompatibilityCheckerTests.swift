import XCTest
@testable import FPVGarage

final class CompatibilityCheckerTests: XCTestCase {

    // MARK: - KV x Voltage Range (Rule 2)

    func testKvVoltageInRange() {
        // 1950 KV * 6S * 3.7V = 43,290 — but that's actually out of 5" range.
        // Let's use a value that is in range: 1100 KV * 6S * 3.7 = 24,420 — just above for 5"
        // Better: 900 KV * 6S * 3.7 = 19,980 — in range for 5"
        let a = Aircraft(name: "Test", frameSizeInch: 5.0, motorKv: 900, batteryCellCount: 6)
        let warnings = CompatibilityChecker.check(aircraft: a, battery: nil)
        XCTAssertTrue(warnings.isEmpty)
    }

    func testKvVoltageBelowRange() {
        // 500 KV * 4S * 3.7 = 7,400 — below 18,000 for 5" quad
        let a = Aircraft(name: "Test", frameSizeInch: 5.0, motorKv: 500, batteryCellCount: 4)
        let warnings = CompatibilityChecker.check(aircraft: a, battery: nil)
        XCTAssertEqual(warnings.count, 1)
        XCTAssertEqual(warnings.first?.rule, "kv_voltage_range")
        XCTAssertEqual(warnings.first?.level, .warning)
    }

    func testKvVoltageAboveRange() {
        // 2800 KV * 6S * 3.7 = 62,160 — well above 24,000 for 5"
        let a = Aircraft(name: "Test", frameSizeInch: 5.0, motorKv: 2800, batteryCellCount: 6)
        let warnings = CompatibilityChecker.check(aircraft: a, battery: nil)
        XCTAssertEqual(warnings.count, 1)
        XCTAssertEqual(warnings.first?.rule, "kv_voltage_range")
    }

    func testKvVoltageSmallFrame() {
        // 3800 KV * 4S * 3.7 = 56,240 — for a 3.5" that uses range 20,000–30,000
        let a = Aircraft(name: "Test", frameSizeInch: 3.5, motorKv: 3800, batteryCellCount: 4)
        let warnings = CompatibilityChecker.check(aircraft: a, battery: nil)
        XCTAssertEqual(warnings.count, 1)
        XCTAssertEqual(warnings.first?.rule, "kv_voltage_range")
    }

    func testKvVoltageSmallFrameInRange() {
        // 1800 KV * 4S * 3.7 = 26,640 — in range for 3.5" (20,000–30,000)
        let a = Aircraft(name: "Test", frameSizeInch: 3.5, motorKv: 1800, batteryCellCount: 4)
        let warnings = CompatibilityChecker.check(aircraft: a, battery: nil)
        XCTAssertTrue(warnings.isEmpty)
    }

    // MARK: - Battery Fallback

    func testUseBatteryCellsWhenAircraftCellCountNil() {
        // 900 KV * 6S * 3.7 = 19,980 — in range for 5"
        let a = Aircraft(name: "Test", frameSizeInch: 5.0, motorKv: 900)
        let b = Battery(name: "B", cells: 6)
        let warnings = CompatibilityChecker.check(aircraft: a, battery: b)
        XCTAssertTrue(warnings.isEmpty)
    }

    func testAircraftCellCountOverridesBattery() {
        // Aircraft says 4S, battery says 6S. Use aircraft's 4S.
        // 900 KV * 4S * 3.7 = 13,320 — below 18,000 for 5"
        let a = Aircraft(name: "Test", frameSizeInch: 5.0, motorKv: 900, batteryCellCount: 4)
        let b = Battery(name: "B", cells: 6)
        let warnings = CompatibilityChecker.check(aircraft: a, battery: b)
        XCTAssertEqual(warnings.count, 1)
    }

    // MARK: - Missing Data (Graceful)

    func testNoWarningsWithoutKv() {
        let a = Aircraft(name: "Test", frameSizeInch: 5.0, batteryCellCount: 6)
        let warnings = CompatibilityChecker.check(aircraft: a, battery: nil)
        XCTAssertTrue(warnings.isEmpty)
    }

    func testNoWarningsWithoutCells() {
        let a = Aircraft(name: "Test", frameSizeInch: 5.0, motorKv: 1950)
        let warnings = CompatibilityChecker.check(aircraft: a, battery: nil)
        XCTAssertTrue(warnings.isEmpty)
    }

    func testNoWarningsForEmptyAircraft() {
        let a = Aircraft(name: "Test")
        let warnings = CompatibilityChecker.check(aircraft: a, battery: nil)
        XCTAssertTrue(warnings.isEmpty)
    }

    // MARK: - Default Frame Size

    func testDefaultFrameSizeUsed() {
        // No frameSizeInch → defaults to 5" range (18,000–24,000)
        // 900 KV * 6S * 3.7 = 19,980 — in range
        let a = Aircraft(name: "Test", motorKv: 900, batteryCellCount: 6)
        let warnings = CompatibilityChecker.check(aircraft: a, battery: nil)
        XCTAssertTrue(warnings.isEmpty)
    }
}
