# Design System & UI Specification

## Project: Olive
**Design Philosophy**: *Organic elegance, glassmorphism, fluidity, and strictly adhering to Apple Human Interface Guidelines (HIG).*

---

## 1. Visual Design Tokens

### 1.1 Color Palette

```
Dark Mode Primary: #0C1014 (Deep Forest Obsidian)
Sidebar Background: #141A20 with NSVisualEffectView Material (.sidebar)
Card Background:    rgba(255, 255, 255, 0.05) with 1px border rgba(255, 255, 255, 0.1)
```

| Token Name | Hex Code | Purpose | Usage Example |
| :--- | :--- | :--- | :--- |
| **`AccentOlive`** | `#84CC16` (Vibrant Olive) | Primary actions, scan buttons | "Scan System", Selected Tab |
| **`AccentSage`** | `#10B981` (Fresh Emerald) | Storage recovered, healthy status | Disk Free Space, Healthy Score |
| **`AccentAmber`** | `#F59E0B` (Amber Warning) | Moderate load, dry-run warning | Memory Pressure Moderate, Large Files |
| **`AccentRose`** | `#F43F5E` (Vibrant Rose) | High load, destructive delete | "Move to Trash", CPU > 85% |
| **`AccentViolet`** | `#8B5CF6` (Nebula Purple) | Developer artifacts | Node Modules, Xcode Caches |
| **`SurfaceCard`** | `rgba(255,255,255,0.06)` | Elevated cards, metric panels | Metric Tiles, Review Items |
| **`BorderSubtle`** | `rgba(255,255,255,0.12)` | Card outlines, dividers | Visual separation |

### 1.2 Typography
- **Primary Font**: System Default (`.system(.body, design: .rounded)` / `.monospacedDigit()`)
- **Metric Numbers**: `.system(size: 28, weight: .bold, design: .rounded)` with tabular digits to prevent layout jittering during real-time updates.
- **Section Headers**: `.system(size: 18, weight: .semibold, design: .default)`.

---

## 2. Layout Structure

### 2.1 Main Window (`NavigationSplitView`)

```
+-------------------------------------------------------------------------------+
|  🔴 🟡 🟢   Olive 🫒                                          [  Scan All  ] |
+------------------+------------------------------------------------------------+
|  📊 Dashboard    |  System Health: 94/100 (Optimal)                           |
|  🧹 Smart Clean  |  +-------------------+  +-------------------+  +----------+ |
|  📦 Uninstaller  |  |  CPU: 18.4%       |  |  RAM: 12.4 GB     |  | Disk: 64%| |
|  🗺️ Disk Map     |  |  [====        ]   |  |  [=======     ]   |  | [======] | |
|  ⚡ Maintenance  |  +-------------------+  +-------------------+  +----------+ |
|  ⚙️ Settings     |                                                            |
|                  |  Quick Actions:                                            |
|                  |  [ Clean 42.1 GB ]   [ Flush DNS ]   [ Review Big Files ]  |
+------------------+------------------------------------------------------------+
```

1. **Sidebar Navigation**:
   - `Dashboard` (Live Telemetry & Overview)
   - `Smart Clean` (Caches, Logs, Dev Artifacts, Trash)
   - `App Uninstaller` (Batch Application & Leftover Manager)
   - `Disk Visualizer` (Sunburst & Large Files Map)
   - `Maintenance` (System Optimization & Startup Items)
   - `Settings` (Exclusions, Whitelist, Preferences)

2. **Detail View Canvas**:
   - Translucent frosted glass effect using `NSVisualEffectView(material: .underWindowBackground)`.
   - Smooth animated card transitions with `.animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedTab)`.

---

## 3. Key Component Specifications

### 3.1 Radial Metric Gauge (`MetricGaugeView`)
- **Visual**: 270-degree circular arc progress ring with glowing gradient stroke.
- **Micro-interaction**: Pulsing center glow when metric crosses warning threshold (>80%).
- **Parameters**: `value: Double`, `minValue: Double`, `maxValue: Double`, `unit: String`, `accentColor: Color`.

### 3.2 Sunburst Disk Visualizer (`SunburstChartView`)
- **Visual**: Multi-tiered concentric ring diagram. Center represents root disk (`/`); concentric outer arcs represent directories.
- **Interaction**:
  - Hovering an arc highlights path and displays human-readable size (`42.8 GB`).
  - Clicking an arc drills down into that directory with smooth zoom transition.
  - Right-click reveals context menu: *"Open in Finder"*, *"QuickLook (Space)"*, *"Move to Trash"*.

### 3.3 Dry-Run Review Tree (`CleanupReviewSheet`)
- **Visual**: Collapsible hierarchical tree view with checkboxes.
- **Features**:
  - Grouped by categories: *User Caches*, *Developer Artifacts*, *App Leftovers*, *Logs*, *Trash*.
  - Individual items display full path, file count, and byte size.
  - "Select All Safe" / "Deselect All" quick buttons.

### 3.4 Menu Bar HUD Popover (`MenuBarHUDView`)
- Compact 320x420px popover anchored to the macOS menu bar icon.
- Displays live sparkline mini-charts for CPU, RAM, Disk I/O, and Network.
- Includes one-click "Quick Clean" button and temperature display.

---

## 4. Animations & Micro-Interactions
- **Scan Button**: Subtle rotating neon gradient border during active disk scanning.
- **Trash Action**: Subtle particle burst animation and macOS trash sound playback upon successful cleanup.
- **Hover States**: 1.02x scale spring effect and background luminance increase on clickable cards.
