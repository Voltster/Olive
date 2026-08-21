import SwiftUI

public struct DashboardView: View {
    @Bindable var monitorService = SystemMonitorService.shared
    @Bindable var cleanerService = CleanerService.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header & Health Banner
                healthBanner
                
                // Telemetry Gauges Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    MetricGaugeView(
                        title: "CPU Utilization",
                        value: monitorService.currentTelemetry.cpuUsage,
                        unit: "%",
                        subtitle: "\(monitorService.currentTelemetry.perCoreUsage.count) Cores Active · Uptime \(monitorService.currentTelemetry.uptimeString)",
                        iconName: "cpu",
                        gradient: Theme.oliveGradient
                    )
                    
                    MetricGaugeView(
                        title: "Memory Used",
                        value: monitorService.currentTelemetry.memoryUsagePercent,
                        unit: "%",
                        subtitle: "\(ByteFormatter.format(monitorService.currentTelemetry.memoryUsedBytes, isMemory: true)) of \(ByteFormatter.format(monitorService.currentTelemetry.memoryTotalBytes, isMemory: true))",
                        iconName: "memorychip",
                        gradient: monitorService.currentTelemetry.memoryUsagePercent > 80 ? Theme.amberGradient : Theme.oliveGradient
                    )
                    
                    MetricGaugeView(
                        title: "Storage Space",
                        value: monitorService.currentTelemetry.diskUsagePercent,
                        unit: "%",
                        subtitle: "\(ByteFormatter.format(monitorService.currentTelemetry.diskFreeBytes)) Free on Primary Disk",
                        iconName: "internaldrive",
                        gradient: Theme.oliveGradient
                    )
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Network Activity", systemImage: "network")
                            .font(.system(.headline, design: .rounded))
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .leading) {
                                Text("Download")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(ByteFormatter.format(UInt64(monitorService.currentTelemetry.networkBytesInPerSec)))/s")
                                    .font(.system(.title3, design: .rounded, weight: .semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(Theme.accentSage)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("Upload")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(ByteFormatter.format(UInt64(monitorService.currentTelemetry.networkBytesOutPerSec)))/s")
                                    .font(.system(.title3, design: .rounded, weight: .semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(Theme.accentCyan)
                            }
                        }
                    }
                    .glassCard()
                }
                
                // Quick Clean Action Card
                quickCleanCard
            }
            .padding(24)
        }
        .onAppear {
            monitorService.startMonitoring()
        }
    }
    
    private var healthBanner: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 70, height: 70)
                
                Circle()
                    .trim(from: 0, to: CGFloat(monitorService.currentTelemetry.healthScore) / 100.0)
                    .stroke(Theme.accentOlive, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                
                Text("\(monitorService.currentTelemetry.healthScore)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Mac System Health: \(monitorService.currentTelemetry.healthScore >= 85 ? "Optimal" : (monitorService.currentTelemetry.healthScore >= 70 ? "Good" : "Needs Attention"))")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                
                Text("Your Mac is running smoothly. All sensors and thermal levels are within optimal operating bounds.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .glassCard(cornerRadius: 18)
    }
    
    private var quickCleanCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Smart System Cleanup")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Text("Scan and reclaim gigabytes from caches, logs, dev build folders, and trash.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                Task {
                    await cleanerService.scanAll()
                }
            } label: {
                HStack(spacing: 8) {
                    if cleanerService.isScanning {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(cleanerService.isScanning ? "Analyzing..." : "Scan System")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accentOlive)
            .disabled(cleanerService.isScanning)
        }
        .glassCard(cornerRadius: 18)
    }
}
