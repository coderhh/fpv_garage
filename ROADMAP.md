# FPV Garage — Roadmap

High-level plan for upcoming features. Dates and order are indicative and may change.

---

## Current (shipped)

- Flights, Aircraft, Batteries, Parts CRUD with local persistence
- Home overview (counts, total flight duration)
- Export all data as JSON
- Aircraft setup with photo; parts mirrored from aircraft
- Map/GPS for flight location; test data seeding and clear-all for development

---

## Planned: LLM-Powered Config Advice & Recommendations

**Goal:** Use an LLM to give FPV pilots actionable advice on configuration, thrust-to-weight (推重比), and part purchases, using data already in the app.

### Features in scope

| Feature | Description |
|--------|-------------|
| **Config advice** | Natural-language suggestions based on current aircraft setup, battery choice, and usage (e.g. freestyle vs racing). |
| **Thrust-to-weight (推重比)** | Compute thrust ÷ weight from motor/prop/AUW (or user input); show ratio and optionally LLM interpretation (“good for X”, “consider lighter battery”). |
| **Part purchase suggestions** | e.g. “Low on ESCs”, “Motor X often pairs with prop Y”, “Consider upgrading VTX” based on inventory and linked aircraft. |

### Solution summary

- **Data:** Read-only use of existing models (Aircraft, Part, Battery, FlightRecord). No new core entities for v1; optional later: explicit motor thrust / AUW fields if not derivable.
- **Thrust-to-weight:** Deterministic formula in-app (offline-capable); result can be passed into LLM context for interpretation.
- **LLM:** Cloud API (OpenAI-compatible) with user-supplied API key; prompt built from a structured summary of fleet/parts/batteries and computed metrics. Settings: enable/disable, key entry, privacy disclosure.
- **UX:** New “Config advice” / “AI 建议” entry (e.g. from Home or Aircraft detail); one flow: trigger → loading → show advice text + metrics (e.g. 推重比).
- **Architecture:** New feature module (view model + view); optional `AdviceService` / `LLMClient` abstraction; repositories stay read-only; prompts and API behind a service for testability and provider swap.

### Phases (implementation order)

1. **Thrust-to-weight calculation** — Add formula and inputs (motor thrust, AUW); show ratio in UI (no LLM). Ensures data model supports metrics needed for advice.
2. **LLM integration & config advice** — Settings for API key and disclosure; `AdviceService`; prompt that includes fleet/parts summary and 推重比; single “Get advice” flow with loading and result screen.
3. **Part purchase suggestions** — Extend prompt (and optionally UI) for inventory-based recommendations (low stock, common pairings, upgrade suggestions).

### Out of scope (for this feature)

- Cloud sync, multi-device, or user accounts
- In-app purchasing or direct retailer integration
- Real-time telemetry or black-box analysis
- Mandatory telemetry/analytics (user data only sent when they use the advice feature and have configured an API key)

### Dependencies & constraints

- **Network:** Advice feature requires network when calling LLM; thrust-to-weight can be offline.
- **Privacy:** User must be informed that using advice sends a data summary to the chosen LLM provider.
- **Cost:** API usage is the user’s responsibility (their key, their billing).

---

## Later (ideas, not committed)

- On-device LLM option for simpler advice (e.g. Apple ML)
- Richer aircraft metrics (thrust tables, prop databases) for more accurate 推重比
- Localization for advice UI and prompts (e.g. Chinese)
