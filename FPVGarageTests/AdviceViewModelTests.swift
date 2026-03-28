import XCTest
@testable import FPVGarage

@MainActor
final class AdviceViewModelTests: XCTestCase {

    private var appState: AppState!
    private var mockLLM: MockLLMClient!
    private var mockKeyStore: MockAPIKeyStore!
    private var mockSessionRepo: MockAdviceSessionRepository!

    private let testAircraftId = UUID()

    private func makeAircraft() -> Aircraft {
        Aircraft(
            id: testAircraftId,
            name: "Test Quad",
            flightStyle: .freestyle,
            frameSizeInch: 5.0,
            motorKv: 1950,
            motorThrustGrams: 1200,
            motorThrustDataSource: .specSheet,
            propSize: "51466",
            allUpWeightGrams: 650,
            batteryCellCount: 6
        )
    }

    private func makeVM(aircraft: Aircraft? = nil) -> AdviceViewModel {
        AdviceViewModel(
            appState: appState,
            aircraft: aircraft ?? makeAircraft(),
            llmClient: mockLLM,
            apiKeyStore: mockKeyStore,
            sessionRepo: mockSessionRepo
        )
    }

    private func validResponseJSON() -> String {
        """
        {"configSummary":"Good build","strengths":["Solid motor choice"],"improvements":["Consider lighter frame"],"twrComment":"Good TWR","compatibilityNotes":[],"partSuggestions":null}
        """
    }

    override func setUp() async throws {
        appState = AppState(
            aircraftRepo: MockAircraftRepository(),
            batteryRepo: MockBatteryRepository(),
            flightRepo: MockFlightRepository(),
            partRepo: MockPartRepository(),
            imageStorage: MockImageStorage()
        )
        mockLLM = MockLLMClient()
        mockKeyStore = MockAPIKeyStore()
        mockSessionRepo = MockAdviceSessionRepository()

        // Clear consent for each test
        UserDefaults.standard.removeObject(forKey: "advice_consent_granted")
    }

    // MARK: - Offline Results

    func testComputeOfflineResultsWithPerformanceData() {
        let vm = makeVM()
        vm.computeOfflineResults()

        XCTAssertNotNil(vm.twrResult)
        XCTAssertEqual(vm.twrResult?.flightStyle, .freestyle)
    }

    func testComputeOfflineResultsWithoutPerformanceData() {
        let bare = Aircraft(name: "Bare")
        let vm = makeVM(aircraft: bare)
        vm.computeOfflineResults()

        XCTAssertNil(vm.twrResult)
        XCTAssertTrue(vm.compatWarnings.isEmpty)
    }

    // MARK: - No API Key

    func testRequestAdviceWithNoAPIKey() async {
        let vm = makeVM()
        await vm.requestAdvice()

        XCTAssertEqual(vm.error, .noAPIKey)
        XCTAssertNil(vm.adviceResponse)
        XCTAssertEqual(mockLLM.sendCallCount, 0)
    }

    // MARK: - Successful Request

    func testRequestAdviceSuccess() async {
        try! mockKeyStore.save(key: "sk-test", for: "openai")
        mockLLM.stubResponse(validResponseJSON())

        let vm = makeVM()
        await vm.requestAdvice()

        XCTAssertNil(vm.error)
        XCTAssertNotNil(vm.adviceResponse)
        XCTAssertEqual(vm.adviceResponse?.configSummary, "Good build")
        XCTAssertEqual(vm.adviceResponse?.strengths, ["Solid motor choice"])
        XCTAssertFalse(vm.isLoading)
        XCTAssertEqual(mockLLM.sendCallCount, 1)
    }

    // MARK: - Streaming

    func testStreamingTextAccumulates() async {
        try! mockKeyStore.save(key: "sk-test", for: "openai")
        mockLLM.stubStreamingResponse([
            "{\"configSummary\":\"Good",
            " build\",\"strengths\":[],\"improvements\":[],",
            "\"twrComment\":null,\"compatibilityNotes\":[],\"partSuggestions\":null}"
        ])

        let vm = makeVM()
        await vm.requestAdvice()

        XCTAssertNotNil(vm.adviceResponse)
        XCTAssertEqual(vm.adviceResponse?.configSummary, "Good build")
    }

    // MARK: - Error Handling

    func testLLMErrorPropagates() async {
        try! mockKeyStore.save(key: "sk-test", for: "openai")
        mockLLM.stubbedError = LLMError.rateLimited(retryAfterSeconds: 30)

        let vm = makeVM()
        await vm.requestAdvice()

        XCTAssertEqual(vm.error, .rateLimited(retryAfterSeconds: 30))
        XCTAssertNil(vm.adviceResponse)
    }

    func testEmptyResponseError() async {
        try! mockKeyStore.save(key: "sk-test", for: "openai")
        mockLLM.stubbedChunks = [] // No chunks at all

        let vm = makeVM()
        await vm.requestAdvice()

        XCTAssertEqual(vm.error, .emptyResponse)
    }

    func testMalformedResponseError() async {
        try! mockKeyStore.save(key: "sk-test", for: "openai")
        mockLLM.stubResponse("this is not json")

        let vm = makeVM()
        await vm.requestAdvice()

        XCTAssertEqual(vm.error, .malformedResponse)
    }

    // MARK: - Cache Hit

    func testCacheHitSkipsLLMCall() async {
        try! mockKeyStore.save(key: "sk-test", for: "openai")

        let aircraft = makeAircraft()
        let hash = ConfigHashCalculator.hash(aircraft: aircraft, battery: nil)
        let response = AdviceResponse(
            configSummary: "Cached", strengths: [], improvements: [],
            twrComment: nil, compatibilityNotes: []
        )
        let session = AdviceSession(
            aircraftId: aircraft.id,
            generatedAt: Date(),
            configHash: hash,
            contextSnapshot: FleetContextBuilder.build(
                aircraft: aircraft, battery: nil, twrResult: nil,
                compatWarnings: [], partCountsByCategory: [:]
            ),
            response: response
        )
        mockSessionRepo.saveSessions([session], for: aircraft.id)

        let vm = makeVM(aircraft: aircraft)
        await vm.requestAdvice()

        XCTAssertEqual(vm.adviceResponse?.configSummary, "Cached")
        XCTAssertEqual(mockLLM.sendCallCount, 0) // No LLM call
        XCTAssertFalse(vm.isStale)
    }

    // MARK: - Stale Detection

    func testStaleDetectionOnHashMismatch() async {
        try! mockKeyStore.save(key: "sk-test", for: "openai")
        mockLLM.stubResponse(validResponseJSON())

        let aircraft = makeAircraft()
        let response = AdviceResponse(
            configSummary: "Old", strengths: [], improvements: [],
            twrComment: nil, compatibilityNotes: []
        )
        let session = AdviceSession(
            aircraftId: aircraft.id,
            generatedAt: Date(),
            configHash: "different_hash",
            contextSnapshot: FleetContextBuilder.build(
                aircraft: aircraft, battery: nil, twrResult: nil,
                compatWarnings: [], partCountsByCategory: [:]
            ),
            response: response
        )
        mockSessionRepo.saveSessions([session], for: aircraft.id)

        let vm = makeVM(aircraft: aircraft)
        await vm.requestAdvice()

        // Should have called LLM since hash doesn't match
        XCTAssertEqual(mockLLM.sendCallCount, 1)
    }

    func testStaleDetectionOnExpiredTTL() async {
        try! mockKeyStore.save(key: "sk-test", for: "openai")
        mockLLM.stubResponse(validResponseJSON())

        let aircraft = makeAircraft()
        let hash = ConfigHashCalculator.hash(aircraft: aircraft, battery: nil)
        let response = AdviceResponse(
            configSummary: "Old", strengths: [], improvements: [],
            twrComment: nil, compatibilityNotes: []
        )
        let session = AdviceSession(
            aircraftId: aircraft.id,
            generatedAt: Date().addingTimeInterval(-8 * 24 * 3600), // 8 days ago
            configHash: hash,
            contextSnapshot: FleetContextBuilder.build(
                aircraft: aircraft, battery: nil, twrResult: nil,
                compatWarnings: [], partCountsByCategory: [:]
            ),
            response: response
        )
        mockSessionRepo.saveSessions([session], for: aircraft.id)

        let vm = makeVM(aircraft: aircraft)
        await vm.requestAdvice()

        // Should have called LLM since TTL expired
        XCTAssertEqual(mockLLM.sendCallCount, 1)
    }

    // MARK: - Force Refresh

    func testForceRefreshBypassesCache() async {
        try! mockKeyStore.save(key: "sk-test", for: "openai")
        mockLLM.stubResponse(validResponseJSON())

        let aircraft = makeAircraft()
        let hash = ConfigHashCalculator.hash(aircraft: aircraft, battery: nil)
        let response = AdviceResponse(
            configSummary: "Cached", strengths: [], improvements: [],
            twrComment: nil, compatibilityNotes: []
        )
        let session = AdviceSession(
            aircraftId: aircraft.id,
            generatedAt: Date(),
            configHash: hash,
            contextSnapshot: FleetContextBuilder.build(
                aircraft: aircraft, battery: nil, twrResult: nil,
                compatWarnings: [], partCountsByCategory: [:]
            ),
            response: response
        )
        mockSessionRepo.saveSessions([session], for: aircraft.id)

        let vm = makeVM(aircraft: aircraft)
        await vm.requestAdvice(forceRefresh: true)

        XCTAssertEqual(mockLLM.sendCallCount, 1)
        XCTAssertEqual(vm.adviceResponse?.configSummary, "Good build")
    }

    // MARK: - Session Persistence

    func testSessionPersistedAfterSuccess() async {
        try! mockKeyStore.save(key: "sk-test", for: "openai")
        mockLLM.stubResponse(validResponseJSON())

        let aircraft = makeAircraft()
        let vm = makeVM(aircraft: aircraft)
        await vm.requestAdvice()

        let sessions = mockSessionRepo.loadSessions(for: aircraft.id)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.response.configSummary, "Good build")
    }

    func testSessionCapAt20() async {
        try! mockKeyStore.save(key: "sk-test", for: "openai")
        mockLLM.stubResponse(validResponseJSON())

        let aircraft = makeAircraft()

        // Pre-fill with 20 sessions
        var existing: [AdviceSession] = []
        for i in 0..<20 {
            existing.append(AdviceSession(
                aircraftId: aircraft.id,
                generatedAt: Date().addingTimeInterval(Double(-i * 3600)),
                configHash: "old_\(i)",
                contextSnapshot: FleetContextBuilder.build(
                    aircraft: aircraft, battery: nil, twrResult: nil,
                    compatWarnings: [], partCountsByCategory: [:]
                ),
                response: AdviceResponse(
                    configSummary: "Old \(i)", strengths: [], improvements: [],
                    twrComment: nil, compatibilityNotes: []
                )
            ))
        }
        mockSessionRepo.saveSessions(existing, for: aircraft.id)

        let vm = makeVM(aircraft: aircraft)
        await vm.requestAdvice()

        let sessions = mockSessionRepo.loadSessions(for: aircraft.id)
        XCTAssertEqual(sessions.count, 20) // Capped, not 21
        XCTAssertEqual(sessions.first?.response.configSummary, "Good build") // Newest first
    }

    // MARK: - Delete All Sessions

    func testDeleteAllSessions() async {
        let aircraft = makeAircraft()
        mockSessionRepo.saveSessions([
            AdviceSession(
                aircraftId: aircraft.id,
                configHash: "x",
                contextSnapshot: FleetContextBuilder.build(
                    aircraft: aircraft, battery: nil, twrResult: nil,
                    compatWarnings: [], partCountsByCategory: [:]
                ),
                response: AdviceResponse(
                    configSummary: "Test", strengths: [], improvements: [],
                    twrComment: nil, compatibilityNotes: []
                )
            )
        ], for: aircraft.id)

        let vm = makeVM(aircraft: aircraft)
        vm.deleteAllSessions()

        XCTAssertTrue(mockSessionRepo.loadSessions(for: aircraft.id).isEmpty)
        XCTAssertNil(vm.cachedSession)
    }

    // MARK: - Consent

    func testConsentDefaultFalse() {
        let vm = makeVM()
        XCTAssertFalse(vm.hasConsented)
    }

    func testGrantAndRevokeConsent() {
        let vm = makeVM()
        vm.grantConsent()
        XCTAssertTrue(vm.hasConsented)

        vm.revokeConsent()
        XCTAssertFalse(vm.hasConsented)
    }

    // MARK: - hasAPIKey

    func testHasAPIKeyReturnsFalseInitially() {
        let vm = makeVM()
        XCTAssertFalse(vm.hasAPIKey)
    }

    func testHasAPIKeyReturnsTrueAfterSave() {
        try! mockKeyStore.save(key: "sk-test", for: "openai")
        let vm = makeVM()
        XCTAssertTrue(vm.hasAPIKey)
    }
}
