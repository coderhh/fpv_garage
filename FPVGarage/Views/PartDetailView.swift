import SwiftUI

struct PartDetailView: View {
    @EnvironmentObject var store: DataStore
    let part: Part
    @State private var showEdit = false

    private var sourceAircraft: Aircraft? {
        guard let id = part.sourceAircraftId else { return nil }
        return store.aircraft(by: id)
    }

    var body: some View {
        List {
            Section("基本信息") {
                HStack {
                    Text("名称")
                    Spacer()
                    Text(part.name)
                        .foregroundStyle(.primary)
                }
                HStack {
                    Text("类型")
                    Spacer()
                    Text(part.category.displayName)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("数量")
                    Spacer()
                    Text("x\(part.quantity)")
                        .foregroundStyle(.primary)
                }
            }

            if let aircraft = sourceAircraft {
                Section("来源飞机") {
                    NavigationLink(value: aircraft) {
                        HStack {
                            Text(aircraft.name)
                            if let model = aircraft.model, !model.isEmpty {
                                Text(model)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }

            if let remark = part.remark, !remark.isEmpty {
                Section("备注") {
                    Text(remark)
                        .font(.body)
                }
            }

            Section("元数据") {
                HStack {
                    Text("创建时间")
                    Spacer()
                    Text(DateFormatter.localizedString(from: part.createdAt, dateStyle: .medium, timeStyle: .short))
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("最后更新")
                    Spacer()
                    Text(DateFormatter.localizedString(from: part.updatedAt, dateStyle: .medium, timeStyle: .short))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("部件详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("编辑") {
                    showEdit = true
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            PartEditView(part: part)
        }
    }
}

