import XCTest
@testable import FPVGarage

final class AdviceSessionRepositoryTests: XCTestCase {

    private var storage: FileStorageService!
    private var repo: AdviceSessionRepository!
    private let aircraftId = UUID()

    override func setUp() {
        super.setUp()
        storage = FileStorageService()
        repo = AdviceSessionRepository(storage: storage)
    }

    override func tearDown() {
        // Clean up advice_sessions files
        let base = storage.storageBaseURL.appendingPathComponent("advice_sessions", isDirectory: true)
        try? FileManager.default.removeItem(at: base)
        super.tearDown()
    }

    private func makeSession(
        aircraftId: UUID? = nil,
        generatedAt: Date = Date(),
        configHash: String = "abc123"
    ) -> AdviceSession {
        AdviceSession(
            aircraftId: aircraftId ?? self.aircraftId,
            generatedAt: generatedAt,
            configHash: configHash,
            contextSnapshot: FleetContextDTO(
                aircraftName: "Test",
                partCountsByCategory: [:],
                compatibilityWarningSummary: [],
                deviceLocale: "en"
            ),
            response: AdviceResponse(
                configSummary: "Test summary",
                strengths: ["Good"],
                improvements: ["Better"],
                twrComment: nil,
                compatibilityNotes: []
            )
        )
    }

    // MARK: - Basic CRUD

    func testSaveAndLoad() {
        let session = makeSession()
        repo.saveSessions([session], for: aircraftId)

        let loaded = repo.loadSessions(for: aircraftId)
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.id, session.id)
        XCTAssertEqual(loaded.first?.response.configSummary, "Test summary")
    }

    func testLoadEmptyReturnsEmptyArray() {
        let loaded = repo.loadSessions(for: UUID())
        XCTAssertTrue(loaded.isEmpty)
    }

    func testOverwriteExistingSessions() {
        let s1 = makeSession(configHash: "hash1")
        repo.saveSessions([s1], for: aircraftId)

        let s2 = makeSession(configHash: "hash2")
        repo.saveSessions([s2], for: aircraftId)

        let loaded = repo.loadSessions(for: aircraftId)
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.configHash, "hash2")
    }

    // MARK: - Multiple sessions

    func testMultipleSessions() {
        let s1 = makeSession(configHash: "hash1")
        let s2 = makeSession(configHash: "hash2")
        repo.saveSessions([s1, s2], for: aircraftId)

        let loaded = repo.loadSessions(for: aircraftId)
        XCTAssertEqual(loaded.count, 2)
    }

    // MARK: - Per-aircraft isolation

    func testPerAircraftIsolation() {
        let id1 = UUID()
        let id2 = UUID()

        repo.saveSessions([makeSession(aircraftId: id1)], for: id1)
        repo.saveSessions([makeSession(aircraftId: id2), makeSession(aircraftId: id2)], for: id2)

        XCTAssertEqual(repo.loadSessions(for: id1).count, 1)
        XCTAssertEqual(repo.loadSessions(for: id2).count, 2)
    }

    // MARK: - Latest session

    func testLatestSessionReturnsMostRecent() {
        let older = makeSession(generatedAt: Date().addingTimeInterval(-3600), configHash: "old")
        let newer = makeSession(generatedAt: Date(), configHash: "new")
        repo.saveSessions([older, newer], for: aircraftId)

        let latest = repo.latestSession(for: aircraftId)
        XCTAssertEqual(latest?.configHash, "new")
    }

    func testLatestSessionReturnsNilWhenEmpty() {
        XCTAssertNil(repo.latestSession(for: UUID()))
    }

    // MARK: - Clear

    func testSaveEmptyArrayClears() {
        repo.saveSessions([makeSession()], for: aircraftId)
        repo.saveSessions([], for: aircraftId)

        XCTAssertTrue(repo.loadSessions(for: aircraftId).isEmpty)
    }
}
