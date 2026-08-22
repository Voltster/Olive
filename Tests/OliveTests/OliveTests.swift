#if canImport(XCTest)
import XCTest
@testable import Olive

final class OliveTests: XCTestCase {
    
    func testByteFormatter() {
        let formatted1GB = ByteFormatter.format(1_000_000_000, isMemory: false)
        XCTAssertTrue(formatted1GB.contains("GB") || formatted1GB.contains("1"))
        
        let formattedMem = ByteFormatter.format(1_073_741_824, isMemory: true)
        XCTAssertTrue(formattedMem.contains("GB") || formattedMem.contains("1"))
    }
    
    func testCleanupReport() {
        let report = CleanupReport(bytesFreed: 500_000_000, itemsRemovedCount: 42, errors: [])
        XCTAssertEqual(report.bytesFreed, 500_000_000)
        XCTAssertEqual(report.itemsRemovedCount, 42)
        XCTAssertTrue(report.errors.isEmpty)
    }
    
    func testDeveloperArtifactDays() {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -8, to: Date()) ?? Date()
        let artifact = DevProjectArtifact(
            projectName: "TestProject",
            projectPath: "/Users/test/TestProject",
            artifactType: .nodeModules,
            path: "/Users/test/TestProject/node_modules",
            sizeBytes: 150_000_000,
            lastModified: oneWeekAgo,
            isSelected: true,
            isRecent: false
        )
        
        XCTAssertGreaterThanOrEqual(artifact.daysSinceModified, 7)
        XCTAssertFalse(artifact.isRecent)
    }
    
    func testStartupItem() {
        let item = StartupItem(
            name: "Test Daemon",
            label: "com.test.daemon",
            path: "/Library/LaunchAgents/com.test.daemon.plist",
            locationType: .systemAgent,
            programPath: "/usr/local/bin/test",
            isEnabled: true
        )
        
        XCTAssertEqual(item.name, "Test Daemon")
        XCTAssertEqual(item.label, "com.test.daemon")
        XCTAssertTrue(item.isEnabled)
    }
}
#endif
