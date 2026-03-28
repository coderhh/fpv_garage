import SwiftUI

struct AdviceHistoryView: View {
    let aircraftId: UUID
    let sessionRepo: AdviceSessionRepositoryProtocol
    let currentConfigHash: String

    @State private var sessions: [AdviceSession] = []
    @State private var showClearConfirm = false

    var body: some View {
        List {
            if sessions.isEmpty {
                Text("No advice history yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sessions) { session in
                    NavigationLink {
                        AdviceHistoryDetailView(session: session, currentConfigHash: currentConfigHash)
                    } label: {
                        sessionRow(session)
                    }
                }
                .onDelete(perform: deleteSessions)
            }
        }
        .navigationTitle("Advice History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !sessions.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear All", role: .destructive) {
                        showClearConfirm = true
                    }
                }
            }
        }
        .alert("Clear All History?", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                sessions = []
                sessionRepo.saveSessions([], for: aircraftId)
            }
        } message: {
            Text("This will delete all advice history for this aircraft.")
        }
        .onAppear { loadSessions() }
    }

    private func sessionRow(_ session: AdviceSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.response.configSummary)
                    .font(.subheadline)
                    .lineLimit(2)
                Text(session.generatedAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            stalenessBadge(session)
        }
    }

    @ViewBuilder
    private func stalenessBadge(_ session: AdviceSession) -> some View {
        if session.configHash != currentConfigHash {
            Text("Stale")
                .font(.caption2.bold())
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.orange.opacity(0.2))
                .foregroundStyle(.orange)
                .clipShape(Capsule())
        } else if Date().timeIntervalSince(session.generatedAt) > 7 * 24 * 3600 {
            Text("Aging")
                .font(.caption2.bold())
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.yellow.opacity(0.2))
                .foregroundStyle(.yellow)
                .clipShape(Capsule())
        }
    }

    private func deleteSessions(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        sessionRepo.saveSessions(sessions, for: aircraftId)
    }

    private func loadSessions() {
        sessions = sessionRepo.loadSessions(for: aircraftId)
            .sorted { $0.generatedAt > $1.generatedAt }
    }
}

// MARK: - History Detail (audit trail)

struct AdviceHistoryDetailView: View {
    let session: AdviceSession
    let currentConfigHash: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AdviceResultView(response: session.response, streamingText: nil)

                if let suggestions = session.response.partSuggestions, !suggestions.isEmpty {
                    partSuggestionsSection(suggestions)
                }

                auditSection
            }
            .padding()
        }
        .navigationTitle("Advice Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func partSuggestionsSection(_ suggestions: [PartSuggestion]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Part Suggestions")
                .font(.subheadline.bold())

            Text("Part suggestions are AI-generated and may be inaccurate. Always verify before purchasing.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(8)
                .background(.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            ForEach(suggestions) { suggestion in
                HStack(alignment: .top, spacing: 8) {
                    priorityBadge(suggestion.priority)
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

    private func priorityBadge(_ priority: SuggestionPriority) -> some View {
        Text(priority.rawValue.capitalized)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priorityColor(priority).opacity(0.2))
            .foregroundStyle(priorityColor(priority))
            .clipShape(Capsule())
    }

    private func priorityColor(_ priority: SuggestionPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }

    private var auditSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Audit Trail")
                .font(.subheadline.bold())

            auditRow("Generated", value: DateFormatter.localizedString(from: session.generatedAt, dateStyle: .medium, timeStyle: .short))
            auditRow("Config Hash", value: String(session.configHash.prefix(12)) + "...")

            if session.configHash != currentConfigHash {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                    Text("Config has changed since this advice was generated.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            if let twr = session.thrustToWeightResult {
                auditRow("TWR at generation", value: String(format: "%.1f:1 (%@)", twr.ratio, twr.tier.displayName))
            }

            if !session.compatibilityWarnings.isEmpty {
                auditRow("Compat warnings", value: "\(session.compatibilityWarnings.count)")
            }

            auditRow("Aircraft", value: session.contextSnapshot.aircraftName)

            if let style = session.contextSnapshot.flightStyle {
                auditRow("Flight Style", value: style.displayName)
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func auditRow(_ label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .multilineTextAlignment(.trailing)
        }
    }
}
