import SwiftUI

struct AircraftListView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAdd = false
    @State private var aircraftPendingDelete: Aircraft?
    @State private var showDeleteOptions = false

    var body: some View {
        NavigationStack {
            Group {
                if store.aircraft.isEmpty {
                    ContentUnavailableView("暂无飞机", systemImage: "cube.box", description: Text("点击 + 添加"))
                } else {
                    List {
                        ForEach(store.aircraft) { item in
                            NavigationLink(value: item) {
                                AircraftRowView(item: item, store: store)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    aircraftPendingDelete = item
                                    showDeleteOptions = true
                                } label: { Text("删除") }
                            }
                        }
                    }
                }
            }
            .navigationTitle("我的飞机")
            .navigationDestination(for: Aircraft.self) { item in
                AircraftDetailView(aircraft: item)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Image(systemName: "plus.circle.fill") }
                }
            }
            .sheet(isPresented: $showAdd) {
                AircraftEditView(aircraft: nil)
            }
            .confirmationDialog("删除飞机", isPresented: $showDeleteOptions, titleVisibility: .visible) {
                if let target = aircraftPendingDelete {
                    Button("卖掉整机（删除对应部件）", role: .destructive) {
                        store.deleteAircraft(target)
                        aircraftPendingDelete = nil
                    }
                    Button("拆机保留部件", role: .destructive) {
                        store.deleteAircraftKeepParts(target)
                        aircraftPendingDelete = nil
                    }
                }
                Button("取消", role: .cancel) {
                    aircraftPendingDelete = nil
                }
            }
        }
    }
}

struct AircraftRowView: View {
    let item: Aircraft
    let store: DataStore

    private var imageURL: URL? {
        store.aircraftImageURL(aircraftId: item.id, fileName: item.imageFileName)
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

