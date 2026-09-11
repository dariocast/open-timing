<p align="center">
  <img src="https://raw.githubusercontent.com/feathericons/feather/master/icons/clock.svg" width="80" height="80" alt="OpenTiming Logo" />
</p>

<h1 align="center">OpenTiming</h1>

<p align="center">
  <strong>A modern, battery-efficient, 100% offline-first automatic time & activity tracker for macOS.</strong><br>
  <em>Directly inspired by <a href="https://timingapp.com/">Timing App</a>, built with Swift & SwiftUI. Free and Open Source (FOSS).</em>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/macOS-14.0%2B-black?logo=apple" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/Privacy-100%25%20Offline-brightgreen" alt="100% Offline">
  <a href="https://github.com/dariocastellano/open-timing/actions"><img src="https://img.shields.io/badge/CI-Passing-brightgreen" alt="CI Status"></a>
  <a href="CONTRIBUTING.md"><img src="https://img.shields.io/badge/PRs-welcome-blueviolet.svg" alt="PRs Welcome"></a>
</p>

---

## 💡 Why OpenTiming?

Proprietary automatic time trackers (like Timing App or RescueTime) are great tools, but they often require recurring subscriptions or upload private browsing/window logs to remote cloud servers.

**OpenTiming** is designed to give you the exact same automatic tracking power, but **100% locally on your machine**:
- 🔒 **Zero Telemetry / Zero Cloud**: Everything stays in your local SQLite database (`~/Library/Application Support/OpenTiming/opetiming.sqlite`). No internet connection is ever needed or used.
- ⚡ **Lightweight & Battery-Friendly**: Built natively in Swift with minimal background overhead.
- 🆓 **100% Free & Open Source**: MIT Licensed. No paywalls, no trial limits, no subscriptions.

---

## ✨ Features

- ⏱️ **Automatic Background Tracking**:
  - Detects active frontmost applications in real-time (`NSWorkspace`).
  - Inspects active window titles and open documents via **macOS Accessibility API (`AXUIElement`)**.
  - Extracts active browser tab URLs & domains (**Safari, Google Chrome, Arc, Brave, Microsoft Edge**).
  - Smart **Idle Detection** (`CGEventSource`): automatically detects when you step away from the keyboard/mouse and marks time as idle.
  - Smart **Session Coalescing**: prevents database bloat by continuously extending ongoing activity segments.

- 📊 **Interactive Dashboard**:
  - **Overview**: Real-time productivity score (%), total tracked hours, productive vs. distracting breakdown, Swift Charts 24h hourly distribution, top applications & categories.
  - **24-Hour Timeline Ribbon**: Visual continuous block chart of your day. Scrub, search, and retroactively reassign categories/projects on any recorded activity.
  - **Projects & Categories**: Create and organize custom categories (colors, icons, productivity ratings from -2 to +2) and projects (hourly rates, client tracking).
  - **Rule Engine**: Create powerful matching rules (*Contains, Exact, StartsWith, EndsWith, Regex*) on App Name, Bundle ID, Window Title, or Web Domain.
  - **Retroactive Rule Application**: Re-categorize your entire historical database with a single click after creating new rules.

- 📥 **Data Portability & Export**:
  - Export your entire tracking history or custom ranges to **CSV** (for Excel, Apple Numbers, Google Sheets) or **JSON**.
  - Full control to clear or backup your local database.

- 🖥️ **Menu Bar Companion**:
  - Live timer in the top macOS Menu Bar.
  - Quick glance at the current running app, today's productivity score, pause/resume tracking, and instant dashboard access.

---

## 📊 Comparison

| Feature | OpenTiming (FOSS) | Timing App | RescueTime |
| :--- | :---: | :---: | :---: |
| **Pricing** | **Free & Open Source** | ~$10 - $16 / mo | ~$12 / mo |
| **Storage Architecture** | **100% Local SQLite** | Cloud / Local Sync | Cloud Only |
| **Privacy & Telemetry** | **Zero Telemetry / No Network** | Cloud Sync | Cloud Hosted |
| **Window Title & URL Tracking** | ✅ Yes (Native AX API) | ✅ Yes | ✅ Yes |
| **Idle Inactivity Detection** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Categorization Rules & Regex** | ✅ Yes | ✅ Yes | Limited |
| **Data Export (CSV / JSON)** | ✅ Yes (Local) | ✅ Yes | ✅ Yes |
| **Menu Bar Companion** | ✅ Yes | ✅ Yes | ✅ Yes |

---

## 🛠️ Architecture

```
open-timing/
├── Package.swift                     # Swift Package Manager manifest (macOS 14+)
├── Info.plist                        # App bundle metadata and permissions description
├── scripts/
│   └── build_app.sh                  # Release compilation and OpenTiming.app bundler
├── Sources/OpenTiming/
│   ├── OpenTimingApp.swift           # Application entry point (SwiftUI Window + MenuBarExtra)
│   ├── Models/
│   │   ├── ActivityRecord.swift      # Activity snapshots, metrics & aggregation models
│   │   ├── Category.swift            # Category & Project data structures
│   │   └── Rule.swift                # Categorization rule definitions & matchers
│   ├── Database/
│   │   └── DatabaseManager.swift     # SQLite engine (WAL mode, indexing, aggregate queries)
│   ├── Tracker/
│   │   ├── ActivityTracker.swift     # Background tracking coordinator & session coalesce
│   │   ├── WindowInspector.swift     # AXUIElement window inspection & browser URL extractors
│   │   └── IdleDetector.swift        # CGEventSource user inactivity detection
│   ├── Rules/
│   │   └── RuleEngine.swift          # Priority matching engine
│   └── Views/
│       ├── AppState.swift            # MainActor Observable ViewModel
│       ├── MainDashboardView.swift   # Sidebar navigation container
│       ├── DashboardOverviewView.swift# Swift Charts graphs & productivity score cards
│       ├── TimelineView.swift        # 24h visual timeline ribbon & activity table
│       ├── CategoriesProjectsView.swift # Category & project management modals
│       ├── RulesView.swift           # Rule editor & retroactive tagging
│       ├── SettingsView.swift        # Permissions guide, idle sliders & CSV/JSON export
│       ├── MenuBarView.swift         # Menu bar popup widget
│       └── Helpers.swift             # App icons, colors, time formatters
└── Tests/OpenTimingTests/
    └── OpenTimingTests.swift         # Unit tests (Database, Rules, Stats, CSV Export)
```

---

## 🚀 Getting Started

### Requirements
- macOS 14.0 (Sonoma) or macOS 15.0+ (Sequoia)
- Apple Silicon (M1/M2/M3/M4) or Intel Mac

### Option 1: Run via Command Line (Debug)
```bash
git clone https://github.com/dariocastellano/open-timing.git
cd open-timing
swift run OpenTiming
```

### Option 2: Build Native macOS App Bundle (`OpenTiming.app`)
```bash
./scripts/build_app.sh
open ./build/OpenTiming.app
```

### Option 3: Open in Xcode
```bash
open Package.swift
```

---

## 🔑 Permissions Setup

To read window titles and browser tabs:
1. When you first launch OpenTiming, it will prompt you if Accessibility permissions are needed.
2. Open **System Settings > Privacy & Security > Accessibility** and ensure **OpenTiming** (or your Terminal if running via `swift run`) is enabled.

---

## 🧪 Running Unit Tests

```bash
swift test
```

All core components (database CRUD, index queries, regex rule engines, idle filters, and CSV exporters) are covered by automated unit tests.

---

## 🤝 Contributing

Contributions are very welcome! Whether it's adding presets for more apps, refining UI/UX, or improving performance, please check out [CONTRIBUTING.md](CONTRIBUTING.md) to get started.

---

## 📜 License

OpenTiming is open-sourced software licensed under the [MIT License](LICENSE).
