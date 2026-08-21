import Foundation

@Observable
public final class DeveloperCleanerService: @unchecked Sendable {
    public static let shared = DeveloperCleanerService()
    
    public var projectArtifacts: [DevProjectArtifact] = []
    public var globalCaches: [DevProjectArtifact] = []
    public var isScanning: Bool = false
    public var isCleaning: Bool = false
    public var scanProgress: Double = 0.0
    public var statusMessage: String = "Ready to scan developer environment"
    public var customScanPaths: [String] = []
    public var lastReport: CleanupReport?
    
    private let fileManager = FileManager.default
    
    public init() {
        // Default scan folders
        let home = fileManager.homeDirectoryForCurrentUser
        customScanPaths = [
            home.appendingPathComponent("Development").path,
            home.appendingPathComponent("Projects").path,
            home.appendingPathComponent("GitHub").path,
            home.appendingPathComponent("Developer").path,
            home.appendingPathComponent("Documents").path,
            home.appendingPathComponent("Code").path,
            home.appendingPathComponent("Workspace").path
        ].filter { fileManager.fileExists(atPath: $0) }
    }
    
    public var totalProjectBytes: UInt64 {
        projectArtifacts.reduce(0) { $0 + $1.sizeBytes }
    }
    
    public var selectedProjectBytes: UInt64 {
        projectArtifacts.filter { $0.isSelected }.reduce(0) { $0 + $1.sizeBytes }
    }
    
    public var totalGlobalCacheBytes: UInt64 {
        globalCaches.reduce(0) { $0 + $1.sizeBytes }
    }
    
    public var selectedGlobalCacheBytes: UInt64 {
        globalCaches.filter { $0.isSelected }.reduce(0) { $0 + $1.sizeBytes }
    }
    
    public var totalReclaimableSelectedBytes: UInt64 {
        selectedProjectBytes + selectedGlobalCacheBytes
    }
    
    public func scanAllDeveloperSpace() async {
        guard !isScanning else { return }
        
        await MainActor.run {
            self.isScanning = true
            self.scanProgress = 0.0
            self.statusMessage = "Discovering developer project build artifacts..."
            self.projectArtifacts = []
            self.globalCaches = []
        }
        
        let pathsToScan = customScanPaths
        
        let (projects, globals) = await Task.detached(priority: .userInitiated) {
            var foundProjects: [DevProjectArtifact] = []
            var foundGlobals: [DevProjectArtifact] = []
            
            // 1. Scan Global Tool Caches
            foundGlobals = Self.scanGlobalToolCaches()
            
            // 2. Scan Projects recursively up to depth 4
            let fm = FileManager.default
            for basePath in pathsToScan {
                guard fm.fileExists(atPath: basePath) else { continue }
                Self.crawlDirectoryForArtifacts(at: URL(fileURLWithPath: basePath), currentDepth: 0, maxDepth: 4, results: &foundProjects)
            }
            
            let sortedProjects = foundProjects.sorted { $0.sizeBytes > $1.sizeBytes }
            let sortedGlobals = foundGlobals.sorted { $0.sizeBytes > $1.sizeBytes }
            return (sortedProjects, sortedGlobals)
        }.value
        
        let finalProjects = projects
        let finalGlobals = globals
        
        await MainActor.run {
            self.projectArtifacts = finalProjects
            self.globalCaches = finalGlobals
            self.isScanning = false
            self.scanProgress = 1.0
            self.statusMessage = "Found \(ByteFormatter.format(self.totalProjectBytes + self.totalGlobalCacheBytes)) in developer artifacts."
        }
    }
    
    private nonisolated static func crawlDirectoryForArtifacts(at url: URL, currentDepth: Int, maxDepth: Int, results: inout [DevProjectArtifact]) {
        guard currentDepth <= maxDepth else { return }
        let fm = FileManager.default
        
        guard let contents = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        
        for itemURL in contents {
            let isDir = (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            guard isDir else { continue }
            
            let name = itemURL.lastPathComponent
            
            // Check for specific artifact folder names
            if let type = self.matchArtifactType(name: name) {
                let size = CleanerService.shared.directorySize(at: itemURL)
                if size > 1_000_000 { // > 1MB
                    let modDate = (try? itemURL.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date()
                    let days = Calendar.current.dateComponents([.day], from: modDate, to: Date()).day ?? 0
                    let isRecent = days < 7
                    
                    let projectName = url.lastPathComponent
                    
                    results.append(DevProjectArtifact(
                        projectName: projectName,
                        projectPath: url.path,
                        artifactType: type,
                        path: itemURL.path,
                        sizeBytes: size,
                        lastModified: modDate,
                        isSelected: !isRecent, // Old projects (>7d) selected by default!
                        isRecent: isRecent
                    ))
                }
                // Do NOT crawl inside node_modules or build folders!
                continue
            }
            
            // Crawl deeper into subprojects
            crawlDirectoryForArtifacts(at: itemURL, currentDepth: currentDepth + 1, maxDepth: maxDepth, results: &results)
        }
    }
    
    private nonisolated static func matchArtifactType(name: String) -> DevArtifactType? {
        switch name {
        case "node_modules":
            return .nodeModules
        case ".next":
            return .nextBuild
        case "target":
            return .rustTarget
        case "venv", ".venv", "env", ".env_py":
            return .pythonVenv
        case "DerivedData":
            return .xcodeDerived
        case ".build":
            return .swiftBuild
        case "dist", "build", "out", ".turbo", ".parcel-cache":
            return .distBuild
        case "Pods":
            return .cocoaPods
        case ".gradle":
            return .gradleCache
        default:
            return nil
        }
    }
    
    private nonisolated static func scanGlobalToolCaches() -> [DevProjectArtifact] {
        var globals: [DevProjectArtifact] = []
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        
        let toolCaches: [(name: String, path: String, type: DevArtifactType)] = [
            ("Xcode DerivedData", home.appendingPathComponent("Library/Developer/Xcode/DerivedData").path, .xcodeDerived),
            ("Xcode Simulator Caches", home.appendingPathComponent("Library/Developer/CoreSimulator/Caches").path, .globalCache),
            ("Xcode Device Support", home.appendingPathComponent("Library/Developer/Xcode/iOS DeviceSupport").path, .globalCache),
            ("CocoaPods Cache", home.appendingPathComponent("Library/Caches/CocoaPods").path, .cocoaPods),
            ("Swift Package Manager Cache", home.appendingPathComponent("Library/Caches/org.swift.swiftpm").path, .swiftBuild),
            ("NPM Cache (~/.npm)", home.appendingPathComponent(".npm").path, .nodeModules),
            ("Yarn Cache", home.appendingPathComponent("Library/Caches/Yarn").path, .nodeModules),
            ("pnpm Store", home.appendingPathComponent("Library/pnpm/store").path, .nodeModules),
            ("Bun Cache", home.appendingPathComponent(".bun/install/cache").path, .nodeModules),
            ("Cargo Package Cache", home.appendingPathComponent(".cargo/registry/cache").path, .rustTarget),
            ("Gradle Cache (~/.gradle/caches)", home.appendingPathComponent(".gradle/caches").path, .gradleCache),
            ("Go Module Cache", home.appendingPathComponent("go/pkg/mod/cache").path, .globalCache),
            ("Homebrew Download Cache", home.appendingPathComponent("Library/Caches/Homebrew").path, .globalCache)
        ]
        
        for cache in toolCaches {
            if fm.fileExists(atPath: cache.path) {
                let size = CleanerService.shared.directorySize(at: URL(fileURLWithPath: cache.path))
                if size > 1_000_000 {
                    globals.append(DevProjectArtifact(
                        projectName: cache.name,
                        projectPath: cache.path,
                        artifactType: cache.type,
                        path: cache.path,
                        sizeBytes: size,
                        lastModified: Date(),
                        isSelected: true,
                        isRecent: false
                    ))
                }
            }
        }
        
        return globals
    }
    
    public func cleanSelectedArtifacts() async -> CleanupReport {
        await MainActor.run {
            self.isCleaning = true
            self.statusMessage = "Cleaning selected developer artifacts safely to Trash..."
        }
        
        var totalFreed: UInt64 = 0
        var count = 0
        var errors: [String] = []
        
        // 1. Clean selected project artifacts
        var remainingProjects: [DevProjectArtifact] = []
        for item in projectArtifacts {
            if item.isSelected {
                let url = URL(fileURLWithPath: item.path)
                do {
                    try fileManager.trashItem(at: url, resultingItemURL: nil)
                    totalFreed += item.sizeBytes
                    count += 1
                } catch {
                    errors.append("\(item.projectName)/\(item.artifactType.rawValue): \(error.localizedDescription)")
                    remainingProjects.append(item)
                }
            } else {
                remainingProjects.append(item)
            }
        }
        
        // 2. Clean selected global caches
        var remainingGlobals: [DevProjectArtifact] = []
        for item in globalCaches {
            if item.isSelected {
                let url = URL(fileURLWithPath: item.path)
                do {
                    try fileManager.trashItem(at: url, resultingItemURL: nil)
                    totalFreed += item.sizeBytes
                    count += 1
                } catch {
                    errors.append("\(item.projectName): \(error.localizedDescription)")
                    remainingGlobals.append(item)
                }
            } else {
                remainingGlobals.append(item)
            }
        }
        
        let report = CleanupReport(bytesFreed: totalFreed, itemsRemovedCount: count, errors: errors)
        let finalProjects = remainingProjects
        let finalGlobals = remainingGlobals
        
        await MainActor.run {
            self.projectArtifacts = finalProjects
            self.globalCaches = finalGlobals
            self.lastReport = report
            self.isCleaning = false
            self.statusMessage = "Developer clean complete. Freed \(ByteFormatter.format(report.bytesFreed))."
        }
        
        return report
    }
}
