import Foundation

@MainActor
final class AdviceViewModel: ObservableObject {
    let appState: AppState
    let aircraft: Aircraft
    private let llmClient: LLMClientProtocol
    private let apiKeyStore: APIKeyStoreProtocol
    private let sessionRepo: AdviceSessionRepositoryProtocol

    @Published var twrResult: ThrustToWeightResult?
    @Published var compatWarnings: [CompatibilityWarning] = []
    @Published var adviceResponse: AdviceResponse?
    @Published var streamingText: String = ""
    @Published var isLoading: Bool = false
    @Published var error: LLMError?
    @Published var cachedSession: AdviceSession?
    @Published var isStale: Bool = false
    @Published var hasConsented: Bool

    private static let consentKey = "advice_consent_granted"
    private static let sessionCap = 20
    private static let staleTTLSeconds: TimeInterval = 7 * 24 * 3600 // 7 days

    init(
        appState: AppState,
        aircraft: Aircraft,
        llmClient: LLMClientProtocol,
        apiKeyStore: APIKeyStoreProtocol,
        sessionRepo: AdviceSessionRepositoryProtocol
    ) {
        self.appState = appState
        self.aircraft = aircraft
        self.llmClient = llmClient
        self.apiKeyStore = apiKeyStore
        self.sessionRepo = sessionRepo
        self.hasConsented = UserDefaults.standard.bool(forKey: Self.consentKey)
    }

    var hasAPIKey: Bool {
        apiKeyStore.load(for: LLMProvider.selected.keychainKey) != nil
    }

    func grantConsent() {
        hasConsented = true
        UserDefaults.standard.set(true, forKey: Self.consentKey)
    }

    func revokeConsent() {
        hasConsented = false
        UserDefaults.standard.set(false, forKey: Self.consentKey)
    }

    // MARK: - Offline Results

    func computeOfflineResults() {
        twrResult = ThrustToWeightCalculator.calculate(from: aircraft)
        compatWarnings = CompatibilityChecker.check(aircraft: aircraft, battery: linkedBattery)
    }

    // MARK: - LLM Advice

    func requestAdvice(forceRefresh: Bool = false) async {
        error = nil
        isLoading = true
        streamingText = ""
        adviceResponse = nil

        defer { isLoading = false }

        computeOfflineResults()

        let currentHash = ConfigHashCalculator.hash(aircraft: aircraft, battery: linkedBattery)

        // Check cache
        if !forceRefresh, let latest = sessionRepo.latestSession(for: aircraft.id) {
            let age = Date().timeIntervalSince(latest.generatedAt)
            if latest.configHash == currentHash && age < Self.staleTTLSeconds {
                cachedSession = latest
                adviceResponse = latest.response
                isStale = false
                return
            }
            isStale = latest.configHash != currentHash
        }

        guard hasAPIKey else {
            error = .noAPIKey
            return
        }

        let partCounts = buildPartCounts()
        let context = FleetContextBuilder.build(
            aircraft: aircraft,
            battery: linkedBattery,
            twrResult: twrResult,
            compatWarnings: compatWarnings,
            partCountsByCategory: partCounts
        )

        let messages = PromptBuilder.buildMessages(from: context)
        let request = LLMRequest(messages: messages)

        do {
            let stream = try await llmClient.send(request: request)
            var accumulated = ""

            for await chunk in stream {
                accumulated += chunk.delta
                streamingText = accumulated
            }

            guard !accumulated.isEmpty else {
                error = .emptyResponse
                return
            }

            guard let data = accumulated.data(using: .utf8),
                  let response = try? JSONDecoder().decode(AdviceResponse.self, from: data) else {
                error = .malformedResponse
                return
            }

            adviceResponse = response

            // Persist session
            let session = AdviceSession(
                aircraftId: aircraft.id,
                configHash: currentHash,
                contextSnapshot: context,
                thrustToWeightResult: twrResult,
                compatibilityWarnings: compatWarnings,
                response: response
            )
            persistSession(session)
            cachedSession = session
            isStale = false

        } catch let llmError as LLMError {
            error = llmError
        } catch {
            self.error = .streamInterrupted
        }
    }

    // MARK: - Session Management

    func deleteAllSessions() {
        sessionRepo.saveSessions([], for: aircraft.id)
        cachedSession = nil
    }

    // MARK: - Private

    private var linkedBattery: Battery? {
        // Find the most recently used battery for this aircraft from flight records
        let flights = appState.flightRecords.filter { $0.aircraftId == aircraft.id }
        guard let lastFlight = flights.sorted(by: { $0.startAt > $1.startAt }).first,
              let batteryId = lastFlight.batteryIds.first else {
            return nil
        }
        return appState.batteries.first { $0.id == batteryId }
    }

    private func buildPartCounts() -> [String: Int] {
        let parts = appState.parts.filter { $0.sourceAircraftId == aircraft.id }
        var counts: [String: Int] = [:]
        for part in parts {
            counts[part.category.rawValue, default: 0] += part.quantity
        }
        return counts
    }

    private func persistSession(_ session: AdviceSession) {
        var sessions = sessionRepo.loadSessions(for: aircraft.id)
        sessions.insert(session, at: 0)
        if sessions.count > Self.sessionCap {
            sessions = Array(sessions.prefix(Self.sessionCap))
        }
        sessionRepo.saveSessions(sessions, for: aircraft.id)
    }
}
