import XCTest
@testable import FPVGarage

final class ConfigHashCalculatorTests: XCTestCase {

    private func makeAircraft(
        motorKv: Int? = 1950,
        motorThrustGrams: Int? = 1200,
        allUpWeightGrams: Int? = 650,
        flightStyle: FlightStyle? = .freestyle,
        frameSizeInch: Double? = 5.0,
        propSize: String? = "51466",
        batteryCellCount: Int? = 6
    ) -> Aircraft {
        Aircraft(
            name: "Test",
            flightStyle: flightStyle,
            frameSizeInch: frameSizeInch,
            motorKv: motorKv,
            motorThrustGrams: motorThrustGrams,
            propSize: propSize,
            allUpWeightGrams: allUpWeightGrams,
            batteryCellCount: batteryCellCount
        )
    }

    private func makeBattery(capacityMah: Int? = 1300, cells: Int? = 6) -> Battery {
        Battery(name: "Test", capacityMah: capacityMah, cells: cells)
    }

    // MARK: - Determinism

    func testSameInputProducesSameHash() {
        let a = makeAircraft()
        let b = makeBattery()
        let hash1 = ConfigHashCalculator.hash(aircraft: a, battery: b)
        let hash2 = ConfigHashCalculator.hash(aircraft: a, battery: b)
        XCTAssertEqual(hash1, hash2)
    }

    func testHashIsSHA256Length() {
        let hash = ConfigHashCalculator.hash(aircraft: makeAircraft(), battery: nil)
        XCTAssertEqual(hash.count, 64) // SHA256 hex = 64 chars
    }

    // MARK: - Any field change produces different hash

    func testDifferentMotorKv() {
        let a1 = makeAircraft(motorKv: 1950)
        let a2 = makeAircraft(motorKv: 2400)
        XCTAssertNotEqual(
            ConfigHashCalculator.hash(aircraft: a1, battery: nil),
            ConfigHashCalculator.hash(aircraft: a2, battery: nil)
        )
    }

    func testDifferentMotorThrust() {
        let a1 = makeAircraft(motorThrustGrams: 1200)
        let a2 = makeAircraft(motorThrustGrams: 1400)
        XCTAssertNotEqual(
            ConfigHashCalculator.hash(aircraft: a1, battery: nil),
            ConfigHashCalculator.hash(aircraft: a2, battery: nil)
        )
    }

    func testDifferentWeight() {
        let a1 = makeAircraft(allUpWeightGrams: 650)
        let a2 = makeAircraft(allUpWeightGrams: 700)
        XCTAssertNotEqual(
            ConfigHashCalculator.hash(aircraft: a1, battery: nil),
            ConfigHashCalculator.hash(aircraft: a2, battery: nil)
        )
    }

    func testDifferentFlightStyle() {
        let a1 = makeAircraft(flightStyle: .freestyle)
        let a2 = makeAircraft(flightStyle: .racing)
        XCTAssertNotEqual(
            ConfigHashCalculator.hash(aircraft: a1, battery: nil),
            ConfigHashCalculator.hash(aircraft: a2, battery: nil)
        )
    }

    func testDifferentFrameSize() {
        let a1 = makeAircraft(frameSizeInch: 5.0)
        let a2 = makeAircraft(frameSizeInch: 3.5)
        XCTAssertNotEqual(
            ConfigHashCalculator.hash(aircraft: a1, battery: nil),
            ConfigHashCalculator.hash(aircraft: a2, battery: nil)
        )
    }

    func testDifferentPropSize() {
        let a1 = makeAircraft(propSize: "51466")
        let a2 = makeAircraft(propSize: "51433")
        XCTAssertNotEqual(
            ConfigHashCalculator.hash(aircraft: a1, battery: nil),
            ConfigHashCalculator.hash(aircraft: a2, battery: nil)
        )
    }

    func testDifferentBatteryCellCount() {
        let a1 = makeAircraft(batteryCellCount: 6)
        let a2 = makeAircraft(batteryCellCount: 4)
        XCTAssertNotEqual(
            ConfigHashCalculator.hash(aircraft: a1, battery: nil),
            ConfigHashCalculator.hash(aircraft: a2, battery: nil)
        )
    }

    func testDifferentBatteryCapacity() {
        let a = makeAircraft()
        let b1 = makeBattery(capacityMah: 1300)
        let b2 = makeBattery(capacityMah: 1500)
        XCTAssertNotEqual(
            ConfigHashCalculator.hash(aircraft: a, battery: b1),
            ConfigHashCalculator.hash(aircraft: a, battery: b2)
        )
    }

    // MARK: - Battery fallback

    func testBatteryCellsFallbackFromBattery() {
        let a = makeAircraft(batteryCellCount: nil)
        let b = makeBattery(capacityMah: nil, cells: 6)
        let hashWithBattery = ConfigHashCalculator.hash(aircraft: a, battery: b)

        let a2 = makeAircraft(batteryCellCount: 6)
        let hashWithAircraftCells = ConfigHashCalculator.hash(aircraft: a2, battery: nil)

        // Both produce the same hash: cell count resolves to 6, capacity resolves to 0
        XCTAssertEqual(hashWithBattery, hashWithAircraftCells)
    }

    // MARK: - Nil fields

    func testNilFieldsProduceConsistentHash() {
        let a = Aircraft(name: "Empty")
        let hash1 = ConfigHashCalculator.hash(aircraft: a, battery: nil)
        let hash2 = ConfigHashCalculator.hash(aircraft: a, battery: nil)
        XCTAssertEqual(hash1, hash2)
        XCTAssertEqual(hash1.count, 64)
    }
}
