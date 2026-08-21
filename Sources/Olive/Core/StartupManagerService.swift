import Foundation

@Observable
public final class StartupManagerService: @unchecked Sendable {
    public static let shared = StartupManagerService()
    
    public var startupItems: [StartupItem] = []
    public var isLoading: Bool = false
    
    private let fileManager = FileManager.default
    
    public init() {}
    
    public func loadStartupItems() async {
        await MainActor.run {
            self.isLoading = true
        }
        
        let items = await Task.detached(priority: .userInitiated) {
            var discovered: [StartupItem] = []
            
            for location in StartupLocationType.allCases {
                let folderURL = URL(fileURLWithPath: location.folderPath)
                guard let contents = try? FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil) else {
                    continue
                }
                
                for fileURL in contents where fileURL.pathExtension == "plist" || fileURL.lastPathComponent.hasSuffix(".plist.disabled") {
                    let isDisabledFile = fileURL.lastPathComponent.hasSuffix(".disabled")
                    
                    if let data = try? Data(contentsOf: fileURL),
                       let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                        
                        let label = plist["Label"] as? String ?? fileURL.deletingPathExtension().lastPathComponent
                        let disabledInPlist = plist["Disabled"] as? Bool ?? false
                        let isEnabled = !isDisabledFile && !disabledInPlist
                        
                        var programPath: String?
                        if let prog = plist["Program"] as? String {
                            programPath = prog
                        } else if let args = plist["ProgramArguments"] as? [String], let first = args.first {
                            programPath = first
                        }
                        
                        let cleanName = self.generateFriendlyName(fromLabel: label, programPath: programPath)
                        
                        discovered.append(StartupItem(
                            name: cleanName,
                            label: label,
                            path: fileURL.path,
                            locationType: location,
                            programPath: programPath,
                            isEnabled: isEnabled
                        ))
                    }
                }
            }
            
            return discovered.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }.value
        
        await MainActor.run {
            self.startupItems = items
            self.isLoading = false
        }
    }
    
    private func generateFriendlyName(fromLabel label: String, programPath: String?) -> String {
        // If program path contains .app, use app name
        if let prog = programPath, let appRange = prog.range(of: ".app") {
            let sub = prog[..<appRange.lowerBound]
            if let lastSlash = sub.lastIndex(of: "/") {
                return String(sub[sub.index(after: lastSlash)...])
            }
        }
        
        // Clean label: e.g. "com.spotify.webhelper" -> "Spotify Webhelper"
        let parts = label.split(separator: ".")
        if parts.count >= 2 {
            let lastTwo = parts.suffix(2).map { $0.capitalized }.joined(separator: " ")
            return lastTwo
        }
        return label
    }
    
    public func toggleItem(_ item: StartupItem) async {
        guard let index = startupItems.firstIndex(where: { $0.id == item.id }) else { return }
        
        let newEnabled = !item.isEnabled
        let path = item.path
        
        // Toggle launchctl
        if newEnabled {
            _ = try? await ProcessRunner.shared.runShellScript("launchctl load '\(path)' || true")
        } else {
            _ = try? await ProcessRunner.shared.runShellScript("launchctl unload '\(path)' || true")
        }
        
        await MainActor.run {
            self.startupItems[index].isEnabled = newEnabled
        }
    }
    
    public func removeStartupItem(_ item: StartupItem) async {
        let url = URL(fileURLWithPath: item.path)
        
        // 1. Unload from launchd
        _ = try? await ProcessRunner.shared.runShellScript("launchctl unload '\(item.path)' || true")
        
        // 2. Move .plist to macOS Trash
        try? fileManager.trashItem(at: url, resultingItemURL: nil)
        
        await MainActor.run {
            self.startupItems.removeAll { $0.id == item.id }
        }
    }
}
