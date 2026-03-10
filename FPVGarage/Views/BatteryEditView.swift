import SwiftUI

struct BatteryEditView: View {
    @StateObject private var viewModel: BatteryEditViewModel
    @Environment(\.dismiss) private var dismiss

    init(appState: AppState, battery: Battery?) {
        _viewModel = StateObject(wrappedValue: BatteryEditViewModel(appState: appState, battery: battery))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $viewModel.name)
                    TextField("Serial (Optional)", text: $viewModel.code)
                }
                Section("Specifications") {
                    TextField("Capacity (mAh)", text: $viewModel.capacityMah)
                        .keyboardType(.numberPad)
                    TextField("Cell Count (S)", text: $viewModel.cells)
                        .keyboardType(.numberPad)
                    TextField("Cycle Count", text: $viewModel.cycles)
                        .keyboardType(.numberPad)
                }
                Section("Status") {
                    Picker("Status", selection: $viewModel.status) {
                        ForEach(BatteryStatus.allCases, id: \.self) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                }
                Section("Remark") {
                    TextField("Remark", text: $viewModel.remark, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(viewModel.isNew ? "Add Battery" : "Edit Battery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save()
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }
}
