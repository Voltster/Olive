import Foundation

public enum DevArtifactType: String, CaseIterable, Identifiable, Sendable {
    case nodeModules = "node_modules (JavaScript)"
    case nextBuild = ".next (Next.js)"
    case rustTarget = "target (Rust/Cargo)"
    case pythonVenv = "venv / .venv (Python)"
    case xcodeDerived = "DerivedData (Xcode)"
    case swiftBuild = ".build (SwiftPM)"
    case distBuild = "dist / build / out"
    case cocoaPods = "Pods (CocoaPods)"
    case gradleCache = ".gradle (Gradle)"
    case globalCache = "Global Tool Cache"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .nodeModules: return "shippingbox.fill"
        case .nextBuild: return "globe"
        case .rustTarget: return "gearshape.2.fill"
        case .pythonVenv: return "curlybraces"
        case .xcodeDerived: return "hammer.fill"
        case .swiftBuild: return "swift"
        case .distBuild: return "folder.badge.gearshape"
        case .cocoaPods: return "cube.box.fill"
        case .gradleCache: return "cylinder.split.1x2.fill"
        case .globalCache: return "server.rack"
        }
    }
}

public struct DevProjectArtifact: Identifiable, Sendable {
    public var id: String { path }
    public let projectName: String
    public let projectPath: String
    public let artifactType: DevArtifactType
    public let path: String
    public let sizeBytes: UInt64
    public let lastModified: Date
    public var isSelected: Bool
    public let isRecent: Bool // < 7 days
    
    public init(
        projectName: String,
        projectPath: String,
        artifactType: DevArtifactType,
        path: String,
        sizeBytes: UInt64,
        lastModified: Date = Date(),
        isSelected: Bool = true,
        isRecent: Bool = false
    ) {
        self.projectName = projectName
        self.projectPath = projectPath
        self.artifactType = artifactType
        self.path = path
        self.sizeBytes = sizeBytes
        self.lastModified = lastModified
        self.isSelected = isSelected
        self.isRecent = isRecent
    }
    
    public var daysSinceModified: Int {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.day], from: lastModified, to: Date())
        return max(0, comps.day ?? 0)
    }
}
