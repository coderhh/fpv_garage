import SwiftUI

struct PartEditView: View {
    @StateObject private var viewModel: PartEditViewModel
    @Environment(\.dismiss) private var dismiss

    init(appState: AppState, part: Part?) {
        _viewModel = StateObject(wrappedValue: PartEditViewModel(appState: appState, part: part))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $viewModel.name)
                    Picker("Type", selection: $viewModel.category) {
                        ForEach(PartCategory.allCases, id: \.self) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                }
                Section("Quantity") {
                    TextField("Quantity", text: $viewModel.quantity)
                        .keyboardType(.numberPad)
                }
                Section("Remark") {
                    TextField("Remark", text: $viewModel.remark, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(viewModel.isNew ? "Add Part" : "Edit Part")
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
