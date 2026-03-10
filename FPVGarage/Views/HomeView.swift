import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @State private var showSettings = false
    @State private var showClearConfirmation = false

    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(appState: appState))
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Overview") {
                    HStack {
                        Label("Flight Count", systemImage: "airplane")
                        Spacer()
                        Text("\(viewModel.flightCount)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Total Duration (sec)", systemImage: "clock")
                        Spacer()
                        Text("\(viewModel.totalDuration)")
                            .foregroundStyle(.green)
                    }
                    HStack {
                        Label("Aircraft", systemImage: "cube.box")
                        Spacer()
                        Text("\(viewModel.aircraftCount)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Batteries", systemImage: "battery.100")
                        Spacer()
                        Text("\(viewModel.batteryCount)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Parts", systemImage: "wrench.and.screwdriver")
                        Spacer()
                        Text("\(viewModel.partCount)")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Data") {
                    Button {
                        viewModel.prepareExport()
                    } label: {
                        Label("Export All Data (JSON)", systemImage: "square.and.arrow.up")
                    }
                }
                #if DEBUG
                Section("Development & Testing") {
                    Button {
                        viewModel.seedTestData()
                    } label: {
                        Label("Generate Test Data", systemImage: "doc.badge.plus")
                    }
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        Label("Clear All Data", systemImage: "trash")
                    }
                }
                #endif
            }
            .navigationTitle("FPV Garage")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityIdentifier("settingsButton")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .confirmationDialog("Clear All Data", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                Button("Delete All", role: .destructive) {
                    viewModel.clearAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all aircraft, batteries, flights, and parts. This action cannot be undone.")
            }
        }
        .fileExporter(
            isPresented: $viewModel.isExporting,
            document: viewModel.exportDocument,
            contentType: .json,
            defaultFilename: "fpv-garage-backup"
        ) { _ in }
    }
}
