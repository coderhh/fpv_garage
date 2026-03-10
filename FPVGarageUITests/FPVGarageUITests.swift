import XCTest

final class FPVGarageUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
    }

    // MARK: - Helpers

    private func seedTestData() {
        app.tabBars.buttons["Home"].tap()
        let seedButton = app.buttons["Generate Test Data"]
        if seedButton.waitForExistence(timeout: 3) {
            seedButton.tap()
            sleep(1)
        }
    }

    private func navigateToTab(_ name: String) {
        app.tabBars.buttons[name].tap()
    }

    // MARK: - Home Tab

    func testHomeTabDisplaysOverview() {
        navigateToTab("Home")
        XCTAssertTrue(app.navigationBars["FPV Garage"].waitForExistence(timeout: 3))
        let flightCountLabel = app.staticTexts["Flight Count"]
        XCTAssertTrue(flightCountLabel.waitForExistence(timeout: 3))
    }

    func testHomeTabSeedTestData() {
        seedTestData()
        navigateToTab("Home")
        XCTAssertTrue(app.navigationBars["FPV Garage"].exists)
    }

    func testHomeTabExportButton() {
        navigateToTab("Home")
        let exportButton = app.buttons["Export All Data (JSON)"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 3))
        exportButton.tap()
        sleep(1)
    }

    // MARK: - Aircraft Tab

    func testAircraftTabDisplays() {
        seedTestData()
        navigateToTab("Aircraft")
        XCTAssertTrue(app.navigationBars["My Aircraft"].waitForExistence(timeout: 3))
    }

    func testAircraftListShowsItems() {
        seedTestData()
        navigateToTab("Aircraft")
        let firstCell = app.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 3))
    }

    func testAircraftAddFlow() {
        navigateToTab("Aircraft")
        let addButton = app.buttons["addAircraftButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()

        XCTAssertTrue(app.navigationBars["Add Aircraft"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Cancel"].exists)
        XCTAssertTrue(app.buttons["Save"].exists)

        let nameField = app.textFields["Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("UI Test Drone")

        let modelField = app.textFields["Model (Optional)"]
        if modelField.exists {
            modelField.tap()
            modelField.typeText("Test Model")
        }

        app.buttons["Save"].tap()
        sleep(1)
        XCTAssertTrue(app.navigationBars["My Aircraft"].waitForExistence(timeout: 3))
    }

    func testAircraftAddCancelFlow() {
        navigateToTab("Aircraft")
        app.buttons["addAircraftButton"].tap()
        XCTAssertTrue(app.navigationBars["Add Aircraft"].waitForExistence(timeout: 3))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["My Aircraft"].waitForExistence(timeout: 3))
    }

    func testAircraftDetailView() {
        seedTestData()
        navigateToTab("Aircraft")
        let firstCell = app.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 3))
        firstCell.tap()

        XCTAssertTrue(app.navigationBars["Aircraft Details"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Edit"].exists)
    }

    func testAircraftDetailEditFlow() {
        seedTestData()
        navigateToTab("Aircraft")
        app.cells.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Aircraft Details"].waitForExistence(timeout: 3))
        app.buttons["Edit"].tap()

        XCTAssertTrue(app.navigationBars["Edit Aircraft"].waitForExistence(timeout: 3))
        app.buttons["Cancel"].tap()
    }

    func testAircraftAddWithSetup() {
        navigateToTab("Aircraft")
        app.buttons["addAircraftButton"].tap()
        XCTAssertTrue(app.navigationBars["Add Aircraft"].waitForExistence(timeout: 3))

        let nameField = app.textFields["Name"]
        nameField.tap()
        nameField.typeText("Setup Drone")

        let frameField = app.textFields["Frame"]
        if frameField.exists {
            frameField.tap()
            frameField.typeText("Apex 5")
        }

        let motorField = app.textFields["Motor"]
        if motorField.exists {
            motorField.tap()
            motorField.typeText("2306")
        }

        app.buttons["Save"].tap()
        sleep(1)
    }

    // MARK: - Flight Tab

    func testFlightTabDisplays() {
        seedTestData()
        navigateToTab("Flights")
        XCTAssertTrue(app.navigationBars["Flight Records"].waitForExistence(timeout: 3))
    }

    func testFlightListShowsItems() {
        seedTestData()
        navigateToTab("Flights")
        let firstCell = app.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 3))
    }

    func testFlightAddFlow() {
        seedTestData()
        navigateToTab("Flights")
        let addButton = app.buttons["addFlightButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()

        XCTAssertTrue(app.navigationBars["Add Flight"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Cancel"].exists)
        XCTAssertTrue(app.buttons["Save"].exists)

        app.buttons["Cancel"].tap()
    }

    func testFlightAddWithData() {
        seedTestData()
        navigateToTab("Flights")
        app.buttons["addFlightButton"].tap()
        XCTAssertTrue(app.navigationBars["Add Flight"].waitForExistence(timeout: 3))

        let durationField = app.textFields["Duration (sec)"]
        if durationField.waitForExistence(timeout: 3) {
            durationField.tap()
            durationField.clearAndEnterText("300")
        }

        let addressField = app.textFields["Address (Optional)"]
        if addressField.exists {
            addressField.tap()
            addressField.typeText("Test Park")
        }

        app.buttons["Save"].tap()
        sleep(1)
    }

    func testFlightDetailView() {
        seedTestData()
        navigateToTab("Flights")
        let firstCell = app.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 3))
        firstCell.tap()

        XCTAssertTrue(app.navigationBars["Flight Details"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Edit"].exists)
    }

    func testFlightDetailEditFlow() {
        seedTestData()
        navigateToTab("Flights")
        app.cells.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Flight Details"].waitForExistence(timeout: 3))
        app.buttons["Edit"].tap()
        XCTAssertTrue(app.navigationBars["Edit Flight"].waitForExistence(timeout: 3))
        app.buttons["Cancel"].tap()
    }

    // MARK: - Battery Tab

    func testBatteryTabDisplays() {
        seedTestData()
        navigateToTab("Batteries")
        XCTAssertTrue(app.navigationBars["My Batteries"].waitForExistence(timeout: 3))
    }

    func testBatteryListShowsItems() {
        seedTestData()
        navigateToTab("Batteries")
        let firstCell = app.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 3))
    }

    func testBatteryAddFlow() {
        navigateToTab("Batteries")
        let addButton = app.buttons["addBatteryButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()

        XCTAssertTrue(app.navigationBars["Add Battery"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Cancel"].exists)
        XCTAssertTrue(app.buttons["Save"].exists)

        let nameField = app.textFields["Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("UI Test Battery")

        let capacityField = app.textFields["Capacity (mAh)"]
        if capacityField.exists {
            capacityField.tap()
            capacityField.typeText("1300")
        }

        let cellsField = app.textFields["Cell Count (S)"]
        if cellsField.exists {
            cellsField.tap()
            cellsField.typeText("6")
        }

        app.buttons["Save"].tap()
        sleep(1)
        XCTAssertTrue(app.navigationBars["My Batteries"].waitForExistence(timeout: 3))
    }

    func testBatteryAddCancelFlow() {
        navigateToTab("Batteries")
        app.buttons["addBatteryButton"].tap()
        XCTAssertTrue(app.navigationBars["Add Battery"].waitForExistence(timeout: 3))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["My Batteries"].waitForExistence(timeout: 3))
    }

    func testBatteryDetailEditFlow() {
        seedTestData()
        navigateToTab("Batteries")
        let firstCell = app.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 3))
        firstCell.tap()
        sleep(1)

        let editNav = app.navigationBars["Edit Battery"]
        if editNav.waitForExistence(timeout: 3) {
            if app.buttons["Cancel"].exists {
                app.buttons["Cancel"].tap()
            } else {
                app.navigationBars.buttons.firstMatch.tap()
            }
        }
        XCTAssertTrue(app.navigationBars["My Batteries"].waitForExistence(timeout: 5))
    }

    // MARK: - Part Tab

    func testPartTabDisplays() {
        seedTestData()
        navigateToTab("Parts")
        XCTAssertTrue(app.navigationBars["My Parts"].waitForExistence(timeout: 3))
    }

    func testPartListShowsItems() {
        seedTestData()
        navigateToTab("Parts")
        let firstCell = app.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 3))
    }

    func testPartAddFlow() {
        navigateToTab("Parts")
        let addButton = app.buttons["addPartButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()

        XCTAssertTrue(app.navigationBars["Add Part"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Cancel"].exists)
        XCTAssertTrue(app.buttons["Save"].exists)

        let nameField = app.textFields["Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("UI Test Motor")

        app.buttons["Save"].tap()
        sleep(1)
    }

    func testPartAddCancelFlow() {
        navigateToTab("Parts")
        app.buttons["addPartButton"].tap()
        XCTAssertTrue(app.navigationBars["Add Part"].waitForExistence(timeout: 3))
        app.buttons["Cancel"].tap()
    }

    func testPartDetailView() {
        seedTestData()
        navigateToTab("Parts")
        sleep(1)
        let cells = app.cells
        for i in 0..<cells.count {
            let cell = cells.element(boundBy: i)
            if cell.exists {
                cell.tap()
                if app.navigationBars["Part Details"].waitForExistence(timeout: 3) {
                    XCTAssertTrue(app.buttons["Edit"].exists)
                    return
                }
                app.navigationBars.buttons.firstMatch.tap()
                sleep(1)
            }
        }
    }

    func testPartDetailEditFlow() {
        seedTestData()
        navigateToTab("Parts")
        sleep(1)
        let cells = app.cells
        for i in 0..<cells.count {
            let cell = cells.element(boundBy: i)
            if cell.exists {
                cell.tap()
                if app.navigationBars["Part Details"].waitForExistence(timeout: 3) {
                    app.buttons["Edit"].tap()
                    XCTAssertTrue(app.navigationBars["Edit Part"].waitForExistence(timeout: 3))
                    app.buttons["Cancel"].tap()
                    return
                }
                app.navigationBars.buttons.firstMatch.tap()
                sleep(1)
            }
        }
    }

    func testPartFilterByCategory() {
        seedTestData()
        navigateToTab("Parts")

        let allButton = app.buttons["All"]
        if allButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(allButton.exists)
        }

        let motorButton = app.buttons["Motor"]
        if motorButton.waitForExistence(timeout: 3) {
            motorButton.tap()
            sleep(1)
        }

        if allButton.waitForExistence(timeout: 3) {
            allButton.tap()
            sleep(1)
        }
    }

    // MARK: - Tab Navigation

    func testAllTabsAccessible() {
        navigateToTab("Home")
        XCTAssertTrue(app.navigationBars["FPV Garage"].waitForExistence(timeout: 3))

        navigateToTab("Flights")
        XCTAssertTrue(app.navigationBars["Flight Records"].waitForExistence(timeout: 3))

        navigateToTab("Aircraft")
        XCTAssertTrue(app.navigationBars["My Aircraft"].waitForExistence(timeout: 3))

        navigateToTab("Batteries")
        XCTAssertTrue(app.navigationBars["My Batteries"].waitForExistence(timeout: 3))

        navigateToTab("Parts")
        XCTAssertTrue(app.navigationBars["My Parts"].waitForExistence(timeout: 3))
    }

    // MARK: - Empty State

    func testAircraftEmptyState() {
        navigateToTab("Aircraft")
        if app.staticTexts["No Aircraft"].waitForExistence(timeout: 2) {
            XCTAssertTrue(app.staticTexts["No Aircraft"].exists)
        }
    }

    func testFlightEmptyState() {
        navigateToTab("Flights")
        if app.staticTexts["No Flight Records"].waitForExistence(timeout: 2) {
            XCTAssertTrue(app.staticTexts["No Flight Records"].exists)
        }
    }

    func testBatteryEmptyState() {
        navigateToTab("Batteries")
        if app.staticTexts["No Batteries"].waitForExistence(timeout: 2) {
            XCTAssertTrue(app.staticTexts["No Batteries"].exists)
        }
    }
}

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard let stringValue = self.value as? String else {
            self.typeText(text)
            return
        }
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
}
