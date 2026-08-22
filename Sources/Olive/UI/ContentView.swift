import SwiftUI

public enum NavigationTab: String, CaseIterable, Identifiable {
    case clean = "Clean"
    case devClean = "Dev Clean"
    case apps = "Apps"
    case optimize = "Optimize"
    case analyze = "Analyze"
    case status = "Status"
    
    public var id: String { rawValue }
}

public struct ContentView: View {
    @State private var selectedTab: NavigationTab = .status
    @State private var isDarkMode: Bool = true
    @State private var showingSettings: Bool = false
    @Environment(\.colorScheme) var systemScheme
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Theme.background(for: isDarkMode ? .dark : .light)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Header with Centered Floating Pill Navigation
                topNavigationBar
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                Divider()
                    .background(Theme.cardBorder(for: isDarkMode ? .dark : .light))
                
                // Active Screen Content
                ZStack {
                    switch selectedTab {
                    case .status:
                        DashboardView()
                    case .clean:
                        CleanerView()
                    case .devClean:
                        DeveloperCleanerView()
                    case .apps:
                        UninstallerView()
                    case .analyze:
                        DiskMapView()
                    case .optimize:
                        MaintenanceView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .frame(minWidth: 980, minHeight: 640)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .frame(minWidth: 500, minHeight: 400)
        }
    }
    
    // MARK: - Top Navigation Bar
    private var topNavigationBar: some View {
        HStack {
            // Left: Brand Logo & Title
            HStack(spacing: 8) {
                OliveLogoView(size: 26)
                Text("Olive")
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(Theme.textPrimary(for: isDarkMode ? .dark : .light))
            }
            .frame(width: 140, alignment: .leading)
            
            Spacer()
            
            // Center: Floating Pill Navigation Selector
            HStack(spacing: 4) {
                ForEach(NavigationTab.allCases) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: selectedTab == tab ? .bold : .medium, design: .rounded))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(selectedTab == tab
                                          ? (isDarkMode ? Color.white : Color(red: 0.15, green: 0.18, blue: 0.12))
                                          : Color.clear)
                            )
                            .foregroundStyle(
                                selectedTab == tab
                                ? (isDarkMode ? Color.black : Color.white)
                                : Theme.textSecondary(for: isDarkMode ? .dark : .light)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(
                Capsule()
                    .fill(isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                    .overlay(
                        Capsule().strokeBorder(Theme.cardBorder(for: isDarkMode ? .dark : .light), lineWidth: 1)
                    )
            )
            
            Spacer()
            
            // Right: Light/Dark Mode Switcher & Settings
            HStack(spacing: 12) {
                Button {
                    withAnimation {
                        isDarkMode.toggle()
                    }
                } label: {
                    Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isDarkMode ? Theme.accentAmber : Theme.accentViolet)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.06)))
                }
                .buttonStyle(.plain)
                .help("Toggle Dark / Light Mode")
                
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary(for: isDarkMode ? .dark : .light))
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.06)))
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
            .frame(width: 140, alignment: .trailing)
        }
    }
}
