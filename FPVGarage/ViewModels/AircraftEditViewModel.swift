import Foundation

final class AircraftEditViewModel: ObservableObject {
    let appState: AppState
    let aircraft: Aircraft?

    @Published var name = ""
    @Published var model = ""
    @Published var remark = ""
    @Published var photoData: Data?
    @Published var frame = ""
    @Published var motor = ""
    @Published var esc = ""
    @Published var flightController = ""
    @Published var camera = ""
    @Published var vtx = ""
    @Published var receiver = ""
    @Published var propeller = ""
    @Published var otherSetup = ""

    // Performance Data
    @Published var flightStyle: FlightStyle?
    @Published var pilotSkillLevel: PilotSkillLevel?
    @Published var frameSizeInch = ""
    @Published var motorModel = ""
    @Published var motorKv = ""
    @Published var motorThrustGrams = ""
    @Published var motorThrustDataSource: ThrustDataSource?
    @Published var propSizeField = ""
    @Published var allUpWeightGrams = ""
    @Published var batteryCellCount = ""

    var isNew: Bool { aircraft == nil }
    var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    init(appState: AppState, aircraft: Aircraft?) {
        self.appState = appState
        self.aircraft = aircraft
        loadFromAircraft()
    }

    func existingImageURL() -> URL? {
        guard let a = aircraft else { return nil }
        return appState.imageStorage.imageURL(aircraftId: a.id, fileName: a.imageFileName)
    }

    func save() {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return }

        let aircraftId = aircraft?.id ?? UUID()
        var imageFileName = aircraft?.imageFileName

        if let data = photoData, let fn = appState.imageStorage.saveImage(aircraftId: aircraftId, imageData: data) {
            imageFileName = fn
        }

        let setup = AircraftSetup(
            frame: trim(frame), motor: trim(motor), esc: trim(esc),
            flightController: trim(flightController), camera: trim(camera),
            vtx: trim(vtx), receiver: trim(receiver), propeller: trim(propeller),
            other: trim(otherSetup)
        )

        if var a = aircraft {
            a.name = n
            a.model = trim(model)
            a.imageFileName = imageFileName
            a.setup = setup.isEmpty ? nil : setup
            a.remark = trim(remark)
            a.updatedAt = Date()
            applyPerformanceData(&a)
            appState.updateAircraft(a)
            appState.syncParts(for: a)
        } else {
            var new = Aircraft(
                id: aircraftId, name: n, model: trim(model),
                imageFileName: imageFileName,
                setup: setup.isEmpty ? nil : setup,
                remark: trim(remark)
            )
            applyPerformanceData(&new)
            appState.addAircraft(new)
            appState.syncParts(for: new)
        }
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

        // Performance Data
        flightStyle = a.flightStyle
        pilotSkillLevel = a.pilotSkillLevel
        frameSizeInch = a.frameSizeInch.map { String($0) } ?? ""
        motorModel = a.motorModel ?? ""
        motorKv = a.motorKv.map { String($0) } ?? ""
        motorThrustGrams = a.motorThrustGrams.map { String($0) } ?? ""
        motorThrustDataSource = a.motorThrustDataSource
        propSizeField = a.propSize ?? ""
        allUpWeightGrams = a.allUpWeightGrams.map { String($0) } ?? ""
        batteryCellCount = a.batteryCellCount.map { String($0) } ?? ""
    }

    private func applyPerformanceData(_ a: inout Aircraft) {
        a.flightStyle = flightStyle
        a.pilotSkillLevel = pilotSkillLevel
        a.frameSizeInch = Double(frameSizeInch.trimmingCharacters(in: .whitespaces))
        a.motorModel = trim(motorModel)
        a.motorKv = Int(motorKv.trimmingCharacters(in: .whitespaces))
        a.motorThrustGrams = Int(motorThrustGrams.trimmingCharacters(in: .whitespaces))
        a.motorThrustDataSource = motorThrustDataSource
        a.propSize = trim(propSizeField)
        a.allUpWeightGrams = Int(allUpWeightGrams.trimmingCharacters(in: .whitespaces))
        a.batteryCellCount = Int(batteryCellCount.trimmingCharacters(in: .whitespaces))
    }

    private func trim(_ s: String) -> String? {
        let t = s.trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? nil : t
    }
}
