# FPV Garage — App Store Release SOP

Standard operating procedure for shipping FPV Garage to the App Store.
Split into **one-time setup** (first release only) and the **per-release loop**
(repeat for 1.0, 1.1, …). Machine-bound steps are marked **[Mac]**;
everything else can be done from any browser.

Project facts (already configured in the repo):

| Item | Value |
|---|---|
| Bundle ID | `com.yehanghan.fpvgarage.app` |
| Signing | Automatic, team `U7XS79B47L` (target-level; overrides project-level `FR7J7V2K3U`) |
| iCloud | CloudDocuments, container `iCloud.com.yehanghan.fpvgarage.app` |
| Deployment target | iOS 17.0, iPhone + iPad |
| Version | `MARKETING_VERSION 1.0`, `CURRENT_PROJECT_VERSION 1` |
| Privacy strings | Camera + Location (when-in-use), Chinese |
| Export compliance | `ITSAppUsesNonExemptEncryption = NO` (no networking in Phase 1) |
| Dependencies | None (no SPM/CocoaPods) |
| Localization | en + zh-Hans |
| App icon | Full set incl. 1024×1024 ✓ |
| Debug tooling | Seed/Clear data is `#if DEBUG` — excluded from Release ✓ |

---

## Part A — One-time setup (first release only)

### A1. Apple Developer account (browser)
- [ ] Enrolled in the Apple Developer Program ($99/yr) and membership is active.
- [ ] You are Account Holder or Admin for team `U7XS79B47L`.

### A2. Identifiers & iCloud container (browser — developer.apple.com)
> The iCloud entitlement is the most common first-archive blocker for this app.
- [ ] Certificates, Identifiers & Profiles → Identifiers → App ID
      `com.yehanghan.fpvgarage.app` exists (Xcode automatic signing usually
      creates it on first device run — verify).
- [ ] The App ID has the **iCloud** capability enabled, with container
      `iCloud.com.yehanghan.fpvgarage.app` assigned (CloudDocuments).
- [ ] If the container doesn't exist: Identifiers → iCloud Containers → **+** →
      `iCloud.com.yehanghan.fpvgarage.app`, then attach it to the App ID.

### A3. App Store Connect record (browser — appstoreconnect.apple.com)
- [ ] My Apps → **+** → New App:
  - Platform iOS, Bundle ID `com.yehanghan.fpvgarage.app`
  - Name (e.g. "FPV Garage") — must be globally unique on the store
  - Primary language, SKU (e.g. `fpvgarage-ios`)
- [ ] App Information: category **Utilities**; age rating questionnaire → **4+**.
- [ ] **App Privacy** → Data Collection: **Data Not Collected**
      (all data is local/user's iCloud; no analytics, no third-party SDKs,
      no network calls in Phase 1).
- [ ] Privacy Policy URL — required even for no-collection apps. The GitHub
      Pages site in `docs/` is a good host: add a `privacy.html`/`privacy.md`
      stating data stays on device/user's iCloud and is never transmitted to
      the developer.

---

## Part B — Per-release loop

### B1. Code freeze & verification [Mac] (~30 min)
```bash
git pull
git checkout <release branch>   # currently claude/trusting-clarke-31nufd
open FPVGarage.xcodeproj
```
- [ ] `⌘B` — 0 errors. (First build after a pull verifies the pbxproj edits.)
- [ ] `⌘U` — all unit tests pass (~40 Phase-1 cases + existing suite).
- [ ] Manual smoke test on the iPhone 15 Pro simulator — follow the 14-step
      table from the Phase 1 test checklist (add aircraft → TWR gauge →
      compatibility warnings → battery → flight → export → delete).
- [ ] **Upgrade test** (protects existing users): install the currently
      shipped build (or previous branch) in the simulator, create data,
      then run the new build over it — data must load intact. New Aircraft
      fields are optional, so old JSON must decode cleanly.
- [ ] Test on at least one **physical device** if available (camera and GPS
      don't work in the simulator).
- [ ] Merge the release branch to `main` and tag: `git tag v1.0 && git push --tags`.

### B2. Version bump [Mac] (1 min)
- [ ] `MARKETING_VERSION`: user-facing (1.0 → 1.1 for features, 1.0.1 for fixes).
- [ ] `CURRENT_PROJECT_VERSION`: must increase for **every** upload, even
      re-uploads of the same marketing version.

### B3. Archive & upload [Mac] (~20 min)
- [ ] Xcode: Product → Destination → **Any iOS Device (arm64)**.
- [ ] Product → **Archive**.
- [ ] Organizer → Distribute App → **App Store Connect** → Upload
      (defaults are fine; automatic signing).
- [ ] Wait for the "processing complete" email (~15–60 min). No export
      compliance question will appear — it's answered by the Info.plist key.

### B4. TestFlight (browser + phone, ~1 day soak)
- [ ] App Store Connect → TestFlight → the build appears after processing.
- [ ] Add yourself (internal tester — no review needed) and install via the
      TestFlight app on a real phone.
- [ ] Use the app normally for a day: add a real quad's specs, log a flight,
      background/foreground it, check iCloud sync between two devices if possible.
- [ ] Optional: invite a couple of FPV friends as internal testers (instant)
      or external testers (requires a lightweight beta review, ~1 day).

### B5. Store listing (browser, first release ~1–2 h; updates ~10 min)
- [ ] **Screenshots** [Mac]: capture in simulator (`⌘S`) —
      6.7" (iPhone 15 Pro Max) required; 13" iPad required because the app
      supports iPad. Minimum 3, ideally 5–6: Home, Aircraft detail with TWR
      gauge + compatibility warnings, Flight list/map, Battery list, Parts.
      Seed data first with the DEBUG "Generate Test Data" button.
- [ ] Description + keywords, in both English and Chinese
      (App Store Connect → localizations en-US and zh-Hans).
      Lead with the offline value: fleet/flight/battery/parts tracking +
      thrust-to-weight and compatibility checks, no account needed.
- [ ] Promotional text (can be changed without review), support URL
      (GitHub Pages site works), marketing URL (optional).
- [ ] "What's New" text for updates.

### B6. Submit for review (browser, 5 min)
- [ ] Version page → select the TestFlight build.
- [ ] Release option: **Manually release** (recommended for 1.0 — you control
      the moment) or automatic.
- [ ] App Review notes: mention that all features work offline with no
      account; reviewer can tap through freely. No demo account needed.
- [ ] Submit. Typical review time: 24–48 h.

### B7. Post-approval
- [ ] Release (if manual), then verify the store listing renders correctly.
- [ ] Install the **store** build on your own device; confirm data from the
      TestFlight build survived (same bundle ID → data persists).
- [ ] Monitor: App Store Connect → App Analytics + Crashes (Xcode Organizer →
      Crashes) for the first week.
- [ ] Phased release is available for updates (7-day gradual rollout) —
      recommended from 1.1 onward.

---

## Rejection playbook (most likely findings for this app)

| Risk | Mitigation |
|---|---|
| Guideline 2.1 — crash on launch/iPad | Smoke-test on an iPad simulator before submitting (app declares iPad support). |
| Guideline 5.1.1 — permission purpose strings | Camera/Location strings exist; ensure the *reviewer-visible* flow that triggers them makes sense (photo add, flight location). |
| Metadata rejection — screenshots don't match app | Use real simulator captures, no device frames with wrong content. |
| Privacy label mismatch | Keep "Data Not Collected" accurate — revisit when Phase 2 adds LLM API calls (user-provided key, data sent to provider ⇒ label and privacy policy must change). |

> **Phase 2 heads-up:** the moment LLM advice ships, revisit: App Privacy
> label, privacy policy, export compliance stays NO (HTTPS is exempt), and
> add the consent sheet per SPEC §11.8 before any network call.
