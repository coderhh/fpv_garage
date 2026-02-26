import SwiftUI

struct BatteryEditView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss

    let battery: Battery?

    @State private var name: String = ""
    @State private var code: String = ""
    @State private var capacityMah: String = ""
    @State private var cells: String = ""
    @State private var cycles: String = "0"
    @State private var status: BatteryStatus = .active
    @State private var remark: String = ""

    private var isNew: Bool { battery == nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("名称", text: $name)
                    TextField("编号(选填)", text: $code)
                }
                Section("规格") {
                    TextField("容量(mAh)", text: $capacityMah)
                        .keyboardType(.numberPad)
                    TextField("电芯数(S)", text: $cells)
                        .keyboardType(.numberPad)
                    TextField("循环次数", text: $cycles)
                        .keyboardType(.numberPad)
                }
                Section("状态") {
                    Picker("状态", selection: $status) {
                        ForEach(BatteryStatus.allCases, id: \.self) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                }
                Section("备注") {
                    TextField("备注", text: $remark, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(isNew ? "添加电池" : "编辑电池")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let b = battery {
                    name = b.name
                    code = b.code ?? ""
                    capacityMah = b.capacityMah.map { "\($0)" } ?? ""
                    cells = b.cells.map { "\($0)" } ?? ""
                    cycles = "\(b.cycles)"
                    status = b.status
                    remark = b.remark ?? ""
                }
            }
        }
    }

    private func save() {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return }

        let cap = Int(capacityMah.trimmingCharacters(in: .whitespaces))
        let cellCount = Int(cells.trimmingCharacters(in: .whitespaces))
        let cycleCount = Int(cycles.trimmingCharacters(in: .whitespaces)) ?? 0

        if var b = battery {
            b.name = n
            b.code = code.trimmingCharacters(in: .whitespaces).isEmpty ? nil : code.trimmingCharacters(in: .whitespaces)
            b.capacityMah = cap
            b.cells = cellCount
            b.cycles = max(0, cycleCount)
            b.status = status
            b.remark = remark.trimmingCharacters(in: .whitespaces).isEmpty ? nil : remark.trimmingCharacters(in: .whitespaces)
            b.updatedAt = Date()
            store.updateBattery(b)
        } else {
            let new = Battery(
                name: n,
                code: code.trimmingCharacters(in: .whitespaces).isEmpty ? nil : code.trimmingCharacters(in: .whitespaces),
                capacityMah: cap,
                cells: cellCount,
                cycles: max(0, cycleCount),
                status: status,
                remark: remark.trimmingCharacters(in: .whitespaces).isEmpty ? nil : remark.trimmingCharacters(in: .whitespaces)
            )
            store.addBattery(new)
        }
        dismiss()
    }
}

