import SwiftUI
import MapKit

struct FlightEditView: View {
    @StateObject private var viewModel: FlightEditViewModel
    @Environment(\.dismiss) private var dismiss

    init(appState: AppState, flight: FlightRecord?) {
        _viewModel = StateObject(wrappedValue: FlightEditViewModel(appState: appState, flight: flight))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Aircraft") {
                    Picker("Select Aircraft", selection: $viewModel.selectedAircraftId) {
                        Text("Please Select").tag(nil as UUID?)
                        ForEach(viewModel.aircraftList) { a in
                            Text(a.name).tag(a.id as UUID?)
                        }
                    }
                    .disabled(viewModel.aircraftList.isEmpty)
                }

                Section("Time & Duration") {
                    DatePicker("Takeoff Time", selection: $viewModel.startAt, displayedComponents: [.date, .hourAndMinute])
                    TextField("Duration (sec)", text: $viewModel.durationSeconds)
                        .keyboardType(.numberPad)
                }

                Section("Location") {
                    TextField("Address (Optional)", text: $viewModel.address, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Map Selection") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tap map to set flight location")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        MapReader { proxy in
                            Map(position: $viewModel.mapPosition, interactionModes: .all) {
                                if let coord = viewModel.coordinate {
                                    Annotation("Flight Location", coordinate: coord) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.red)
                                    }
                                }
                            }
                            .onTapGesture { position in
                                if let coord = proxy.convert(position, from: .local) {
                                    viewModel.setCoordinate(coord)
                                }
                            }
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        Button {
                            viewModel.requestCurrentLocation()
                        } label: {
                            Label("Use Current Location", systemImage: "location.fill")
                        }
                        if viewModel.coordinate != nil {
                            Button(role: .destructive) {
                                viewModel.clearCoordinate()
                            } label: {
                                Label("Clear Location", systemImage: "xmark.circle")
                            }
                        }
                    }
                }

                Section("Remark") {
                    TextField("Remark", text: $viewModel.remark, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(viewModel.isNew ? "Add Flight" : "Edit Flight")
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
            .onAppear { viewModel.setupInitial() }
        }
    }
}
