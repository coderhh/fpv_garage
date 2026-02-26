import SwiftUI
import PhotosUI

struct AircraftEditView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss

    let aircraft: Aircraft?

    @State private var name: String = ""
    @State private var model: String = ""
    @State private var remark: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var showCamera = false
    @State private var showPhotoSourceDialog = false
    @State private var showPhotoPicker = false
    @State private var frame: String = ""
    @State private var motor: String = ""
    @State private var esc: String = ""
    @State private var flightController: String = ""
    @State private var camera: String = ""
    @State private var vtx: String = ""
    @State private var receiver: String = ""
    @State private var propeller: String = ""
    @State private var otherSetup: String = ""

    private var isNew: Bool { aircraft == nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("照片") {
                    HStack(spacing: 16) {
                        if let data = photoData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else if let a = aircraft, let url = store.aircraftImageURL(aircraftId: a.id, fileName: a.imageFileName), let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Image(systemName: "photo.badge.plus")
                                .font(.title)
                                .foregroundStyle(.secondary)
                                .frame(width: 80, height: 80)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("选填")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button {
                                showPhotoSourceDialog = true
                            } label: {
                                Label("添加照片", systemImage: "photo.on.rectangle.angled")
                                    .font(.subheadline)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .confirmationDialog("选择照片来源", isPresented: $showPhotoSourceDialog, titleVisibility: .visible) {
                    Button("从相册选择") {
                        showPhotoPicker = true
                    }
                    Button("拍照") {
                        selectedPhotoItem = nil
                        showCamera = true
                    }
                    Button("取消", role: .cancel) {}
                }
                .fullScreenCover(isPresented: $showCamera) {
                    CameraImagePicker(imageData: $photoData)
                        .ignoresSafeArea()
                }

                Section("基本信息") {
                    TextField("名称", text: $name)
                    TextField("机型(选填)", text: $model)
                    TextField("备注", text: $remark, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("详细配置") {
                    TextField("机架 Frame", text: $frame)
                    TextField("电机 Motor", text: $motor)
                    TextField("电调 ESC", text: $esc)
                    TextField("飞控 Flight Controller", text: $flightController)
                    TextField("图传 VTX", text: $vtx)
                    TextField("摄像头 Camera", text: $camera)
                    TextField("接收机 Receiver", text: $receiver)
                    TextField("桨叶 Propeller", text: $propeller)
                    TextField("其他 Other", text: $otherSetup, axis: .vertical)
                        .lineLimit(2...3)
                }
            }
            .navigationTitle(isNew ? "添加飞机" : "编辑飞机")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    guard let item = newItem else {
                        photoData = nil
                        return
                    }
                    photoData = try? await item.loadTransferable(type: Data.self)
                }
            }
            .onAppear { loadFromAircraft() }
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        )
    }

    private func loadFromAircraft() {
        guard let a = aircraft else { return }
        name = a.name
        model = a.model ?? ""
        remark = a.remark ?? ""
        let s = a.setupOrEmpty
        frame = s.frame ?? ""
        motor = s.motor ?? ""
        esc = s.esc ?? ""
        flightController = s.flightController ?? ""
        camera = s.camera ?? ""
        vtx = s.vtx ?? ""
        receiver = s.receiver ?? ""
        propeller = s.propeller ?? ""
        otherSetup = s.other ?? ""
    }

    private func trim(_ s: String) -> String? {
        let t = s.trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? nil : t
    }

    private func save() {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return }

        let aircraftId = aircraft?.id ?? UUID()
        var imageFileName = aircraft?.imageFileName

        if let data = photoData, let fn = store.saveAircraftImage(aircraftId: aircraftId, imageData: data) {
            imageFileName = fn
        }

        let setup = AircraftSetup(
            frame: trim(frame),
            motor: trim(motor),
            esc: trim(esc),
            flightController: trim(flightController),
            camera: trim(camera),
            vtx: trim(vtx),
            receiver: trim(receiver),
            propeller: trim(propeller),
            other: trim(otherSetup)
        )

        if var a = aircraft {
            a.name = n
            a.model = trim(model)
            a.imageFileName = imageFileName
            a.setup = setup.isEmpty ? nil : setup
            a.remark = trim(remark)
            a.updatedAt = Date()
            store.updateAircraft(a)
            store.syncParts(for: a)
        } else {
            let new = Aircraft(
                id: aircraftId,
                name: n,
                model: trim(model),
                imageFileName: imageFileName,
                setup: setup.isEmpty ? nil : setup,
                remark: trim(remark)
            )
            store.addAircraft(new)
            store.syncParts(for: new)
        }
        dismiss()
    }
}

