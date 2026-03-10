import Foundation

final class FileStorageService {
    private let fileManager = FileManager.default
    private(set) var iCloudBaseURL: URL?

    var storageBaseURL: URL {
        iCloudBaseURL ?? localBaseURL
    }

    var localBaseURL: URL {
        let doc = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return doc.appendingPathComponent("FPVGarage", isDirectory: true)
    }

    var aircraftImagesURL: URL {
        let url = storageBaseURL.appendingPathComponent("aircraft_images", isDirectory: true)
        ensureDirectory(url)
        return url
    }

    init() {
        ensureDirectory(localBaseURL)
    }

    func ensureDirectory(_ url: URL) {
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    func load<T: Decodable>(_ type: T.Type, from file: String) -> T? {
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

    func save<T: Encodable>(_ value: T, to file: String) {
        ensureDirectory(storageBaseURL)
        let url = storageBaseURL.appendingPathComponent(file)
        guard let data = try? JSONEncoder().encode(value) else { return }
        let coordinator = NSFileCoordinator()
        var coordinatorError: NSError?
        coordinator.coordinate(writingItemAt: url, options: .forReplacing, error: &coordinatorError) { coordinatedURL in
            try? data.write(to: coordinatedURL)
        }
    }

    func resolveICloud(completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            guard let containerURL = self.fileManager.url(forUbiquityContainerIdentifier: "iCloud.com.yehanghan.fpvgarage.app") else {
                return
            }
            let iCloudBase = containerURL
                .appendingPathComponent("Documents", isDirectory: true)
                .appendingPathComponent("FPVGarage", isDirectory: true)
            self.ensureDirectory(iCloudBase)
            DispatchQueue.main.async {
                let hadICloud = self.iCloudBaseURL != nil
                self.iCloudBaseURL = iCloudBase
                if !hadICloud {
                    self.migrateLocalToICloud(local: self.localBaseURL, iCloud: iCloudBase)
                }
                completion()
            }
        }
    }

    private func migrateLocalToICloud(local: URL, iCloud: URL) {
        let files = ["aircraft.json", "batteries.json", "flight_records.json", "parts.json"]
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
}
