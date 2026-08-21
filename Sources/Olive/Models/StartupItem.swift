import Foundation

public enum StartupLocationType: String, CaseIterable, Sendable {
    case userAgent = "User Launch Agent"
    case systemAgent = "System Launch Agent"
    case systemDaemon = "System Launch Daemon"
    
    public var folderPath: String {
        switch self {
        case .userAgent:
            return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents").path
        case .systemAgent:
            return "/Library/LaunchAgents"
        case .systemDaemon:
            return "/Library/LaunchDaemons"
        }
    }
}

public struct StartupItem: Identifiable, Sendable {
    public var id: String { path }
    public let name: String
    public let label: String
    public let path: String
    public let locationType: StartupLocationType
    public let programPath: String?
    public var isEnabled: Bool
    
    public init(
        name: String,
        label: String,
        path: String,
        locationType: StartupLocationType,
        programPath: String? = nil,
        isEnabled: Bool = true
    ) {
        self.name = name
        self.label = label
        self.path = path
        self.locationType = locationType
        self.programPath = programPath
        self.isEnabled = isEnabled
    }
}
