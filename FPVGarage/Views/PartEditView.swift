import SwiftUI

struct PartEditView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss

    let part: Part?

    @State private var name: String = ""
    @State private var category: PartCategory = .other
    @State private var quantity: String = "1"
    @State private var remark: String = ""

    private var isNew: Bool { part == nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("名称", text: $name)
                    Picker("类型", selection: $category) {
                        ForEach(PartCategory.allCases, id: \.self) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                }
                Section("数量") {
                    TextField("数量", text: $quantity)
                        .keyboardType(.numberPad)
                }
                Section("备注") {
                    TextField("备注", text: $remark, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(isNew ? "添加部件" : "编辑部件")
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
                if let p = part {
                    name = p.name
                    category = p.category
                    quantity = "\(p.quantity)"
                    remark = p.remark ?? ""
                }
            }
        }
    }

    private func save() {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return }

        let q = max(1, Int(quantity.trimmingCharacters(in: .whitespaces)) ?? 1)

        if var p = part {
            p.name = n
            p.category = category
            p.quantity = q
            p.remark = remark.trimmingCharacters(in: .whitespaces).isEmpty ? nil : remark.trimmingCharacters(in: .whitespaces)
            p.updatedAt = Date()
            store.updatePart(p)
        } else {
            let new = Part(
                name: n,
                category: category,
                quantity: q,
                sourceAircraftId: nil,
                remark: remark.trimmingCharacters(in: .whitespaces).isEmpty ? nil : remark.trimmingCharacters(in: .whitespaces)
            )
            store.addPart(new)
        }
        dismiss()
    }
}

