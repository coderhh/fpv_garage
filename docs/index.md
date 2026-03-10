---
layout: default
title: FPV Garage
---

# FPV Garage – iOS App

Record FPV drone flights, aircraft, batteries, and parts inventory on your iPhone. Data is stored **only on your device** (no server or account).

## Features

- **Flights**
  - Log aircraft, time, duration, place, and notes.
  - Pick locations from Apple Maps or your current GPS position.
- **Aircraft**
  - Manage all your drones with detailed setup (frame, motors, ESC, flight controller, camera, VTX, receiver, props, other).
  - Attach a photo from the camera or photo library.
- **Batteries**
  - Track packs with capacity, cell count, cycle count, and status (active, retired, damaged).
- **Parts**
  - Global inventory of frames, motors, ESCs, FCs, etc.
  - Aircraft setups are mirrored into the Parts tab; deleting an aircraft lets you decide whether to delete or keep its parts as loose inventory.

## Screens

- **Home**
  - Overview of flight count, total duration, and counts of aircraft, batteries, and parts.
  - Development/test utilities: seed demo data or clear all data (debug builds).
- **Flights**
  - List, add, edit, and delete flight records.
  - Associate flights with aircraft and batteries; optionally attach a map location.
- **Aircraft**
  - List and edit all aircraft with detailed component breakdown and photos.
- **Batteries**
  - Manage your LiPo inventory, including status and cycles.
- **Parts**
  - View and filter inventory of all parts, including those detached from retired aircraft.

## Data & Privacy

- All data is stored **locally on your device** in the app’s documents directory.
- There is **no backend service** and no account system.
- The app can export all data as a single JSON file for backup or migration.

## Export & Backup

- From the **Home** screen, use “Export All Data (JSON)” to:
  - Generate a `fpv-garage-backup.json` file containing aircraft, batteries, flights, and parts.
  - Save the file to Files, iCloud Drive, or share it with other apps.

## Requirements

- **Xcode 15+** to build from source.
- **iOS 17+** to run on device or simulator.

For full technical details and contribution guidelines, see the repository’s `README.md` and `SPEC.md`.

