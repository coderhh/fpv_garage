import SwiftUI

struct PartListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAdd = false
    @State private var selectedCategory: PartCategory?

    private var categories: [PartCategory] { PartCategory.allCases }

    private var groupedParts: [(PartCategory, [Part])] {
        let sourceCategories = selectedCategory.map { [$0] } ?? categories
        return sourceCategories.compactMap { category in
            let items = appState.parts
                .filter { $0.category == category }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            return items.isEmpty ? nil : (category, items)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if appState.parts.isEmpty {
                    ContentUnavailableView("No Parts", systemImage: "wrench.and.screwdriver", description: Text("Add aircraft setup or add parts manually"))
                } else {
                    List {
                        Section("Filter") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    filterChip(title: String(localized: "All"), isSelected: selectedCategory == nil) {
                                        selectedCategory = nil
                                    }
                                    ForEach(categories, id: \.self) { category in
                                        filterChip(title: category.displayName, isSelected: selectedCategory == category) {
                                            selectedCategory = category
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }

                        ForEach(groupedParts, id: \.0) { category, items in
                            Section(category.displayName) {
                                ForEach(items) { item in
                                    NavigationLink(value: item) {
                                        PartRowView(item: item)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            appState.deletePart(item)
                                        } label: { Text("Delete") }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Parts")
            .navigationDestination(for: Part.self) { item in
                PartDetailView(part: item)
            }
            .navigationDestination(for: Aircraft.self) { item in
                AircraftDetailView(aircraft: item)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Image(systemName: "plus.circle.fill") }
                        .accessibilityIdentifier("addPartButton")
                }
            }
            .sheet(isPresented: $showAdd) {
                PartEditView(appState: appState, part: nil)
            }
        }
    }
}

private extension PartListView {
    @ViewBuilder
    func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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

