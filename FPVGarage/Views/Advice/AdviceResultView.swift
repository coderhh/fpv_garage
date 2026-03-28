import SwiftUI

struct AdviceResultView: View {
    let response: AdviceResponse?
    let streamingText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let response {
                structuredView(response)
            } else if let text = streamingText, !text.isEmpty {
                streamingView(text)
            }
        }
    }

    // MARK: - Streaming

    @ViewBuilder
    private func streamingView(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("Generating advice...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Structured Response

    @ViewBuilder
    private func structuredView(_ response: AdviceResponse) -> some View {
        section(title: "Summary", content: response.configSummary)

        if !response.strengths.isEmpty {
            listSection(title: "Strengths", items: response.strengths, icon: "checkmark.circle.fill", color: .green)
        }

        if !response.improvements.isEmpty {
            listSection(title: "Improvements", items: response.improvements, icon: "arrow.up.circle.fill", color: .orange)
        }

        if let twr = response.twrComment {
            section(title: "TWR Comment", content: twr)
        }

        if !response.compatibilityNotes.isEmpty {
            listSection(title: "Compatibility Notes", items: response.compatibilityNotes, icon: "info.circle.fill", color: .blue)
        }

        if let suggestions = response.partSuggestions, !suggestions.isEmpty {
            partSuggestionsSection(suggestions)
        }
    }

    private func partSuggestionsSection(_ suggestions: [PartSuggestion]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Part Suggestions")
                .font(.subheadline.bold())

            Text("Part suggestions are AI-generated and may be inaccurate. Always verify before purchasing.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(8)
                .background(.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            ForEach(suggestions) { suggestion in
                HStack(alignment: .top, spacing: 6) {
                    Text(suggestion.priority.rawValue.capitalized)
                        .font(.caption2.bold())
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(priorityColor(suggestion.priority).opacity(0.2))
                        .foregroundStyle(priorityColor(suggestion.priority))
                        .clipShape(Capsule())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(suggestion.name)
                            .font(.body.bold())
                        Text(suggestion.reason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func priorityColor(_ priority: SuggestionPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }

    private func section(title: LocalizedStringKey, content: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.bold())
            Text(content)
                .font(.body)
        }
    }

    private func listSection(title: LocalizedStringKey, items: [String], icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                        .font(.caption)
                        .padding(.top, 2)
                    Text(item)
                        .font(.body)
                }
            }
        }
    }
}
