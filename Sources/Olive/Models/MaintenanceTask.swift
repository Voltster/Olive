import Foundation

public enum MaintenanceTaskId: String, CaseIterable, Identifiable, Sendable {
    case flushDNS = "flush_dns"
    case rebuildQuickLook = "rebuild_quicklook"
    case rebuildSpotlight = "rebuild_spotlight"
    case purgeRAM = "purge_ram"
    case repairPermissions = "repair_disk_perms"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .flushDNS: return "Flush DNS Resolver Cache"
        case .rebuildQuickLook: return "Rebuild QuickLook Cache"
        case .rebuildSpotlight: return "Re-index Spotlight Search"
        case .purgeRAM: return "Purge Inactive Memory"
        case .repairPermissions: return "Verify Disk Volumes"
        }
    }
    
    public var iconName: String {
        switch self {
        case .flushDNS: return "network"
        case .rebuildQuickLook: return "eye.fill"
        case .rebuildSpotlight: return "magnifyingglass.circle.fill"
        case .purgeRAM: return "memorychip.fill"
        case .repairPermissions: return "wrench.and.screwdriver.fill"
        }
    }
    
    public var description: String {
        switch self {
        case .flushDNS:
            return "Clears local DNS caches to resolve network name resolution glitches."
        case .rebuildQuickLook:
            return "Resets Finder thumbnail generation service to fix blank file previews."
        case .rebuildSpotlight:
            return "Re-indexes search metadata to restore fast and accurate Finder search results."
        case .purgeRAM:
            return "Forces macOS memory manager to free inactive cached memory pages."
        case .repairPermissions:
            return "Scans local APFS volumes for filesystem consistency and integrity."
        }
    }
}

public struct MaintenanceTaskItem: Identifiable, Sendable {
    public var id: MaintenanceTaskId { taskId }
    public let taskId: MaintenanceTaskId
    public var isRunning: Bool
    public var isCompleted: Bool
    public var lastRunDate: Date?
    public var resultMessage: String?
    
    public init(taskId: MaintenanceTaskId, isRunning: Bool = false, isCompleted: Bool = false, lastRunDate: Date? = nil, resultMessage: String? = nil) {
        self.taskId = taskId
        self.isRunning = isRunning
        self.isCompleted = isCompleted
        self.lastRunDate = lastRunDate
        self.resultMessage = resultMessage
    }
}
