import SwiftUI

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("autoRefreshInterval") private var autoRefreshInterval = 2.0
    @AppStorage("safeTrashEnabled") private var safeTrashEnabled = true
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header with Close / Done Button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text("Customize safety boundaries and telemetry refresh rates.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Done")
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accentOlive)
                .keyboardShortcut(.cancelAction) // Closes on Escape
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            Divider()
                .background(Theme.cardBorder(for: colorScheme))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Safety Section
                    VStack(alignment: .leading, spacing: 12) {
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
                    VStack(alignment: .leading, spacing: 12) {
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
                    HStack(spacing: 16) {
                        OliveLogoView(size: 44)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Olive")
                                .font(.system(.title3, design: .rounded, weight: .bold))
                            
                            Text("Version 1.0.0 (GPL-3.0 Open Source)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text("A gentle, privacy-first, community-driven Mac optimizer and live system telemetry monitor.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .glassCard()
                }
                .padding(24)
            }
        }
        .frame(minWidth: 520, minHeight: 460)
    }
}
