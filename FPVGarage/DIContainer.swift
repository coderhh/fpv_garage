import Foundation
import UIKit

final class DIContainer: ObservableObject {
    let appState: AppState
    let apiKeyStore: APIKeyStoreProtocol
    let adviceSessionRepo: AdviceSessionRepositoryProtocol

    @Published var selectedProvider: LLMProvider {
        didSet {
            LLMProvider.selected = selectedProvider
        }
    }

    var llmClient: LLMClientProtocol {
        LLMClientFactory.makeClient(provider: selectedProvider, apiKeyStore: apiKeyStore)
    }

    init() {
        let storage = FileStorageService()

        let aircraftRepo = AircraftRepository(storage: storage)
        let batteryRepo = BatteryRepository(storage: storage)
        let flightRepo = FlightRepository(storage: storage)
        let partRepo = PartRepository(storage: storage)
        let imageRepo = ImageRepository(storage: storage)

        let keyStore = APIKeyStore()
        self.apiKeyStore = keyStore
        self.selectedProvider = LLMProvider.selected
        self.adviceSessionRepo = AdviceSessionRepository(storage: storage)

        self.appState = AppState(
            aircraftRepo: aircraftRepo,
            batteryRepo: batteryRepo,
            flightRepo: flightRepo,
            partRepo: partRepo,
            imageStorage: imageRepo
        )

        storage.resolveICloud { [weak appState] in
            appState?.loadAll()
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil, queue: .main
        ) { [weak appState] _ in
            appState?.loadAll()
        }
    }
}
