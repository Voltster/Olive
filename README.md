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

## ✨ Key Modules & Capabilities

| Module | Built & Implemented Features |
| :--- | :--- |
| **🧹 Deep System Cleanup** | • User Caches (`~/Library/Caches`)<br>• Developer Artifacts (`DerivedData`, NPM, Gradle)<br>• System & App Logs (`~/Library/Logs`)<br>• Browser Caches (Chrome, Safari, Arc)<br>• App Leftovers & Orphaned Application Support files<br>• System Trash inspection & safe recovery<br>• Item-by-item Inspector Sheet with Finder reveal<br>• 100% Trash-Only Deletions (`FileManager.trashItem`, zero `rm -rf`) |
| **🛠️ Developer Clean Hub** | • Hidden Next.js build cache (`.next`) recursive cleaner<br>• `node_modules` in JS/TS and MERN projects<br>• Python Virtual Environments (`venv`, `.venv`)<br>• Rust Cargo build outputs (`target/`)<br>• Xcode DerivedData & Simulator caches<br>• Swift Package Manager (`.build` & caches)<br>• Global Tool Caches (NPM, Yarn, pnpm, Bun, Cargo, Gradle, CocoaPods, Homebrew)<br>• Inactive Project Protection (&lt;7d active vs &gt;7d inactive) |
| **💽 Radial Disk Visualizer** | • DaisyDisk-style Canvas Radial Sunburst visualizer<br>• Concentric Ring Tracks (Level 1 & Level 2 hierarchies)<br>• Small-Item Aggregation (groups tiny slivers into "Other")<br>• Dynamic Center Hub with folder size & % of parent share<br>• Multi-level breadcrumb trail navigation<br>• Large & Old Files Finder (&gt;100 MB & &gt;1 GB) |
| **📊 Status Telemetry & Activity Monitor** | • 3D Solar Health Sphere & composite health score<br>• Per-Core CPU utilization histogram<br>• Metal GPU load & memory bandwidth tracker<br>• Mach Kernel Memory Pressure (calibrated to Activity Monitor)<br>• APFS Disk Capacity (calibrated to macOS Finder available capacity)<br>• Battery health %, cycle count, temperature & wattage<br>• Live Process Activity Table streaming top 50 processes with icons, CPU, and RAM<br>• 1-Click Process Kill action & Fan Control Presets (`Auto/Cool/Max`) |
| **📱 Smart App Uninstaller** | • Full `/Applications` directory scanner<br>• High-resolution native system icons (`NSWorkspace`)<br>• Deep residual search (`Application Support`, `Caches`, `Preferences`, `Saved State`)<br>• Batch uninstallation safely routed to macOS Trash |
| **⚡ Maintenance & Startup Manager** | • One-click DNS Cache Flush (`mDNSResponder`)<br>• QuickLook cache reset & thumbnail rebuild<br>• Spotlight index rebuild (`mdutil`)<br>• Mach kernel memory purge (`purge`)<br>• Startup & LaunchAgents Manager (`~/Library/LaunchAgents` & `/Library/LaunchDaemons`) |
| **🎨 Native Design & Safety** | • Zero-sidebar UI with floating top-pill navigation<br>• Full Light & Dark Mode with instant sun/moon switcher<br>• Settings dialog with `Esc` keyboard shortcut<br>• Native vector Olive logo mark (`OliveLogoView`)<br>• 100% Offline, Zero Telemetry & GNU GPL-3.0 License |

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

* **Voltster & Akritrim**: Architecture, SwiftUI components, design, and packaging.
* **Tw93 ([Mole](https://github.com/tw93/mole))**: Inspiration for CLI cleanliness and macOS deep cleaning scripts.

> 💡 **Prefer the command line?** Check out the CLI tool [Mole by Tw93](https://github.com/tw93/mole) at [mole.fit](https://mole.fit/)!
