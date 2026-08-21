import Foundation

@Observable
public final class CleanerService: @unchecked Sendable {
    public static let shared = CleanerService()
    
    public var summaries: [ScanCategorySummary] = []
    public var isScanning: Bool = false
    public var isCleaning: Bool = false
    public var scanProgress: Double = 0.0
    public var statusMessage: String = "Ready to scan"
    public var lastReport: CleanupReport?
    
    private let fileManager = FileManager.default
    
    public init() {}
    
    public var totalScannedBytes: UInt64 {
        summaries.reduce(0) { $0 + $1.totalSizeBytes }
    }
    
    public var totalSelectedBytes: UInt64 {
        summaries.reduce(0) { $0 + $1.selectedSizeBytes }
    }
    
    public func scanAll() async {
        guard !isScanning else { return }
        await MainActor.run {
            self.isScanning = true
            self.scanProgress = 0.0
            self.statusMessage = "Starting system analysis..."
            self.summaries = []
        }
        
        var results: [ScanCategorySummary] = []
        let categories = CleanupCategoryType.allCases
        let totalSteps = Double(categories.count)
        
        for (index, category) in categories.enumerated() {
            await MainActor.run {
                self.statusMessage = "Scanning \(category.rawValue)..."
                self.scanProgress = Double(index) / totalSteps
            }
            
            let items = await scanCategory(category)
            results.append(ScanCategorySummary(category: category, items: items, isSelected: true))
        }
        
        let finalResults = results
        await MainActor.run {
            self.summaries = finalResults
            self.isScanning = false
            self.scanProgress = 1.0
            self.statusMessage = "Scan complete. Found \(ByteFormatter.format(self.totalScannedBytes)) reclaimable space."
        }
    }
    
    private func scanCategory(_ category: CleanupCategoryType) async -> [CleanupItem] {
        return await Task.detached(priority: .userInitiated) {
            var items: [CleanupItem] = []
            let fm = FileManager.default
            let home = fm.homeDirectoryForCurrentUser
            
            switch category {
            case .userCaches:
                let cachesURL = home.appendingPathComponent("Library/Caches")
                items.append(contentsOf: self.scanDirectorySubfolders(at: cachesURL, category: .userCaches))
                
            case .developerArtifacts:
                // Xcode DerivedData
                let derivedDataURL = home.appendingPathComponent("Library/Developer/Xcode/DerivedData")
                if fm.fileExists(atPath: derivedDataURL.path) {
                    let size = self.directorySize(at: derivedDataURL)
                    if size > 0 {
                        items.append(CleanupItem(
                            path: derivedDataURL.path,
                            name: "Xcode DerivedData",
                            sizeBytes: size,
                            category: .developerArtifacts,
                            isSelected: true,
                            isSafe: true
                        ))
                    }
                }
                
                // Xcode Archives / CoreSimulator Caches
                let archivesURL = home.appendingPathComponent("Library/Developer/Xcode/Archives")
                if fm.fileExists(atPath: archivesURL.path) {
                    let size = self.directorySize(at: archivesURL)
                    if size > 0 {
                        items.append(CleanupItem(
                            path: archivesURL.path,
                            name: "Xcode Legacy Archives",
                            sizeBytes: size,
                            category: .developerArtifacts,
                            isSelected: false,
                            isSafe: true
                        ))
                    }
                }
                
                // Homebrew Caches
                let brewCache = home.appendingPathComponent("Library/Caches/Homebrew")
                if fm.fileExists(atPath: brewCache.path) {
                    let size = self.directorySize(at: brewCache)
                    if size > 0 {
                        items.append(CleanupItem(
                            path: brewCache.path,
                            name: "Homebrew Download Caches",
                            sizeBytes: size,
                            category: .developerArtifacts,
                            isSelected: true,
                            isSafe: true
                        ))
                    }
                }
                
                // Common Developer tool caches
                let npmCache = home.appendingPathComponent(".npm")
                if fm.fileExists(atPath: npmCache.path) {
                    let size = self.directorySize(at: npmCache)
                    if size > 0 {
                        items.append(CleanupItem(
                            path: npmCache.path,
                            name: "NPM Cache (~/.npm)",
                            sizeBytes: size,
                            category: .developerArtifacts,
                            isSelected: true,
                            isSafe: true
                        ))
                    }
                }
                
                let cargoCache = home.appendingPathComponent(".cargo/registry/cache")
                if fm.fileExists(atPath: cargoCache.path) {
                    let size = self.directorySize(at: cargoCache)
                    if size > 0 {
                        items.append(CleanupItem(
                            path: cargoCache.path,
                            name: "Rust Cargo Package Cache",
                            sizeBytes: size,
                            category: .developerArtifacts,
                            isSelected: true,
                            isSafe: true
                        ))
                    }
                }
                
            case .systemLogs:
                let userLogsURL = home.appendingPathComponent("Library/Logs")
                items.append(contentsOf: self.scanDirectorySubfolders(at: userLogsURL, category: .systemLogs))
                
                let diagURL = URL(fileURLWithPath: "/Library/Logs/DiagnosticReports")
                if fm.fileExists(atPath: diagURL.path) {
                    let size = self.directorySize(at: diagURL)
                    if size > 0 {
                        items.append(CleanupItem(
                            path: diagURL.path,
                            name: "System Diagnostic Reports",
                            sizeBytes: size,
                            category: .systemLogs,
                            isSelected: true,
                            isSafe: true
                        ))
                    }
                }
                
            case .browserCaches:
                let chromeCache = home.appendingPathComponent("Library/Caches/Google/Chrome")
                if fm.fileExists(atPath: chromeCache.path) {
                    let size = self.directorySize(at: chromeCache)
                    if size > 0 {
                        items.append(CleanupItem(
                            path: chromeCache.path,
                            name: "Google Chrome Cache",
                            sizeBytes: size,
                            category: .browserCaches
                        ))
                    }
                }
                
                let arcCache = home.appendingPathComponent("Library/Caches/company.thebrowser.Browser")
                if fm.fileExists(atPath: arcCache.path) {
                    let size = self.directorySize(at: arcCache)
                    if size > 0 {
                        items.append(CleanupItem(
                            path: arcCache.path,
                            name: "Arc Browser Cache",
                            sizeBytes: size,
                            category: .browserCaches
                        ))
                    }
                }
                
                let safariCache = home.appendingPathComponent("Library/Caches/com.apple.Safari")
                if fm.fileExists(atPath: safariCache.path) {
                    let size = self.directorySize(at: safariCache)
                    if size > 0 {
                        items.append(CleanupItem(
                            path: safariCache.path,
                            name: "Safari Cache",
                            sizeBytes: size,
                            category: .browserCaches
                        ))
                    }
                }
                
            case .orphanedLeftovers:
                let appSupport = home.appendingPathComponent("Library/Application Support")
                items.append(contentsOf: self.scanOrphanedAppFolders(appSupportURL: appSupport))
                
            case .trash:
                let trashURL = home.appendingPathComponent(".Trash")
                if fm.fileExists(atPath: trashURL.path) {
                    let size = self.directorySize(at: trashURL)
                    if size > 0 {
                        items.append(CleanupItem(
                            path: trashURL.path,
                            name: "User Trash (~/.Trash)",
                            sizeBytes: size,
                            category: .trash,
                            isSelected: true,
                            isSafe: true
                        ))
                    }
                }
            }
            
            return items.sorted { $0.sizeBytes > $1.sizeBytes }
        }.value
    }
    
    private func scanDirectorySubfolders(at url: URL, category: CleanupCategoryType) -> [CleanupItem] {
        var items: [CleanupItem] = []
        guard let contents = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey], options: [.skipsHiddenFiles]) else {
            return []
        }
        
        for itemURL in contents {
            let size = directorySize(at: itemURL)
            // Only report folders greater than 1 MB
            if size > 1_000_000 {
                items.append(CleanupItem(
                    path: itemURL.path,
                    name: itemURL.lastPathComponent,
                    sizeBytes: size,
                    category: category,
                    isSelected: true,
                    isSafe: true
                ))
            }
        }
        return items
    }
    
    private func scanOrphanedAppFolders(appSupportURL: URL) -> [CleanupItem] {
        var items: [CleanupItem] = []
        guard let contents = try? fileManager.contentsOfDirectory(at: appSupportURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return []
        }
        
        // Scan for prominent known leftover directories
        let installedApps = getInstalledAppNames()
        for folderURL in contents {
            let name = folderURL.lastPathComponent
            if isProtectedSystemAppSupportFolder(name) { continue }
            
            if !installedApps.contains(where: { name.localizedCaseInsensitiveContains($0) }) {
                let size = directorySize(at: folderURL)
                if size > 5_000_000 { // > 5MB
                    items.append(CleanupItem(
                        path: folderURL.path,
                        name: "\(name) (Uninstalled app)",
                        sizeBytes: size,
                        category: .orphanedLeftovers,
                        isSelected: false, // Default unselected for user safety
                        isSafe: true
                    ))
                }
            }
        }
        return items
    }
    
    private func getInstalledAppNames() -> Set<String> {
        var apps = Set<String>()
        let appDirs = [URL(fileURLWithPath: "/Applications"), fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications")]
        
        for dir in appDirs {
            if let contents = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                for url in contents where url.pathExtension == "app" {
                    apps.insert(url.deletingPathExtension().lastPathComponent)
                }
            }
        }
        return apps
    }
    
    private func isProtectedSystemAppSupportFolder(_ name: String) -> Bool {
        let protected: Set<String> = [
            "Apple", "iCloud", "AddressBook", "CallHistoryDB", "CrashReporter", "Dock",
            "com.apple.sharedfilelist", "SyncServices", "Quick Look", "CloudDocs"
        ]
        return protected.contains(name) || name.hasPrefix("com.apple.")
    }
    
    public func directorySize(at url: URL) -> UInt64 {
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }
        
        if !isDir.boolValue {
            if let attrs = try? fileManager.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? UInt64 {
                return size
            }
            return 0
        }
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .fileSizeKey],
            options: [],
            errorHandler: nil
        ) else { return 0 }
        
        var total: UInt64 = 0
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .fileSizeKey]) else { continue }
            total += UInt64(resourceValues.totalFileAllocatedSize ?? resourceValues.fileAllocatedSize ?? resourceValues.fileSize ?? 0)
        }
        return total
    }
    
    // MARK: - Safe Deletion
    public func cleanSelectedItems() async -> CleanupReport {
        await MainActor.run {
            self.isCleaning = true
            self.statusMessage = "Moving selected items safely to Trash..."
        }
        
        var totalFreed: UInt64 = 0
        var removedCount = 0
        var errors: [String] = []
        
        for (catIndex, summary) in summaries.enumerated() {
            var updatedItems = summary.items
            for (itemIndex, item) in summary.items.enumerated() where item.isSelected {
                let url = URL(fileURLWithPath: item.path)
                do {
                    // Safe deletion via macOS Trash API
                    try fileManager.trashItem(at: url, resultingItemURL: nil)
                    totalFreed += item.sizeBytes
                    removedCount += 1
                    updatedItems.remove(at: itemIndex - (summary.items.count - updatedItems.count))
                } catch {
                    errors.append("\(item.name): \(error.localizedDescription)")
                }
            }
            summaries[catIndex].items = updatedItems
        }
        
        let report = CleanupReport(
            bytesFreed: totalFreed,
            itemsRemovedCount: removedCount,
            errors: errors
        )
        
        await MainActor.run {
            self.lastReport = report
            self.isCleaning = false
            self.statusMessage = "Cleanup completed. Freed \(ByteFormatter.format(report.bytesFreed))."
        }
        
        return report
    }
}

public enum ByteFormatter {
    private static let fileFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useAll]
        formatter.includesUnit = true
        return formatter
    }()
    
    private static let memoryFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        formatter.allowedUnits = [.useAll]
        formatter.includesUnit = true
        return formatter
    }()
    
    public static func format(_ bytes: UInt64, isMemory: Bool = false) -> String {
        let count = Int64(min(UInt64(Int64.max), bytes))
        if isMemory {
            return memoryFormatter.string(fromByteCount: count)
        }
        return fileFormatter.string(fromByteCount: count)
    }
}
