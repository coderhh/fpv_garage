import XCTest
@testable import FPVGarage

final class PromptBuilderTests: XCTestCase {

    private func makeContext(
        aircraftName: String = "Test Quad",
        flightStyle: FlightStyle? = .freestyle,
        pilotSkillLevel: PilotSkillLevel? = .intermediate,
        frameSizeInch: Double? = 5.0,
        motorModel: String? = "T-Motor F60",
        motorKv: Int? = 1950,
        propSize: String? = "51466",
        twrRatio: Double? = 6.5,
        twrTier: TWRTier? = .good,
        batteryCells: Int? = 6,
        batteryCapacityMah: Int? = 1300,
        partCountsByCategory: [String: Int] = [:],
        compatibilityWarningSummary: [String] = [],
        deviceLocale: String = "en"
    ) -> FleetContextDTO {
        FleetContextDTO(
            aircraftName: aircraftName,
            flightStyle: flightStyle,
            pilotSkillLevel: pilotSkillLevel,
            frameSizeInch: frameSizeInch,
            motorModel: motorModel,
            motorKv: motorKv,
            propSize: propSize,
            twrRatio: twrRatio,
            twrTier: twrTier,
            batteryCells: batteryCells,
            batteryCapacityMah: batteryCapacityMah,
            partCountsByCategory: partCountsByCategory,
            compatibilityWarningSummary: compatibilityWarningSummary,
            deviceLocale: deviceLocale
        )
    }

    // MARK: - Message structure

    func testBuildMessagesProducesSystemAndUser() {
        let context = makeContext()
        let messages = PromptBuilder.buildMessages(from: context)

        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0].role, "system")
        XCTAssertEqual(messages[1].role, "user")
    }

    // MARK: - System prompt

    func testSystemPromptContainsFPVDomain() {
        let system = PromptBuilder.systemPrompt(locale: "en")
        XCTAssertTrue(system.contains("FPV"))
        XCTAssertTrue(system.contains("thrust-to-weight"))
        XCTAssertTrue(system.contains("JSON"))
    }

    func testSystemPromptEnglishLocale() {
        let system = PromptBuilder.systemPrompt(locale: "en")
        XCTAssertTrue(system.contains("English"))
        XCTAssertFalse(system.contains("Chinese"))
    }

    func testSystemPromptChineseLocale() {
        let system = PromptBuilder.systemPrompt(locale: "zh-Hans")
        XCTAssertTrue(system.contains("Chinese"))
    }

    func testSystemPromptContainsJSONSchema() {
        let system = PromptBuilder.systemPrompt(locale: "en")
        XCTAssertTrue(system.contains("configSummary"))
        XCTAssertTrue(system.contains("strengths"))
        XCTAssertTrue(system.contains("improvements"))
        XCTAssertTrue(system.contains("twrComment"))
        XCTAssertTrue(system.contains("compatibilityNotes"))
    }

    // MARK: - User prompt content

    func testUserPromptContainsAircraftName() {
        let context = makeContext(aircraftName: "My Racing Quad")
        let user = PromptBuilder.userPrompt(from: context)
        XCTAssertTrue(user.contains("My Racing Quad"))
    }

    func testUserPromptContainsFlightStyle() {
        let context = makeContext(flightStyle: .racing)
        let user = PromptBuilder.userPrompt(from: context)
        XCTAssertTrue(user.contains("racing"))
    }

    func testUserPromptContainsMotorKv() {
        let context = makeContext(motorKv: 2400)
        let user = PromptBuilder.userPrompt(from: context)
        XCTAssertTrue(user.contains("2400"))
    }

    func testUserPromptContainsTWR() {
        let context = makeContext(twrRatio: 7.2, twrTier: .ideal)
        let user = PromptBuilder.userPrompt(from: context)
        XCTAssertTrue(user.contains("7.2"))
        XCTAssertTrue(user.contains("ideal"))
    }

    func testUserPromptContainsBatteryInfo() {
        let context = makeContext(batteryCells: 6, batteryCapacityMah: 1300)
        let user = PromptBuilder.userPrompt(from: context)
        XCTAssertTrue(user.contains("6S"))
        XCTAssertTrue(user.contains("1300mAh"))
    }

    func testUserPromptContainsCompatWarnings() {
        let context = makeContext(compatibilityWarningSummary: ["RPM too high for frame"])
        let user = PromptBuilder.userPrompt(from: context)
        XCTAssertTrue(user.contains("RPM too high for frame"))
    }

    func testUserPromptContainsPartCounts() {
        let context = makeContext(partCountsByCategory: ["motor": 4, "propeller": 8])
        let user = PromptBuilder.userPrompt(from: context)
        XCTAssertTrue(user.contains("motor: 4"))
        XCTAssertTrue(user.contains("propeller: 8"))
    }

    // MARK: - Low stock signals (Phase 3)

    func testUserPromptContainsLowStockCategories() {
        let context = makeContext(partCountsByCategory: ["motor": 1, "propeller": 8, "esc": 1])
        let user = PromptBuilder.userPrompt(from: context)
        XCTAssertTrue(user.contains("Low stock"))
        // motor and esc have quantity <= 1, so they appear in low stock
        let lowStockLine = user.components(separatedBy: "\n").first { $0.contains("Low stock") }!
        XCTAssertTrue(lowStockLine.contains("esc"))
        XCTAssertTrue(lowStockLine.contains("motor"))
        // propeller has quantity 8, so it should NOT appear in low stock line
        XCTAssertFalse(lowStockLine.contains("propeller"))
    }

    func testUserPromptOmitsLowStockWhenAllAboveThreshold() {
        let context = makeContext(partCountsByCategory: ["motor": 4, "propeller": 8])
        let user = PromptBuilder.userPrompt(from: context)
        XCTAssertFalse(user.contains("Low stock"))
    }

    // MARK: - Part suggestion instructions in system prompt

    func testSystemPromptContainsPartSuggestionInstructions() {
        let system = PromptBuilder.systemPrompt(locale: "en")
        XCTAssertTrue(system.contains("partSuggestions"))
        XCTAssertTrue(system.contains("priority"))
        XCTAssertTrue(system.contains("independent verification"))
    }

    // MARK: - Omits nil fields

    func testUserPromptOmitsNilFields() {
        let context = makeContext(
            flightStyle: nil,
            pilotSkillLevel: nil,
            motorModel: nil,
            motorKv: nil,
            twrRatio: nil,
            twrTier: nil,
            batteryCells: nil,
            batteryCapacityMah: nil
        )
        let user = PromptBuilder.userPrompt(from: context)
        XCTAssertFalse(user.contains("Flight Style"))
        XCTAssertFalse(user.contains("Motor KV"))
        XCTAssertFalse(user.contains("TWR"))
        XCTAssertFalse(user.contains("Battery"))
    }

    // MARK: - Version

    func testSystemPromptVersionExists() {
        XCTAssertEqual(PromptBuilder.systemPromptVersion, "v1")
    }
}
