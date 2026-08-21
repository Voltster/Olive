import Foundation

public enum CleanupCategoryType: String, CaseIterable, Identifiable, Codable, Sendable {
    case userCaches = "User Caches"
    case developerArtifacts = "Developer Artifacts"
    case systemLogs = "System & App Logs"
    case browserCaches = "Browser Caches"
    case orphanedLeftovers = "App Leftovers"
    case trash = "System Trash"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .userCaches: return "externaldrive.badge.timemachine"
        case .developerArtifacts: return "hammer.fill"
        case .systemLogs: return "doc.text.magnifyingglass"
        case .browserCaches: return "safari.fill"
        case .orphanedLeftovers: return "shippingbox.and.arrow.backward"
        case .trash: return "trash.fill"
        }
    }
    
    public var description: String {
        switch self {
        case .userCaches:
            return "Application cache files in ~/Library/Caches that can be safely refreshed."
        case .developerArtifacts:
            return "Disposable build caches, Xcode DerivedData, node_modules, and target directories."
        case .systemLogs:
            return "Stale diagnostic logs, crash reports, and system log archives."
        case .browserCaches:
            return "Temporary cached files from Safari, Chrome, Firefox, Arc, and Brave."
        case .orphanedLeftovers:
            return "Residual preference files and application support folders from uninstalled apps."
        case .trash:
            return "Files currently in your macOS Trash."
        }
    }
}

public struct CleanupItem: Identifiable, Codable, Sendable {
    public var id: String { path }
    public let path: String
    public let name: String
    public let sizeBytes: UInt64
    public let category: CleanupCategoryType
    public var isSelected: Bool
    public let isSafe: Bool
    public let fileCount: Int
    
    public init(
        path: String,
        name: String,
        sizeBytes: UInt64,
        category: CleanupCategoryType,
        isSelected: Bool = true,
        isSafe: Bool = true,
        fileCount: Int = 1
    ) {
        self.path = path
        self.name = name
        self.sizeBytes = sizeBytes
        self.category = category
        self.isSelected = isSelected
        self.isSafe = isSafe
        self.fileCount = fileCount
    }
}

public struct ScanCategorySummary: Identifiable, Sendable {
    public var id: CleanupCategoryType { category }
    public let category: CleanupCategoryType
    public var items: [CleanupItem]
    public var isSelected: Bool
    
    public var totalSizeBytes: UInt64 {
        items.reduce(0) { $0 + $1.sizeBytes }
    }
    
    public var selectedSizeBytes: UInt64 {
        items.filter { $0.isSelected }.reduce(0) { $0 + $1.sizeBytes }
    }
    
    public init(category: CleanupCategoryType, items: [CleanupItem] = [], isSelected: Bool = true) {
        self.category = category
        self.items = items
        self.isSelected = isSelected
    }
}

public struct CleanupReport: Sendable {
    public let bytesFreed: UInt64
    public let itemsRemovedCount: Int
    public let errors: [String]
    public let timestamp: Date
    
    public init(bytesFreed: UInt64, itemsRemovedCount: Int, errors: [String] = [], timestamp: Date = Date()) {
        self.bytesFreed = bytesFreed
        self.itemsRemovedCount = itemsRemovedCount
        self.errors = errors
        self.timestamp = timestamp
    }
}
