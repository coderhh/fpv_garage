import Foundation
@testable import FPVGarage

final class MockAPIKeyStore: APIKeyStoreProtocol {
    private var keys: [String: String] = [:]
    var saveCallCount = 0
    var deleteCallCount = 0

    func save(key: String, for provider: String) throws {
        saveCallCount += 1
        keys[provider] = key
    }

    func load(for provider: String) -> String? {
        keys[provider]
    }

    func delete(for provider: String) throws {
        deleteCallCount += 1
        keys.removeValue(forKey: provider)
    }
}
