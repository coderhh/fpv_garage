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
        case .frame: return String(localized: "Frame")
        case .motor: return String(localized: "Motor")
        case .esc: return String(localized: "ESC")
        case .flightController: return String(localized: "Flight Controller")
        case .camera: return String(localized: "Camera")
        case .vtx: return String(localized: "VTX")
        case .receiver: return String(localized: "Receiver")
        case .propeller: return String(localized: "Propeller")
        case .other: return String(localized: "Other")
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

