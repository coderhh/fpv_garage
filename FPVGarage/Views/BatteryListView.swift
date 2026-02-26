import SwiftUI

struct BatteryListView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if store.batteries.isEmpty {
                    ContentUnavailableView("暂无电池", systemImage: "battery.100", description: Text("点击 + 添加"))
                } else {
                    List {
                        ForEach(store.batteries) { item in
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
                                        Text("循环 \(item.cycles)")
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
                                    store.deleteBattery(item)
                                } label: { Text("删除") }
                            }
                        }
                    }
                }
            }
            .navigationTitle("我的电池")
            .navigationDestination(for: Battery.self) { item in
                BatteryEditView(battery: item)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Image(systemName: "plus.circle.fill") }
                }
            }
            .sheet(isPresented: $showAdd) {
                BatteryEditView(battery: nil)
            }
        }
    }
}

