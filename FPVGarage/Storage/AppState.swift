import Foundation
import Combine

final class AppState: ObservableObject {
    @Published var aircraft: [Aircraft] = []
    @Published var batteries: [Battery] = []
    @Published var flightRecords: [FlightRecord] = []
    @Published var parts: [Part] = []

    private let aircraftRepo: AircraftRepositoryProtocol
    private let batteryRepo: BatteryRepositoryProtocol
    private let flightRepo: FlightRepositoryProtocol
    private let partRepo: PartRepositoryProtocol
    let imageStorage: ImageStorageProtocol

    init(
        aircraftRepo: AircraftRepositoryProtocol,
        batteryRepo: BatteryRepositoryProtocol,
        flightRepo: FlightRepositoryProtocol,
        partRepo: PartRepositoryProtocol,
        imageStorage: ImageStorageProtocol
    ) {
        self.aircraftRepo = aircraftRepo
        self.batteryRepo = batteryRepo
        self.flightRepo = flightRepo
        self.partRepo = partRepo
        self.imageStorage = imageStorage
        loadAll()
    }

    func loadAll() {
        aircraft = aircraftRepo.loadAll()
        batteries = batteryRepo.loadAll()
        flightRecords = flightRepo.loadAll()
        parts = partRepo.loadAll()
    }

    // MARK: - Aircraft

    func addAircraft(_ item: Aircraft) {
        aircraft.append(item)
        aircraftRepo.save(aircraft)
    }

    func updateAircraft(_ item: Aircraft) {
        guard let i = aircraft.firstIndex(where: { $0.id == item.id }) else { return }
        aircraft[i] = item
        aircraftRepo.save(aircraft)
    }

    func deleteAircraftWithParts(_ item: Aircraft) {
        imageStorage.deleteImage(fileName: item.imageFileName)
        aircraft.removeAll { $0.id == item.id }
        aircraftRepo.save(aircraft)
        parts.removeAll { $0.sourceAircraftId == item.id }
        partRepo.save(parts)
    }

    func deleteAircraftKeepParts(_ item: Aircraft) {
        imageStorage.deleteImage(fileName: item.imageFileName)
        aircraft.removeAll { $0.id == item.id }
        aircraftRepo.save(aircraft)
        for idx in parts.indices where parts[idx].sourceAircraftId == item.id {
            parts[idx].sourceAircraftId = nil
        }
        partRepo.save(parts)
    }

    func findAircraft(by id: UUID) -> Aircraft? {
        aircraft.first { $0.id == id }
    }

    // MARK: - Batteries

    func addBattery(_ item: Battery) {
        batteries.append(item)
        batteryRepo.save(batteries)
    }

    func updateBattery(_ item: Battery) {
        guard let i = batteries.firstIndex(where: { $0.id == item.id }) else { return }
        batteries[i] = item
        batteryRepo.save(batteries)
    }

    func deleteBattery(_ item: Battery) {
        batteries.removeAll { $0.id == item.id }
        batteryRepo.save(batteries)
    }

    func findBatteries(by ids: [UUID]) -> [Battery] {
        batteries.filter { ids.contains($0.id) }
    }

    // MARK: - Flights

    func addFlight(_ item: FlightRecord) {
        flightRecords.append(item)
        flightRepo.save(flightRecords)
    }

    func updateFlight(_ item: FlightRecord) {
        guard let i = flightRecords.firstIndex(where: { $0.id == item.id }) else { return }
        flightRecords[i] = item
        flightRepo.save(flightRecords)
    }

    func deleteFlight(_ item: FlightRecord) {
        flightRecords.removeAll { $0.id == item.id }
        flightRepo.save(flightRecords)
    }

    // MARK: - Parts

    func addPart(_ item: Part) {
        parts.append(item)
        partRepo.save(parts)
    }

    func updatePart(_ item: Part) {
        guard let i = parts.firstIndex(where: { $0.id == item.id }) else { return }
        parts[i] = item
        partRepo.save(parts)
    }

    func deletePart(_ item: Part) {
        parts.removeAll { $0.id == item.id }
        partRepo.save(parts)
    }

    func syncParts(for aircraft: Aircraft) {
        parts.removeAll { $0.sourceAircraftId == aircraft.id }

        guard let setup = aircraft.setup, !setup.isEmpty else {
            partRepo.save(parts)
            return
        }

        func makePart(name: String?, category: PartCategory) -> Part? {
            guard let raw = name?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
            return Part(name: raw, category: category, quantity: 1, sourceAircraftId: aircraft.id)
        }

        var newParts: [Part] = []
        if let p = makePart(name: setup.frame, category: .frame) { newParts.append(p) }
        if let p = makePart(name: setup.motor, category: .motor) { newParts.append(p) }
        if let p = makePart(name: setup.esc, category: .esc) { newParts.append(p) }
        if let p = makePart(name: setup.flightController, category: .flightController) { newParts.append(p) }
        if let p = makePart(name: setup.camera, category: .camera) { newParts.append(p) }
        if let p = makePart(name: setup.vtx, category: .vtx) { newParts.append(p) }
        if let p = makePart(name: setup.receiver, category: .receiver) { newParts.append(p) }
        if let p = makePart(name: setup.propeller, category: .propeller) { newParts.append(p) }
        if let p = makePart(name: setup.other, category: .other) { newParts.append(p) }

        parts.append(contentsOf: newParts)
        partRepo.save(parts)
    }

    // MARK: - Test Data

    func clearAllData() {
        for a in aircraft {
            imageStorage.deleteImage(fileName: a.imageFileName)
        }
        aircraft.removeAll()
        batteries.removeAll()
        flightRecords.removeAll()
        parts.removeAll()
        aircraftRepo.save(aircraft)
        batteryRepo.save(batteries)
        flightRepo.save(flightRecords)
        partRepo.save(parts)
    }

    func seedTestData() {
        let now = Date()
        let cal = Calendar.current

        let a1Id = UUID()
        let a2Id = UUID()
        let b1Id = UUID()
        let b2Id = UUID()
        let b3Id = UUID()

        let aircraftList: [Aircraft] = [
            Aircraft(
                id: a1Id, name: "5寸花飞机", model: "自组",
                setup: AircraftSetup(
                    frame: "Apex 5\"", motor: "2306 1950kv", esc: "35A BLHeli_32",
                    flightController: "F7", camera: "Caddx Ratel", vtx: "1.2W",
                    receiver: "ELRS 2.4G", propeller: "51466"
                ),
                remark: "日常练习",
                createdAt: cal.date(byAdding: .day, value: -30, to: now)!, updatedAt: now
            ),
            Aircraft(
                id: a2Id, name: "3.5寸 cinewhoop", model: "自组",
                setup: AircraftSetup(
                    frame: "GEPRC CineLog", motor: "1404 3800kv", esc: "20A",
                    flightController: "F4", camera: "Nebula Pro", vtx: "400mW",
                    receiver: "ELRS", propeller: "3520", other: "GoPro 支架"
                ),
                remark: "拍视频用",
                createdAt: cal.date(byAdding: .day, value: -14, to: now)!, updatedAt: now
            ),
        ]

        let batteryList: [Battery] = [
            Battery(id: b1Id, name: "Tattu 6S 1300", code: "T1", capacityMah: 1300, cells: 6, cycles: 12, status: .active, createdAt: now, updatedAt: now),
            Battery(id: b2Id, name: "Tattu 6S 1300", code: "T2", capacityMah: 1300, cells: 6, cycles: 28, status: .active, createdAt: now, updatedAt: now),
            Battery(id: b3Id, name: "CNHL 4S 850", code: "C1", capacityMah: 850, cells: 4, cycles: 5, status: .active, remark: "cinewhoop用", createdAt: now, updatedAt: now),
        ]

        let flightList: [FlightRecord] = [
            FlightRecord(aircraftId: a1Id, batteryIds: [b1Id], startAt: cal.date(byAdding: .day, value: -2, to: now)!, durationSeconds: 480, address: "郊区飞场", latitude: 39.9, longitude: 116.4, remark: "花飞练习", createdAt: now, updatedAt: now),
            FlightRecord(aircraftId: a1Id, batteryIds: [b2Id], startAt: cal.date(byAdding: .day, value: -2, to: now)!, durationSeconds: 460, address: "郊区飞场", latitude: 39.9, longitude: 116.4, createdAt: now, updatedAt: now),
            FlightRecord(aircraftId: a1Id, batteryIds: [b1Id], startAt: cal.date(byAdding: .day, value: -1, to: now)!, durationSeconds: 510, address: "公园", createdAt: now, updatedAt: now),
            FlightRecord(aircraftId: a2Id, batteryIds: [b3Id], startAt: cal.date(byAdding: .day, value: -1, to: now)!, durationSeconds: 360, address: "小区", remark: "试拍", createdAt: now, updatedAt: now),
            FlightRecord(aircraftId: a2Id, batteryIds: [b3Id], startAt: now, durationSeconds: 0, remark: "刚起飞", createdAt: now, updatedAt: now),
        ]

        for a in aircraftList { addAircraft(a) }
        for b in batteryList { addBattery(b) }
        for f in flightList { addFlight(f) }
        for a in aircraftList { syncParts(for: a) }
    }
}
