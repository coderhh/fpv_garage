import Foundation

final class OpenAIClient: LLMClientProtocol {
    private let apiKeyStore: APIKeyStoreProtocol
    private let session: URLSession
    private let baseURL = "https://api.openai.com/v1/chat/completions"

    init(apiKeyStore: APIKeyStoreProtocol, session: URLSession = .shared) {
        self.apiKeyStore = apiKeyStore
        self.session = session
    }

    func send(request: LLMRequest) async throws -> AsyncStream<LLMChunk> {
        guard let apiKey = apiKeyStore.load(for: LLMProvider.openai.keychainKey) else {
            throw LLMError.noAPIKey
        }

        var urlRequest = URLRequest(url: URL(string: baseURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = [
            "model": request.model,
            "temperature": request.temperature,
            "stream": true,
            "messages": request.messages.map { ["role": $0.role, "content": $0.content] }
        ]
        if request.responseFormat == .json {
            body["response_format"] = ["type": "json_object"]
        }
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await session.bytes(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.serverError(statusCode: 0)
        }

        switch httpResponse.statusCode {
        case 200: break
        case 401: throw LLMError.invalidAPIKey
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap(Int.init)
            throw LLMError.rateLimited(retryAfterSeconds: retryAfter)
        default:
            throw LLMError.serverError(statusCode: httpResponse.statusCode)
        }

        return AsyncStream { continuation in
            Task {
                do {
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))

                        if payload == "[DONE]" {
                            continuation.yield(LLMChunk(delta: "", isFinished: true))
                            continuation.finish()
                            return
                        }

                        guard let data = payload.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let delta = choices.first?["delta"] as? [String: Any],
                              let content = delta["content"] as? String else {
                            continue
                        }

                        continuation.yield(LLMChunk(delta: content, isFinished: false))
                    }
                    // Stream ended without [DONE]
                    continuation.yield(LLMChunk(delta: "", isFinished: true))
                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }
        }
    }
}
