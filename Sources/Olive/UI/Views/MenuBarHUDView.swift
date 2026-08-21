import SwiftUI
import AppKit

public struct MenuBarHUDView: View {
    @Bindable var monitorService = SystemMonitorService.shared
    @Bindable var cleanerService = CleanerService.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 12) {
            // Header with Health
            HStack {
                Label("Olive", systemImage: "circle.circle.fill")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.accentOlive)
                
                Spacer()
                
                Text("Health: \(monitorService.currentTelemetry.healthScore)%")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.accentSage)
            }
            
            Divider()
            
            // Metrics Mini Grid
            VStack(spacing: 8) {
                metricRow(title: "CPU", val: String(format: "%.1f%%", monitorService.currentTelemetry.cpuUsage), icon: "cpu", color: Theme.accentOlive)
                metricRow(title: "RAM", val: String(format: "%.1f%%", monitorService.currentTelemetry.memoryUsagePercent), icon: "memorychip", color: Theme.accentAmber)
                metricRow(title: "Disk Free", val: ByteFormatter.format(monitorService.currentTelemetry.diskFreeBytes), icon: "internaldrive", color: Theme.accentCyan)
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
            
            // Quick Actions
            HStack(spacing: 8) {
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                } label: {
                    Text("Open Olive")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button {
                    NSApp.terminate(nil)
                } label: {
                    Image(systemName: "power")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(14)
        .frame(width: 260)
        .onAppear {
            monitorService.startMonitoring()
        }
    }
    
    private func metricRow(title: String, val: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 18)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(val)
                .font(.caption.bold().monospacedDigit())
        }
    }
}
