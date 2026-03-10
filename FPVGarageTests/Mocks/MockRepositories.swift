import Foundation
@testable import FPVGarage

final class MockAircraftRepository: AircraftRepositoryProtocol {
    var items: [Aircraft] = []
    func loadAll() -> [Aircraft] { items }
    func save(_ items: [Aircraft]) { self.items = items }
}

final class MockBatteryRepository: BatteryRepositoryProtocol {
    var items: [Battery] = []
    func loadAll() -> [Battery] { items }
    func save(_ items: [Battery]) { self.items = items }
}

final class MockFlightRepository: FlightRepositoryProtocol {
    var items: [FlightRecord] = []
    func loadAll() -> [FlightRecord] { items }
    func save(_ items: [FlightRecord]) { self.items = items }
}

final class MockPartRepository: PartRepositoryProtocol {
    var items: [Part] = []
    func loadAll() -> [Part] { items }
    func save(_ items: [Part]) { self.items = items }
}

final class MockImageStorage: ImageStorageProtocol {
    var savedImages: [UUID: Data] = [:]
    var deletedFiles: [String] = []

    func saveImage(aircraftId: UUID, imageData: Data) -> String? {
        savedImages[aircraftId] = imageData
        return "\(aircraftId.uuidString).jpg"
    }

    func imageURL(aircraftId: UUID, fileName: String?) -> URL? {
        guard let fn = fileName, savedImages[aircraftId] != nil else { return nil }
        return URL(fileURLWithPath: "/tmp/\(fn)")
    }

    func deleteImage(fileName: String?) {
        if let fn = fileName { deletedFiles.append(fn) }
    }
}
