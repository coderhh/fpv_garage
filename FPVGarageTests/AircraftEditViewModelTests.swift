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

    // MARK: - Performance Data

    func testNewAircraftPerformanceDefaults() {
        let vm = AircraftEditViewModel(appState: appState, aircraft: nil)
        XCTAssertNil(vm.flightStyle)
        XCTAssertNil(vm.pilotSkillLevel)
        XCTAssertEqual(vm.frameSizeInch, "")
        XCTAssertEqual(vm.motorModel, "")
        XCTAssertEqual(vm.motorKv, "")
        XCTAssertEqual(vm.motorThrustGrams, "")
        XCTAssertNil(vm.motorThrustDataSource)
        XCTAssertEqual(vm.propSizeField, "")
        XCTAssertEqual(vm.allUpWeightGrams, "")
        XCTAssertEqual(vm.batteryCellCount, "")
    }

    func testEditAircraftLoadsPerformanceData() {
        let a = Aircraft(
            name: "Drone",
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
        let vm = AircraftEditViewModel(appState: appState, aircraft: a)
        XCTAssertEqual(vm.flightStyle, .freestyle)
        XCTAssertEqual(vm.pilotSkillLevel, .advanced)
        XCTAssertEqual(vm.frameSizeInch, "5.0")
        XCTAssertEqual(vm.motorModel, "T-Motor")
        XCTAssertEqual(vm.motorKv, "1950")
        XCTAssertEqual(vm.motorThrustGrams, "500")
        XCTAssertEqual(vm.motorThrustDataSource, .specSheet)
        XCTAssertEqual(vm.propSizeField, "51466")
        XCTAssertEqual(vm.allUpWeightGrams, "650")
        XCTAssertEqual(vm.batteryCellCount, "6")
    }

    func testSavePerformanceData() {
        let vm = AircraftEditViewModel(appState: appState, aircraft: nil)
        vm.name = "Drone"
        vm.flightStyle = .racing
        vm.motorKv = "2400"
        vm.motorThrustGrams = "600"
        vm.motorThrustDataSource = .measured
        vm.allUpWeightGrams = "500"
        vm.batteryCellCount = "6"
        vm.save()

        let saved = appState.aircraft.first
        XCTAssertEqual(saved?.flightStyle, .racing)
        XCTAssertEqual(saved?.motorKv, 2400)
        XCTAssertEqual(saved?.motorThrustGrams, 600)
        XCTAssertEqual(saved?.motorThrustDataSource, .measured)
        XCTAssertEqual(saved?.allUpWeightGrams, 500)
        XCTAssertEqual(saved?.batteryCellCount, 6)
    }

    func testSaveEmptyNumericFieldsAreNil() {
        let vm = AircraftEditViewModel(appState: appState, aircraft: nil)
        vm.name = "Drone"
        vm.motorKv = ""
        vm.allUpWeightGrams = "  "
        vm.save()

        let saved = appState.aircraft.first
        XCTAssertNil(saved?.motorKv)
        XCTAssertNil(saved?.allUpWeightGrams)
    }

    func testSaveInvalidNumericFieldsAreNil() {
        let vm = AircraftEditViewModel(appState: appState, aircraft: nil)
        vm.name = "Drone"
        vm.motorKv = "abc"
        vm.save()

        XCTAssertNil(appState.aircraft.first?.motorKv)
    }
}
