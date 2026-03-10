import Foundation
import Combine

final class HomeViewModel: ObservableObject {
    let appState: AppState
    private var cancellables = Set<AnyCancellable>()

    @Published var isExporting = false
    @Published var exportDocument: AllDataDocument?

    var flightCount: Int { appState.flightRecords.count }
    var totalDuration: Int { appState.flightRecords.reduce(0) { $0 + $1.durationSeconds } }
    var aircraftCount: Int { appState.aircraft.count }
    var batteryCount: Int { appState.batteries.count }
    var partCount: Int { appState.parts.count }

    init(appState: AppState) {
        self.appState = appState
        appState.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func prepareExport() {
        let snapshot = AllDataSnapshot(
            aircraft: appState.aircraft,
            batteries: appState.batteries,
            flights: appState.flightRecords,
            parts: appState.parts
        )
        exportDocument = AllDataDocument(snapshot: snapshot)
        isExporting = true
    }

    func seedTestData() {
        appState.seedTestData()
    }

    func clearAllData() {
        appState.clearAllData()
    }
}
