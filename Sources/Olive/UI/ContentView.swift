import SwiftUI

public enum NavigationSection: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case cleaner = "Smart Clean"
    case uninstaller = "App Uninstaller"
    case diskMap = "Disk Analyzer"
    case maintenance = "Maintenance"
    case settings = "Settings"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.50percent"
        case .cleaner: return "sparkles"
        case .uninstaller: return "trash.circle"
        case .diskMap: return "internaldrive"
        case .maintenance: return "wrench.and.screwdriver"
        case .settings: return "gearshape"
        }
    }
}

public struct ContentView: View {
    @State private var selectedSection: NavigationSection = .dashboard
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            List(NavigationSection.allCases, selection: $selectedSection) { section in
                NavigationLink(value: section) {
                    Label(section.rawValue, systemImage: section.iconName)
                        .font(.system(.body, design: .rounded))
                        .padding(.vertical, 4)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
            .safeAreaInset(edge: .bottom) {
                sidebarBottomBadge
            }
        } detail: {
            ZStack {
                Theme.backgroundDark
                    .ignoresSafeArea()
                
                Group {
                    switch selectedSection {
                    case .dashboard:
                        DashboardView()
                    case .cleaner:
                        CleanerView()
                    case .uninstaller:
                        UninstallerView()
                    case .diskMap:
                        DiskMapView()
                    case .maintenance:
                        MaintenanceView()
                    case .settings:
                        SettingsView()
                    }
                }
            }
        }
        .frame(minWidth: 900, minHeight: 580)
    }
    
    private var sidebarBottomBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "shield.lefthalf.filled")
                .foregroundStyle(Theme.accentOlive)
            VStack(alignment: .leading, spacing: 2) {
                Text("Olive 🫒")
                    .font(.caption.bold())
                Text("Zero Telemetry · GPL-3.0")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Theme.surfaceCard)
        .cornerRadius(10)
        .padding(12)
    }
}
