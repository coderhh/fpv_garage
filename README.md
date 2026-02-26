# FPV Garage — iOS App

Record FPV drone flights, aircraft, batteries, and parts inventory on your iPhone. Data is stored **only on your device** (no server or account).

### Main features

- **Flights**: log aircraft, time, duration, place, remark; pick location from **Apple Map** or your current GPS position.
- **Aircraft**: manage all your drones with detailed setup (frame, motor, ESC, FC, camera, VTX, receiver, prop, other) and a photo (camera or album).
- **Batteries**: track packs with capacity, cell count, cycles, and status.
- **Parts**: global inventory of frames, motors, ESCs, FCs, etc.  
  When you edit an aircraft’s setup, its parts are **mirrored into the Parts tab**; deleting a drone lets you choose whether to remove parts or keep them as loose inventory.

## Requirements

- **Xcode 15+** (from Mac App Store)
- **iOS 17+** on your iPhone (for running the app)
- **Apple ID** (free) to run the app on your device

## Open and Run

**Why is the Run button disabled?** You must open the **project file**, not the source folder. In Finder double‑click **`FPVGarage.xcodeproj`**, or in Xcode use **File → Open** and select **`FPVGarage.xcodeproj`**. Do not open the `FPVGarage` folder (the one with the .swift files) — that gives no runnable target.

If you already have the project open: choose a **run destination** at the top (e.g. **iPhone 16** simulator or your connected iPhone), then press **Run** (▶).

---

## Alternative: Create a new project and add source files

If opening `FPVGarage.xcodeproj` does not work (e.g. Xcode version mismatch), you can create a new app and add the source:

### 1. Create a new iOS App in Xcode

1. Open **Xcode**.
2. **File → New → Project**.
3. Choose **iOS → App** → Next.
4. Set:
   - **Product Name:** `FPVGarage`
   - **Team:** your Apple ID (or “Add Account…” and sign in)
   - **Organization Identifier:** e.g. `com.yourname`
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** None  
   → Next, choose **this repository’s folder** as the save location (the folder that already contains the `FPVGarage` source folder). If Xcode warns that “FPVGarage” folder exists, choose **Create** or **Replace** so the project is created.

### 2. Use the app source code in the project

1. In the Project Navigator (left sidebar), **delete** the default `ContentView.swift` and `FPVGarageApp.swift` that Xcode added (Move to Trash). Do **not** delete the `FPVGarage` group (yellow folder).
2. Right‑click the **FPVGarage** group → **Add Files to "FPVGarage"…**.
3. Go to the **FPVGarage** folder in this repo (the one with `FPVGarageApp.swift`, `ContentView.swift`, `Models`, `Views`, `Storage`).
4. Select **FPVGarageApp.swift**, **ContentView.swift**, and the **Models**, **Views**, and **Storage** folders (or select the whole folder and add).
5. Leave **“Copy items if needed”** **unchecked**, **“Create groups”** selected, and tick the **FPVGarage** target.
6. Click **Add**.

### 3. Set deployment target

1. Click the blue **FPVGarage** project in the navigator.
2. Select the **FPVGarage** target.
3. Under **General → Minimum Deployments**, set **iOS 17.0** (or the minimum iOS version you want).

### 4. Run on your iPhone

1. Connect your iPhone with a USB cable and unlock it; tap “Trust” if asked.
2. At the top of Xcode, select your **iPhone** as the run destination (instead of a simulator).
3. Press **Run** (▶) or **Product → Run**.
4. On the iPhone: **Settings → General → VPN & Device Management** → trust your Apple ID / developer certificate if prompted.
5. Open **FPVGarage** on the home screen and use it.

Data (flights, aircraft, batteries, parts) is saved locally in the app’s documents and stays on your device.

## How to test the app

### Option A: iOS Simulator (no iPhone needed)

1. In Xcode, at the top toolbar click the **run destination** (next to the Run ▶ button).
2. Choose **iPhone 16** or any **iPhone 15 / 16** simulator. If none appear, go to **Xcode → Settings → Platforms** and download an iOS simulator.
3. Press **Run** (▶) or **⌘R**. The app launches in the simulator.
4. Use the simulator: add aircraft and batteries first, then add a flight; check that the **首页** summary updates.

### Option B: Your iPhone

1. Connect the iPhone with a USB cable and unlock it.
2. Select your **iPhone** as the run destination in the toolbar.
3. Press **Run** (▶). If Xcode says “Untrusted Developer”, on the iPhone go to **Settings → General → VPN & Device Management** → your Apple ID → **Trust**.
4. Open **FPV Garage** on the home screen and use it.

### Quick test checklist (manual)

| Step | What to do |
|------|------------|
| 1 | **飞机** tab → tap **+** → add an aircraft (name + some setup fields like frame/motor) → Save. |
| 2 | **电池** tab → tap **+** → add a battery (e.g. name “Bat1”, 1500 mAh, 4S) → Save. |
| 3 | **飞行** tab → tap **+** → pick the aircraft, set time and duration (e.g. 120 sec), optionally set map location → Save. |
| 4 | **首页** tab → confirm flight count = 1, total duration and aircraft/battery counts are correct. |
| 5 | **部件** tab → verify parts were created from the aircraft setup (frame, motor, etc.). |
| 6 | **飞行** tab → tap a row to edit, or swipe left to delete; confirm list updates. |

### Quick test checklist (seed demo data)

On **首页** there is a **“开发与测试 → 生成测试数据”** button. Tapping it will:

- Add a few sample aircraft (with detailed setups).
- Add several batteries and flights.
- Auto-generate linked parts from each aircraft’s setup so you can immediately see how the **部件** tab works.

If all of the above work, the app is functioning correctly.

## App structure

- **首页 Home:** Summary (flight count, total duration, aircraft/battery/part counts) and a button to generate test data.
- **飞行 Flights:** List, add, edit, delete flight records (time, duration, aircraft, optional map location + address, remark).
- **飞机 Aircraft:** List, add, edit, delete aircraft (name, model, remark, photo, detailed setup).
- **电池 Batteries:** List, add, edit, delete batteries (name, code, capacity, cells, cycles, status, remark).
- **部件 Parts:** Global inventory of all components:
  - Parts auto-generated from each aircraft’s setup and linked via `sourceAircraftId`.
  - Manual parts you add yourself (not tied to a specific aircraft).
  - Deleting a drone lets you choose:
    - **Sell whole drone** → remove linked parts.
    - **Tear down** → detach parts but keep them in inventory.

The app requests **Camera** permission (to take aircraft photos) and **Location When In Use** permission (to set flight locations on the map).

## License

MIT
