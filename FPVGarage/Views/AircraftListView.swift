import SwiftUI

struct AircraftListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAdd = false
    @State private var aircraftPendingDelete: Aircraft?
    @State private var showDeleteOptions = false

    var body: some View {
        NavigationStack {
            Group {
                if appState.aircraft.isEmpty {
                    ContentUnavailableView("No Aircraft", systemImage: "cube.box", description: Text("Tap + to add"))
                } else {
                    List {
                        ForEach(appState.aircraft) { item in
                            NavigationLink(value: item) {
                                AircraftRowView(item: item, appState: appState)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    aircraftPendingDelete = item
                                    showDeleteOptions = true
                                } label: { Text("Delete") }
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Aircraft")
            .navigationDestination(for: Aircraft.self) { item in
                AircraftDetailView(aircraft: item)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Image(systemName: "plus.circle.fill") }
                        .accessibilityIdentifier("addAircraftButton")
                }
            }
            .sheet(isPresented: $showAdd) {
                AircraftEditView(appState: appState, aircraft: nil)
            }
            .confirmationDialog("Delete Aircraft", isPresented: $showDeleteOptions, titleVisibility: .visible) {
                if let target = aircraftPendingDelete {
                    Button("Sell with Parts (Delete Parts)", role: .destructive) {
                        appState.deleteAircraftWithParts(target)
                        aircraftPendingDelete = nil
                    }
                    Button("Tear Apart (Keep Parts)", role: .destructive) {
                        appState.deleteAircraftKeepParts(target)
                        aircraftPendingDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    aircraftPendingDelete = nil
                }
            }
        }
    }
}

struct AircraftRowView: View {
    let item: Aircraft
    let appState: AppState

    private var imageURL: URL? {
        appState.imageStorage.imageURL(aircraftId: item.id, fileName: item.imageFileName)
    }

    private var setupSummary: String? {
        let s = item.setupOrEmpty
        let parts = [s.frame, s.motor, s.esc].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            if let url = imageURL, let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "cube.box")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    )
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                if let m = item.model, !m.isEmpty {
                    Text(m)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let summary = setupSummary {
                    Text(summary)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
