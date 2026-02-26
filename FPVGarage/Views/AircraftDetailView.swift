import SwiftUI

struct AircraftDetailView: View {
    @EnvironmentObject var store: DataStore
    let aircraft: Aircraft
    @State private var showEdit = false

    private var imageURL: URL? {
        store.aircraftImageURL(aircraftId: aircraft.id, fileName: aircraft.imageFileName)
    }

    private var setup: AircraftSetup {
        aircraft.setupOrEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    if let url = imageURL,
                       let data = try? Data(contentsOf: url),
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.gray.opacity(0.15))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "cube.box")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(aircraft.name)
                            .font(.title2)
                            .bold()
                        if let model = aircraft.model, !model.isEmpty {
                            Text(model)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let remark = aircraft.remark, !remark.isEmpty {
                            Text(remark)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                    }
                    Spacer()
                }

                if !setup.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("详细配置")
                            .font(.headline)
                        detailRow(label: "机架 Frame", value: setup.frame)
                        detailRow(label: "电机 Motor", value: setup.motor)
                        detailRow(label: "电调 ESC", value: setup.esc)
                        detailRow(label: "飞控 Flight Controller", value: setup.flightController)
                        detailRow(label: "图传 VTX", value: setup.vtx)
                        detailRow(label: "摄像头 Camera", value: setup.camera)
                        detailRow(label: "接收机 Receiver", value: setup.receiver)
                        detailRow(label: "桨叶 Propeller", value: setup.propeller)
                        detailRow(label: "其他 Other", value: setup.other)
                    }
                    .padding()
                    .background(.background.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("元数据")
                        .font(.headline)
                    detailRow(label: "创建时间", value: DateFormatter.localizedString(from: aircraft.createdAt, dateStyle: .medium, timeStyle: .short))
                    detailRow(label: "最后更新", value: DateFormatter.localizedString(from: aircraft.updatedAt, dateStyle: .medium, timeStyle: .short))
                }
                .padding()
                .background(.background.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer(minLength: 0)
            }
            .padding()
        }
        .navigationTitle("飞机详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("编辑") {
                    showEdit = true
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            AircraftEditView(aircraft: aircraft)
        }
    }

    @ViewBuilder
    private func detailRow(label: String, value: String?) -> some View {
        if let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.body)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}

