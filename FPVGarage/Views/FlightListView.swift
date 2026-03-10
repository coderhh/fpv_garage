import SwiftUI

struct FlightListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAdd = false

    var sortedFlights: [FlightRecord] {
        appState.flightRecords.sorted { $0.startAt > $1.startAt }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sortedFlights.isEmpty {
                    ContentUnavailableView("No Flight Records", systemImage: "airplane", description: Text("Tap + to add"))
                } else {
                    List {
                        ForEach(sortedFlights) { flight in
                            NavigationLink(value: flight) {
                                FlightRowView(flight: flight, appState: appState)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    appState.deleteFlight(flight)
                                } label: { Text("Delete") }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Flight Records")
            .navigationDestination(for: FlightRecord.self) { flight in
                FlightDetailView(flight: flight)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Image(systemName: "plus.circle.fill") }
                        .accessibilityIdentifier("addFlightButton")
                }
            }
            .sheet(isPresented: $showAdd) {
                FlightEditView(appState: appState, flight: nil)
            }
        }
    }
}

struct FlightRowView: View {
    let flight: FlightRecord
    let appState: AppState

    var aircraftName: String {
        appState.findAircraft(by: flight.aircraftId)?.name ?? "—"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(aircraftName)
                    .font(.headline)
                Spacer()
                Text("\(flight.durationSeconds) sec")
                    .foregroundStyle(.secondary)
            }
            Text(flight.startAt, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let addr = flight.address, !addr.isEmpty {
                Text(addr)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}
