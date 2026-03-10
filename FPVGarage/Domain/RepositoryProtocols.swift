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
