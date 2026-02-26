import Foundation

struct Battery: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var code: String?
    var capacityMah: Int?
    var cells: Int?
    var cycles: Int
    var status: BatteryStatus
    var remark: String?
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), name: String, code: String? = nil, capacityMah: Int? = nil, cells: Int? = nil, cycles: Int = 0, status: BatteryStatus = .active, remark: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.code = code
        self.capacityMah = capacityMah
        self.cells = cells
        self.cycles = cycles
        self.status = status
        self.remark = remark
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum BatteryStatus: String, Codable, CaseIterable, Hashable {
    case active
    case retired
    case damaged

    var displayName: String {
        switch self {
        case .active: return "使用中"
        case .retired: return "已退役"
        case .damaged: return "损坏"
        }
    }
}
