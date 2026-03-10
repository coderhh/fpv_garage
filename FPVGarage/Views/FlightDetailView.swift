import SwiftUI

struct FlightDetailView: View {
    @EnvironmentObject var appState: AppState
    let flight: FlightRecord
    @State private var showEdit = false

    private var aircraft: Aircraft? {
        appState.findAircraft(by: flight.aircraftId)
    }

    private var batteries: [Battery] {
        appState.findBatteries(by: flight.batteryIds)
    }

    private var durationText: String {
        String(localized: "\(flight.durationSeconds) sec")
    }

    var body: some View {
        List {
            Section("Aircraft") {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(aircraft?.name ?? "—")
                        .foregroundStyle(.primary)
                }
            }

            Section("Time & Duration") {
                HStack {
                    Text("Takeoff Time")
                    Spacer()
                    Text(DateFormatter.localizedString(from: flight.startAt, dateStyle: .medium, timeStyle: .short))
                        .foregroundStyle(.primary)
                }
                HStack {
                    Text("Flight Duration")
                    Spacer()
                    Text(durationText)
                        .foregroundStyle(.primary)
                }
            }

            if !batteries.isEmpty {
                Section("Batteries Used") {
                    ForEach(batteries) { battery in
                        HStack {
                            Text(battery.name)
                            Spacer()
                            Text("Cycles \(battery.cycles)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if let address = flight.address, !address.isEmpty {
                Section("Location") {
                    Text(address)
                        .font(.body)
                }
            }

            if flight.latitude != nil || flight.longitude != nil {
                Section("Coordinates") {
                    HStack {
                        Text("Latitude")
                        Spacer()
                        Text(flight.latitude.map { String(format: "%.6f", $0) } ?? "—")
                    }
                    HStack {
                        Text("Longitude")
                        Spacer()
                        Text(flight.longitude.map { String(format: "%.6f", $0) } ?? "—")
                    }
                }
            }

            if let remark = flight.remark, !remark.isEmpty {
                Section("Remark") {
                    Text(remark)
                        .font(.body)
                }
            }
        }
        .navigationTitle("Flight Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) {
            FlightEditView(appState: appState, flight: flight)
        }
    }
}
