import Foundation

final class PartEditViewModel: ObservableObject {
    let appState: AppState
    let part: Part?

    @Published var name = ""
    @Published var category: PartCategory = .other
    @Published var quantity = "1"
    @Published var remark = ""

    var isNew: Bool { part == nil }
    var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    init(appState: AppState, part: Part?) {
        self.appState = appState
        self.part = part
        loadFromPart()
    }

    func save() {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return }

        let q = max(1, Int(quantity.trimmingCharacters(in: .whitespaces)) ?? 1)
        let trimmedRemark = remark.trimmingCharacters(in: .whitespaces).isEmpty
            ? nil : remark.trimmingCharacters(in: .whitespaces)

        if var p = part {
            p.name = n
            p.category = category
            p.quantity = q
            p.remark = trimmedRemark
            p.updatedAt = Date()
            appState.updatePart(p)
        } else {
            let new = Part(name: n, category: category, quantity: q, sourceAircraftId: nil, remark: trimmedRemark)
            appState.addPart(new)
        }
    }

    private func loadFromPart() {
        guard let p = part else { return }
        name = p.name
        category = p.category
        quantity = "\(p.quantity)"
        remark = p.remark ?? ""
    }
}
