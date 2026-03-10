import XCTest
import Combine
@testable import FPVGarage

final class HomeViewModelTests: XCTestCase {
    var appState: AppState!
    var viewModel: HomeViewModel!

    override func setUp() {
        super.setUp()
        appState = AppState(
            aircraftRepo: MockAircraftRepository(),
            batteryRepo: MockBatteryRepository(),
            flightRepo: MockFlightRepository(),
            partRepo: MockPartRepository(),
            imageStorage: MockImageStorage()
        )
        viewModel = HomeViewModel(appState: appState)
    }

    func testInitialCounts() {
        XCTAssertEqual(viewModel.flightCount, 0)
        XCTAssertEqual(viewModel.totalDuration, 0)
        XCTAssertEqual(viewModel.aircraftCount, 0)
        XCTAssertEqual(viewModel.batteryCount, 0)
        XCTAssertEqual(viewModel.partCount, 0)
    }

    func testCountsAfterAdding() {
        appState.addAircraft(Aircraft(name: "A"))
        appState.addBattery(Battery(name: "B"))
        appState.addFlight(FlightRecord(aircraftId: UUID(), startAt: Date(), durationSeconds: 300))
        appState.addPart(Part(name: "P", category: .frame))

        XCTAssertEqual(viewModel.aircraftCount, 1)
        XCTAssertEqual(viewModel.batteryCount, 1)
        XCTAssertEqual(viewModel.flightCount, 1)
        XCTAssertEqual(viewModel.totalDuration, 300)
        XCTAssertEqual(viewModel.partCount, 1)
    }

    func testTotalDurationMultipleFlights() {
        appState.addFlight(FlightRecord(aircraftId: UUID(), startAt: Date(), durationSeconds: 100))
        appState.addFlight(FlightRecord(aircraftId: UUID(), startAt: Date(), durationSeconds: 200))
        appState.addFlight(FlightRecord(aircraftId: UUID(), startAt: Date(), durationSeconds: 300))
        XCTAssertEqual(viewModel.totalDuration, 600)
    }

    func testPrepareExport() {
        appState.addAircraft(Aircraft(name: "A"))
        viewModel.prepareExport()
        XCTAssertTrue(viewModel.isExporting)
        XCTAssertNotNil(viewModel.exportDocument)
    }

    func testPrepareExportEmpty() {
        viewModel.prepareExport()
        XCTAssertTrue(viewModel.isExporting)
        XCTAssertNotNil(viewModel.exportDocument)
    }

    func testSeedTestData() {
        viewModel.seedTestData()
        XCTAssertGreaterThan(viewModel.aircraftCount, 0)
        XCTAssertGreaterThan(viewModel.batteryCount, 0)
        XCTAssertGreaterThan(viewModel.flightCount, 0)
    }
}
