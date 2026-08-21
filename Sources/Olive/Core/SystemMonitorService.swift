import Foundation
import Darwin
import IOKit.ps

@Observable
public final class SystemMonitorService: @unchecked Sendable {
    public static let shared = SystemMonitorService()
    
    public var currentTelemetry: SystemTelemetry = SystemTelemetry()
    public var isMonitoring: Bool = false
    
    private var timer: Timer?
    private var previousCPUInfo: processor_info_array_t?
    private var previousCPUInfoCount: mach_msg_type_number_t = 0
    private var previousNetInBytes: UInt64 = 0
    private var previousNetOutBytes: UInt64 = 0
    private var previousNetTimestamp: Date = Date()
    
    public init() {}
    
    public func startMonitoring(interval: TimeInterval = 2.0) {
        guard !isMonitoring else { return }
        isMonitoring = true
        refreshTelemetry()
        
        DispatchQueue.main.async { [weak self] in
            self?.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                self?.refreshTelemetry()
            }
        }
    }
    
    public func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
        if let previousCPUInfo = previousCPUInfo {
            let prevSize = vm_size_t(previousCPUInfoCount) * vm_size_t(MemoryLayout<integer_t>.size)
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: previousCPUInfo)), prevSize)
            self.previousCPUInfo = nil
            self.previousCPUInfoCount = 0
        }
    }
    
    public func refreshTelemetry() {
        let cpu = getCPUUsage()
        let memory = getMemoryUsage()
        let disk = getDiskUsage()
        let network = getNetworkThroughput()
        let battery = getBatteryInfo()
        let healthScore = calculateHealthScore(cpuUsage: cpu.total, memoryPercent: memory.usagePercent, diskPercent: disk.usagePercent)
        
        let telemetry = SystemTelemetry(
            cpuUsage: cpu.total,
            perCoreUsage: cpu.perCore,
            memoryUsedBytes: memory.used,
            memoryTotalBytes: memory.total,
            memoryFreeBytes: memory.free,
            memoryPressure: memory.pressure,
            diskUsedBytes: disk.used,
            diskTotalBytes: disk.total,
            diskFreeBytes: disk.free,
            diskReadBytesPerSec: 0,
            diskWriteBytesPerSec: 0,
            networkBytesInPerSec: network.bytesInPerSec,
            networkBytesOutPerSec: network.bytesOutPerSec,
            batteryLevel: battery.level,
            isCharging: battery.isCharging,
            fanSpeedRPM: nil,
            cpuTemperatureCelsius: nil,
            healthScore: healthScore,
            uptimeString: getUptimeString()
        )
        
        DispatchQueue.main.async {
            self.currentTelemetry = telemetry
        }
    }
    
    // MARK: - CPU Telemetry
    private func getCPUUsage() -> (total: Double, perCore: [Double]) {
        var numCPUsU: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0
        
        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUsU,
            &cpuInfo,
            &numCPUInfo
        )
        
        guard result == KERN_SUCCESS, let cpuInfo = cpuInfo else {
            return (0, [])
        }
        
        var perCore: [Double] = []
        var totalUsage: Double = 0
        let numCPUs = Int(numCPUsU)
        
        if let prevInfo = previousCPUInfo {
            for i in 0..<numCPUs {
                let inUse: Int32
                let total: Int32
                
                let base = i * Int(CPU_STATE_MAX)
                let user = cpuInfo[base + Int(CPU_STATE_USER)] - prevInfo[base + Int(CPU_STATE_USER)]
                let system = cpuInfo[base + Int(CPU_STATE_SYSTEM)] - prevInfo[base + Int(CPU_STATE_SYSTEM)]
                let nice = cpuInfo[base + Int(CPU_STATE_NICE)] - prevInfo[base + Int(CPU_STATE_NICE)]
                let idle = cpuInfo[base + Int(CPU_STATE_IDLE)] - prevInfo[base + Int(CPU_STATE_IDLE)]
                
                inUse = user + system + nice
                total = inUse + idle
                
                let corePercent: Double = total > 0 ? (Double(inUse) / Double(total)) * 100.0 : 0
                perCore.append(corePercent)
                totalUsage += corePercent
            }
            
            let prevSize = vm_size_t(previousCPUInfoCount) * vm_size_t(MemoryLayout<integer_t>.size)
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: prevInfo)), prevSize)
        }
        
        self.previousCPUInfo = cpuInfo
        self.previousCPUInfoCount = numCPUInfo
        
        let avgUsage = numCPUs > 0 ? (totalUsage / Double(numCPUs)) : 0
        return (min(100.0, max(0.0, avgUsage)), perCore)
    }
    
    // MARK: - Memory Telemetry
    private func getMemoryUsage() -> (used: UInt64, total: UInt64, free: UInt64, usagePercent: Double, pressure: MemoryPressureLevel) {
        let hostPort = mach_host_self()
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var vmStats = vm_statistics64()
        
        let totalMem = ProcessInfo.processInfo.physicalMemory
        let kerr = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &size)
            }
        }
        
        guard kerr == KERN_SUCCESS else {
            return (0, totalMem, totalMem, 0, .normal)
        }
        
        let pageSize = UInt64(vm_kernel_page_size)
        let active = UInt64(vmStats.active_count) * pageSize
        let wired = UInt64(vmStats.wire_count) * pageSize
        let compressed = UInt64(vmStats.compressor_page_count) * pageSize
        let free = UInt64(vmStats.free_count) * pageSize
        
        let used = active + wired + compressed
        let percent = totalMem > 0 ? (Double(used) / Double(totalMem)) * 100.0 : 0
        
        let pressure: MemoryPressureLevel
        if percent > 85.0 {
            pressure = .critical
        } else if percent > 70.0 {
            pressure = .warn
        } else {
            pressure = .normal
        }
        
        return (used, totalMem, free, percent, pressure)
    }
    
    // MARK: - Disk Telemetry
    private func getDiskUsage() -> (used: UInt64, total: UInt64, free: UInt64, usagePercent: Double) {
        var stat = statfs()
        guard statfs("/", &stat) == 0 else {
            return (0, 0, 0, 0)
        }
        
        let blockSize = UInt64(stat.f_bsize)
        let total = UInt64(stat.f_blocks) * blockSize
        let free = UInt64(stat.f_bavail) * blockSize
        let used = total > free ? total - free : 0
        let percent = total > 0 ? (Double(used) / Double(total)) * 100.0 : 0
        
        return (used, total, free, percent)
    }
    
    // MARK: - Network Telemetry
    private func getNetworkThroughput() -> (bytesInPerSec: Double, bytesOutPerSec: Double) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return (0, 0)
        }
        defer { freeifaddrs(ifaddr) }
        
        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0
        
        var cursor: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let ptr = cursor {
            let name = String(cString: ptr.pointee.ifa_name)
            if (ptr.pointee.ifa_flags & UInt32(IFF_LOOPBACK)) == 0 && (name.hasPrefix("en") || name.hasPrefix("wl")) {
                if let data = ptr.pointee.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self)
                    totalIn += UInt64(networkData.pointee.ifi_ibytes)
                    totalOut += UInt64(networkData.pointee.ifi_obytes)
                }
            }
            cursor = ptr.pointee.ifa_next
        }
        
        let now = Date()
        let elapsed = now.timeIntervalSince(previousNetTimestamp)
        var inRate: Double = 0
        var outRate: Double = 0
        
        if elapsed > 0 && previousNetInBytes > 0 {
            let deltaIn = totalIn >= previousNetInBytes ? totalIn - previousNetInBytes : 0
            let deltaOut = totalOut >= previousNetOutBytes ? totalOut - previousNetOutBytes : 0
            inRate = Double(deltaIn) / elapsed
            outRate = Double(deltaOut) / elapsed
        }
        
        previousNetInBytes = totalIn
        previousNetOutBytes = totalOut
        previousNetTimestamp = now
        
        return (inRate, outRate)
    }
    
    // MARK: - Battery Telemetry
    private func getBatteryInfo() -> (level: Double?, isCharging: Bool?) {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              !sources.isEmpty else {
            return (nil, nil)
        }
        
        for ps in sources {
            guard let desc = IOPSGetPowerSourceDescription(snapshot, ps)?.takeUnretainedValue() as? [String: Any] else { continue }
            if let current = desc[kIOPSCurrentCapacityKey as String] as? Int,
               let max = desc[kIOPSMaxCapacityKey as String] as? Int,
               max > 0 {
                let percent = (Double(current) / Double(max)) * 100.0
                let isCharging = desc[kIOPSIsChargingKey as String] as? Bool ?? false
                return (percent, isCharging)
            }
        }
        return (nil, nil)
    }
    
    private func calculateHealthScore(cpuUsage: Double, memoryPercent: Double, diskPercent: Double) -> Int {
        var score: Double = 100.0
        
        if cpuUsage > 80 {
            score -= (cpuUsage - 80) * 0.8
        } else if cpuUsage > 50 {
            score -= (cpuUsage - 50) * 0.3
        }
        
        if memoryPercent > 85 {
            score -= (memoryPercent - 85) * 1.0
        } else if memoryPercent > 70 {
            score -= (memoryPercent - 70) * 0.4
        }
        
        if diskPercent > 90 {
            score -= (diskPercent - 90) * 1.5
        } else if diskPercent > 75 {
            score -= (diskPercent - 75) * 0.5
        }
        
        return max(10, min(100, Int(score)))
    }
    
    private func getUptimeString() -> String {
        var boottime = timeval()
        var size = MemoryLayout<timeval>.size
        var mib = [CTL_KERN, KERN_BOOTTIME]
        
        guard sysctl(&mib, 2, &boottime, &size, nil, 0) == 0 else {
            return "Unknown"
        }
        
        let now = Date().timeIntervalSince1970
        let uptimeSeconds = Int(now) - boottime.tv_sec
        
        let days = uptimeSeconds / 86400
        let hours = (uptimeSeconds % 86400) / 3600
        let minutes = (uptimeSeconds % 3600) / 60
        
        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
