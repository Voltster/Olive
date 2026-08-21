# 🫒 Olive

<div align="center">
  <p><strong>The gentle, privacy-first, open-source Mac optimizer and system monitor.</strong></p>
  <p>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPL_v3-blue.svg?style=flat-square" alt="License: GPL v3"></a>
    <a href="https://apple.com/macos"><img src="https://img.shields.io/badge/Platform-macOS_14%2B-black.svg?style=flat-square&logo=apple" alt="macOS 14+"></a>
    <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat-square&logo=swift" alt="Swift 6"></a>
    <img src="https://img.shields.io/badge/Telemetry-Zero-green.svg?style=flat-square" alt="Zero Telemetry">
  </p>
</div>

---

## ✨ Features

- 🧹 **Deep System Cleaner**: Safely reclaim gigabytes from user caches, developer artifacts (`node_modules`, `DerivedData`, `target`), stale logs, and orphaned application leftovers.
- 📦 **Smart App Uninstaller**: Completely remove apps alongside their hidden library folders, preferences, saved states, and launch agents.
- 🗺️ **Visual Disk Space Analyzer**: Interactive radial sunburst and treemap charts to visualize disk hogs and preview large files with macOS QuickLook (`Spacebar`).
- 📊 **Real-Time Hardware Monitor & Menu Bar HUD**: Live CPU per-core utilization, memory pressure, fan speeds, disk I/O, and battery stats right in your top menu bar.
- ⚡ **macOS System Maintenance**: One-click DNS flushes, QuickLook cache repairs, Spotlight re-indexing, and startup item management.
- 🛡️ **Safety-First Guarantee**: Uses macOS Trash API (`trashItem`) for full undoability. Zero permanent accidental deletions.

---

## 🛠️ Tech Stack & Architecture

- **Language**: Swift 6
- **UI Framework**: SwiftUI + AppKit (macOS 14 Sonoma & macOS 15 Sequoia)
- **Telemetry**: Native `Mach` kernel host statistics, `IOKit`, and Apple Silicon `SMC` sensor bridges.
- **Safety**: Native Apple `FileManager.trashItem` & `NSWorkspace.recycle`.

---

## 🚀 Getting Started

### Prerequisites
- macOS 14.0 or later (Apple Silicon or Intel)
- Xcode 15.0+ or Swift 6.0+

### Building from Source
```bash
# Clone the repository
git clone https://github.com/your-username/Olive.git
cd Olive

# Open in Xcode or build via Swift Package Manager
swift build -c release
```

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
