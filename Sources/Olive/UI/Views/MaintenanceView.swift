import SwiftUI
import AppKit

public enum MaintenanceTab: String, CaseIterable, Identifiable {
    case optimizations = "System Scripts"
    case startupItems = "Startup & LaunchAgents"
    
    public var id: String { rawValue }
}

public struct MaintenanceView: View {
    @Bindable var maintenance = MaintenanceService.shared
    @Bindable var startupService = StartupManagerService.shared
    @State private var selectedTab: MaintenanceTab = .optimizations
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Tab Switcher
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("macOS Maintenance")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text("Optimize performance, fix system glitches, and control startup launch agents.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Picker("", selection: $selectedTab) {
                    ForEach(MaintenanceTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            // Tab Content
            if selectedTab == .optimizations {
                optimizationsLayout
            } else {
                startupItemsLayout
            }
        }
        .onAppear {
            if startupService.startupItems.isEmpty {
                Task {
                    await startupService.loadStartupItems()
                }
            }
        }
    }
    
    // MARK: - Optimizations Layout
    private var optimizationsLayout: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(maintenance.tasks) { task in
                    taskCard(task: task)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    private func taskCard(task: MaintenanceTaskItem) -> some View {
        HStack(spacing: 16) {
            Image(systemName: task.taskId.iconName)
                .font(.title2)
                .foregroundStyle(Theme.accentOlive)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.white.opacity(0.06)))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.taskId.title)
                    .font(.system(.headline, design: .rounded))
                Text(task.taskId.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let msg = task.resultMessage {
                    Text(msg)
                        .font(.caption2.bold())
                        .foregroundStyle(task.isCompleted ? Theme.accentSage : Theme.accentAmber)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            Button {
                Task {
                    await maintenance.executeTask(task.taskId)
                }
            } label: {
                HStack(spacing: 6) {
                    if task.isRunning {
                        ProgressView().controlSize(.small)
                    } else if task.isCompleted {
                        Image(systemName: "checkmark")
                    }
                    Text(task.isRunning ? "Running..." : (task.isCompleted ? "Re-run" : "Execute"))
                }
                .frame(minWidth: 80)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accentOlive)
            .disabled(task.isRunning)
        }
        .glassCard()
    }
    
    // MARK: - Startup Items Layout
    private var startupItemsLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Persistent Background Agents")
                    .font(.headline)
                Spacer()
                Button {
                    Task {
                        await startupService.loadStartupItems()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 24)
            
            if startupService.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Scanning LaunchAgents and Daemons...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if startupService.startupItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bolt.slash.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No third-party launch agents detected.")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(startupService.startupItems) { item in
                    startupItemRow(item: item)
                }
                .listStyle(.plain)
            }
        }
        .padding(.bottom, 24)
    }
    
    private func startupItemRow(item: StartupItem) -> some View {
        HStack(spacing: 14) {
            Image(systemName: item.locationType == .systemDaemon ? "server.rack" : "bolt.horizontal.fill")
                .foregroundStyle(item.isEnabled ? Theme.accentOlive : .secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                    Text(item.locationType.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.white.opacity(0.06)))
                        .foregroundStyle(.secondary)
                }
                
                Text(item.label)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { item.isEnabled },
                set: { _ in
                    Task {
                        await startupService.toggleItem(item)
                    }
                }
            ))
            .toggleStyle(.switch)
            .tint(Theme.accentOlive)
            
            Button {
                NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: "")
            } label: {
                Image(systemName: "arrow.up.forward.square")
            }
            .buttonStyle(.plain)
            .help("Reveal Plist in Finder")
            
            Button {
                Task {
                    await startupService.removeStartupItem(item)
                }
            } label: {
                Image(systemName: "trash.fill")
                    .foregroundStyle(Theme.accentRose)
            }
            .buttonStyle(.plain)
            .help("Delete LaunchAgent")
        }
        .padding(.vertical, 4)
    }
}
