import SwiftUI

struct AdviceSettingsView: View {
    @ObservedObject var container: DIContainer
    @State private var apiKeyText = ""
    @State private var hasKey = false
    @State private var showSaved = false
    @State private var showDeleteConfirm = false

    private var currentProvider: LLMProvider {
        container.selectedProvider
    }

    var body: some View {
        Form {
            Section("Provider") {
                Picker("Provider", selection: $container.selectedProvider) {
                    ForEach(LLMProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                HStack {
                    Text("Model")
                    Spacer()
                    Text(currentProvider.defaultModel)
                        .foregroundStyle(.secondary)
                }
            }

            Section("API Key — \(currentProvider.displayName)") {
                SecureField("API Key", text: $apiKeyText)
                    .textContentType(.password)
                    .autocorrectionDisabled()

                HStack {
                    Button("Save Key") {
                        guard !apiKeyText.isEmpty else { return }
                        try? container.apiKeyStore.save(key: apiKeyText, for: currentProvider.keychainKey)
                        hasKey = true
                        showSaved = true
                        apiKeyText = ""
                    }
                    .disabled(apiKeyText.isEmpty)

                    if hasKey {
                        Button("Remove Key", role: .destructive) {
                            try? container.apiKeyStore.delete(for: currentProvider.keychainKey)
                            hasKey = false
                        }
                    }
                }
            }

            Section {
                Text("Your API key is stored securely in the iOS Keychain. It is never included in data exports or sent to anyone other than the selected LLM provider.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("History") {
                HStack {
                    Text("Session Cap")
                    Spacer()
                    Text("20 per aircraft")
                        .foregroundStyle(.secondary)
                }
                Button("Delete All Advice Sessions", role: .destructive) {
                    showDeleteConfirm = true
                }
            }

            #if DEBUG
            Section("Debug") {
                HStack {
                    Text("API Key Set")
                    Spacer()
                    Text(hasKey ? "Yes" : "No")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Provider Key")
                    Spacer()
                    Text(currentProvider.keychainKey)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Base URL")
                    Spacer()
                    Text(currentProvider.baseURL)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            #endif
        }
        .navigationTitle("AI Advice Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refreshKeyStatus() }
        .onChange(of: container.selectedProvider) { _ in
            refreshKeyStatus()
            apiKeyText = ""
        }
        .alert("API Key Saved", isPresented: $showSaved) {
            Button("OK") {}
        }
        .alert("Delete All Sessions?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete All", role: .destructive) {
                deleteAllSessions()
            }
        } message: {
            Text("This will delete all advice history for all aircraft.")
        }
    }

    private func refreshKeyStatus() {
        hasKey = container.apiKeyStore.load(for: currentProvider.keychainKey) != nil
    }

    private func deleteAllSessions() {
        let storage = FileStorageService()
        let sessionsDir = storage.storageBaseURL.appendingPathComponent("advice_sessions", isDirectory: true)
        try? FileManager.default.removeItem(at: sessionsDir)
    }
}
