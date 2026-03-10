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

**Goal:** Give FPV pilots accurate, actionable advice on configuration, compatibility, thrust-to-weight (推重比), and part choices — using data already in the app. Offline layers (推重比 + compatibility checks) deliver value without any API key. The LLM layer adds depth and natural-language guidance on top.

See [SPEC.md §11](SPEC.md) for the full product and technical specification.

---

### Three layers of intelligence

| Layer | What it does | Requires network? | Hallucination risk |
|---|---|---|---|
| **推重比 (TWR)** | Deterministic calculation; flight-style-relative tier (freestyle / racing / cinematic / long-range / whoop). Confidence indicator based on data source (measured / spec sheet / estimated). | No | None — pure maths |
| **Compatibility checker** | Rule-based offline checks: ESC current rating vs motor draw, motor KV × battery voltage, battery C-rating vs peak draw, ESC protocol vs FC. Surfaces `error / warning / info` items in Aircraft detail. | No | None — deterministic rules |
| **AI advice** | LLM-generated config assessment, strengths, improvements, and part suggestions. Takes offline layer results as context input. | Yes — LLM API call | Medium — part suggestions carry explicit disclaimer |

---

### Key FPV domain corrections (from professional review)

> These drive the spec and are not negotiable from a domain standpoint.

- **TWR tiers are flight-style-dependent.** A 4:1 TWR is great for long-range, inadequate for freestyle. Absolute tiers without flight-style context are misleading. (Previous spec had absolute thresholds of <2.0 / 2.0–3.0 / 3.0–4.5 / >4.5 — all too low for real builds.)
- **TWR is voltage-dependent.** Must use actual battery cell count. Prop size and model add ±15–20% uncertainty; confidence indicator required.
- **Compatibility rules are deterministic, not LLM.** ESC sizing, KV/voltage matching, and C-rating are rule-based checks — more reliable and faster than LLM for these.
- **Pilot skill level changes everything.** Beginner and advanced pilots need fundamentally different advice. Added `pilotSkillLevel` to aircraft context.
- **Part suggestions carry inherent hallucination risk.** LLMs confidently recommend wrong, discontinued, or incompatible parts. Deterministic checks are shown first; LLM part suggestions carry a persistent disclaimer.
- **Cache staleness is config-driven, not time-driven.** Pilots swap parts constantly. Advice is stale when the build configuration changes (`configHash`), not just after 24 hours.
- **Data entry friction is the #1 adoption risk.** `motorThrustGrams` is hard to know without a thrust stand. Added `motorModel` (free text) + `motorThrustDataSource` to reduce friction and set expectations.

---

### Implementation phases

#### Phase 1 — Offline 推重比 + Compatibility Checker

**Goal:** Deliver immediate offline value. No API key, no network, no LLM.

- Extend `Aircraft` with `flightStyle`, `pilotSkillLevel`, `frameSizeInch`, `motorModel`, `motorKv`, `motorThrustGrams`, `motorThrustDataSource`, `propSize`, `allUpWeightGrams`.
- Add `FlightStyle`, `PilotSkillLevel`, `ThrustDataSource`, `TWRTier` enums.
- Implement `ThrustToWeightCalculator` — pure function with flight-style-relative tiers per §11.3 thresholds.
- Implement `CompatibilityChecker` — rule-based: ESC current, KV/voltage, C-rating, FC protocol.
- Aircraft detail view: TWR gauge with tier badge and confidence indicator; compatibility warnings list (error/warning/info).
- Unit tests: `ThrustToWeightCalculator` (all flight styles, all tier boundaries); `CompatibilityChecker` (each rule, pass + fail).

**Done when:** A user can fill in motor KV, thrust, AUW, and flight style on any aircraft and immediately see their 推重比 tier and any compatibility warnings — offline, no API key required.

---

#### Phase 2 — LLM Config Advice

**Goal:** Add LLM-powered natural-language advice on top of the offline foundation.

- Implement `FleetContextDTO` with field allowlist (see §11.4); includes computed TWR and compatibility warnings as grounding context.
- Implement `PromptBuilder` (versioned, snapshot-tested); include flight style, pilot skill level, and domain rule reference in system prompt.
- Implement `LLMClientProtocol` + `OpenAIClient` (streaming SSE + JSON mode).
- Implement `APIKeyStore` (Keychain-backed).
- Implement `AdviceSession` with `configHash` for config-driven staleness; `AdviceSessionRepository`.
- Implement `AdviceViewModel`: TWR + compat check → config hash → cache check → LLM call → persist.
- Consent opt-in sheet (one-time); `AdviceSettingsView` (provider, key, disclosure).
- `AdviceResultView`: streaming render, per-section `AdviceResponse` display; stale-session badge.
- Unit tests: `AdviceViewModel` with `MockLLMClient`; config-hash cache hit/miss; all error states.
- UI test: full advice flow; opt-in sheet.

**Done when:** A user can tap "AI 建议", see the consent sheet once, and receive streaming config advice that references their TWR result and any compatibility warnings, with per-section rendering.

---

#### Phase 3 — Part Suggestions & Advice History

**Goal:** Add inventory-aware part recommendations and a per-aircraft advice history.

- Extend `PromptBuilder` with inventory context (part counts by category, low-stock signals).
- Extend `AdviceResponse` with `[PartSuggestion]` (name, reason, priority).
- Part suggestions UI: persistent disclaimer "AI-generated — verify before purchasing"; priority badge.
- `AdviceHistoryView`: past sessions per aircraft; `configHash` staleness indicator ("Config changed – regenerate?"); per-session audit (show `FleetContextDTO` that was sent).
- Settings: delete individual sessions or all; session cap management (default 20 per aircraft).
- UI tests: part suggestion rendering; staleness badge; history navigation.

**Done when:** A user can see their advice history, identify stale sessions when they've modified their build, and receive part suggestions with a clear disclaimer and priority ranking.

---

### Out of scope (this feature)

- Fixed-wing / wing advice (different physics: wing loading, stall speed — TWR doesn't apply).
- Real-time telemetry or black-box analysis.
- Automated retailer sync or in-app purchasing.
- Multi-turn conversation (chat) UX.
- Mandatory analytics or telemetry.

---

### Dependencies & constraints

| Constraint | Note |
|---|---|
| **Data quality** | TWR accuracy depends on motor thrust input quality. Confidence indicator informs users of uncertainty. |
| **Hallucination risk** | Part suggestions are LLM-generated and may be wrong. Deterministic checks always shown first; LLM suggestions always carry disclaimer. |
| **Network** | LLM requires network. TWR, compat checks, and advice history work offline. |
| **Privacy** | Opt-in required; `FleetContextDTO` field allowlist; Keychain; no server proxy. |
| **Cost** | User's own API key and billing. |
| **Prompt stability** | `PromptBuilder` snapshot-tested; prompt changes produce explicit diffs in code review. |

---

## Later (ideas, not committed)

- **On-device LLM** — Apple Intelligence / Core ML for simple advice with full privacy and no API key.
- **Motor model database** — curated static lookup: motor model name → KV, max current, thrust at common voltages. Eliminates manual thrust entry for common motors.
- **Frame-size-aware KV guidance** — extend KV/voltage rule to be frame-size-sensitive (3" vs 5" vs 7" have different optimal KV ranges).
- **PID starting point suggestions** — "For your 2306 2450KV on 5" freestyle, try these Betaflight PID values as a starting point."
- **Multi-aircraft comparison** — head-to-head advice ("which build is better for freestyle?").
- **Fixed-wing advice** — separate spec; wing loading and stall speed replace TWR.
- **Anthropic / Gemini provider** — additional `LLMClientProtocol` implementations.
