import Foundation
import AppKit

public struct RunningProcess: Identifiable, Sendable {
    public var id: Int { pid }
    public let pid: Int
    public let name: String
    public let fullPath: String
    public let cpuPercent: Double
    public let memoryBytes: UInt64
    public let isSystem: Bool
    
    public init(
        pid: Int,
        name: String,
        fullPath: String,
        cpuPercent: Double,
        memoryBytes: UInt64,
        isSystem: Bool = false
    ) {
        self.pid = pid
        self.name = name
        self.fullPath = fullPath
        self.cpuPercent = cpuPercent
        self.memoryBytes = memoryBytes
        self.isSystem = isSystem
    }
}

@Observable
public final class ProcessMonitorService: @unchecked Sendable {
    public static let shared = ProcessMonitorService()
    
    public var processes: [RunningProcess] = []
    public var isMonitoring: Bool = false
    public var sortOption: ProcessSortOption = .cpu
    
    private var monitorTask: Task<Void, Never>?
    
    public enum ProcessSortOption: String, CaseIterable, Identifiable {
        case cpu = "CPU"
        case memory = "MEM"
        public var id: String { rawValue }
    }
    
    public init() {}
    
    public func startMonitoring() {
        guard monitorTask == nil else { return }
        isMonitoring = true
        
        monitorTask = Task {
            while !Task.isCancelled {
                await self.refreshProcesses()
                try? await Task.sleep(for: .seconds(2.0))
            }
        }
    }
    
    public func stopMonitoring() {
        monitorTask?.cancel()
        monitorTask = nil
        isMonitoring = false
    }
    
    public func refreshProcesses() async {
        let result = try? await ProcessRunner.shared.runShellScript("ps -eo pid,%cpu,rss,comm -r | head -n 60")
        guard let output = result?.stdout else { return }
        
        let lines = output.components(separatedBy: .newlines)
        var parsed: [RunningProcess] = []
        
        for line in lines.dropFirst() { // Skip header
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            let parts = trimmed.split(separator: " ", maxSplits: 3, omittingEmptySubsequences: true)
            guard parts.count >= 4 else { continue }
            
            guard let pid = Int(parts[0]),
                  let cpu = Double(parts[1]),
                  let rssKB = UInt64(parts[2]) else {
                continue
            }
            
            let fullPath = String(parts[3])
            let name = Self.deriveProcessName(from: fullPath)
            let memBytes = rssKB * 1024
            let isSys = fullPath.hasPrefix("/System") || fullPath.hasPrefix("/usr/libexec")
            
            parsed.append(RunningProcess(
                pid: pid,
                name: name,
                fullPath: fullPath,
                cpuPercent: cpu,
                memoryBytes: memBytes,
                isSystem: isSys
            ))
        }
        
        let finalItems = parsed.prefix(50)
        await MainActor.run {
            self.processes = Array(finalItems)
        }
    }
    
    private static func deriveProcessName(from path: String) -> String {
        if let appRange = path.range(of: ".app") {
            let sub = path[..<appRange.lowerBound]
            if let lastSlash = sub.lastIndex(of: "/") {
                return String(sub[sub.index(after: lastSlash)...])
            }
        }
        return URL(fileURLWithPath: path).lastPathComponent
    }
    
    public func killProcess(_ process: RunningProcess) async {
        _ = try? await ProcessRunner.shared.runShellScript("kill -9 \(process.pid) || true")
        await MainActor.run {
            self.processes.removeAll { $0.pid == process.pid }
        }
    }
}
