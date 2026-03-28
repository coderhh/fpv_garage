import Foundation
@testable import FPVGarage

final class MockLLMClient: LLMClientProtocol {
    var stubbedChunks: [LLMChunk] = []
    var stubbedError: Error?
    var lastRequest: LLMRequest?
    var sendCallCount = 0

    func send(request: LLMRequest) async throws -> AsyncStream<LLMChunk> {
        sendCallCount += 1
        lastRequest = request

        if let error = stubbedError {
            throw error
        }

        let chunks = stubbedChunks
        return AsyncStream { continuation in
            for chunk in chunks {
                continuation.yield(chunk)
            }
            continuation.finish()
        }
    }

    /// Helper: stub a full JSON response as a single chunk
    func stubResponse(_ json: String) {
        stubbedChunks = [LLMChunk(delta: json, isFinished: true)]
    }

    /// Helper: stub a streaming response split into chunks
    func stubStreamingResponse(_ parts: [String]) {
        stubbedChunks = parts.enumerated().map { index, part in
            LLMChunk(delta: part, isFinished: index == parts.count - 1)
        }
    }
}
