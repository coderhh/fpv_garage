import SwiftUI

struct PartDetailView: View {
    @EnvironmentObject var appState: AppState
    let part: Part
    @State private var showEdit = false

    private var sourceAircraft: Aircraft? {
        guard let id = part.sourceAircraftId else { return nil }
        return appState.findAircraft(by: id)
    }

    var body: some View {
        List {
            Section("Basic Info") {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(part.name)
                        .foregroundStyle(.primary)
                }
                HStack {
                    Text("Type")
                    Spacer()
                    Text(part.category.displayName)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Quantity")
                    Spacer()
                    Text("x\(part.quantity)")
                        .foregroundStyle(.primary)
                }
            }

            if let aircraft = sourceAircraft {
                Section("Source Aircraft") {
                    NavigationLink(value: aircraft) {
                        HStack {
                            Text(aircraft.name)
                            if let model = aircraft.model, !model.isEmpty {
                                Text(model)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }

            if let remark = part.remark, !remark.isEmpty {
                Section("Remark") {
                    Text(remark)
                        .font(.body)
                }
            }

            Section("Metadata") {
                HStack {
                    Text("Created")
                    Spacer()
                    Text(DateFormatter.localizedString(from: part.createdAt, dateStyle: .medium, timeStyle: .short))
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Last Updated")
                    Spacer()
                    Text(DateFormatter.localizedString(from: part.updatedAt, dateStyle: .medium, timeStyle: .short))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Part Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) {
            PartEditView(appState: appState, part: part)
        }
    }
}
