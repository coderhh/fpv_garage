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
    - “Export All Data (JSON)” triggers a file export flow using `AllDataDocument`.
  - **Development & Testing section** (debug only)
    - “Generate Test Data” seeds local storage with sample entities.
    - “Clear All Data” shows a confirmation dialog and then wipes all stored entities.
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
  - Local, file‑based persistence using JSON files under the app’s container.
  - `FileStorageService` handles encoding/decoding entities and writing to disk.
  - `AppState` is the single source of truth for in‑memory data and reacts to changes.
- **Export**
  - `AllDataDocument` implements `FileDocument` with `UTType.json`.
  - `HomeView` uses `.fileExporter` bound to `HomeViewModel`’s `exportDocument` and `isExporting`.
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
  - Debug‑only “Clear All Data” flow supports repeated manual experiments.

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

