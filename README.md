# Olive

<div align="center">
  <p><strong>The gentle, privacy-first, open-source Mac optimizer and system monitor.</strong></p>
  <p>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPL_v3-blue.svg?style=flat-square" alt="License: GPL v3"></a>
    <a href="https://apple.com/macos"><img src="https://img.shields.io/badge/Platform-macOS_14%2B-black.svg?style=flat-square&logo=apple" alt="macOS 14+"></a>
    <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat-square&logo=swift" alt="Swift 6"></a>
    <img src="https://img.shields.io/badge/Telemetry-Zero-green.svg?style=flat-square" alt="Zero Telemetry">
    <a href="https://github.com/Voltster/Olive/releases/latest"><img src="https://img.shields.io/github/v/release/Voltster/Olive?style=flat-square&color=84CC16" alt="Latest Release"></a>
  </p>
</div>

---

## ✨ Features

- 🧹 **Deep System Cleaner**: Safely reclaim gigabytes from user caches, developer artifacts (`node_modules`, `DerivedData`, `target`), stale logs, and orphaned application leftovers.
- 🛠️ **Developer Clean Hub**: Scans and cleans `.next` (Next.js), `node_modules`, `venv` (Python), `target` (Rust), and global tool package caches with smart inactive project detection (>7 days).
- 📦 **Smart App Uninstaller**: Completely remove apps alongside their hidden library support files, preferences, saved states, and launch agents.
- 🗺️ **Visual Disk Space Analyzer**: Interactive DaisyDisk-style Canvas Radial Sunburst visualizer with hover bloom, breadcrumbs, and a dedicated Large Files finder (>100MB).
- 📊 **8-Card Telemetry Dashboard & Live Process Manager**: Real-time per-core CPU histogram, RAM pressure, APFS disk capacity matching Finder, network waveforms, and an embedded Activity Monitor table.
- ⚡ **macOS System Maintenance & Startup Manager**: One-click DNS flushes, QuickLook repairs, Spotlight re-indexing, and LaunchAgent daemon toggle switches.
- 🌗 **Light & Dark Mode Support**: Dynamic theme tokens with instant sun/moon toggle.
- 🛡️ **Safety-First Guarantee**: Uses the official macOS Trash API (`FileManager.trashItem`) for full undoability (`⌘Z`). Zero permanent `rm -rf` deletions.

---

## 📥 Installation

### Option 1: Download DMG Installer (Recommended)
Download the latest `Olive-1.0.0.dmg` from the **[GitHub Releases](https://github.com/Voltster/Olive/releases/latest)** page and drag `Olive.app` into your `/Applications` folder.

### Option 2: Homebrew Cask
```bash
brew install --cask https://raw.githubusercontent.com/Voltster/Olive/main/Casks/olive.rb
```

### Option 3: Build from Source
```bash
# Clone the repository
git clone https://github.com/Voltster/Olive.git
cd Olive

# Build release bundle
./scripts/build_app.sh

# Install into /Applications
cp -R build/Olive.app /Applications/
```

---

## 🛠️ Tech Stack & Architecture

- **Language**: Swift 6
- **UI Framework**: SwiftUI + AppKit (macOS 14 Sonoma & macOS 15 Sequoia)
- **Telemetry**: Native `Mach` kernel host statistics, `IOKit`, and `APFS` volume resource keys.
- **Safety**: Native Apple `FileManager.trashItem`.

---

## 📜 Documentation

- [Product Requirements Document (PRD)](PRD.md)
- [Design System & UI Specification](DESIGN.md)
- [Development Roadmap](ROADMAP.md)
- [Security Architecture & Safety Policy](SECURITY.md)
- [Privacy Policy](PRIVACY.md)

---

## 📄 License & Attribution

Olive is released under the **GNU General Public License v3.0 (GPL-3.0)**. See the [LICENSE](LICENSE) file for details.

*Attribution*: Inspired by the open-source CLI project [Mole](https://github.com/tw93/mole) by Tw93.
