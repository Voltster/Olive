import Foundation

@Observable
public final class UninstallerService: @unchecked Sendable {
    public static let shared = UninstallerService()
    
    public var installedApps: [AppInfo] = []
    public var isLoading: Bool = false
    public var searchQuery: String = ""
    public var selectedAppForDetail: AppInfo?
    
    private let fileManager = FileManager.default
    
    public init() {}
    
    public var filteredApps: [AppInfo] {
        if searchQuery.isEmpty {
            return installedApps
        }
        return installedApps.filter {
            $0.name.localizedCaseInsensitiveContains(searchQuery) ||
            ($0.bundleIdentifier?.localizedCaseInsensitiveContains(searchQuery) ?? false)
        }
    }
    
    public func loadInstalledApps() async {
        await MainActor.run {
            self.isLoading = true
        }
        
        let apps = await Task.detached(priority: .userInitiated) {
            var discovered: [AppInfo] = []
            let appDirs = [
                URL(fileURLWithPath: "/Applications"),
                FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
            ]
            
            for dir in appDirs {
                guard let contents = try? FileManager.default.contentsOfDirectory(
                    at: dir,
                    includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
                    options: [.skipsHiddenFiles]
                ) else { continue }
                
                for appURL in contents where appURL.pathExtension == "app" {
                    let name = appURL.deletingPathExtension().lastPathComponent
                    let bundle = Bundle(url: appURL)
                    let bundleId = bundle?.bundleIdentifier
                    let version = bundle?.infoDictionary?["CFBundleShortVersionString"] as? String
                    
                    let appSize = CleanerService.shared.directorySize(at: appURL)
                    let leftovers = self.findRelatedFiles(forAppName: name, bundleIdentifier: bundleId)
                    
                    discovered.append(AppInfo(
                        name: name,
                        bundleIdentifier: bundleId,
                        bundlePath: appURL.path,
                        version: version,
                        appSizeBytes: appSize,
                        relatedItems: leftovers,
                        isSelected: false
                    ))
                }
            }
            
            return discovered.sorted { $0.totalSizeBytes > $1.totalSizeBytes }
        }.value
        
        await MainActor.run {
            self.installedApps = apps
            self.isLoading = false
        }
    }
    
    private func findRelatedFiles(forAppName appName: String, bundleIdentifier: String?) -> [LeftoverItem] {
        var items: [LeftoverItem] = []
        let home = fileManager.homeDirectoryForCurrentUser
        let library = home.appendingPathComponent("Library")
        
        // 1. Application Support
        let appSupport = library.appendingPathComponent("Application Support").appendingPathComponent(appName)
        if fileManager.fileExists(atPath: appSupport.path) {
            let size = CleanerService.shared.directorySize(at: appSupport)
            if size > 0 {
                items.append(LeftoverItem(path: appSupport.path, itemType: .applicationSupport, sizeBytes: size))
            }
        }
        
        // 2. Caches
        if let bundleId = bundleIdentifier {
            let cacheURL = library.appendingPathComponent("Caches").appendingPathComponent(bundleId)
            if fileManager.fileExists(atPath: cacheURL.path) {
                let size = CleanerService.shared.directorySize(at: cacheURL)
                if size > 0 {
                    items.append(LeftoverItem(path: cacheURL.path, itemType: .caches, sizeBytes: size))
                }
            }
            
            // Preferences
            let prefURL = library.appendingPathComponent("Preferences").appendingPathComponent("\(bundleId).plist")
            if fileManager.fileExists(atPath: prefURL.path) {
                if let attrs = try? fileManager.attributesOfItem(atPath: prefURL.path),
                   let size = attrs[.size] as? UInt64 {
                    items.append(LeftoverItem(path: prefURL.path, itemType: .preferences, sizeBytes: size))
                }
            }
            
            // Saved Application State
            let savedStateURL = library.appendingPathComponent("Saved Application State").appendingPathComponent("\(bundleId).savedState")
            if fileManager.fileExists(atPath: savedStateURL.path) {
                let size = CleanerService.shared.directorySize(at: savedStateURL)
                if size > 0 {
                    items.append(LeftoverItem(path: savedStateURL.path, itemType: .savedState, sizeBytes: size))
                }
            }
            
            // WebKit Storage
            let webKitURL = library.appendingPathComponent("WebKit").appendingPathComponent(bundleId)
            if fileManager.fileExists(atPath: webKitURL.path) {
                let size = CleanerService.shared.directorySize(at: webKitURL)
                if size > 0 {
                    items.append(LeftoverItem(path: webKitURL.path, itemType: .webKit, sizeBytes: size))
                }
            }
        }
        
        return items
    }
    
    public func uninstallApp(_ app: AppInfo) async -> CleanupReport {
        var freed: UInt64 = 0
        var count = 0
        var errors: [String] = []
        
        // 1. Move main app to trash
        let appURL = URL(fileURLWithPath: app.bundlePath)
        do {
            try fileManager.trashItem(at: appURL, resultingItemURL: nil)
            freed += app.appSizeBytes
            count += 1
        } catch {
            errors.append("App: \(error.localizedDescription)")
        }
        
        // 2. Move selected leftovers to trash
        for item in app.relatedItems where item.isSelected {
            let itemURL = URL(fileURLWithPath: item.path)
            do {
                try fileManager.trashItem(at: itemURL, resultingItemURL: nil)
                freed += item.sizeBytes
                count += 1
            } catch {
                errors.append("\(item.itemType.rawValue): \(error.localizedDescription)")
            }
        }
        
        await MainActor.run {
            self.installedApps.removeAll { $0.id == app.id }
        }
        
        return CleanupReport(bytesFreed: freed, itemsRemovedCount: count, errors: errors)
    }
}
