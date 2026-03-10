import Foundation
import UniformTypeIdentifiers
import SwiftUI

/// Snapshot of all persisted entities for export/import.
struct AllDataSnapshot: Codable {
    let aircraft: [Aircraft]
    let batteries: [Battery]
    let flights: [FlightRecord]
    let parts: [Part]
}

/// FileDocument used to export all app data as a single JSON file.
struct AllDataDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var snapshot: AllDataSnapshot

    init(snapshot: AllDataSnapshot) {
        self.snapshot = snapshot
    }

    init(configuration: ReadConfiguration) throws {
        // Basic decode support if we add import later.
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.snapshot = try JSONDecoder().decode(AllDataSnapshot.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        return .init(regularFileWithContents: data)
    }
}

