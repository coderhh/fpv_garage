import Foundation

enum PartCategory: String, Codable, CaseIterable, Hashable {
    case frame
    case motor
    case esc
    case flightController
    case camera
    case vtx
    case receiver
    case propeller
    case other

    var displayName: String {
        switch self {
        case .frame: return "机架 Frame"
        case .motor: return "电机 Motor"
        case .esc: return "电调 ESC"
        case .flightController: return "飞控 FC"
        case .camera: return "摄像头 Camera"
        case .vtx: return "图传 VTX"
        case .receiver: return "接收机 Receiver"
        case .propeller: return "桨叶 Propeller"
        case .other: return "其他 Other"
        }
    }
}

struct Part: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var category: PartCategory
    var quantity: Int
    /// Aircraft this part comes from (if any). Nil for loose inventory parts.
    var sourceAircraftId: UUID?
    var remark: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        category: PartCategory,
        quantity: Int = 1,
        sourceAircraftId: UUID? = nil,
        remark: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.quantity = max(1, quantity)
        self.sourceAircraftId = sourceAircraftId
        self.remark = remark
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

