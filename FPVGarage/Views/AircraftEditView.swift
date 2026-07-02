import SwiftUI
import PhotosUI

struct AircraftEditView: View {
    @StateObject private var viewModel: AircraftEditViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showPhotoSourceDialog = false
    @State private var showPhotoPicker = false

    init(appState: AppState, aircraft: Aircraft?) {
        _viewModel = StateObject(wrappedValue: AircraftEditViewModel(appState: appState, aircraft: aircraft))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    HStack(spacing: 16) {
                        if let data = viewModel.photoData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else if let url = viewModel.existingImageURL(), let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
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
                            Text("Optional")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button {
                                showPhotoSourceDialog = true
                            } label: {
                                Label("Add Photo", systemImage: "photo.on.rectangle.angled")
                                    .font(.subheadline)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .confirmationDialog("Select Photo Source", isPresented: $showPhotoSourceDialog, titleVisibility: .visible) {
                    Button("Choose from Library") { showPhotoPicker = true }
                    Button("Take Photo") {
                        selectedPhotoItem = nil
                        showCamera = true
                    }
                    Button("Cancel", role: .cancel) {}
                }
                .fullScreenCover(isPresented: $showCamera) {
                    CameraImagePicker(imageData: $viewModel.photoData)
                        .ignoresSafeArea()
                }

                Section("Basic Info") {
                    TextField("Name", text: $viewModel.name)
                    TextField("Model (Optional)", text: $viewModel.model)
                    TextField("Remark", text: $viewModel.remark, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Detailed Setup") {
                    TextField("Frame", text: $viewModel.frame)
                    TextField("Motor", text: $viewModel.motor)
                    TextField("ESC", text: $viewModel.esc)
                    TextField("Flight Controller", text: $viewModel.flightController)
                    TextField("VTX", text: $viewModel.vtx)
                    TextField("Camera", text: $viewModel.camera)
                    TextField("Receiver", text: $viewModel.receiver)
                    TextField("Propeller", text: $viewModel.propeller)
                    TextField("Other", text: $viewModel.otherSetup, axis: .vertical)
                        .lineLimit(2...3)
                }

                Section {
                    Picker("Flight Style", selection: $viewModel.flightStyle) {
                        Text("Not Set").tag(FlightStyle?.none)
                        ForEach(FlightStyle.allCases, id: \.self) { s in
                            Text(s.displayName).tag(FlightStyle?.some(s))
                        }
                    }
                    Picker("Pilot Level", selection: $viewModel.pilotSkillLevel) {
                        Text("Not Set").tag(PilotSkillLevel?.none)
                        ForEach(PilotSkillLevel.allCases, id: \.self) { s in
                            Text(s.displayName).tag(PilotSkillLevel?.some(s))
                        }
                    }
                    TextField("Frame Size (inch, e.g. 5)", text: $viewModel.frameSizeInch)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Flight Profile")
                }

                Section {
                    TextField("Motor Model (e.g. T-Motor F60 Pro IV)", text: $viewModel.motorModel)
                    TextField("Motor KV", text: $viewModel.motorKv)
                        .keyboardType(.numberPad)
                    TextField("Motor Thrust per Motor (g)", text: $viewModel.motorThrustGrams)
                        .keyboardType(.numberPad)
                    Picker("Thrust Data Source", selection: $viewModel.motorThrustDataSource) {
                        Text("Not Set").tag(ThrustDataSource?.none)
                        ForEach(ThrustDataSource.allCases, id: \.self) { s in
                            Text(s.displayName).tag(ThrustDataSource?.some(s))
                        }
                    }
                    TextField("Prop Size (e.g. 5148)", text: $viewModel.propSize)
                    TextField("All-Up Weight (g)", text: $viewModel.allUpWeightGrams)
                        .keyboardType(.numberPad)
                    TextField("Battery Cell Count Override (S)", text: $viewModel.batteryCellCount)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Motor & Weight")
                } footer: {
                    Text("All-Up Weight should include battery. Thrust data from a thrust stand gives the most accurate 推重比.")
                }

                Section {
                    TextField("ESC Continuous Current Rating (A)", text: $viewModel.escCurrentRating)
                        .keyboardType(.numberPad)
                    TextField("Motor Max Current Draw (A)", text: $viewModel.motorMaxCurrentAmps)
                        .keyboardType(.numberPad)
                } header: {
                    Text("ESC & Current")
                } footer: {
                    Text("Used for compatibility checks. Check your ESC and motor spec sheets.")
                }
            }
            .navigationTitle(viewModel.isNew ? "Add Aircraft" : "Edit Aircraft")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save()
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    guard let item = newItem else {
                        viewModel.photoData = nil
                        return
                    }
                    viewModel.photoData = try? await item.loadTransferable(type: Data.self)
                }
            }
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        )
    }
}
