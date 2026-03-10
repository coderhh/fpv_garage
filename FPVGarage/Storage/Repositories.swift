import Foundation

final class AircraftRepository: AircraftRepositoryProtocol {
    private let storage: FileStorageService
    init(storage: FileStorageService) { self.storage = storage }
    func loadAll() -> [Aircraft] { storage.load([Aircraft].self, from: "aircraft.json") ?? [] }
    func save(_ items: [Aircraft]) { storage.save(items, to: "aircraft.json") }
}

final class BatteryRepository: BatteryRepositoryProtocol {
    private let storage: FileStorageService
    init(storage: FileStorageService) { self.storage = storage }
    func loadAll() -> [Battery] { storage.load([Battery].self, from: "batteries.json") ?? [] }
    func save(_ items: [Battery]) { storage.save(items, to: "batteries.json") }
}

final class FlightRepository: FlightRepositoryProtocol {
    private let storage: FileStorageService
    init(storage: FileStorageService) { self.storage = storage }
    func loadAll() -> [FlightRecord] { storage.load([FlightRecord].self, from: "flight_records.json") ?? [] }
    func save(_ items: [FlightRecord]) { storage.save(items, to: "flight_records.json") }
}

final class PartRepository: PartRepositoryProtocol {
    private let storage: FileStorageService
    init(storage: FileStorageService) { self.storage = storage }
    func loadAll() -> [Part] { storage.load([Part].self, from: "parts.json") ?? [] }
    func save(_ items: [Part]) { storage.save(items, to: "parts.json") }
}

final class ImageRepository: ImageStorageProtocol {
    private let storage: FileStorageService
    private let fileManager = FileManager.default

    init(storage: FileStorageService) { self.storage = storage }

    func saveImage(aircraftId: UUID, imageData: Data) -> String? {
        let filename = "\(aircraftId.uuidString).jpg"
        let url = storage.aircraftImagesURL.appendingPathComponent(filename)
        guard (try? imageData.write(to: url)) != nil else { return nil }
        return filename
    }

    func imageURL(aircraftId: UUID, fileName: String?) -> URL? {
        guard let fn = fileName else { return nil }
        let url = storage.aircraftImagesURL.appendingPathComponent(fn)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func deleteImage(fileName: String?) {
        guard let fn = fileName else { return }
        let url = storage.aircraftImagesURL.appendingPathComponent(fn)
        try? fileManager.removeItem(at: url)
    }
}
