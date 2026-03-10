import XCTest
@testable import FPVGarage

final class PartEditViewModelTests: XCTestCase {
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

    func testNewPartDefaults() {
        let vm = PartEditViewModel(appState: appState, part: nil)
        XCTAssertTrue(vm.isNew)
        XCTAssertFalse(vm.canSave)
        XCTAssertEqual(vm.name, "")
        XCTAssertEqual(vm.category, .other)
        XCTAssertEqual(vm.quantity, "1")
        XCTAssertEqual(vm.remark, "")
    }

    func testEditPartLoadsData() {
        let p = Part(name: "Motor", category: .motor, quantity: 4, remark: "Spare")
        let vm = PartEditViewModel(appState: appState, part: p)
        XCTAssertFalse(vm.isNew)
        XCTAssertEqual(vm.name, "Motor")
        XCTAssertEqual(vm.category, .motor)
        XCTAssertEqual(vm.quantity, "4")
        XCTAssertEqual(vm.remark, "Spare")
    }

    func testCanSaveWithName() {
        let vm = PartEditViewModel(appState: appState, part: nil)
        vm.name = "Frame"
        XCTAssertTrue(vm.canSave)
    }

    func testCanSaveWhitespace() {
        let vm = PartEditViewModel(appState: appState, part: nil)
        vm.name = "   "
        XCTAssertFalse(vm.canSave)
    }

    func testSaveNewPart() {
        let vm = PartEditViewModel(appState: appState, part: nil)
        vm.name = "Frame"
        vm.category = .frame
        vm.quantity = "2"
        vm.save()

        XCTAssertEqual(appState.parts.count, 1)
        XCTAssertEqual(appState.parts.first?.name, "Frame")
        XCTAssertEqual(appState.parts.first?.category, .frame)
        XCTAssertEqual(appState.parts.first?.quantity, 2)
        XCTAssertNil(appState.parts.first?.sourceAircraftId)
    }

    func testSaveUpdatesExisting() {
        let p = Part(name: "Old", category: .frame)
        appState.addPart(p)
        let vm = PartEditViewModel(appState: appState, part: p)
        vm.name = "New"
        vm.category = .motor
        vm.quantity = "4"
        vm.save()

        XCTAssertEqual(appState.parts.count, 1)
        XCTAssertEqual(appState.parts.first?.name, "New")
        XCTAssertEqual(appState.parts.first?.category, .motor)
        XCTAssertEqual(appState.parts.first?.quantity, 4)
    }

    func testSaveEmptyNameDoesNothing() {
        let vm = PartEditViewModel(appState: appState, part: nil)
        vm.save()
        XCTAssertTrue(appState.parts.isEmpty)
    }

    func testSaveQuantityMinimumOne() {
        let vm = PartEditViewModel(appState: appState, part: nil)
        vm.name = "Part"
        vm.quantity = "0"
        vm.save()
        XCTAssertEqual(appState.parts.first?.quantity, 1)
    }

    func testSaveNegativeQuantityBecomesOne() {
        let vm = PartEditViewModel(appState: appState, part: nil)
        vm.name = "Part"
        vm.quantity = "-5"
        vm.save()
        XCTAssertEqual(appState.parts.first?.quantity, 1)
    }

    func testSaveInvalidQuantityDefaultsToOne() {
        let vm = PartEditViewModel(appState: appState, part: nil)
        vm.name = "Part"
        vm.quantity = "abc"
        vm.save()
        XCTAssertEqual(appState.parts.first?.quantity, 1)
    }

    func testSaveRemarkTrimmed() {
        let vm = PartEditViewModel(appState: appState, part: nil)
        vm.name = "Part"
        vm.remark = "  "
        vm.save()
        XCTAssertNil(appState.parts.first?.remark)
    }

    func testSaveRemarkNonEmpty() {
        let vm = PartEditViewModel(appState: appState, part: nil)
        vm.name = "Part"
        vm.remark = "Some note"
        vm.save()
        XCTAssertEqual(appState.parts.first?.remark, "Some note")
    }

    func testSaveAllCategories() {
        for cat in PartCategory.allCases {
            let vm = PartEditViewModel(appState: appState, part: nil)
            vm.name = "Part-\(cat.rawValue)"
            vm.category = cat
            vm.save()
        }
        XCTAssertEqual(appState.parts.count, PartCategory.allCases.count)
    }
}
