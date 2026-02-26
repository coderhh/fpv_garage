import SwiftUI

struct FlightListView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAdd = false

    var sortedFlights: [FlightRecord] {
        store.flightRecords.sorted { $0.startAt > $1.startAt }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sortedFlights.isEmpty {
                    ContentUnavailableView("暂无飞行记录", systemImage: "airplane", description: Text("点击 + 添加"))
                } else {
                    List {
                        ForEach(sortedFlights) { flight in
                            NavigationLink(value: flight) {
                                FlightRowView(flight: flight, store: store)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    store.deleteFlight(flight)
                                } label: { Text("删除") }
                            }
                        }
                    }
                }
            }
            .navigationTitle("飞行记录")
            .navigationDestination(for: FlightRecord.self) { flight in
                FlightDetailView(flight: flight)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Image(systemName: "plus.circle.fill") }
                }
            }
            .sheet(isPresented: $showAdd) {
                FlightEditView(flight: nil)
            }
        }
    }
}

struct FlightRowView: View {
    let flight: FlightRecord
    let store: DataStore

    var aircraftName: String {
        store.aircraft(by: flight.aircraftId)?.name ?? "—"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(aircraftName)
                    .font(.headline)
                Spacer()
                Text("\(flight.durationSeconds) 秒")
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

