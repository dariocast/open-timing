# Contributing to OpenTiming 🤝

Thank you for your interest in contributing to **OpenTiming**! As a 100% free and open-source (FOSS) project, we welcome contributions of all kinds: bug reports, documentation improvements, UI polish, rules presets, and new features.

---

## 🛠️ Development Setup

### Prerequisites
- macOS 14.0 (Sonoma) or newer.
- Xcode 15.0+ or Swift 5.9+ CLI tools.

### Getting Started

1. **Fork and Clone**
   ```bash
   git clone https://github.com/dariocast/open-timing.git
   cd open-timing
   ```

2. **Build the project**
   ```bash
   swift build
   ```

3. **Run the app locally**
   ```bash
   swift run OpenTiming
   ```

4. **Run the test suite**
   ```bash
   swift test
   ```

5. **Build the release `.app` bundle**
   ```bash
   ./scripts/build_app.sh
   open ./build/OpenTiming.app
   ```

---

## 🌿 Branching & Pull Requests

1. Create a feature branch from `main`:
   ```bash
   git checkout -b feat/my-new-feature
   ```
2. Make your changes adhering to standard Swift / SwiftUI guidelines.
3. Write or update unit tests in `Tests/OpenTimingTests/` when applicable.
4. Verify that `swift test` passes.
5. Commit with concise, descriptive commit messages (e.g. `feat: ...`, `fix: ...`, `docs: ...`).
6. Open a Pull Request on GitHub against `main`.

---

## 🔒 Offline-First Guarantee

A fundamental principle of OpenTiming is **100% offline privacy**:
- **NO** telemetry libraries, tracking pixels, or remote analytics are permitted.
- **NO** network requests for core tracking operations.
- All data must remain strictly in the local SQLite database.

Thank you for making OpenTiming better!
