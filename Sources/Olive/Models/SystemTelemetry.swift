import Foundation

public struct SystemTelemetry: Codable, Sendable {
    public var cpuUsage: Double // 0.0 - 100.0%
    public var perCoreUsage: [Double]
    public var memoryUsedBytes: UInt64
    public var memoryTotalBytes: UInt64
    public var memoryFreeBytes: UInt64
    public var memoryPressure: MemoryPressureLevel
    
    public var diskUsedBytes: UInt64
    public var diskTotalBytes: UInt64
    public var diskFreeBytes: UInt64
    public var diskReadBytesPerSec: Double
    public var diskWriteBytesPerSec: Double
    
    public var networkBytesInPerSec: Double
    public var networkBytesOutPerSec: Double
    
    public var batteryLevel: Double? // 0.0 - 100.0%
    public var isCharging: Bool?
    public var fanSpeedRPM: Int?
    public var cpuTemperatureCelsius: Double?
    
    public var healthScore: Int // 0 - 100
    public var uptimeString: String
    
    public init(
        cpuUsage: Double = 0,
        perCoreUsage: [Double] = [],
        memoryUsedBytes: UInt64 = 0,
        memoryTotalBytes: UInt64 = 0,
        memoryFreeBytes: UInt64 = 0,
        memoryPressure: MemoryPressureLevel = .normal,
        diskUsedBytes: UInt64 = 0,
        diskTotalBytes: UInt64 = 0,
        diskFreeBytes: UInt64 = 0,
        diskReadBytesPerSec: Double = 0,
        diskWriteBytesPerSec: Double = 0,
        networkBytesInPerSec: Double = 0,
        networkBytesOutPerSec: Double = 0,
        batteryLevel: Double? = nil,
        isCharging: Bool? = nil,
        fanSpeedRPM: Int? = nil,
        cpuTemperatureCelsius: Double? = nil,
        healthScore: Int = 100,
        uptimeString: String = "0m"
    ) {
        self.cpuUsage = cpuUsage
        self.perCoreUsage = perCoreUsage
        self.memoryUsedBytes = memoryUsedBytes
        self.memoryTotalBytes = memoryTotalBytes
        self.memoryFreeBytes = memoryFreeBytes
        self.memoryPressure = memoryPressure
        self.diskUsedBytes = diskUsedBytes
        self.diskTotalBytes = diskTotalBytes
        self.diskFreeBytes = diskFreeBytes
        self.diskReadBytesPerSec = diskReadBytesPerSec
        self.diskWriteBytesPerSec = diskWriteBytesPerSec
        self.networkBytesInPerSec = networkBytesInPerSec
        self.networkBytesOutPerSec = networkBytesOutPerSec
        self.batteryLevel = batteryLevel
        self.isCharging = isCharging
        self.fanSpeedRPM = fanSpeedRPM
        self.cpuTemperatureCelsius = cpuTemperatureCelsius
        self.healthScore = healthScore
        self.uptimeString = uptimeString
    }
    
    public var memoryUsagePercent: Double {
        guard memoryTotalBytes > 0 else { return 0 }
        return (Double(memoryUsedBytes) / Double(memoryTotalBytes)) * 100.0
    }
    
    public var diskUsagePercent: Double {
        guard diskTotalBytes > 0 else { return 0 }
        return (Double(diskUsedBytes) / Double(diskTotalBytes)) * 100.0
    }
}

public enum MemoryPressureLevel: String, Codable, Sendable {
    case normal = "Normal"
    case warn = "Warning"
    case critical = "Critical"
}
