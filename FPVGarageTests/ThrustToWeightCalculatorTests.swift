import XCTest
@testable import FPVGarage

final class ThrustToWeightCalculatorTests: XCTestCase {

    // MARK: - Tier Classification

    func testFreestyleTiers() {
        XCTAssertEqual(ThrustToWeightCalculator.tier(ratio: 3.0, flightStyle: .freestyle), .underpowered)
        XCTAssertEqual(ThrustToWeightCalculator.tier(ratio: 4.0, flightStyle: .freestyle), .adequate)
        XCTAssertEqual(ThrustToWeightCalculator.tier(ratio: 5.5, flightStyle: .freestyle), .good)
        XCTAssertEqual(ThrustToWeightCalculator.tier(ratio: 8.0, flightStyle: .freestyle), .ideal)
        XCTAssertEqual(ThrustToWeightCalculator.tier(ratio: 12.0, flightStyle: .freestyle), .ideal)
    }

    func testRacingTiers() {
        XCTAssertEqual(ThrustToWeightCalculator.tier(ratio: 5.0, flightStyle: .racing), .underpowered)
        XCTAssertEqual(ThrustToWeightCalculator.tier(ratio: 6.0, flightStyle: .racing), .adequate)
        XCTAssertEqual(ThrustToWeightCalculator.tier(ratio: 8.0, flightStyle: .racing), .good)
        XCTAssertEqual(ThrustToWeightCalculator.tier(ratio: 10.0, flightStyle: .racing), .ideal)
    }

    func testCinematicTiers() {
        XCTAssertEqual(ThrustToWeightCalculator.tier(ratio: 2.0, flightStyle: .cinematic), .underpowered)
        XCTAssertEqual(ThrustToWeightCalculator.tier(ratio: 3.0, flightStyle: .cinematic), .adequate)
        XCTAssertEqual(ThrustToWeightCalculator.tier(ratio: 4.5, flightStyle: .cinematic), .good)
        XCTAssertEqual(ThrustToWeightCalculator.tier(ratio: 6.0, flightStyle: .cinematic), .ideal)
    }

    func testLongRangeTiers() {
        XCTAssertEqual(ThrustToWeightCalculator.tier(ratio: 2.0, flightStyle: .longRange), .underpowered)
        XCTAssertEqual(ThrustToWeightCalculator.tier(ratio: 2.5, flightStyle: .longRange), .adequate)
        XCTAssertEqual(ThrustToWeightCalculator.tier(ratio: 3.5, flightStyle: .longRange), .good)
        XCTAssertEqual(ThrustToWeightCalculator.tier(ratio: 5.0, flightStyle: .longRange), .ideal)
    }

    func testWhoopTiers() {
        XCTAssertEqual(ThrustToWeightCalculator.tier(ratio: 1.5, flightStyle: .whoop), .underpowered)
        XCTAssertEqual(ThrustToWeightCalculator.tier(ratio: 2.0, flightStyle: .whoop), .adequate)
        XCTAssertEqual(ThrustToWeightCalculator.tier(ratio: 3.0, flightStyle: .whoop), .good)
        XCTAssertEqual(ThrustToWeightCalculator.tier(ratio: 4.0, flightStyle: .whoop), .ideal)
    }

    // MARK: - Calculate

    func testCalculateBasic() {
        // 4 motors x 500g = 2000g thrust / 400g AUW = 5.0 TWR
        let result = ThrustToWeightCalculator.calculate(
            motorThrustGrams: 500,
            allUpWeightGrams: 400,
            flightStyle: .freestyle,
            thrustDataSource: .specSheet
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.ratio, 5.0, accuracy: 0.01)
        XCTAssertEqual(result!.tier, .adequate)
        XCTAssertEqual(result!.confidence, .specSheet)
        XCTAssertEqual(result!.flightStyle, .freestyle)
    }

    func testCalculateReturnsNilForZeroWeight() {
        let result = ThrustToWeightCalculator.calculate(
            motorThrustGrams: 500,
            allUpWeightGrams: 0,
            flightStyle: .freestyle,
            thrustDataSource: .measured
        )
        XCTAssertNil(result)
    }

    func testCalculateReturnsNilForZeroThrust() {
        let result = ThrustToWeightCalculator.calculate(
            motorThrustGrams: 0,
            allUpWeightGrams: 400,
            flightStyle: .freestyle,
            thrustDataSource: .measured
        )
        XCTAssertNil(result)
    }

    // MARK: - Convenience from Aircraft

    func testCalculateFromAircraftWithAllFields() {
        let a = Aircraft(
            name: "Test",
            flightStyle: .freestyle,
            motorThrustGrams: 500,
            motorThrustDataSource: .measured,
            allUpWeightGrams: 400
        )
        let result = ThrustToWeightCalculator.calculate(from: a)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.ratio, 5.0, accuracy: 0.01)
    }

    func testCalculateFromAircraftMissingThrust() {
        let a = Aircraft(name: "Test", flightStyle: .freestyle, allUpWeightGrams: 400)
        XCTAssertNil(ThrustToWeightCalculator.calculate(from: a))
    }

    func testCalculateFromAircraftMissingFlightStyle() {
        let a = Aircraft(name: "Test", motorThrustGrams: 500, motorThrustDataSource: .measured, allUpWeightGrams: 400)
        XCTAssertNil(ThrustToWeightCalculator.calculate(from: a))
    }

    func testCalculateFromAircraftMissingWeight() {
        let a = Aircraft(name: "Test", flightStyle: .freestyle, motorThrustGrams: 500, motorThrustDataSource: .measured)
        XCTAssertNil(ThrustToWeightCalculator.calculate(from: a))
    }

    func testCalculateFromAircraftMissingDataSource() {
        let a = Aircraft(name: "Test", flightStyle: .freestyle, motorThrustGrams: 500, allUpWeightGrams: 400)
        XCTAssertNil(ThrustToWeightCalculator.calculate(from: a))
    }
}
