import SwiftUI

struct AdviceEntryView: View {
    @EnvironmentObject var container: DIContainer
    @StateObject private var viewModel: AdviceViewModel
    @State private var showConsent = false

    init(appState: AppState, aircraft: Aircraft, container: DIContainer) {
        _viewModel = StateObject(wrappedValue: AdviceViewModel(
            appState: appState,
            aircraft: aircraft,
            llmClient: container.llmClient,
            apiKeyStore: container.apiKeyStore,
            sessionRepo: container.adviceSessionRepo
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Offline TWR
                if let twr = viewModel.twrResult {
                    TWRGaugeView(result: twr)
                }

                // Offline compat warnings
                if !viewModel.compatWarnings.isEmpty {
                    CompatibilityWarningsView(warnings: viewModel.compatWarnings)
                }

                // AI Advice section
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Config Advice")
                        .font(.headline)

                    if let response = viewModel.adviceResponse {
                        AdviceResultView(response: response, streamingText: nil)
                    } else if viewModel.isLoading {
                        AdviceResultView(response: nil, streamingText: viewModel.streamingText)
                    } else if let error = viewModel.error {
                        errorView(error)
                    }

                    if viewModel.isStale, viewModel.cachedSession != nil {
                        Label("Config changed — regenerate?", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    HStack {
                        if !viewModel.hasAPIKey {
                            NavigationLink("Set Up API Key") {
                                AdviceSettingsView(container: container)
                            }
                            .font(.subheadline)
                        } else {
                            Button {
                                if viewModel.hasConsented {
                                    Task { await viewModel.requestAdvice() }
                                } else {
                                    showConsent = true
                                }
                            } label: {
                                Label("Get AI Advice", systemImage: "sparkles")
                            }
                            .disabled(viewModel.isLoading)

                            if viewModel.cachedSession != nil {
                                Button {
                                    Task { await viewModel.requestAdvice(forceRefresh: true) }
                                } label: {
                                    Label("Regenerate", systemImage: "arrow.clockwise")
                                }
                                .disabled(viewModel.isLoading)
                            }
                        }
                    }
                    .buttonStyle(.bordered)

                    if viewModel.cachedSession != nil {
                        NavigationLink {
                            AdviceHistoryView(
                                aircraftId: viewModel.aircraft.id,
                                sessionRepo: container.adviceSessionRepo,
                                currentConfigHash: ConfigHashCalculator.hash(aircraft: viewModel.aircraft, battery: nil)
                            )
                        } label: {
                            Label("Advice History", systemImage: "clock.arrow.circlepath")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(.background.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .navigationTitle("Config Advice")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.computeOfflineResults() }
        .sheet(isPresented: $showConsent) {
            consentSheet
        }
    }

    // MARK: - Consent Sheet

    private var consentSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("LLM Configuration Advice")
                        .font(.title2.bold())

                    Text("This feature uses an LLM to analyze your aircraft configuration and provide advice.")

                    Text("We will send to the LLM provider:")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 6) {
                        bulletPoint("Aircraft name, flight style, pilot skill level, motor specs, TWR ratio, compatibility warnings")
                        bulletPoint("Battery cell count and capacity (no names or personal data)")
                        bulletPoint("Part counts by category")
                        bulletPoint("Your device locale")
                    }

                    Text("Your API key is stored securely in Keychain. We do not proxy or meter your usage.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Text("Part suggestions are AI-generated and may be inaccurate. Always verify before purchasing.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Text("You can disable this feature at any time in Settings.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showConsent = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enable") {
                        viewModel.grantConsent()
                        showConsent = false
                        Task { await viewModel.requestAdvice() }
                    }
                }
            }
        }
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
            Text(text)
        }
        .font(.callout)
    }

    // MARK: - Error View

    @ViewBuilder
    private func errorView(_ error: LLMError) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(errorMessage(error))
                .font(.subheadline)
        }
    }

    private func errorMessage(_ error: LLMError) -> String {
        switch error {
        case .noAPIKey: return String(localized: "No API key configured.")
        case .invalidAPIKey: return String(localized: "Invalid API key. Check Settings.")
        case .rateLimited: return String(localized: "Rate limited. Please try again later.")
        case .networkUnavailable: return String(localized: "No network connection.")
        case .serverError(let code): return String(localized: "Server error (\(code)).")
        case .malformedResponse: return String(localized: "Could not parse LLM response.")
        case .streamInterrupted: return String(localized: "Connection interrupted. Try again.")
        case .emptyResponse: return String(localized: "Empty response from LLM.")
        }
    }
}
