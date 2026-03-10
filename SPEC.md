## FPV Garage – Product & Technical Spec

### 1. Overview

- **Product name**: FPV Garage
- **Platform**: iOS (SwiftUI app)
- **Purpose**: Help FPV pilots manage their fleet (aircraft), batteries, flights, and spare parts in a single, offline-first app with simple backup/export.

### 2. Goals & Non‑Goals

- **Goals**
  - Track aircraft, batteries, flights, and parts with enough detail for real‑world use.
  - Provide quick at‑a‑glance stats on the home screen (counts, total flight duration).
  - Make it easy to seed test data and clear all data for development.
  - Support export of all data as a JSON snapshot for backup or migration.
  - Keep architecture clean (MVVM + repositories) to enable future features.
- **Non‑Goals (for now)**
  - Cloud sync, multi‑device real‑time collaboration.
  - In‑app analytics dashboards beyond simple counts and totals.
  - Complex user management or authentication.

### 3. User Personas & Use Cases

- **Primary persona**: FPV hobbyist / pilot with multiple quads, a box of batteries, and a bin of parts.
- **Key use cases**
  - Record new flights and review flight history.
  - Track aircraft inventory (e.g., quads, wings) and basic metadata.
  - Track LiPo batteries, status (active/retired/damaged), and cycle count.
  - Track parts inventory (frames, motors, ESCs, etc.) and their quantities.
  - See quick overview of counts and total flight duration on the home screen.
  - Export all data to JSON for backup; optionally clear all data and reseed for testing.

### 4. Core Domain Model

- **Aircraft** (inferred)
  - Represents a flyable platform (e.g., quadcopter).
  - Typical fields: id, name, type, remarks, timestamps.
- **Battery**
  - `id: UUID`, `name: String`, `code: String?`, `capacityMah: Int?`, `cells: Int?`, `cycles: Int`, `status: BatteryStatus`, `remark: String?`, `createdAt: Date`, `updatedAt: Date`.
  - `BatteryStatus`: `active`, `retired`, `damaged` (+ localized `displayName`).
- **Part**
  - `id: UUID`, `name: String`, `category: PartCategory`, `quantity: Int`, `sourceAircraftId: UUID?`, `remark: String?`, `createdAt: Date`, `updatedAt: Date`.
  - `PartCategory`: `frame`, `motor`, `esc`, `flightController`, `camera`, `vtx`, `receiver`, `propeller`, `other` (+ localized `displayName`).
- **FlightRecord** (inferred)
  - Represents a single flight with aircraft, battery, duration, and notes.
- **AllDataSnapshot**
  - Aggregates `[Aircraft]`, `[Battery]`, `[FlightRecord]`, `[Part]` for export/import.

### 5. UX Flows & Screens

- **Home**
  - Shows overview metrics:
    - Flight Count
    - Total Duration (seconds)
    - Aircraft count
    - Battery count
    - Part count
  - **Data section**
    - "Export All Data (JSON)" triggers a file export flow using `AllDataDocument`.
  - **Development & Testing section** (debug only)
    - "Generate Test Data" seeds local storage with sample entities.
    - "Clear All Data" shows a confirmation dialog and then wipes all stored entities.
  - Toolbar: gear button opens **Settings**.
- **Settings**
  - Central place for global app options (exact options can evolve; currently simple).
- **Entities CRUD**
  - **Aircraft** list, detail, and edit views.
  - **Battery** list and edit views (includes status and cycle count).
  - **Flight** list, detail, and edit views (duration, associated entities).
  - **Part** list, detail, and edit views, with filter chips by `PartCategory`.

### 6. Architecture

- **Overall pattern**: MVVM + repository + file‑based persistence.
- **Layers**
  - **Domain models**
    - Simple `struct`s (`Aircraft`, `Battery`, `FlightRecord`, `Part`, etc.) + enums.
    - Codable, `Identifiable` where appropriate.
  - **Repository protocols (`Domain/RepositoryProtocols.swift`)**
    - Define interfaces for CRUD operations on each aggregate.
    - Hide persistence details from the rest of the app.
  - **Storage layer (`Storage/*`)**
    - `AppState`: Observable, holds in‑memory collections of domain entities and orchestrates loading/saving via repositories.
    - `FileStorageService`: Low‑level file IO using `FileManager` and JSON encoding/decoding.
    - `Repositories`: Concrete repository implementations that persist via `FileStorageService`.
    - `AllDataDocument`: `FileDocument` used for exporting `AllDataSnapshot` as JSON.
  - **Dependency injection (`DIContainer`)**
    - Owns `AppState` and repository instances.
    - Exposed as a `@StateObject` in `FPVGarageApp` and injected via `.environmentObject(appState)`.
  - **View models (`ViewModels/*`)**
    - One per major feature (home, aircraft edit, battery edit, flight edit, part edit).
    - Sit between SwiftUI views and the repositories/AppState.
  - **SwiftUI views (`Views/*`)**
    - Stateless (or lightly stateful) presentation components that bind to view models.
    - Use `NavigationStack`, `List`, `Sheet`, `ConfirmationDialog`, and `fileExporter`.

### 7. Persistence & Data Export

- **Persistence**
  - Local, file‑based persistence using JSON files under the app's container.
  - `FileStorageService` handles encoding/decoding entities and writing to disk.
  - `AppState` is the single source of truth for in‑memory data and reacts to changes.
- **Export**
  - `AllDataDocument` implements `FileDocument` with `UTType.json`.
  - `HomeView` uses `.fileExporter` bound to `HomeViewModel`'s `exportDocument` and `isExporting`.
  - Exported file is named `fpv-garage-backup.json` by default and contains a full `AllDataSnapshot`.

### 8. Localization & Accessibility

- **Localization**
  - Uses `String(localized:)` for user‑facing strings (e.g., `BatteryStatus.displayName`, `PartCategory.displayName`).
  - `Localizable.xcstrings` stores localized strings; new text should be added there.
- **Accessibility**
  - Use SF Symbols and `Label` for list rows where possible.
  - Provide identifiers where needed for UI testing (e.g., `settingsButton`).

### 9. Testing

- **Unit tests (`FPVGarageTests`)**
  - Cover view models, AppState, repositories, and storage behavior.
  - Include mocks for repositories to test view models in isolation.
- **UI tests (`FPVGarageUITests`)**
  - Exercise primary navigation flows and basic interactions (e.g., opening settings).
- **Development utilities**
  - `HomeViewModel.seedTestData()` fills the app with sample entities for manual testing.
  - Debug‑only "Clear All Data" flow supports repeated manual experiments.

### 10. Non‑Functional Requirements

- **Performance**
  - Designed for small to medium personal inventories (tens to hundreds of entities).
  - File‑based JSON storage is acceptable; no database is required at this scale.
- **Reliability**
  - Reading/writing failures should be surfaced via errors in repositories and test coverage.
  - Clearing and seeding should always leave `AppState` in a consistent state.
- **Maintainability**
  - New features should be introduced by:
    - Extending domain models.
    - Updating repository protocols and concrete implementations.
    - Adding/adjusting view models and views.
  - Avoid putting business logic directly inside SwiftUI views.

---

### 11. Planned: LLM-Powered Config Advice & Recommendations

#### 11.1 Overview

A dedicated feature module will provide FPV pilots with data-driven, actionable advice across three layers:

| Layer | Mechanism | Network required? |
|---|---|---|
| **Thrust-to-weight (推重比)** | Deterministic offline calculation + flight-style-relative tier | No |
| **Compatibility checker** | Rule-based offline checks (ESC/motor/battery/KV rules) | No |
| **AI config advice & part suggestions** | LLM API call with structured prompt + response | Yes |

The offline layers (推重比 + compatibility) deliver immediate value without any API key or network dependency, and feed context into the LLM layer.

#### 11.2 Scope

- **In scope (v1)**
  - Offline 推重比 with flight-style-relative tier and visual gauge.
  - Offline compatibility checker surfacing rule-based warnings (ESC current, KV/voltage, C-rating).
  - LLM config advice and part suggestions via user-supplied API key.
  - Pilot skill level as advice context input.
  - Advice history: past sessions stored locally, invalidated by configuration change (not just TTL).
  - Settings: provider selection, API key (Keychain-backed), opt-in toggle, privacy disclosure.
- **Out of scope (v1)**
  - Real-time telemetry or black-box data.
  - Automated retailer sync or in-app purchasing.
  - Multi-turn conversation (chat) UX.
  - Fixed-wing / wing-specific advice (different physics; addressed in a future pass).

#### 11.3 FPV Domain Rules & Constraints

> These rules encode professional FPV knowledge. They drive both the compatibility checker and the LLM prompt context. They are **deterministic** — the LLM is not used to answer these.

**Thrust-to-weight tiers (flight-style-relative)**

TWR thresholds are meaningless without flight style context. A 4:1 TWR is excellent for long-range but inadequate for freestyle.

| Flight style | Under-powered | Adequate | Good | Ideal |
|---|---|---|---|---|
| `freestyle` | < 4.0 | 4.0–5.5 | 5.5–8.0 | > 8.0 |
| `racing` | < 6.0 | 6.0–8.0 | 8.0–10.0 | > 10.0 |
| `cinematic` | < 3.0 | 3.0–4.5 | 4.5–6.0 | > 6.0 |
| `longRange` | < 2.5 | 2.5–3.5 | 3.5–5.0 | > 5.0 |
| `whoop` | < 2.0 | 2.0–3.0 | 3.0–4.0 | > 4.0 |

**TWR calculation nuances**

- Thrust is voltage-dependent; the calculation must use actual battery cell count (from linked `Battery.cells`) and nominal cell voltage (3.7V LiPo, 3.8V LiHV).
- Manufacturer thrust figures are typically at 100% throttle on a specific prop. Without knowing the prop, results carry ±15–20% uncertainty — the UI should display a confidence indicator.
- AUW must include the battery weight; this links `Aircraft` to its associated `Battery` for weight.

**ESC–motor–battery compatibility rules (deterministic, offline)**

| Rule | Rationale |
|---|---|
| `ESC continuous current ≥ motor max draw` | Most common beginner mistake. Undersized ESC burns during aggressive flights. |
| `motor KV × battery voltage ∈ [18 000, 24 000] RPM` | Rule of thumb for 5" quads; outside this range the motor is mismatched to the battery. Ratio shifts for other frame sizes. |
| `battery C-rating × capacity (Ah) ≥ total peak motor draw` | Prevents over-discharging, puffing, and cell damage. |
| `ESC protocol supported by FC` | DSHOT300/600/1200 must match FC output; mismatched protocol causes erratic behaviour. |

> These checks produce `CompatibilityWarning` items (error / warning / info severity) displayed in the Aircraft detail view — **independent of and prior to any LLM call**.

#### 11.4 Domain Model Extensions

All fields are optional and backward-compatible.

**Extensions to `Aircraft`**

| Field | Type | Purpose |
|---|---|---|
| `flightStyle` | `FlightStyle?` | Drives TWR tier thresholds and LLM advice context |
| `pilotSkillLevel` | `PilotSkillLevel?` | Adjusts advice tone and detail (beginner / intermediate / advanced) |
| `frameSizeInch` | `Double?` | Frame size (e.g. 3.0, 5.0, 7.0); critical for motor/prop pairing advice |
| `motorModel` | `String?` | User-entered motor name (e.g. "T-Motor F60 Pro IV 2400KV"); used in LLM prompt |
| `motorKv` | `Int?` | Motor KV rating; used in voltage-KV compatibility check |
| `motorThrustGrams` | `Int?` | Per-motor static thrust at rated voltage; source: spec sheet or thrust-stand |
| `motorThrustDataSource` | `ThrustDataSource?` | `measured` / `specSheet` / `estimated` — drives confidence indicator |
| `propSize` | `String?` | e.g. "5148", "5045"; displayed in TWR confidence note |
| `batteryCellCount` | `Int?` | Overrides linked battery cells if different battery used for bench data |
| `allUpWeightGrams` | `Int?` | Full AUW; app can estimate from linked battery if not entered |

**New enums**

- **`FlightStyle`**: `freestyle`, `racing`, `cinematic`, `longRange`, `whoop`.
  - `fixedWing` deferred to a future spec (different physics; TWR and ESC rules don't apply).
- **`PilotSkillLevel`**: `beginner`, `intermediate`, `advanced`.
  - Injected into LLM prompt to tune advice tone and specificity.
- **`ThrustDataSource`**: `measured`, `specSheet`, `estimated`.
  - Used to render a confidence indicator on the TWR display.
- **`TWRTier`**: `underpowered`, `adequate`, `good`, `ideal` (thresholds per §11.3).
- **`CompatibilityWarningLevel`**: `error`, `warning`, `info`.

**New value types**

- **`ThrustToWeightResult`** (`Codable`): `ratio: Double`, `tier: TWRTier`, `flightStyle: FlightStyle`, `confidence: ThrustDataSource`, `calculatedAt: Date`.
- **`CompatibilityWarning`** (`Codable`): `rule: String`, `level: CompatibilityWarningLevel`, `detail: String`.
- **`AdviceResponse`** (`Codable`): `configSummary: String`, `strengths: [String]`, `improvements: [String]`, `partSuggestions: [PartSuggestion]`, `twrComment: String?`, `compatibilityNotes: [String]`.
  - `PartSuggestion`: `name: String`, `reason: String`, `priority: SuggestionPriority`, `hallucination_disclaimer: Bool` (always `true` for part suggestions; surfaced in UI).

**New entity**

- **`AdviceSession`** (`Codable`): `id: UUID`, `aircraftId: UUID`, `generatedAt: Date`, `configHash: String` (hash of aircraft+battery config at generation time — used for staleness detection), `contextSnapshot: FleetContextDTO`, `thrustToWeightResult: ThrustToWeightResult?`, `compatibilityWarnings: [CompatibilityWarning]`, `response: AdviceResponse`.

**`FleetContextDTO`** (data-transfer object, never stored with secrets)

Explicit allowlist sent to LLM:
- Aircraft: name, flightStyle, pilotSkillLevel, frameSizeInch, motorModel, motorKv, propSize, computed TWR ratio and tier, compatibility warning summaries.
- Battery: cells, capacityMah (no name, no code, no personal text).
- Parts: counts by category only (no names, no remarks).
- Excludes: GPS, all free-text remarks, photo references, personally identifiable data.

#### 11.5 Architecture

```
Views/Advice/
  AdviceEntryView            ← "AI 建议" button on AircraftDetailView
  CompatibilityWarningsView  ← inline in AircraftDetailView; shows rule-based warnings
  AdviceResultView           ← renders AdviceResponse sections + TWR gauge (streamed)
  AdviceHistoryView          ← past AdviceSession list per aircraft; staleness indicator
  AdviceSettingsView         ← provider picker, API key entry, consent, debug panel

ViewModels/
  AdviceViewModel            ← orchestrates: TWR calc → compat check → cache → LLM call → persist

Domain/
  ThrustToWeightCalculator   ← pure function: (Aircraft, Battery?) -> ThrustToWeightResult?
  CompatibilityChecker       ← pure function: (Aircraft, Battery?) -> [CompatibilityWarning]
  PromptBuilder              ← pure struct: (FleetContextDTO) -> [LLMMessage]; versioned
  FlightStyle / PilotSkillLevel / ThrustDataSource / TWRTier / CompatibilityWarningLevel
  ThrustToWeightResult / CompatibilityWarning / AdviceSession / FleetContextDTO / AdviceResponse

Services/
  LLMClientProtocol          ← send(request: LLMRequest) async throws -> AsyncStream<LLMChunk>
  OpenAIClient               ← concrete; supports streaming (SSE) + JSON mode
  AnthropicClient            ← concrete (future)
  MockLLMClient              ← fixture-based for unit/UI tests

Storage/
  AdviceSessionRepository    ← CRUD + config-hash-based staleness query
  AdviceSessionRepositoryProtocol

Security/
  APIKeyStore                ← iOS Keychain only (Security.framework); never UserDefaults
```

#### 11.6 Prompt Engineering Strategy

- **System prompt**: defines the LLM as an expert FPV technician. Includes domain rules summary (KV/voltage table, ESC sizing guideline, TWR reference ranges per flight style) so the LLM has grounding. Versioned as `Prompts.systemV1` in source control.
- **Pilot skill level in prompt**: explicitly states skill level so advice tone adjusts. Beginner → explain basics; advanced → assume terminology, go deeper.
- **Structured output (JSON mode)**: LLM returns schema matching `AdviceResponse`. Each field renders in a dedicated UI component; no wall of unstructured text.
- **Compatibility warnings in context**: rule-based `CompatibilityWarning` items are included in the prompt. The LLM can reference them ("as noted by the compatibility check, your ESC may be undersized…") rather than re-derive them, reducing hallucination risk.
- **Part suggestions disclaimer**: the prompt instructs the LLM to explicitly flag part suggestions as recommendations requiring independent verification, and to prefer commonly available options over niche products.
- **Context window discipline**: `FleetContextDTO` is capped at ~2,000 tokens. Parts are summarised by count per category, not enumerated individually.
- **Streaming**: `AdviceResultView` renders via `AsyncStream<LLMChunk>`; first token visible within 1–2 s.
- **Locale-aware**: system prompt includes device locale; advice returned in Chinese or English accordingly.

#### 11.7 Staleness Model

Advice becomes stale when the aircraft or battery **configuration changes**, not just when time passes (pilots swap parts frequently).

- On each advice request, compute `configHash = SHA256(aircraft relevant fields + linked battery fields)`.
- If the most recent `AdviceSession.configHash` matches the current hash: return cached session (no API call).
- If hashes differ: session is marked stale; `AdviceHistoryView` shows a "Config changed – regenerate?" badge.
- Force-refresh bypasses the hash check and always calls the LLM.
- A secondary TTL (7 days, longer than the previous 24 hours) acts as a background staleness signal for unchanged configs (market evolves; advice ages).

#### 11.8 Security & Privacy

- **API key storage**: `APIKeyStore` wraps `SecItemAdd` / `SecItemCopyMatching`. Keys never touch `UserDefaults`, `AppStorage`, or the JSON export.
- **Data minimisation**: `FleetContextDTO` is constructed from an explicit allowlist. No free-text remarks, GPS, photo references, or personal identifiers are sent.
- **Consent**: one-time opt-in sheet before first API call; describes what is sent and to which provider. Revocable at any time in Settings; all saved sessions can be deleted.
- **Part suggestion disclaimer**: UI displays a persistent notice that part suggestions are LLM-generated and may be inaccurate or refer to unavailable products; always verify before purchasing.
- **No proxying**: the app calls the provider directly using the user's key. No intermediate server; no usage metering by this app.

#### 11.9 Error Handling

| Condition | Handling |
|---|---|
| No API key | Block call; deep-link to Settings. |
| 401 Unauthorized | "Invalid API key" with Settings link. |
| 429 Rate limited | Retry countdown; exponential backoff (1 s, 2 s, 4 s, cap 30 s). |
| Network unavailable | "No network" banner; TWR gauge and compatibility warnings still shown offline. |
| LLM refusal / empty response | Generic fallback; do not persist empty session. |
| Malformed JSON response | Partial parse attempt; fall back to raw text; log in debug panel. |
| Streaming interrupted | Show partial content + "Response incomplete" + Retry button. |
| TWR inputs missing | Show "Incomplete data" state; prompt user to enter motor thrust / AUW; still show compatibility warnings. |

#### 11.10 Testing Strategy

- **`ThrustToWeightCalculator`**: pure unit tests with known inputs (motor thrust, AUW, cell count, flight style) and expected ratio, tier, and confidence.
- **`CompatibilityChecker`**: unit tests for each rule (ESC current, KV/voltage, C-rating, FC protocol) with passing and failing cases.
- **`PromptBuilder`** (prompt regression): snapshot tests asserting exact prompt structure for fixed `FleetContextDTO` inputs. Prompt changes produce explicit test failures and reviewable diffs.
- **`AdviceViewModel`**: unit-tested with `MockLLMClient` and mock repository; covers config-hash cache hit/miss, stale session detection, streaming start, all error states, loading transitions.
- **`APIKeyStore`**: integration tests in a dedicated test target against the Keychain on simulator.
- **Debug panel** (debug builds only in `AdviceSettingsView`): raw `FleetContextDTO` JSON, full prompt, last `configHash` — for manual validation and prompt tuning.
- **UI tests**: full advice flow (entry → loading → result), opt-in consent sheet, compatibility warning display, stale session badge.

#### 11.11 Non-Functional Requirements

| Requirement | Target |
|---|---|
| **Perceived response time** | First token ≤ 2 s (streaming); full response ≤ 15 s. |
| **Offline capability** | TWR gauge, compatibility warnings, and advice history fully available offline. |
| **Accuracy** | Deterministic checks (TWR, compatibility) are exact. LLM advice marked as AI-generated; part suggestions carry explicit verification disclaimer. |
| **Privacy** | Explicit opt-in; `FleetContextDTO` allowlist; Keychain for secrets; no server proxy. |
| **Testability** | All deterministic logic pure and unit-tested; all LLM calls mockable. |
| **Provider portability** | New provider = new `LLMClientProtocol` implementation only. |
| **Cost** | User's key and billing; app does not proxy or meter usage. |
| **Storage growth** | `AdviceSessionRepository` caps at 20 sessions per aircraft; oldest pruned automatically. |
