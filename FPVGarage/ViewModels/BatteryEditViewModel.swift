import Foundation

final class BatteryEditViewModel: ObservableObject {
    let appState: AppState
    let battery: Battery?

    @Published var name = ""
    @Published var code = ""
    @Published var capacityMah = ""
    @Published var cells = ""
    @Published var cycles = "0"
    @Published var cRating = ""
    @Published var status: BatteryStatus = .active
    @Published var remark = ""

    var isNew: Bool { battery == nil }
    var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    init(appState: AppState, battery: Battery?) {
        self.appState = appState
        self.battery = battery
        loadFromBattery()
    }

    func save() {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return }

        let cap = Int(capacityMah.trimmingCharacters(in: .whitespaces))
        let cellCount = Int(cells.trimmingCharacters(in: .whitespaces))
        let cycleCount = Int(cycles.trimmingCharacters(in: .whitespaces)) ?? 0
        let cRatingValue = Int(cRating.trimmingCharacters(in: .whitespaces))

        if var b = battery {
            b.name = n
            b.code = trimmed(code)
            b.capacityMah = cap
            b.cells = cellCount
            b.cycles = max(0, cycleCount)
            b.cRating = cRatingValue
            b.status = status
            b.remark = trimmed(remark)
            b.updatedAt = Date()
            appState.updateBattery(b)
        } else {
            let new = Battery(
                name: n, code: trimmed(code),
                capacityMah: cap, cells: cellCount,
                cycles: max(0, cycleCount), cRating: cRatingValue,
                status: status, remark: trimmed(remark)
            )
            appState.addBattery(new)
        }
    }

    private func loadFromBattery() {
        guard let b = battery else { return }
        name = b.name
        code = b.code ?? ""
        capacityMah = b.capacityMah.map { "\($0)" } ?? ""
        cells = b.cells.map { "\($0)" } ?? ""
        cycles = "\(b.cycles)"
        cRating = b.cRating.map { "\($0)" } ?? ""
        status = b.status
        remark = b.remark ?? ""
    }

    private func trimmed(_ s: String) -> String? {
        let t = s.trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? nil : t
    }
}
