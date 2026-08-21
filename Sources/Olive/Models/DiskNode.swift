import Foundation

public final class DiskNode: Identifiable, @unchecked Sendable {
    public let id: UUID
    public let name: String
    public let path: String
    public let isDirectory: Bool
    public var sizeBytes: UInt64
    public var children: [DiskNode]
    public weak var parent: DiskNode?
    
    public init(
        name: String,
        path: String,
        isDirectory: Bool,
        sizeBytes: UInt64 = 0,
        children: [DiskNode] = [],
        parent: DiskNode? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.sizeBytes = sizeBytes
        self.children = children
        self.parent = parent
    }
    
    public var percentageOfParent: Double {
        guard let parent = parent, parent.sizeBytes > 0 else { return 100.0 }
        return (Double(sizeBytes) / Double(parent.sizeBytes)) * 100.0
    }
}

public struct DiskItem: Identifiable, Sendable {
    public var id: String { path }
    public let name: String
    public let path: String
    public let sizeBytes: UInt64
    public let isDirectory: Bool
    
    public init(name: String, path: String, sizeBytes: UInt64, isDirectory: Bool) {
        self.name = name
        self.path = path
        self.sizeBytes = sizeBytes
        self.isDirectory = isDirectory
    }
}
