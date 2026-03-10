import XCTest
import MapKit
@testable import FPVGarage

final class FlightEditViewModelTests: XCTestCase {
    var appState: AppState!

    override func setUp() {
        super.setUp()
        appState = AppState(
            aircraftRepo: MockAircraftRepository(),
            batteryRepo: MockBatteryRepository(),
            flightRepo: MockFlightRepository(),
            partRepo: MockPartRepository(),
            imageStorage: MockImageStorage()
        )
    }

    func testNewFlightDefaults() {
        let vm = FlightEditViewModel(appState: appState, flight: nil)
        XCTAssertTrue(vm.isNew)
        XCTAssertNil(vm.coordinate)
        XCTAssertEqual(vm.durationSeconds, "0")
        XCTAssertEqual(vm.address, "")
        XCTAssertEqual(vm.remark, "")
    }

    func testCanSaveRequiresAircraft() {
        let vm = FlightEditViewModel(appState: appState, flight: nil)
        XCTAssertFalse(vm.canSave)

        vm.selectedAircraftId = UUID()
        XCTAssertTrue(vm.canSave)
    }

    func testCanSaveInvalidDuration() {
        let vm = FlightEditViewModel(appState: appState, flight: nil)
        vm.selectedAircraftId = UUID()
        vm.durationSeconds = "abc"
        XCTAssertFalse(vm.canSave)
    }

    func testCanSaveNegativeDuration() {
        let vm = FlightEditViewModel(appState: appState, flight: nil)
        vm.selectedAircraftId = UUID()
        vm.durationSeconds = "-1"
        XCTAssertFalse(vm.canSave)
    }

    func testAircraftList() {
        appState.addAircraft(Aircraft(name: "A"))
        appState.addAircraft(Aircraft(name: "B"))
        let vm = FlightEditViewModel(appState: appState, flight: nil)
        XCTAssertEqual(vm.aircraftList.count, 2)
    }

    func testSetupInitialNewFlight() {
        let a = Aircraft(name: "A")
        appState.addAircraft(a)
        let vm = FlightEditViewModel(appState: appState, flight: nil)
        vm.setupInitial()
        XCTAssertEqual(vm.selectedAircraftId, a.id)
    }

    func testSetupInitialNewFlightNoAircraft() {
        let vm = FlightEditViewModel(appState: appState, flight: nil)
        vm.setupInitial()
        XCTAssertNil(vm.selectedAircraftId)
    }

    func testSetupInitialExistingFlight() {
        let aId = UUID()
        let f = FlightRecord(aircraftId: aId, startAt: Date(), durationSeconds: 300,
                              address: "Park", latitude: 39.9, longitude: 116.4, remark: "Test")
        let vm = FlightEditViewModel(appState: appState, flight: f)
        vm.setupInitial()

        XCTAssertEqual(vm.selectedAircraftId, aId)
        XCTAssertEqual(vm.durationSeconds, "300")
        XCTAssertEqual(vm.address, "Park")
        XCTAssertEqual(vm.remark, "Test")
        XCTAssertNotNil(vm.coordinate)
        XCTAssertEqual(vm.coordinate!.latitude, 39.9, accuracy: 0.001)
        XCTAssertEqual(vm.coordinate!.longitude, 116.4, accuracy: 0.001)
    }

    func testSetupInitialFlightWithoutLocation() {
        let f = FlightRecord(aircraftId: UUID(), startAt: Date(), durationSeconds: 180)
        let vm = FlightEditViewModel(appState: appState, flight: f)
        vm.setupInitial()

        XCTAssertNil(vm.coordinate)
        XCTAssertEqual(vm.durationSeconds, "180")
    }

    func testSetCoordinate() {
        let vm = FlightEditViewModel(appState: appState, flight: nil)
        let coord = CLLocationCoordinate2D(latitude: 40.0, longitude: 116.0)
        vm.setCoordinate(coord)

        XCTAssertEqual(vm.coordinate!.latitude, 40.0, accuracy: 0.001)
        XCTAssertEqual(vm.coordinate!.longitude, 116.0, accuracy: 0.001)
    }

    func testClearCoordinate() {
        let vm = FlightEditViewModel(appState: appState, flight: nil)
        vm.setCoordinate(CLLocationCoordinate2D(latitude: 40, longitude: 116))
        XCTAssertNotNil(vm.coordinate)
        vm.clearCoordinate()
        XCTAssertNil(vm.coordinate)
    }

    func testSaveNewFlight() {
        let aId = UUID()
        appState.addAircraft(Aircraft(id: aId, name: "A"))
        let vm = FlightEditViewModel(appState: appState, flight: nil)
        vm.selectedAircraftId = aId
        vm.durationSeconds = "300"
        vm.address = "Park"
        vm.remark = "Good flight"
        vm.save()

        XCTAssertEqual(appState.flightRecords.count, 1)
        XCTAssertEqual(appState.flightRecords.first?.durationSeconds, 300)
        XCTAssertEqual(appState.flightRecords.first?.address, "Park")
        XCTAssertEqual(appState.flightRecords.first?.remark, "Good flight")
    }

    func testSaveUpdatesExisting() {
        let aId = UUID()
        let f = FlightRecord(aircraftId: aId, startAt: Date(), durationSeconds: 300)
        appState.addFlight(f)

        let vm = FlightEditViewModel(appState: appState, flight: f)
        vm.setupInitial()
        vm.durationSeconds = "600"
        vm.save()

        XCTAssertEqual(appState.flightRecords.count, 1)
        XCTAssertEqual(appState.flightRecords.first?.durationSeconds, 600)
    }

    func testSaveWithCoordinate() {
        let aId = UUID()
        let vm = FlightEditViewModel(appState: appState, flight: nil)
        vm.selectedAircraftId = aId
        vm.durationSeconds = "120"
        vm.setCoordinate(CLLocationCoordinate2D(latitude: 39.9, longitude: 116.4))
        vm.save()

        XCTAssertEqual(appState.flightRecords.first?.latitude, 39.9)
        XCTAssertEqual(appState.flightRecords.first?.longitude, 116.4)
    }

    func testSaveWithoutCoordinate() {
        let vm = FlightEditViewModel(appState: appState, flight: nil)
        vm.selectedAircraftId = UUID()
        vm.save()

        XCTAssertNil(appState.flightRecords.first?.latitude)
        XCTAssertNil(appState.flightRecords.first?.longitude)
    }

    func testSaveInvalidDoesNothing() {
        let vm = FlightEditViewModel(appState: appState, flight: nil)
        vm.save()
        XCTAssertTrue(appState.flightRecords.isEmpty)
    }

    func testSaveEmptyStringsAreNil() {
        let vm = FlightEditViewModel(appState: appState, flight: nil)
        vm.selectedAircraftId = UUID()
        vm.address = ""
        vm.remark = ""
        vm.save()

        XCTAssertNil(appState.flightRecords.first?.address)
        XCTAssertNil(appState.flightRecords.first?.remark)
    }

    func testSaveWhitespaceStringsKept() {
        let vm = FlightEditViewModel(appState: appState, flight: nil)
        vm.selectedAircraftId = UUID()
        vm.address = "   "
        vm.remark = "   "
        vm.save()

        XCTAssertEqual(appState.flightRecords.first?.address, "   ")
        XCTAssertEqual(appState.flightRecords.first?.remark, "   ")
    }
}
