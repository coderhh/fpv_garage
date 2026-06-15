import XCTest
@testable import FPVGarage

final class CompatibilityCheckerTests: XCTestCase {

    // MARK: - No warnings with no data

    func testNoWarningsWhenNoData() {
        let a = Aircraft(name: "Test")
        let warnings = CompatibilityChecker.check(aircraft: a, linkedBattery: nil)
        XCTAssertTrue(warnings.isEmpty)
    }

    // MARK: - ESC Current (Rule 1)

    func testESCCurrentPassWhenRatingCoversMotor() {
        let a = Aircraft(name: "Test", escCurrentRating: 40, motorMaxCurrentAmps: 35)
        let warnings = CompatibilityChecker.check(aircraft: a, linkedBattery: nil)
        XCTAssertFalse(warnings.contains { $0.rule == "ESC Current Rating" })
    }

    func testESCCurrentPassWhenEqual() {
        let a = Aircraft(name: "Test", escCurrentRating: 35, motorMaxCurrentAmps: 35)
        let warnings = CompatibilityChecker.check(aircraft: a, linkedBattery: nil)
        XCTAssertFalse(warnings.contains { $0.rule == "ESC Current Rating" })
    }

    func testESCCurrentErrorWhenUndersized() {
        let a = Aircraft(name: "Test", escCurrentRating: 20, motorMaxCurrentAmps: 35)
        let warnings = CompatibilityChecker.check(aircraft: a, linkedBattery: nil)
        let w = warnings.first { $0.rule == "ESC Current Rating" }
        XCTAssertNotNil(w)
        XCTAssertEqual(w?.level, .error)
    }

    func testESCCurrentSkippedWhenEitherFieldMissing() {
        let onlyESC = Aircraft(name: "Test", escCurrentRating: 40)
        XCTAssertTrue(CompatibilityChecker.check(aircraft: onlyESC, linkedBattery: nil).isEmpty)

        let onlyMotor = Aircraft(name: "Test", motorMaxCurrentAmps: 35)
        XCTAssertTrue(CompatibilityChecker.check(aircraft: onlyMotor, linkedBattery: nil).isEmpty)
    }

    // MARK: - KV / Voltage (Rule 2)

    func testKVVoltagePassWhenInRange() {
        // 5" default range [18000, 24000]; 5S 18.5V × 1100 KV = 20350 RPM ✓
        let a = Aircraft(name: "Test", motorKv: 1100, batteryCellCount: 5)
        let warnings = CompatibilityChecker.check(aircraft: a, linkedBattery: nil)
        XCTAssertFalse(warnings.contains { $0.rule == "Motor KV / Voltage" })
    }

    func testKVVoltageWarningWhenBelowRange() {
        // 5" default range [18000, 24000]; 4S 14.8V × 800 KV = 11840 RPM ✗
        let a = Aircraft(name: "Test", motorKv: 800, batteryCellCount: 4)
        let warnings = CompatibilityChecker.check(aircraft: a, linkedBattery: nil)
        let w = warnings.first { $0.rule == "Motor KV / Voltage" }
        XCTAssertNotNil(w)
        XCTAssertEqual(w?.level, .warning)
    }

    func testKVVoltageWarningWhenAboveRange() {
        // 5" default range [18000, 24000]; 6S 22.2V × 2450 KV = 54390 RPM ✗
        let a = Aircraft(name: "Test", motorKv: 2450, batteryCellCount: 6)
        let warnings = CompatibilityChecker.check(aircraft: a, linkedBattery: nil)
        let w = warnings.first { $0.rule == "Motor KV / Voltage" }
        XCTAssertNotNil(w)
        XCTAssertEqual(w?.level, .warning)
    }

    func testKVVoltageSkippedWhenNoCellCount() {
        let a = Aircraft(name: "Test", motorKv: 2450)
        let warnings = CompatibilityChecker.check(aircraft: a, linkedBattery: nil)
        XCTAssertFalse(warnings.contains { $0.rule == "Motor KV / Voltage" })
    }

    func testKVVoltageUsesLinkedBatteryCells() {
        // 5" default; 4S 14.8V × 1300 KV = 19240 ✓ (in [18000, 24000])
        let a = Aircraft(name: "Test", motorKv: 1300)
        let battery = Battery(name: "4S", cells: 4)
        let warnings = CompatibilityChecker.check(aircraft: a, linkedBattery: battery)
        XCTAssertFalse(warnings.contains { $0.rule == "Motor KV / Voltage" })
    }

    func testKVVoltagePrefersAircraftCellCountOverBattery() {
        // Aircraft overrides with 6S; 6S × 1300 KV = 28860 → above 5" range [18000, 24000] → warning
        let a = Aircraft(name: "Test", motorKv: 1300, batteryCellCount: 6)
        let battery = Battery(name: "4S", cells: 4)
        let warnings = CompatibilityChecker.check(aircraft: a, linkedBattery: battery)
        XCTAssertTrue(warnings.contains { $0.rule == "Motor KV / Voltage" })
    }

    // MARK: - KV Voltage range by frame size

    func testKVVoltageRangeFor3Inch() {
        let (min, max) = CompatibilityChecker.kvVoltageRange(for: 3.0)
        XCTAssertEqual(min, 14_000)
        XCTAssertEqual(max, 20_000)
    }

    func testKVVoltageRangeFor5Inch() {
        let (min, max) = CompatibilityChecker.kvVoltageRange(for: 5.0)
        XCTAssertEqual(min, 18_000)
        XCTAssertEqual(max, 24_000)
    }

    func testKVVoltageRangeNilDefaultsTo5Inch() {
        let (min, max) = CompatibilityChecker.kvVoltageRange(for: nil)
        XCTAssertEqual(min, 18_000)
        XCTAssertEqual(max, 24_000)
    }

    // MARK: - C-Rating (Rule 3)

    func testCRatingPassWhenSufficient() {
        // 50C × 1.3 Ah = 65 A; 4 motors × 15 A = 60 A → pass
        let battery = Battery(name: "Test", capacityMah: 1300, cRating: 50)
        let a = Aircraft(name: "Test", motorMaxCurrentAmps: 15)
        let warnings = CompatibilityChecker.check(aircraft: a, linkedBattery: battery)
        XCTAssertFalse(warnings.contains { $0.rule == "Battery C-Rating" })
    }

    func testCRatingWarningWhenInsufficient() {
        // 25C × 1.3 Ah = 32.5 A; 4 × 15 A = 60 A → warning
        let battery = Battery(name: "Test", capacityMah: 1300, cRating: 25)
        let a = Aircraft(name: "Test", motorMaxCurrentAmps: 15)
        let warnings = CompatibilityChecker.check(aircraft: a, linkedBattery: battery)
        let w = warnings.first { $0.rule == "Battery C-Rating" }
        XCTAssertNotNil(w)
        XCTAssertEqual(w?.level, .warning)
    }

    func testCRatingSkippedWhenNoBattery() {
        let a = Aircraft(name: "Test", motorMaxCurrentAmps: 15)
        let warnings = CompatibilityChecker.check(aircraft: a, linkedBattery: nil)
        XCTAssertFalse(warnings.contains { $0.rule == "Battery C-Rating" })
    }

    func testCRatingSkippedWhenBatteryHasNoCRating() {
        let battery = Battery(name: "Test", capacityMah: 1300)
        let a = Aircraft(name: "Test", motorMaxCurrentAmps: 15)
        let warnings = CompatibilityChecker.check(aircraft: a, linkedBattery: battery)
        XCTAssertFalse(warnings.contains { $0.rule == "Battery C-Rating" })
    }

    func testCRatingSkippedWhenNoMotorMaxCurrent() {
        let battery = Battery(name: "Test", capacityMah: 1300, cRating: 50)
        let a = Aircraft(name: "Test")
        let warnings = CompatibilityChecker.check(aircraft: a, linkedBattery: battery)
        XCTAssertFalse(warnings.contains { $0.rule == "Battery C-Rating" })
    }

    // MARK: - Multiple warnings at once

    func testMultipleWarningsReturned() {
        // Undersized ESC + below-range KV
        let a = Aircraft(name: "Test",
                         motorKv: 800,
                         batteryCellCount: 4,
                         escCurrentRating: 20,
                         motorMaxCurrentAmps: 35)
        let warnings = CompatibilityChecker.check(aircraft: a, linkedBattery: nil)
        XCTAssertGreaterThanOrEqual(warnings.count, 2)
    }
}
