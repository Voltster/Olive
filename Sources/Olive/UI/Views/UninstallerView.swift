import SwiftUI
import AppKit

public struct UninstallerView: View {
    @Bindable var uninstaller = UninstallerService.shared
    @State private var selectedApp: AppInfo?
    @State private var showingConfirmAlert: Bool = false
    @State private var isUninstalling: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header & Search
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("App Uninstaller")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text("Completely remove apps and their leftover preferences, caches, and support files.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    Task {
                        await uninstaller.loadInstalledApps()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            // Search Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search installed applications...", text: $uninstaller.searchQuery)
                    .textFieldStyle(.plain)
                
                if !uninstaller.searchQuery.isEmpty {
                    Button {
                        uninstaller.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
            .padding(.horizontal, 24)
            
            // App List
            if uninstaller.isLoading {
                VStack(spacing: 14) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Scanning applications & residual library files...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if uninstaller.filteredApps.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                    Text("No applications found")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(uninstaller.filteredApps) { app in
                    appRow(app: app)
                }
                .listStyle(.plain)
            }
        }
        .sheet(item: $selectedApp) { app in
            appDetailSheet(app: app)
        }
        .onAppear {
            if uninstaller.installedApps.isEmpty {
                Task {
                    await uninstaller.loadInstalledApps()
                }
            }
        }
    }
    
    private func appRow(app: AppInfo) -> some View {
        HStack(spacing: 16) {
            // Real macOS App Icon
            AppIconView(path: app.bundlePath, size: 40)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(app.name)
                    .font(.system(.headline, design: .rounded))
                
                HStack(spacing: 8) {
                    if let version = app.version {
                        Text("v\(version)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if !app.relatedItems.isEmpty {
                        Text("• \(app.relatedItems.count) leftover items")
                            .font(.caption.bold())
                            .foregroundStyle(Theme.accentAmber)
                    }
                }
            }
            
            Spacer()
            
            Text(ByteFormatter.format(app.totalSizeBytes))
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .monospacedDigit()
            
            Button("Review") {
                selectedApp = app
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 6)
    }
    
    private func appDetailSheet(app: AppInfo) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                AppIconView(path: app.bundlePath, size: 54)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.title2.bold())
                    Text("Total reclaimable space: \(ByteFormatter.format(app.totalSizeBytes))")
                        .font(.subheadline)
                        .foregroundStyle(Theme.accentOlive)
                }
                
                Spacer()
                
                Button("Done") {
                    selectedApp = nil
                }
                .buttonStyle(.bordered)
            }
            
            Divider()
            
            Text("Associated Files to Remove")
                .font(.headline)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    // Application Bundle
                    HStack(spacing: 12) {
                        Image(systemName: "app.fill")
                            .foregroundStyle(Theme.accentOlive)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Application Bundle")
                                .font(.caption.bold())
                            Text(app.bundlePath)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Text(ByteFormatter.format(app.appSizeBytes))
                            .font(.caption.monospacedDigit().bold())
                        
                        Button {
                            NSWorkspace.shared.selectFile(app.bundlePath, inFileViewerRootedAtPath: "")
                        } label: {
                            Image(systemName: "arrow.up.forward.square")
                        }
                        .buttonStyle(.plain)
                        .help("Reveal in Finder")
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
                    
                    // Leftovers
                    ForEach(app.relatedItems) { item in
                        HStack(spacing: 12) {
                            Image(systemName: itemIconName(for: item.itemType))
                                .foregroundStyle(Theme.accentAmber)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.itemType.rawValue)
                                    .font(.caption.bold())
                                Text(item.path)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Text(ByteFormatter.format(item.sizeBytes))
                                .font(.caption.monospacedDigit())
                            
                            Button {
                                NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: "")
                            } label: {
                                Image(systemName: "arrow.up.forward.square")
                            }
                            .buttonStyle(.plain)
                            .help("Reveal in Finder")
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
                    }
                }
            }
            .frame(maxHeight: 280)
            
            HStack {
                Spacer()
                Button(role: .destructive) {
                    Task {
                        isUninstalling = true
                        _ = await uninstaller.uninstallApp(app)
                        isUninstalling = false
                        selectedApp = nil
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isUninstalling {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "trash.fill")
                        }
                        Text("Move App & All Leftovers to Trash")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accentRose)
                .disabled(isUninstalling)
            }
        }
        .padding(24)
        .frame(minWidth: 540, minHeight: 460)
    }
    
    private func itemIconName(for type: LeftoverType) -> String {
        switch type {
        case .applicationSupport: return "folder.badge.gearshape"
        case .caches: return "externaldrive.badge.timemachine"
        case .preferences: return "gearshape.2"
        case .savedState: return "clock.arrow.circlepath"
        case .webKit: return "safari"
        case .launchAgent: return "bolt.horizontal"
        case .logs: return "doc.text"
        case .other: return "doc"
        }
    }
}
