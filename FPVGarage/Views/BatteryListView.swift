import SwiftUI

struct BatteryListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if appState.batteries.isEmpty {
                    ContentUnavailableView("No Batteries", systemImage: "battery.100", description: Text("Tap + to add"))
                } else {
                    List {
                        ForEach(appState.batteries) { item in
                            NavigationLink(value: item) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.headline)
                                    HStack(spacing: 8) {
                                        if let cap = item.capacityMah {
                                            Text("\(cap) mAh")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        if let c = item.cells {
                                            Text("\(c)S")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Text("Cycles \(item.cycles)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(item.status.displayName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    appState.deleteBattery(item)
                                } label: { Text("Delete") }
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Batteries")
            .navigationDestination(for: Battery.self) { item in
                BatteryEditView(appState: appState, battery: item)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Image(systemName: "plus.circle.fill") }
                        .accessibilityIdentifier("addBatteryButton")
                }
            }
            .sheet(isPresented: $showAdd) {
                BatteryEditView(appState: appState, battery: nil)
            }
        }
    }
}
