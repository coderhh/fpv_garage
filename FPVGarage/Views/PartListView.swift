import SwiftUI

struct PartListView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if store.parts.isEmpty {
                    ContentUnavailableView("暂无部件", systemImage: "wrench.and.screwdriver", description: Text("添加飞机配置或手动添加部件"))
                } else {
                    List {
                        ForEach(store.parts) { item in
                            NavigationLink(value: item) {
                                PartRowView(item: item)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    store.deletePart(item)
                                } label: { Text("删除") }
                            }
                        }
                    }
                }
            }
            .navigationTitle("我的部件")
            .navigationDestination(for: Part.self) { item in
                PartDetailView(part: item)
            }
            .navigationDestination(for: Aircraft.self) { item in
                AircraftDetailView(aircraft: item)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Image(systemName: "plus.circle.fill") }
                }
            }
            .sheet(isPresented: $showAdd) {
                PartEditView(part: nil)
            }
        }
    }
}

struct PartRowView: View {
    let item: Part

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.name)
                    .font(.headline)
                Spacer()
                Text("x\(item.quantity)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Text(item.category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let remark = item.remark, !remark.isEmpty {
                    Text(remark)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

