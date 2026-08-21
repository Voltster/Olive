import SwiftUI

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
                    Image(systemName: "arrow.clockwise")
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
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
            .padding(.horizontal, 24)
            
            // App List
            if uninstaller.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Scanning applications & residual library files...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if uninstaller.filteredApps.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 40))
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
        HStack(spacing: 14) {
            Image(systemName: "app.dashed")
                .font(.title2)
                .foregroundStyle(Theme.accentOlive)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(.headline, design: .rounded))
                
                HStack(spacing: 8) {
                    if let version = app.version {
                        Text("v\(version)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if !app.relatedItems.isEmpty {
                        Text("\(app.relatedItems.count) leftover items")
                            .font(.caption2)
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
        .padding(.vertical, 4)
    }
    
    private func appDetailSheet(app: AppInfo) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Uninstall \(app.name)")
                        .font(.title2.bold())
                    Text("Total space to reclaim: \(ByteFormatter.format(app.totalSizeBytes))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") {
                    selectedApp = nil
                }
            }
            
            Divider()
            
            Text("Associated Files")
                .font(.headline)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "app.fill")
                        Text("Application Bundle (\(app.bundlePath))")
                            .font(.caption)
                        Spacer()
                        Text(ByteFormatter.format(app.appSizeBytes))
                            .font(.caption.monospacedDigit())
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.04)))
                    
                    ForEach(app.relatedItems) { item in
                        HStack {
                            Image(systemName: "folder.badge.gearshape")
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.itemType.rawValue)
                                    .font(.caption.bold())
                                Text(item.path)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(ByteFormatter.format(item.sizeBytes))
                                .font(.caption.monospacedDigit())
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.04)))
                    }
                }
            }
            .frame(maxHeight: 250)
            
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
                    HStack {
                        if isUninstalling {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "trash.fill")
                        }
                        Text("Move App & Leftovers to Trash")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accentRose)
            }
        }
        .padding(24)
        .frame(minWidth: 500, minHeight: 400)
    }
}
