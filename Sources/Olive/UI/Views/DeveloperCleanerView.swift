import SwiftUI
import AppKit

public enum DevCleanSection: String, CaseIterable, Identifiable {
    case projects = "Project Build Folders"
    case globalCaches = "Global Tool Caches"
    
    public var id: String { rawValue }
}

public struct DeveloperCleanerView: View {
    @Bindable var devService = DeveloperCleanerService.shared
    @State private var selectedSection: DevCleanSection = .projects
    @State private var selectedFilterType: DevArtifactType? = nil
    @State private var showingCelebration: Bool = false
    
    public init() {}
    
    public var filteredProjects: [DevProjectArtifact] {
        if let filter = selectedFilterType {
            return devService.projectArtifacts.filter { $0.artifactType == filter }
        }
        return devService.projectArtifacts
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Developer Cleanup")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text("Reclaim tens of gigabytes from old node_modules, build targets, venvs, and package caches.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    Task {
                        await devService.scanAllDeveloperSpace()
                    }
                } label: {
                    HStack(spacing: 6) {
                        if devService.isScanning {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text(devService.isScanning ? "Scanning..." : "Scan Dev Space")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accentOlive)
                .disabled(devService.isScanning || devService.isCleaning)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            // Progress Bar if Scanning
            if devService.isScanning {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(devService.statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        ProgressView().controlSize(.small)
                    }
                }
                .glassCard()
                .padding(.horizontal, 24)
            }
            
            // Stats Banner
            statsOverviewBanner
                .padding(.horizontal, 24)
            
            // Mode & Filter Controls
            HStack {
                Picker("", selection: $selectedSection) {
                    ForEach(DevCleanSection.allCases) { sec in
                        Text(sec.rawValue).tag(sec)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 320)
                
                Spacer()
                
                if selectedSection == .projects && !devService.projectArtifacts.isEmpty {
                    Button("Select Inactive (>7d)") {
                        for i in 0..<devService.projectArtifacts.count {
                            devService.projectArtifacts[i].isSelected = !devService.projectArtifacts[i].isRecent
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("Select All") {
                        for i in 0..<devService.projectArtifacts.count {
                            devService.projectArtifacts[i].isSelected = true
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("Deselect All") {
                        for i in 0..<devService.projectArtifacts.count {
                            devService.projectArtifacts[i].isSelected = false
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 24)
            
            // Main List Area
            if selectedSection == .projects {
                projectArtifactsList
            } else {
                globalCachesList
            }
            
            // Bottom Action Clean Bar
            bottomCleanBar
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
        }
        .onAppear {
            if devService.projectArtifacts.isEmpty && devService.globalCaches.isEmpty {
                Task {
                    await devService.scanAllDeveloperSpace()
                }
            }
        }
        .alert("Developer Clean Complete!", isPresented: $showingCelebration) {
            Button("Done", role: .cancel) {}
        } message: {
            if let report = devService.lastReport {
                Text("Successfully freed \(ByteFormatter.format(report.bytesFreed)) across \(report.itemsRemovedCount) build artifact directories. All items were moved safely to your macOS Trash.")
            }
        }
    }
    
    // MARK: - Stats Overview Banner
    private var statsOverviewBanner: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total Reclaimable Space")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(ByteFormatter.format(devService.totalProjectBytes + devService.totalGlobalCacheBytes))
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.accentOlive)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Project Build Folders")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(devService.projectArtifacts.count) projects")
                    .font(.system(.body, design: .rounded, weight: .semibold))
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Global Tool Caches")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(devService.globalCaches.count) tools")
                    .font(.system(.body, design: .rounded, weight: .semibold))
            }
        }
        .glassCard(cornerRadius: 14)
    }
    
    // MARK: - Projects List
    private var projectArtifactsList: some View {
        Group {
            if filteredProjects.isEmpty && !devService.isScanning {
                VStack(spacing: 10) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No build artifacts found in scanned project folders.")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(0..<devService.projectArtifacts.count, id: \.self) { idx in
                        projectRow(index: idx)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    private func projectRow(index: Int) -> some View {
        let item = devService.projectArtifacts[index]
        return HStack(spacing: 14) {
            Toggle("", isOn: Binding(
                get: { devService.projectArtifacts[index].isSelected },
                set: { devService.projectArtifacts[index].isSelected = $0 }
            ))
            .toggleStyle(.checkbox)
            
            Image(systemName: item.artifactType.iconName)
                .font(.title3)
                .foregroundStyle(item.isRecent ? Theme.accentAmber : Theme.accentOlive)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(item.projectName)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                    
                    Text(item.artifactType.rawValue)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                        .foregroundStyle(Theme.accentCyan)
                    
                    if item.isRecent {
                        Text("Active Project (<7d)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Theme.accentAmber.opacity(0.15)))
                            .foregroundStyle(Theme.accentAmber)
                    } else {
                        Text("\(item.daysSinceModified)d inactive")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text(item.path)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(ByteFormatter.format(item.sizeBytes))
                .font(.system(.body, design: .rounded, weight: .bold))
                .monospacedDigit()
            
            Button {
                NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: "")
            } label: {
                Image(systemName: "arrow.up.forward.square")
            }
            .buttonStyle(.plain)
            .help("Reveal in Finder")
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Global Caches List
    private var globalCachesList: some View {
        Group {
            if devService.globalCaches.isEmpty && !devService.isScanning {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.accentSage)
                    Text("All global developer caches are clean.")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(0..<devService.globalCaches.count, id: \.self) { idx in
                        globalCacheRow(index: idx)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    private func globalCacheRow(index: Int) -> some View {
        let item = devService.globalCaches[index]
        return HStack(spacing: 14) {
            Toggle("", isOn: Binding(
                get: { devService.globalCaches[index].isSelected },
                set: { devService.globalCaches[index].isSelected = $0 }
            ))
            .toggleStyle(.checkbox)
            
            Image(systemName: item.artifactType.iconName)
                .font(.title3)
                .foregroundStyle(Theme.accentViolet)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.projectName)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                Text(item.path)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(ByteFormatter.format(item.sizeBytes))
                .font(.system(.body, design: .rounded, weight: .bold))
                .monospacedDigit()
            
            Button {
                NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: "")
            } label: {
                Image(systemName: "arrow.up.forward.square")
            }
            .buttonStyle(.plain)
            .help("Reveal in Finder")
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Bottom Clean Bar
    private var bottomCleanBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Selected for Safe Removal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(ByteFormatter.format(devService.totalReclaimableSelectedBytes))
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.accentOlive)
            }
            
            Spacer()
            
            Button {
                Task {
                    let report = await devService.cleanSelectedArtifacts()
                    if report.bytesFreed > 0 {
                        showingCelebration = true
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if devService.isCleaning {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "trash.fill")
                    }
                    Text(devService.isCleaning ? "Purging..." : "Purge Selected Artifacts")
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accentRose)
            .disabled(devService.totalReclaimableSelectedBytes == 0 || devService.isCleaning)
        }
        .glassCard(cornerRadius: 16)
    }
}
