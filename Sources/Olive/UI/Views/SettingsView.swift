import SwiftUI

public struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("autoRefreshInterval") private var autoRefreshInterval = 2.0
    @AppStorage("safeTrashEnabled") private var safeTrashEnabled = true
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text("Customize safety boundaries and telemetry refresh rates.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Safety Section
                VStack(alignment: .leading, spacing: 14) {
                    Text("Safety & Protection")
                        .font(.headline)
                    
                    Toggle("Always move deleted files to macOS Trash (Undoable)", isOn: $safeTrashEnabled)
                        .disabled(true) // Enforced for safety!
                    
                    Text("Olive enforces safe deletion through the Apple Trash API to prevent accidental data loss.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .glassCard()
                
                // Telemetry Section
                VStack(alignment: .leading, spacing: 14) {
                    Text("Menu Bar & Telemetry")
                        .font(.headline)
                    
                    Picker("Sensor Refresh Rate", selection: $autoRefreshInterval) {
                        Text("1 second (High responsiveness)").tag(1.0)
                        Text("2 seconds (Recommended)").tag(2.0)
                        Text("5 seconds (Battery saver)").tag(5.0)
                    }
                }
                .glassCard()
                
                // About Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("About Olive 🫒")
                        .font(.headline)
                    
                    Text("Version 1.0.0 (GPL-3.0 Open Source)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("A gentle, privacy-first, community-driven Mac optimizer and live system telemetry monitor.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .glassCard()
            }
            .padding(24)
        }
    }
}
