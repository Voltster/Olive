# Privacy Policy

## Project: NovaClean
**Privacy Guarantee**: *100% Local, Zero Telemetry, Zero Tracking, Zero Network Overhead.*

---

## 1. Core Principles

1. **No Data Collection**: NovaClean does **not** collect, store, track, or transmit any user information, file paths, hardware metrics, or usage behavior.
2. **Zero Analytics SDKs**: There are no Google Analytics, Firebase, Mixpanel, Sentry, or third-party telemetry SDKs bundled in NovaClean.
3. **No Network Requests (Except Manual Updates)**:
   - NovaClean makes **zero** background outbound network calls during normal operation.
   - The only network activity occurs when the user manually checks for software updates (via the Sparkle open-source framework querying the official GitHub Releases API).

---

## 2. File & Sensor Access

- **Disk Access**: NovaClean accesses files exclusively to measure sizes, identify caches, and execute user-approved deletions. File contents are never read, analyzed, or uploaded.
- **Hardware Sensors**: CPU, memory, battery, and fan speeds are queried locally via Apple's public Mach Kernel and `IOKit` APIs.

---

## 3. Transparency & Auditability
NovaClean is distributed as 100% open-source software under the **GNU General Public License v3.0**. Anyone can inspect the complete source code, build it from scratch, and verify that these privacy promises are upheld.
