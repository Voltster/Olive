import SwiftUI

@main
public struct OliveApp: App {
    @State private var monitorService = SystemMonitorService.shared
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1020, height: 680)
        
        MenuBarExtra("Olive", systemImage: "leaf.fill") {
            MenuBarHUDView()
        }
        .menuBarExtraStyle(.window)
    }
}
