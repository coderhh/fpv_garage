import XCTest
@testable import FPVGarage

final class AircraftEditViewModelTests: XCTestCase {
    var appState: AppState!
    var imageStorage: MockImageStorage!

    override func setUp() {
        super.setUp()
        imageStorage = MockImageStorage()
        appState = AppState(
            aircraftRepo: MockAircraftRepository(),
            batteryRepo: MockBatteryRepository(),
            flightRepo: MockFlightRepository(),
            partRepo: MockPartRepository(),
            imageStorage: imageStorage
        )
    }

    func testNewAircraftDefaults() {
        let vm = AircraftEditViewModel(appState: appState, aircraft: nil)
        XCTAssertTrue(vm.isNew)
        XCTAssertFalse(vm.canSave)
        XCTAssertEqual(vm.name, "")
        XCTAssertEqual(vm.model, "")
        XCTAssertEqual(vm.frame, "")
    }

    func testEditAircraftLoadsData() {
        let a = Aircraft(name: "Drone", model: "Custom",
                         setup: AircraftSetup(frame: "Apex", motor: "2306", esc: "35A",
                                              flightController: "F7", camera: "DJI",
                                              vtx: "1W", receiver: "ELRS",
                                              propeller: "5145", other: "GPS"),
                         remark: "Test")
        let vm = AircraftEditViewModel(appState: appState, aircraft: a)
        XCTAssertFalse(vm.isNew)
        XCTAssertEqual(vm.name, "Drone")
        XCTAssertEqual(vm.model, "Custom")
        XCTAssertEqual(vm.frame, "Apex")
        XCTAssertEqual(vm.motor, "2306")
        XCTAssertEqual(vm.esc, "35A")
        XCTAssertEqual(vm.flightController, "F7")
        XCTAssertEqual(vm.camera, "DJI")
        XCTAssertEqual(vm.vtx, "1W")
        XCTAssertEqual(vm.receiver, "ELRS")
        XCTAssertEqual(vm.propeller, "5145")
        XCTAssertEqual(vm.otherSetup, "GPS")
        XCTAssertEqual(vm.remark, "Test")
    }

    func testCanSaveWithName() {
        let vm = AircraftEditViewModel(appState: appState, aircraft: nil)
        vm.name = "Test"
        XCTAssertTrue(vm.canSave)
    }

    func testCanSaveWhitespaceOnly() {
        let vm = AircraftEditViewModel(appState: appState, aircraft: nil)
        vm.name = "   "
        XCTAssertFalse(vm.canSave)
    }

    func testSaveNewAircraft() {
        let vm = AircraftEditViewModel(appState: appState, aircraft: nil)
        vm.name = "New Drone"
        vm.model = "Custom"
        vm.frame = "Apex"
        vm.motor = "2306"
        vm.save()

        XCTAssertEqual(appState.aircraft.count, 1)
        XCTAssertEqual(appState.aircraft.first?.name, "New Drone")
        XCTAssertEqual(appState.aircraft.first?.model, "Custom")
        XCTAssertNotNil(appState.aircraft.first?.setup)
    }

    func testSaveUpdatesExisting() {
        let a = Aircraft(name: "Old")
        appState.addAircraft(a)
        let vm = AircraftEditViewModel(appState: appState, aircraft: a)
        vm.name = "New"
        vm.save()

        XCTAssertEqual(appState.aircraft.count, 1)
        XCTAssertEqual(appState.aircraft.first?.name, "New")
    }

    func testSaveWithPhoto() {
        let vm = AircraftEditViewModel(appState: appState, aircraft: nil)
        vm.name = "Photo Drone"
        vm.photoData = Data([0xFF, 0xD8, 0xFF, 0xE0])
        vm.save()

        XCTAssertEqual(appState.aircraft.count, 1)
        XCTAssertNotNil(appState.aircraft.first?.imageFileName)
    }

    func testSaveEmptyNameDoesNothing() {
        let vm = AircraftEditViewModel(appState: appState, aircraft: nil)
        vm.name = ""
        vm.save()
        XCTAssertTrue(appState.aircraft.isEmpty)
    }

    func testSaveWhitespaceNameDoesNothing() {
        let vm = AircraftEditViewModel(appState: appState, aircraft: nil)
        vm.name = "   "
        vm.save()
        XCTAssertTrue(appState.aircraft.isEmpty)
    }

    func testSaveSyncsPartsFromSetup() {
        let vm = AircraftEditViewModel(appState: appState, aircraft: nil)
        vm.name = "Drone"
        vm.frame = "Apex"
        vm.motor = "2306"
        vm.esc = "35A"
        vm.save()

        XCTAssertEqual(appState.parts.count, 3)
    }

    func testSaveEmptySetupNoParts() {
        let vm = AircraftEditViewModel(appState: appState, aircraft: nil)
        vm.name = "Drone"
        vm.save()

        XCTAssertTrue(appState.parts.isEmpty)
    }

    func testSaveUpdatedSetupResyncsParts() {
        let a = Aircraft(name: "Drone", setup: AircraftSetup(frame: "Old"))
        appState.addAircraft(a)
        appState.syncParts(for: a)
        XCTAssertEqual(appState.parts.count, 1)

        let vm = AircraftEditViewModel(appState: appState, aircraft: a)
        vm.frame = "New"
        vm.motor = "Motor"
        vm.save()

        XCTAssertEqual(appState.parts.count, 2)
    }

    func testExistingImageURLForNew() {
        let vm = AircraftEditViewModel(appState: appState, aircraft: nil)
        XCTAssertNil(vm.existingImageURL())
    }

    func testExistingImageURLWithImage() {
        let id = UUID()
        imageStorage.savedImages[id] = Data([0x01])
        let a = Aircraft(id: id, name: "Test", imageFileName: "\(id.uuidString).jpg")
        let vm = AircraftEditViewModel(appState: appState, aircraft: a)
        XCTAssertNotNil(vm.existingImageURL())
    }

    func testSaveTrimsOptionalFields() {
        let vm = AircraftEditViewModel(appState: appState, aircraft: nil)
        vm.name = "Drone"
        vm.model = "  "
        vm.remark = "  "
        vm.save()

        XCTAssertNil(appState.aircraft.first?.model)
        XCTAssertNil(appState.aircraft.first?.remark)
    }
}
