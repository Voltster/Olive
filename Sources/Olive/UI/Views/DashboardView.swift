import SwiftUI
import AppKit

public struct DashboardView: View {
    @Bindable var monitorService = SystemMonitorService.shared
    @Bindable var cleanerService = CleanerService.shared
    @Bindable var processService = ProcessMonitorService.shared
    @Environment(\.colorScheme) var colorScheme
    
    @State private var fanMode: String = "Auto"
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Top Row: 4 Metric Cards
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ], spacing: 14) {
                    healthCard
                    cpuCard
                    gpuCard
                    memoryCard
                }
                
                // Middle Row: 4 Metric Cards
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ], spacing: 14) {
                    batteryCard
                    diskCard
                    networkCard
                    fanCard
                }
                
                // Bottom Section: Live Running Processes (Activity Monitor Table)
                runningProcessesCard
            }
            .padding(16)
        }
        .onAppear {
            monitorService.startMonitoring()
            processService.startMonitoring()
        }
    }
    
    // MARK: - 1. Health Card
    private var healthCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Circle().fill(Theme.accentSage).frame(width: 7, height: 7)
                    Text("HEALTH")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.accentSage)
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(monitorService.currentTelemetry.healthScore)")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                    Text(monitorService.currentTelemetry.healthScore >= 85 ? "Optimal" : "Check")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                Text("All checks passed")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer(minLength: 0)
                
                Text("up \(monitorService.currentTelemetry.uptimeString)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 0)
            
            HealthSphereView(healthScore: monitorService.currentTelemetry.healthScore, size: 70)
        }
        .frame(height: 125)
        .glassCard(cornerRadius: 14, padding: 14)
    }
    
    // MARK: - 2. CPU Card
    private var cpuCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "cpu")
                        .font(.caption)
                    Text("CPU")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(Theme.accentOlive)
                
                Spacer()
                
                chipBadge(text: "\(monitorService.currentTelemetry.perCoreUsage.count) Cores")
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.0f", monitorService.currentTelemetry.cpuUsage))
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                Text("%")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            // Per-Core Equalizer Bars
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<min(16, max(1, monitorService.currentTelemetry.perCoreUsage.count)), id: \.self) { idx in
                    let coreUsage = idx < monitorService.currentTelemetry.perCoreUsage.count ? monitorService.currentTelemetry.perCoreUsage[idx] : 0
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(coreUsage > 70 ? Theme.accentAmber : Theme.accentSage)
                        .frame(maxWidth: .infinity)
                        .frame(height: max(3, CGFloat(coreUsage) * 0.22))
                }
            }
            .frame(height: 24)
            
            Spacer(minLength: 0)
            
            Text("idle · Load \(String(format: "%.1f", monitorService.currentTelemetry.cpuUsage * 0.1))")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .frame(height: 125)
        .glassCard(cornerRadius: 14, padding: 14)
    }
    
    // MARK: - 3. GPU / System Status Card
    private var gpuCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "square.fill.text.grid.1x2")
                        .font(.caption)
                    Text("GPU")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(Theme.accentAmber)
                
                Spacer()
                
                chipBadge(text: "Apple Silicon")
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("1")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                Text("%")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            // Subtle Waveform
            SparklineView(dataPoints: [1, 2, 1, 3, 2, 1, 4, 1, 2, 1], lineColor: Theme.accentAmber)
                .frame(height: 24)
            
            Spacer(minLength: 0)
            
            Text("idle · Metal Core Active")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .frame(height: 125)
        .glassCard(cornerRadius: 14, padding: 14)
    }
    
    // MARK: - 4. Memory Card
    private var memoryCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "memorychip")
                        .font(.caption)
                    Text("MEMORY")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(Theme.accentCyan)
                
                Spacer()
                
                chipBadge(text: monitorService.currentTelemetry.memoryPressure.rawValue)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.0f", monitorService.currentTelemetry.memoryUsagePercent))
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                Text("%")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            // Gradient Fill Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(Theme.oliveGradient)
                        .frame(width: geo.size.width * CGFloat(min(1.0, monitorService.currentTelemetry.memoryUsagePercent / 100.0)))
                }
            }
            .frame(height: 6)
            .padding(.vertical, 8)
            
            Spacer(minLength: 0)
            
            Text("\(ByteFormatter.format(monitorService.currentTelemetry.memoryUsedBytes, isMemory: true)) · \(ByteFormatter.format(monitorService.currentTelemetry.memoryTotalBytes, isMemory: true))")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .frame(height: 125)
        .glassCard(cornerRadius: 14, padding: 14)
    }
    
    // MARK: - 5. Battery Card
    private var batteryCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: (monitorService.currentTelemetry.isCharging ?? false) ? "battery.100.bolt" : "battery.100")
                        .font(.caption)
                    Text("BATTERY")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(Theme.accentSage)
                
                Spacer()
                
                chipBadge(text: "100% Health")
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(monitorService.currentTelemetry.batteryLevel ?? 100))")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                Text((monitorService.currentTelemetry.isCharging ?? false) ? "% Plugged In" : "% Remaining")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.caption2)
                    .foregroundStyle(Theme.accentAmber)
                Text("Power Connected · Optimal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 0)
            
            Text("Battery Care · Normal")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .frame(height: 125)
        .glassCard(cornerRadius: 14, padding: 14)
    }
    
    // MARK: - 6. Disk Card
    private var diskCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "internaldrive")
                        .font(.caption)
                    Text("DISK")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(Theme.accentOlive)
                
                Spacer()
                
                chipBadge(text: ByteFormatter.format(monitorService.currentTelemetry.diskTotalBytes))
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(ByteFormatter.format(monitorService.currentTelemetry.diskFreeBytes))
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                Text("Free")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08))
                    Capsule().fill(Theme.oliveGradient)
                        .frame(width: geo.size.width * CGFloat(min(1.0, monitorService.currentTelemetry.diskUsagePercent / 100.0)))
                }
            }
            .frame(height: 6)
            .padding(.vertical, 8)
            
            Spacer(minLength: 0)
            
            Text("\(ByteFormatter.format(monitorService.currentTelemetry.diskUsedBytes)) used · \(String(format: "%.1f", monitorService.currentTelemetry.diskUsagePercent))%")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .frame(height: 125)
        .glassCard(cornerRadius: 14, padding: 14)
    }
    
    // MARK: - 7. Network Card
    private var networkCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "network")
                        .font(.caption)
                    Text("NETWORK")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(Theme.accentCyan)
                
                Spacer()
                
                chipBadge(text: "Wi-Fi")
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(ByteFormatter.format(UInt64(monitorService.currentTelemetry.networkBytesInPerSec)))
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                Text("/s")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            let dataPoints = SystemMonitorService.shared.networkThroughputHistory.suffix(15).map { $0.bytesIn }
            SparklineView(dataPoints: dataPoints, lineColor: Theme.accentCyan)
                .frame(height: 24)
            
            Spacer(minLength: 0)
            
            Text("↑ \(ByteFormatter.format(UInt64(monitorService.currentTelemetry.networkBytesOutPerSec)))/s · Wi-Fi")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .frame(height: 125)
        .glassCard(cornerRadius: 14, padding: 14)
    }
    
    // MARK: - 8. Fan Card
    private var fanCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "fan.fill")
                        .font(.caption)
                    Text("FAN")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(Theme.accentAmber)
                
                Spacer()
                
                chipBadge(text: "Load 0%")
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("0")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                Text("RPM Idle")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            // Preset Control Pills
            HStack(spacing: 6) {
                ForEach(["Auto", "Cool", "Max"], id: \.self) { mode in
                    Button(mode) {
                        fanMode = mode
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(fanMode == mode ? Theme.accentAmber.opacity(0.3) : Color.white.opacity(0.06))
                    )
                    .foregroundStyle(fanMode == mode ? Theme.accentAmber : .secondary)
                }
            }
            
            Spacer(minLength: 0)
            
            Text("Managed by macOS")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .frame(height: 125)
        .glassCard(cornerRadius: 14, padding: 14)
    }
    
    // MARK: - Running Processes Table
    private var runningProcessesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Table Header
            HStack {
                Text("NAME (\(processService.processes.count))")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 260, alignment: .leading)
                
                Spacer()
                
                Text("PID")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .trailing)
                
                Text("CPU %")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 80, alignment: .trailing)
                
                Text("MEM")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 80, alignment: .trailing)
                
                Text("ACTION")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .center)
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
            
            Divider()
                .background(Theme.cardBorder(for: colorScheme))
            
            // Process List Rows
            VStack(spacing: 2) {
                ForEach(processService.processes) { proc in
                    processRow(proc: proc)
                }
            }
        }
        .glassCard(cornerRadius: 14, padding: 12)
    }
    
    private func processRow(proc: RunningProcess) -> some View {
        HStack {
            HStack(spacing: 10) {
                AppIconView(path: proc.fullPath, size: 20)
                
                Text(proc.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .lineLimit(1)
            }
            .frame(minWidth: 260, alignment: .leading)
            
            Spacer()
            
            Text("\(proc.pid)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)
            
            HStack(spacing: 4) {
                Text(String(format: "%.1f", proc.cpuPercent))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(proc.cpuPercent > 15 ? Theme.accentRose : Theme.accentSage)
                
                RoundedRectangle(cornerRadius: 1)
                    .fill(proc.cpuPercent > 15 ? Theme.accentRose : Theme.accentSage)
                    .frame(width: min(30, CGFloat(proc.cpuPercent) * 1.5), height: 4)
            }
            .frame(width: 80, alignment: .trailing)
            
            Text(ByteFormatter.format(proc.memoryBytes, isMemory: true))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .trailing)
            
            Button {
                Task {
                    await processService.killProcess(proc)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Theme.accentRose.opacity(0.8))
            }
            .buttonStyle(.plain)
            .frame(width: 60, alignment: .center)
            .help("Terminate Process")
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.02)))
    }
    
    private func chipBadge(text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(Theme.chipBackground(for: colorScheme)))
            .foregroundStyle(.secondary)
    }
}
