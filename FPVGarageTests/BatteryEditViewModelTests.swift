import XCTest
@testable import FPVGarage

final class BatteryEditViewModelTests: XCTestCase {
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

    func testNewBatteryDefaults() {
        let vm = BatteryEditViewModel(appState: appState, battery: nil)
        XCTAssertTrue(vm.isNew)
        XCTAssertFalse(vm.canSave)
        XCTAssertEqual(vm.name, "")
        XCTAssertEqual(vm.code, "")
        XCTAssertEqual(vm.capacityMah, "")
        XCTAssertEqual(vm.cells, "")
        XCTAssertEqual(vm.cycles, "0")
        XCTAssertEqual(vm.status, .active)
        XCTAssertEqual(vm.remark, "")
    }

    func testEditBatteryLoadsData() {
        let b = Battery(name: "Tattu", code: "T1", capacityMah: 1300, cells: 6,
                        cycles: 10, status: .retired, remark: "Old")
        let vm = BatteryEditViewModel(appState: appState, battery: b)
        XCTAssertFalse(vm.isNew)
        XCTAssertEqual(vm.name, "Tattu")
        XCTAssertEqual(vm.code, "T1")
        XCTAssertEqual(vm.capacityMah, "1300")
        XCTAssertEqual(vm.cells, "6")
        XCTAssertEqual(vm.cycles, "10")
        XCTAssertEqual(vm.status, .retired)
        XCTAssertEqual(vm.remark, "Old")
    }

    func testCanSaveWithName() {
        let vm = BatteryEditViewModel(appState: appState, battery: nil)
        vm.name = "Battery"
        XCTAssertTrue(vm.canSave)
    }

    func testCanSaveWhitespace() {
        let vm = BatteryEditViewModel(appState: appState, battery: nil)
        vm.name = "   "
        XCTAssertFalse(vm.canSave)
    }

    func testSaveNewBattery() {
        let vm = BatteryEditViewModel(appState: appState, battery: nil)
        vm.name = "New Battery"
        vm.capacityMah = "1500"
        vm.cells = "6"
        vm.cycles = "0"
        vm.save()

        XCTAssertEqual(appState.batteries.count, 1)
        XCTAssertEqual(appState.batteries.first?.name, "New Battery")
        XCTAssertEqual(appState.batteries.first?.capacityMah, 1500)
        XCTAssertEqual(appState.batteries.first?.cells, 6)
    }

    func testSaveUpdatesExisting() {
        let b = Battery(name: "Old")
        appState.addBattery(b)
        let vm = BatteryEditViewModel(appState: appState, battery: b)
        vm.name = "Updated"
        vm.cycles = "5"
        vm.status = .damaged
        vm.save()

        XCTAssertEqual(appState.batteries.first?.name, "Updated")
        XCTAssertEqual(appState.batteries.first?.cycles, 5)
        XCTAssertEqual(appState.batteries.first?.status, .damaged)
    }

    func testSaveEmptyNameDoesNothing() {
        let vm = BatteryEditViewModel(appState: appState, battery: nil)
        vm.save()
        XCTAssertTrue(appState.batteries.isEmpty)
    }

    func testSaveOptionalFieldsNilWhenEmpty() {
        let vm = BatteryEditViewModel(appState: appState, battery: nil)
        vm.name = "Battery"
        vm.code = ""
        vm.capacityMah = ""
        vm.cells = ""
        vm.remark = "  "
        vm.save()

        XCTAssertNil(appState.batteries.first?.code)
        XCTAssertNil(appState.batteries.first?.capacityMah)
        XCTAssertNil(appState.batteries.first?.cells)
        XCTAssertNil(appState.batteries.first?.remark)
    }

    func testSaveNegativeCyclesClampedToZero() {
        let vm = BatteryEditViewModel(appState: appState, battery: nil)
        vm.name = "Battery"
        vm.cycles = "-5"
        vm.save()
        XCTAssertEqual(appState.batteries.first?.cycles, 0)
    }

    func testSaveInvalidCyclesDefaultsToZero() {
        let vm = BatteryEditViewModel(appState: appState, battery: nil)
        vm.name = "Battery"
        vm.cycles = "abc"
        vm.save()
        XCTAssertEqual(appState.batteries.first?.cycles, 0)
    }

    func testSaveWithAllFields() {
        let vm = BatteryEditViewModel(appState: appState, battery: nil)
        vm.name = "Full Battery"
        vm.code = "FB-001"
        vm.capacityMah = "1300"
        vm.cells = "4"
        vm.cycles = "25"
        vm.status = .active
        vm.remark = "Good condition"
        vm.save()

        let b = appState.batteries.first
        XCTAssertEqual(b?.name, "Full Battery")
        XCTAssertEqual(b?.code, "FB-001")
        XCTAssertEqual(b?.capacityMah, 1300)
        XCTAssertEqual(b?.cells, 4)
        XCTAssertEqual(b?.cycles, 25)
        XCTAssertEqual(b?.status, .active)
        XCTAssertEqual(b?.remark, "Good condition")
    }
}
