import Foundation

/// Detailed setup fields for the drone (all optional)
struct AircraftSetup: Codable, Equatable, Hashable {
    var frame: String?
    var motor: String?
    var esc: String?
    var flightController: String?
    var camera: String?
    var vtx: String?
    var receiver: String?
    var propeller: String?
    var other: String?

    static var empty: AircraftSetup { AircraftSetup() }

    var isEmpty: Bool {
        [frame, motor, esc, flightController, camera, vtx, receiver, propeller, other]
            .allSatisfy { $0?.trimmingCharacters(in: .whitespaces).isEmpty ?? true }
    }
}

struct Aircraft: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var model: String?
    /// Filename of the photo in Documents (e.g. "aircraft_<uuid>.jpg")
    var imageFileName: String?
    var setup: AircraftSetup?
    var remark: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        model: String? = nil,
        imageFileName: String? = nil,
        setup: AircraftSetup? = nil,
        remark: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.model = model
        self.imageFileName = imageFileName
        self.setup = setup
        self.remark = remark
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var setupOrEmpty: AircraftSetup { setup ?? .empty }
}
