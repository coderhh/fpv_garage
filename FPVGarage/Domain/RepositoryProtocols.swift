import Foundation

protocol AircraftRepositoryProtocol {
    func loadAll() -> [Aircraft]
    func save(_ items: [Aircraft])
}

protocol BatteryRepositoryProtocol {
    func loadAll() -> [Battery]
    func save(_ items: [Battery])
}

protocol FlightRepositoryProtocol {
    func loadAll() -> [FlightRecord]
    func save(_ items: [FlightRecord])
}

protocol PartRepositoryProtocol {
    func loadAll() -> [Part]
    func save(_ items: [Part])
}

protocol ImageStorageProtocol {
    func saveImage(aircraftId: UUID, imageData: Data) -> String?
    func imageURL(aircraftId: UUID, fileName: String?) -> URL?
    func deleteImage(fileName: String?)
}

protocol AdviceSessionRepositoryProtocol {
    func loadSessions(for aircraftId: UUID) -> [AdviceSession]
    func saveSessions(_ sessions: [AdviceSession], for aircraftId: UUID)
    func latestSession(for aircraftId: UUID) -> AdviceSession?
}
