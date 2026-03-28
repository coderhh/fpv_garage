import XCTest
@testable import FPVGarage

@MainActor
final class AdviceSessionStalenessTests: XCTestCase {

    private var appState: AppState!
    private var mockLLM: MockLLMClient!
    private var mockKeyStore: MockAPIKeyStore!
    private var mockSessionRepo: MockAdviceSessionRepository!

    private let aircraftId = UUID()

    private func makeAircraft(motorKv: Int? = 1950) -> Aircraft {
        Aircraft(
            id: aircraftId,
            name: "Test Quad",
            flightStyle: .freestyle,
            frameSizeInch: 5.0,
            motorKv: motorKv,
            motorThrustGrams: 1200,
            motorThrustDataSource: .specSheet,
            propSize: "51466",
            allUpWeightGrams: 650,
            batteryCellCount: 6
        )
    }

    private func makeSession(
        configHash: String,
        generatedAt: Date = Date()
    ) -> AdviceSession {
        AdviceSession(
            aircraftId: aircraftId,
            generatedAt: generatedAt,
            configHash: configHash,
            contextSnapshot: FleetContextDTO(
                aircraftName: "Test",
                partCountsByCategory: [:],
                compatibilityWarningSummary: [],
                deviceLocale: "en"
            ),
            response: AdviceResponse(
                configSummary: "Test", strengths: [], improvements: [],
                twrComment: nil, compatibilityNotes: []
            )
        )
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
        UserDefaults.standard.removeObject(forKey: "advice_consent_granted")
    }

    // MARK: - Hash match + fresh = cache hit

    func testFreshMatchingHashUsesCachedSession() async {
        try! mockKeyStore.save(key: "sk-test", for: "openai")

        let aircraft = makeAircraft()
        let hash = ConfigHashCalculator.hash(aircraft: aircraft, battery: nil)
        let session = makeSession(configHash: hash, generatedAt: Date())
        mockSessionRepo.saveSessions([session], for: aircraftId)

        let vm = AdviceViewModel(
            appState: appState, aircraft: aircraft,
            llmClient: mockLLM, apiKeyStore: mockKeyStore,
            sessionRepo: mockSessionRepo
        )
        await vm.requestAdvice()

        XCTAssertEqual(mockLLM.sendCallCount, 0) // Cache hit
        XCTAssertFalse(vm.isStale)
    }

    // MARK: - Hash mismatch + fresh = stale, calls LLM

    func testHashMismatchCallsLLM() async {
        try! mockKeyStore.save(key: "sk-test", for: "openai")
        mockLLM.stubResponse("""
        {"configSummary":"New","strengths":[],"improvements":[],"twrComment":null,"compatibilityNotes":[],"partSuggestions":null}
        """)

        let aircraft = makeAircraft()
        let session = makeSession(configHash: "different_hash", generatedAt: Date())
        mockSessionRepo.saveSessions([session], for: aircraftId)

        let vm = AdviceViewModel(
            appState: appState, aircraft: aircraft,
            llmClient: mockLLM, apiKeyStore: mockKeyStore,
            sessionRepo: mockSessionRepo
        )
        await vm.requestAdvice()

        XCTAssertEqual(mockLLM.sendCallCount, 1) // Stale → new request
    }

    // MARK: - Hash match + expired TTL = calls LLM

    func testExpiredTTLCallsLLM() async {
        try! mockKeyStore.save(key: "sk-test", for: "openai")
        mockLLM.stubResponse("""
        {"configSummary":"New","strengths":[],"improvements":[],"twrComment":null,"compatibilityNotes":[],"partSuggestions":null}
        """)

        let aircraft = makeAircraft()
        let hash = ConfigHashCalculator.hash(aircraft: aircraft, battery: nil)
        let session = makeSession(
            configHash: hash,
            generatedAt: Date().addingTimeInterval(-8 * 24 * 3600) // 8 days ago
        )
        mockSessionRepo.saveSessions([session], for: aircraftId)

        let vm = AdviceViewModel(
            appState: appState, aircraft: aircraft,
            llmClient: mockLLM, apiKeyStore: mockKeyStore,
            sessionRepo: mockSessionRepo
        )
        await vm.requestAdvice()

        XCTAssertEqual(mockLLM.sendCallCount, 1) // TTL expired
    }

    // MARK: - Hash mismatch + expired = stale, calls LLM

    func testBothMismatchAndExpiredCallsLLM() async {
        try! mockKeyStore.save(key: "sk-test", for: "openai")
        mockLLM.stubResponse("""
        {"configSummary":"New","strengths":[],"improvements":[],"twrComment":null,"compatibilityNotes":[],"partSuggestions":null}
        """)

        let aircraft = makeAircraft()
        let session = makeSession(
            configHash: "different_hash",
            generatedAt: Date().addingTimeInterval(-8 * 24 * 3600)
        )
        mockSessionRepo.saveSessions([session], for: aircraftId)

        let vm = AdviceViewModel(
            appState: appState, aircraft: aircraft,
            llmClient: mockLLM, apiKeyStore: mockKeyStore,
            sessionRepo: mockSessionRepo
        )
        await vm.requestAdvice()

        XCTAssertEqual(mockLLM.sendCallCount, 1)
    }

    // MARK: - Auto-pruning at 21

    func testAutoPruningAtSessionCap() async {
        try! mockKeyStore.save(key: "sk-test", for: "openai")
        mockLLM.stubResponse("""
        {"configSummary":"Newest","strengths":[],"improvements":[],"twrComment":null,"compatibilityNotes":[],"partSuggestions":null}
        """)

        let aircraft = makeAircraft()

        // Pre-fill with 20 sessions
        var existing: [AdviceSession] = []
        for i in 0..<20 {
            existing.append(makeSession(
                configHash: "old_\(i)"
            ))
        }
        mockSessionRepo.saveSessions(existing, for: aircraftId)

        let vm = AdviceViewModel(
            appState: appState, aircraft: aircraft,
            llmClient: mockLLM, apiKeyStore: mockKeyStore,
            sessionRepo: mockSessionRepo
        )
        await vm.requestAdvice()

        let sessions = mockSessionRepo.loadSessions(for: aircraftId)
        XCTAssertEqual(sessions.count, 20) // Capped at 20, not 21
        XCTAssertEqual(sessions.first?.response.configSummary, "Newest")
    }

    // MARK: - Delete all sessions

    func testDeleteAllSessionsClearsAndResetsCache() async {
        let aircraft = makeAircraft()
        let hash = ConfigHashCalculator.hash(aircraft: aircraft, battery: nil)
        mockSessionRepo.saveSessions([makeSession(configHash: hash)], for: aircraftId)

        let vm = AdviceViewModel(
            appState: appState, aircraft: aircraft,
            llmClient: mockLLM, apiKeyStore: mockKeyStore,
            sessionRepo: mockSessionRepo
        )
        vm.deleteAllSessions()

        XCTAssertTrue(mockSessionRepo.loadSessions(for: aircraftId).isEmpty)
        XCTAssertNil(vm.cachedSession)
    }
}
