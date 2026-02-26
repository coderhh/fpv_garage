import Foundation

struct FlightRecord: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var aircraftId: UUID
    var batteryIds: [UUID]
    var startAt: Date
    var durationSeconds: Int
    var address: String?
    var latitude: Double?
    var longitude: Double?
    var remark: String?
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), aircraftId: UUID, batteryIds: [UUID] = [], startAt: Date, durationSeconds: Int, address: String? = nil, latitude: Double? = nil, longitude: Double? = nil, remark: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.aircraftId = aircraftId
        self.batteryIds = batteryIds
        self.startAt = startAt
        self.durationSeconds = durationSeconds
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.remark = remark
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
