# CLAUDE.md - Developer Guide for Olive

## Build & Test Commands
```bash
# Build the project using Swift Package Manager
swift build

# Run unit and integration tests
swift test

# Build optimized release binary
swift build -c release
```

## Architecture Summary
- **App Target**: macOS 14.0+ (Sonoma / Sequoia)
- **UI Framework**: SwiftUI + AppKit for native glassmorphism and MenuBarExtra
- **Safety Policy**: Deletions MUST use `FileManager.default.trashItem`
- **Core Modules**:
  - `CleanerModule`: Caches, dev artifacts, logs, leftovers
  - `UninstallerModule`: App bundles & associated library files
  - `DiskMapperModule`: Sunburst/treemap disk space visualizer
  - `MonitorModule`: Real-time telemetry, SMC fans, Menu Bar HUD
  - `MaintenanceModule`: DNS, QuickLook, Spotlight, Startup items

## Code Style & Standards
- **Swift 6 Concurrency**: Use `async/await` and `@MainActor` for view models.
- **Safety Boundaries**: Never target SIP-protected folders (`/System`, `/usr/bin`, etc.).
- **Zero Telemetry**: No analytics or outbound tracking calls.
