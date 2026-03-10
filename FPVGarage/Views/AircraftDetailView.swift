import SwiftUI

struct AircraftDetailView: View {
    @EnvironmentObject var appState: AppState
    let aircraft: Aircraft
    @State private var showEdit = false

    private var imageURL: URL? {
        appState.imageStorage.imageURL(aircraftId: aircraft.id, fileName: aircraft.imageFileName)
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
                        Text("Detailed Setup")
                            .font(.headline)
                        detailRow(label: "Frame", value: setup.frame)
                        detailRow(label: "Motor", value: setup.motor)
                        detailRow(label: "ESC", value: setup.esc)
                        detailRow(label: "Flight Controller", value: setup.flightController)
                        detailRow(label: "VTX", value: setup.vtx)
                        detailRow(label: "Camera", value: setup.camera)
                        detailRow(label: "Receiver", value: setup.receiver)
                        detailRow(label: "Propeller", value: setup.propeller)
                        detailRow(label: "Other", value: setup.other)
                    }
                    .padding()
                    .background(.background.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Metadata")
                        .font(.headline)
                    detailRow(label: "Created", value: DateFormatter.localizedString(from: aircraft.createdAt, dateStyle: .medium, timeStyle: .short))
                    detailRow(label: "Last Updated", value: DateFormatter.localizedString(from: aircraft.updatedAt, dateStyle: .medium, timeStyle: .short))
                }
                .padding()
                .background(.background.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer(minLength: 0)
            }
            .padding()
        }
        .navigationTitle("Aircraft Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) {
            AircraftEditView(appState: appState, aircraft: aircraft)
        }
    }

    @ViewBuilder
    private func detailRow(label: LocalizedStringKey, value: String?) -> some View {
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
