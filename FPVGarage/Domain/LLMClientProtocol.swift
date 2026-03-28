import Foundation

// MARK: - Provider

enum LLMProvider: String, Codable, CaseIterable, Identifiable, Hashable {
    case openai
    case minimax

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openai: return "OpenAI"
        case .minimax: return "MiniMax"
        }
    }

    var defaultModel: String {
        switch self {
        case .openai: return "gpt-4o-mini"
        case .minimax: return "MiniMax-Text-01"
        }
    }

    var baseURL: String {
        switch self {
        case .openai: return "https://api.openai.com/v1/chat/completions"
        case .minimax: return "https://api.minimax.chat/v1/text/chatcompletion_v2"
        }
    }

    /// Key used in Keychain to store the API key for this provider
    var keychainKey: String { rawValue }

    static var selected: LLMProvider {
        get {
            guard let raw = UserDefaults.standard.string(forKey: "selected_llm_provider"),
                  let provider = LLMProvider(rawValue: raw) else {
                return .openai
            }
            return provider
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "selected_llm_provider")
        }
    }
}

// MARK: - Protocol

protocol LLMClientProtocol {
    func send(request: LLMRequest) async throws -> AsyncStream<LLMChunk>
}

// MARK: - Request Types

struct LLMRequest {
    let messages: [LLMMessage]
    let model: String
    let temperature: Double
    let responseFormat: LLMResponseFormat

    init(
        messages: [LLMMessage],
        model: String? = nil,
        temperature: Double = 0.4,
        responseFormat: LLMResponseFormat = .json
    ) {
        self.messages = messages
        self.model = model ?? LLMProvider.selected.defaultModel
        self.temperature = temperature
        self.responseFormat = responseFormat
    }
}

struct LLMMessage: Codable {
    let role: String   // "system" | "user"
    let content: String
}

enum LLMResponseFormat {
    case json
    case text
}

// MARK: - Response Types

struct LLMChunk {
    let delta: String
    let isFinished: Bool
}

// MARK: - Client Factory

enum LLMClientFactory {
    static func makeClient(
        provider: LLMProvider,
        apiKeyStore: APIKeyStoreProtocol,
        session: URLSession = .shared
    ) -> LLMClientProtocol {
        switch provider {
        case .openai:
            return OpenAIClient(apiKeyStore: apiKeyStore, session: session)
        case .minimax:
            return MiniMaxClient(apiKeyStore: apiKeyStore, session: session)
        }
    }
}
