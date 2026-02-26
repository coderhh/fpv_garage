import Foundation
import SwiftUI
import UIKit

final class DataStore: ObservableObject {
    static let shared = DataStore()

    @Published var aircraft: [Aircraft] = []
    @Published var batteries: [Battery] = []
    @Published var flightRecords: [FlightRecord] = []
    @Published var parts: [Part] = []

    private let fileManager = FileManager.default

    /// Base directory for app data: iCloud Documents when available, otherwise local Documents.
    /// Uses subfolder "FPVGarage" in both cases.
    private var storageBaseURL: URL {
        if let url = _iCloudBaseURL {
            return url
        }
        return localBaseURL
    }

    private var localBaseURL: URL {
        let doc = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return doc.appendingPathComponent("FPVGarage", isDirectory: true)
    }

    /// Set when iCloud container becomes available (resolved on background queue). Not persisted (path is device-specific).
    private var _iCloudBaseURL: URL?

    private var aircraftImagesURL: URL {
        let url = storageBaseURL.appendingPathComponent("aircraft_images", isDirectory: true)
        ensureDirectory(url)
        return url
    }

    private init() {
        ensureDirectory(localBaseURL)
        loadAll()
        resolveiCloudAndReload()
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadAll()
        }
    }

    private func ensureDirectory(_ url: URL) {
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    /// Resolve iCloud container URL on background; migrate local → iCloud if needed, then reload.
    private func resolveiCloudAndReload() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            guard let containerURL = self.fileManager.url(forUbiquityContainerIdentifier: "iCloud.com.fpvgarage.app") else {
                return
            }
            let iCloudDocuments = containerURL.appendingPathComponent("Documents", isDirectory: true)
            let iCloudBase = iCloudDocuments.appendingPathComponent("FPVGarage", isDirectory: true)
            self.ensureDirectory(iCloudBase)
            DispatchQueue.main.async {
                let hadICloud = self._iCloudBaseURL != nil
                self._iCloudBaseURL = iCloudBase
                if !hadICloud {
                    self.migrateLocalToICloud(local: self.localBaseURL, iCloud: iCloudBase)
                }
                self.loadAll()
            }
        }
    }

    private func migrateLocalToICloud(local: URL, iCloud: URL) {
        let files = ["aircraft.json", "batteries.json", "flight_records.json"]
        for file in files {
            let localFile = local.appendingPathComponent(file)
            let iCloudFile = iCloud.appendingPathComponent(file)
            if fileManager.fileExists(atPath: localFile.path), !fileManager.fileExists(atPath: iCloudFile.path) {
                try? fileManager.copyItem(at: localFile, to: iCloudFile)
            }
        }
        let localImages = local.appendingPathComponent("aircraft_images", isDirectory: true)
        let iCloudImages = iCloud.appendingPathComponent("aircraft_images", isDirectory: true)
        if fileManager.fileExists(atPath: localImages.path) {
            ensureDirectory(iCloudImages)
            if let contents = try? fileManager.contentsOfDirectory(at: localImages, includingPropertiesForKeys: nil) {
                for src in contents {
                    let dest = iCloudImages.appendingPathComponent(src.lastPathComponent)
                    if !fileManager.fileExists(atPath: dest.path) {
                        try? fileManager.copyItem(at: src, to: dest)
                    }
                }
            }
        }
    }

    func loadAll() {
        ensureDirectory(storageBaseURL)
        aircraft = load([Aircraft].self, from: "aircraft.json") ?? []
        batteries = load([Battery].self, from: "batteries.json") ?? []
        flightRecords = load([FlightRecord].self, from: "flight_records.json") ?? []
        parts = load([Part].self, from: "parts.json") ?? []
    }

    private func load<T: Decodable>(_ type: T.Type, from file: String) -> T? {
        let url = storageBaseURL.appendingPathComponent(file)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let coordinator = NSFileCoordinator()
        var result: T?
        var coordinatorError: NSError?
        coordinator.coordinate(readingItemAt: url, options: .withoutChanges, error: &coordinatorError) { coordinatedURL in
            guard let data = try? Data(contentsOf: coordinatedURL) else { return }
            result = try? JSONDecoder().decode(T.self, from: data)
        }
        return result
    }

    private func save<T: Encodable>(_ value: T, to file: String) {
        let url = storageBaseURL.appendingPathComponent(file)
        guard let data = try? JSONEncoder().encode(value) else { return }
        let coordinator = NSFileCoordinator()
        var coordinatorError: NSError?
        coordinator.coordinate(writingItemAt: url, options: .forReplacing, error: &coordinatorError) { coordinatedURL in
            try? data.write(to: coordinatedURL)
        }
    }

    // MARK: - Aircraft
    func addAircraft(_ item: Aircraft) {
        aircraft.append(item)
        save(aircraft, to: "aircraft.json")
    }

    func updateAircraft(_ item: Aircraft) {
        guard let i = aircraft.firstIndex(where: { $0.id == item.id }) else { return }
        aircraft[i] = item
        save(aircraft, to: "aircraft.json")
    }

    /// Delete aircraft and also remove all parts that were derived from it.
    /// Use when you sell a complete drone (airframe + parts).
    func deleteAircraft(_ item: Aircraft) {
        deleteAircraftInternal(item, partsMode: .remove)
    }

    /// Delete aircraft but keep its parts in inventory, detaching their linkage.
    /// Use when you tear down a drone and keep the components.
    func deleteAircraftKeepParts(_ item: Aircraft) {
        deleteAircraftInternal(item, partsMode: .detach)
    }

    private enum AircraftPartsDeleteMode {
        case remove   // delete parts for this aircraft
        case detach   // keep parts, clear sourceAircraftId
    }

    private func deleteAircraftInternal(_ item: Aircraft, partsMode: AircraftPartsDeleteMode) {
        if let fn = item.imageFileName {
            let url = aircraftImagesURL.appendingPathComponent(fn)
            try? fileManager.removeItem(at: url)
        }
        aircraft.removeAll { $0.id == item.id }
        save(aircraft, to: "aircraft.json")

        switch partsMode {
        case .remove:
            parts.removeAll { $0.sourceAircraftId == item.id }
        case .detach:
            for idx in parts.indices {
                if parts[idx].sourceAircraftId == item.id {
                    parts[idx].sourceAircraftId = nil
                }
            }
        }
        save(parts, to: "parts.json")
    }

    /// Save image data for an aircraft. Returns filename to store in aircraft.imageFileName.
    func saveAircraftImage(aircraftId: UUID, imageData: Data) -> String? {
        let filename = "\(aircraftId.uuidString).jpg"
        let url = aircraftImagesURL.appendingPathComponent(filename)
        guard (try? imageData.write(to: url)) != nil else { return nil }
        return filename
    }

    /// Load image file for an aircraft. Returns nil if no image or file missing.
    func aircraftImageURL(aircraftId: UUID, fileName: String?) -> URL? {
        guard let fn = fileName else { return nil }
        let url = aircraftImagesURL.appendingPathComponent(fn)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Batteries
    func addBattery(_ item: Battery) {
        batteries.append(item)
        save(batteries, to: "batteries.json")
    }

    func updateBattery(_ item: Battery) {
        guard let i = batteries.firstIndex(where: { $0.id == item.id }) else { return }
        batteries[i] = item
        save(batteries, to: "batteries.json")
    }

    func deleteBattery(_ item: Battery) {
        batteries.removeAll { $0.id == item.id }
        save(batteries, to: "batteries.json")
    }

    // MARK: - Flights
    func addFlight(_ item: FlightRecord) {
        flightRecords.append(item)
        save(flightRecords, to: "flight_records.json")
    }

    func updateFlight(_ item: FlightRecord) {
        guard let i = flightRecords.firstIndex(where: { $0.id == item.id }) else { return }
        flightRecords[i] = item
        save(flightRecords, to: "flight_records.json")
    }

    func deleteFlight(_ item: FlightRecord) {
        flightRecords.removeAll { $0.id == item.id }
        save(flightRecords, to: "flight_records.json")
    }

    func aircraft(by id: UUID) -> Aircraft? {
        aircraft.first { $0.id == id }
    }

    func batteries(by ids: [UUID]) -> [Battery] {
        batteries.filter { ids.contains($0.id) }
    }

    // MARK: - Parts
    func addPart(_ item: Part) {
        parts.append(item)
        save(parts, to: "parts.json")
    }

    func updatePart(_ item: Part) {
        guard let i = parts.firstIndex(where: { $0.id == item.id }) else { return }
        parts[i] = item
        save(parts, to: "parts.json")
    }

    func deletePart(_ item: Part) {
        parts.removeAll { $0.id == item.id }
        save(parts, to: "parts.json")
    }

    /// All parts that originate from a specific aircraft.
    func parts(forAircraftId id: UUID) -> [Part] {
        parts.filter { $0.sourceAircraftId == id }
    }

    /// Synchronize parts derived from an aircraft's setup (Option B).
    /// Existing parts for this aircraft are removed and re-created from current setup.
    func syncParts(for aircraft: Aircraft) {
        // Remove existing derived parts for this aircraft
        parts.removeAll { $0.sourceAircraftId == aircraft.id }

        guard let setup = aircraft.setup, !setup.isEmpty else {
            save(parts, to: "parts.json")
            return
        }

        func makePart(name: String?, category: PartCategory) -> Part? {
            guard let raw = name?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
                return nil
            }
            return Part(
                name: raw,
                category: category,
                quantity: 1,
                sourceAircraftId: aircraft.id
            )
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
        save(parts, to: "parts.json")
    }

    // MARK: - Test data
    /// Inserts sample aircraft, batteries, and flight records for testing.
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
                id: a1Id,
                name: "5寸花飞机",
                model: "自组",
                imageFileName: nil,
                setup: AircraftSetup(
                    frame: "Apex 5\"",
                    motor: "2306 1950kv",
                    esc: "35A BLHeli_32",
                    flightController: "F7",
                    camera: "Caddx Ratel",
                    vtx: "1.2W",
                    receiver: "ELRS 2.4G",
                    propeller: "51466",
                    other: nil
                ),
                remark: "日常练习",
                createdAt: cal.date(byAdding: .day, value: -30, to: now)!,
                updatedAt: now
            ),
            Aircraft(
                id: a2Id,
                name: "3.5寸 cinewhoop",
                model: "自组",
                imageFileName: nil,
                setup: AircraftSetup(
                    frame: "GEPRC CineLog",
                    motor: "1404 3800kv",
                    esc: "20A",
                    flightController: "F4",
                    camera: "Nebula Pro",
                    vtx: "400mW",
                    receiver: "ELRS",
                    propeller: "3520",
                    other: "GoPro 支架"
                ),
                remark: "拍视频用",
                createdAt: cal.date(byAdding: .day, value: -14, to: now)!,
                updatedAt: now
            ),
        ]

        let batteryList: [Battery] = [
            Battery(id: b1Id, name: "Tattu 6S 1300", code: "T1", capacityMah: 1300, cells: 6, cycles: 12, status: .active, remark: nil, createdAt: now, updatedAt: now),
            Battery(id: b2Id, name: "Tattu 6S 1300", code: "T2", capacityMah: 1300, cells: 6, cycles: 28, status: .active, remark: nil, createdAt: now, updatedAt: now),
            Battery(id: b3Id, name: "CNHL 4S 850", code: "C1", capacityMah: 850, cells: 4, cycles: 5, status: .active, remark: "cinewhoop用", createdAt: now, updatedAt: now),
        ]

        let flightList: [FlightRecord] = [
            FlightRecord(aircraftId: a1Id, batteryIds: [b1Id], startAt: cal.date(byAdding: .day, value: -2, to: now)!, durationSeconds: 480, address: "郊区飞场", latitude: 39.9, longitude: 116.4, remark: "花飞练习", createdAt: now, updatedAt: now),
            FlightRecord(aircraftId: a1Id, batteryIds: [b2Id], startAt: cal.date(byAdding: .day, value: -2, to: now)!, durationSeconds: 460, address: "郊区飞场", latitude: 39.9, longitude: 116.4, remark: nil, createdAt: now, updatedAt: now),
            FlightRecord(aircraftId: a1Id, batteryIds: [b1Id], startAt: cal.date(byAdding: .day, value: -1, to: now)!, durationSeconds: 510, address: "公园", remark: nil, createdAt: now, updatedAt: now),
            FlightRecord(aircraftId: a2Id, batteryIds: [b3Id], startAt: cal.date(byAdding: .day, value: -1, to: now)!, durationSeconds: 360, address: "小区", remark: "试拍", createdAt: now, updatedAt: now),
            FlightRecord(aircraftId: a2Id, batteryIds: [b3Id], startAt: now, durationSeconds: 0, address: nil, remark: "刚起飞", createdAt: now, updatedAt: now),
        ]

        for a in aircraftList { addAircraft(a) }
        for b in batteryList { addBattery(b) }
        for f in flightList { addFlight(f) }

        // Derive parts from seeded aircraft
        for a in aircraftList {
            syncParts(for: a)
        }
    }
}
