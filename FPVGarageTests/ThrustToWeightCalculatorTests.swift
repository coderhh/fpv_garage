import XCTest
@testable import FPVGarage

final class ThrustToWeightCalculatorTests: XCTestCase {

    // MARK: - Missing data returns nil

    func testNilWhenNoThrust() {
        let a = Aircraft(name: "Test", flightStyle: .freestyle, allUpWeightGrams: 500)
        XCTAssertNil(ThrustToWeightCalculator.calculate(aircraft: a, linkedBattery: nil))
    }

    func testNilWhenNoAUW() {
        let a = Aircraft(name: "Test", flightStyle: .freestyle, motorThrustGrams: 800)
        XCTAssertNil(ThrustToWeightCalculator.calculate(aircraft: a, linkedBattery: nil))
    }

    func testNilWhenNoFlightStyle() {
        let a = Aircraft(name: "Test", motorThrustGrams: 800, allUpWeightGrams: 500)
        XCTAssertNil(ThrustToWeightCalculator.calculate(aircraft: a, linkedBattery: nil))
    }

    func testNilWhenAUWIsZero() {
        let a = Aircraft(name: "Test", flightStyle: .freestyle, motorThrustGrams: 800, allUpWeightGrams: 0)
        XCTAssertNil(ThrustToWeightCalculator.calculate(aircraft: a, linkedBattery: nil))
    }

    // MARK: - Ratio calculation

    func testRatioCalculation() {
        // 4 motors × 800 g = 3200 g total thrust; AUW = 500 g → ratio = 6.4
        let a = Aircraft(name: "Test", flightStyle: .freestyle, motorThrustGrams: 800, allUpWeightGrams: 500)
        let result = ThrustToWeightCalculator.calculate(aircraft: a, linkedBattery: nil)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.ratio, 6.4, accuracy: 0.01)
    }

    // MARK: - Freestyle tiers (< 4.0 / 4.0–5.5 / 5.5–8.0 / > 8.0)

    func testFreestyleUnderpowered() {
        let a = makeAircraft(thrustPerMotor: 350, auw: 500, style: .freestyle) // 2.8x
        XCTAssertEqual(result(a).tier, .underpowered)
    }

    func testFreestyleAdequate() {
        let a = makeAircraft(thrustPerMotor: 550, auw: 500, style: .freestyle) // 4.4x
        XCTAssertEqual(result(a).tier, .adequate)
    }

    func testFreestyleGood() {
        let a = makeAircraft(thrustPerMotor: 850, auw: 500, style: .freestyle) // 6.8x
        XCTAssertEqual(result(a).tier, .good)
    }

    func testFreestyleIdeal() {
        let a = makeAircraft(thrustPerMotor: 1100, auw: 500, style: .freestyle) // 8.8x
        XCTAssertEqual(result(a).tier, .ideal)
    }

    // MARK: - Racing tiers (< 6.0 / 6.0–8.0 / 8.0–10.0 / > 10.0)

    func testRacingUnderpowered() {
        let a = makeAircraft(thrustPerMotor: 600, auw: 500, style: .racing) // 4.8x
        XCTAssertEqual(result(a).tier, .underpowered)
    }

    func testRacingAdequate() {
        let a = makeAircraft(thrustPerMotor: 900, auw: 500, style: .racing) // 7.2x
        XCTAssertEqual(result(a).tier, .adequate)
    }

    func testRacingGood() {
        let a = makeAircraft(thrustPerMotor: 1125, auw: 500, style: .racing) // 9.0x
        XCTAssertEqual(result(a).tier, .good)
    }

    func testRacingIdeal() {
        let a = makeAircraft(thrustPerMotor: 1400, auw: 500, style: .racing) // 11.2x
        XCTAssertEqual(result(a).tier, .ideal)
    }

    // MARK: - Cinematic tiers (< 3.0 / 3.0–4.5 / 4.5–6.0 / > 6.0)

    func testCinematicUnderpowered() {
        let a = makeAircraft(thrustPerMotor: 300, auw: 500, style: .cinematic) // 2.4x
        XCTAssertEqual(result(a).tier, .underpowered)
    }

    func testCinematicAdequate() {
        let a = makeAircraft(thrustPerMotor: 475, auw: 500, style: .cinematic) // 3.8x
        XCTAssertEqual(result(a).tier, .adequate)
    }

    func testCinematicGood() {
        let a = makeAircraft(thrustPerMotor: 650, auw: 500, style: .cinematic) // 5.2x
        XCTAssertEqual(result(a).tier, .good)
    }

    func testCinematicIdeal() {
        let a = makeAircraft(thrustPerMotor: 850, auw: 500, style: .cinematic) // 6.8x
        XCTAssertEqual(result(a).tier, .ideal)
    }

    // MARK: - Long Range tiers (< 2.5 / 2.5–3.5 / 3.5–5.0 / > 5.0)

    func testLongRangeUnderpowered() {
        let a = makeAircraft(thrustPerMotor: 250, auw: 500, style: .longRange) // 2.0x
        XCTAssertEqual(result(a).tier, .underpowered)
    }

    func testLongRangeAdequate() {
        let a = makeAircraft(thrustPerMotor: 375, auw: 500, style: .longRange) // 3.0x
        XCTAssertEqual(result(a).tier, .adequate)
    }

    func testLongRangeGood() {
        let a = makeAircraft(thrustPerMotor: 525, auw: 500, style: .longRange) // 4.2x
        XCTAssertEqual(result(a).tier, .good)
    }

    func testLongRangeIdeal() {
        let a = makeAircraft(thrustPerMotor: 700, auw: 500, style: .longRange) // 5.6x
        XCTAssertEqual(result(a).tier, .ideal)
    }

    // MARK: - Whoop tiers (< 2.0 / 2.0–3.0 / 3.0–4.0 / > 4.0)

    func testWhoopUnderpowered() {
        let a = makeAircraft(thrustPerMotor: 200, auw: 500, style: .whoop) // 1.6x
        XCTAssertEqual(result(a).tier, .underpowered)
    }

    func testWhoopAdequate() {
        let a = makeAircraft(thrustPerMotor: 310, auw: 500, style: .whoop) // 2.48x
        XCTAssertEqual(result(a).tier, .adequate)
    }

    func testWhoopGood() {
        let a = makeAircraft(thrustPerMotor: 430, auw: 500, style: .whoop) // 3.44x
        XCTAssertEqual(result(a).tier, .good)
    }

    func testWhoopIdeal() {
        let a = makeAircraft(thrustPerMotor: 550, auw: 500, style: .whoop) // 4.4x
        XCTAssertEqual(result(a).tier, .ideal)
    }

    // MARK: - Confidence / data source

    func testDefaultsToEstimatedWhenSourceNil() {
        let a = Aircraft(name: "Test", flightStyle: .freestyle, motorThrustGrams: 800, allUpWeightGrams: 500)
        XCTAssertEqual(result(a).confidence, .estimated)
    }

    func testMeasuredConfidence() {
        let a = Aircraft(name: "Test", flightStyle: .freestyle, motorThrustGrams: 800, motorThrustDataSource: .measured, allUpWeightGrams: 500)
        XCTAssertEqual(result(a).confidence, .measured)
    }

    func testSpecSheetConfidence() {
        let a = Aircraft(name: "Test", flightStyle: .freestyle, motorThrustGrams: 800, motorThrustDataSource: .specSheet, allUpWeightGrams: 500)
        XCTAssertEqual(result(a).confidence, .specSheet)
    }

    // MARK: - Helpers

    private func makeAircraft(thrustPerMotor: Int, auw: Int, style: FlightStyle) -> Aircraft {
        Aircraft(name: "Test", flightStyle: style, motorThrustGrams: thrustPerMotor, allUpWeightGrams: auw)
    }

    private func result(_ aircraft: Aircraft) -> ThrustToWeightResult {
        ThrustToWeightCalculator.calculate(aircraft: aircraft, linkedBattery: nil)!
    }
}
