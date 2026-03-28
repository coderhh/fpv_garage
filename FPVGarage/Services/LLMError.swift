import Foundation

enum LLMError: Error, Equatable {
    case noAPIKey
    case invalidAPIKey
    case rateLimited(retryAfterSeconds: Int?)
    case networkUnavailable
    case serverError(statusCode: Int)
    case malformedResponse
    case streamInterrupted
    case emptyResponse
}
