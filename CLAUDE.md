# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Build (simulator)
xcodebuild -project FPVGarage.xcodeproj -scheme FPVGarage -sdk iphonesimulator -quiet build

# Run all tests
xcodebuild -project FPVGarage.xcodeproj -scheme FPVGarage -sdk iphonesimulator -quiet test

# Run only unit tests (faster)
xcodebuild -project FPVGarage.xcodeproj -scheme FPVGarageTests -sdk iphonesimulator -quiet test
```

Always verify the project builds before committing.

## Architecture

MVVM + Repository pattern with file-based JSON persistence. No third-party dependencies — all native iOS frameworks.

**Layer responsibilities:**
- `Models/` — Plain Swift structs (Codable); no business logic
- `Domain/RepositoryProtocols.swift` — Abstract interfaces for all CRUD operations
- `Storage/Repositories.swift` — Concrete implementations; `FileStorageService.swift` handles all disk I/O via `NSFileCoordinator` (supports iCloud Drive)
- `Storage/AppState.swift` — `ObservableObject` holding in-memory arrays for all entities; owns all CRUD methods; `syncParts()` mirrors aircraft setup entries into the parts list automatically
- `DIContainer.swift` — Creates and owns AppState and all repository instances; injected as `@StateObject` at app root
- `ViewModels/` — One per edit/detail context; receive AppState from DI container; contain all business logic
- `Views/` — SwiftUI only; no business logic

**Data flow:**
```
View → ViewModel → AppState.mutatingMethod() → Repository.save() → FileStorageService → JSON on disk
                       ↑ @Published arrays trigger view updates
```

**Key behaviors:**
- `AppState.syncParts()` is called after any aircraft save/delete — keeps the Parts tab in sync with aircraft component setup
- iCloud Drive is the primary storage location when available; auto-migrates from local `Documents/FPVGarage/` on first run
- Images are stored as JPEG files in `aircraft_images/` by UUID filename, separate from the JSON data files

## Testing Approach

- `XCTest` with no external frameworks
- `FPVGarageTests/Mocks/MockRepositories.swift` provides in-memory mock implementations of all repository protocols — use these in ViewModel tests
- `AppStateTests.swift` exercises real CRUD + `syncParts()` behavior
- `FileStorageServiceTests.swift` uses a temp directory to avoid touching real app storage

## Localization

All user-facing strings go through `String(localized:)` and are registered in `Localizable.xcstrings`. The app supports English (default) and Simplified Chinese (zh-Hans).

## Planned Feature: LLM Config Advice

`SPEC.md` (Section 11) and `ROADMAP.md` document a planned AI-powered config advisor. Key design decisions already made:
- Offline-first: thrust-to-weight and compatibility checks are deterministic/rule-based with no network required
- LLM integration is opt-in; API keys stored in Keychain
- Only an explicit allowlist of fields is ever sent to the LLM — no GPS coordinates, free-text remarks, or PII
- Advice is per-aircraft, keyed by a config hash for staleness detection
