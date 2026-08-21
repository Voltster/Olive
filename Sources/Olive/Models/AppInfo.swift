import Foundation

public struct AppInfo: Identifiable, Sendable {
    public var id: String { bundlePath }
    public let name: String
    public let bundleIdentifier: String?
    public let bundlePath: String
    public let version: String?
    public let appSizeBytes: UInt64
    public var relatedItems: [LeftoverItem]
    public var isSelected: Bool
    
    public var totalSizeBytes: UInt64 {
        appSizeBytes + relatedItems.reduce(0) { $0 + $1.sizeBytes }
    }
    
    public init(
        name: String,
        bundleIdentifier: String? = nil,
        bundlePath: String,
        version: String? = nil,
        appSizeBytes: UInt64 = 0,
        relatedItems: [LeftoverItem] = [],
        isSelected: Bool = false
    ) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.bundlePath = bundlePath
        self.version = version
        self.appSizeBytes = appSizeBytes
        self.relatedItems = relatedItems
        self.isSelected = isSelected
    }
}

public struct LeftoverItem: Identifiable, Sendable {
    public var id: String { path }
    public let path: String
    public let itemType: LeftoverType
    public let sizeBytes: UInt64
    public var isSelected: Bool
    
    public init(path: String, itemType: LeftoverType, sizeBytes: UInt64, isSelected: Bool = true) {
        self.path = path
        self.itemType = itemType
        self.sizeBytes = sizeBytes
        self.isSelected = isSelected
    }
}

public enum LeftoverType: String, CaseIterable, Sendable {
    case applicationSupport = "Application Support"
    case caches = "Caches"
    case preferences = "Preferences"
    case savedState = "Saved State"
    case webKit = "WebKit Data"
    case launchAgent = "Launch Agent"
    case logs = "Logs"
    case other = "Other Residual"
}
