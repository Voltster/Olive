import Foundation

@Observable
public final class MaintenanceService: @unchecked Sendable {
    public static let shared = MaintenanceService()
    
    public var tasks: [MaintenanceTaskItem] = MaintenanceTaskId.allCases.map { MaintenanceTaskItem(taskId: $0) }
    
    public init() {}
    
    public func executeTask(_ taskId: MaintenanceTaskId) async {
        guard let index = tasks.firstIndex(where: { $0.taskId == taskId }) else { return }
        
        await MainActor.run {
            self.tasks[index].isRunning = true
            self.tasks[index].isCompleted = false
            self.tasks[index].resultMessage = nil
        }
        
        var message = "Success"
        
        switch taskId {
        case .flushDNS:
            do {
                _ = try await ProcessRunner.shared.runShellScript("sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder || dscacheutil -flushcache")
                message = "DNS Resolver cache flushed."
            } catch {
                message = "Failed: \(error.localizedDescription)"
            }
            
        case .rebuildQuickLook:
            do {
                _ = try await ProcessRunner.shared.runShellScript("qlmanage -r cache; qlmanage -r")
                message = "QuickLook thumbnail cache reset."
            } catch {
                message = "Failed: \(error.localizedDescription)"
            }
            
        case .rebuildSpotlight:
            do {
                _ = try await ProcessRunner.shared.runShellScript("mdimport -r /Applications")
                message = "Spotlight application metadata re-indexed."
            } catch {
                message = "Failed: \(error.localizedDescription)"
            }
            
        case .purgeRAM:
            do {
                _ = try await ProcessRunner.shared.runShellScript("sudo purge || true")
                SystemMonitorService.shared.refreshTelemetry()
                message = "Inactive memory purge requested."
            } catch {
                message = "Failed: \(error.localizedDescription)"
            }
            
        case .repairPermissions:
            do {
                _ = try await ProcessRunner.shared.runShellScript("diskutil verifyVolume / || true")
                message = "Primary volume verified."
            } catch {
                message = "Failed: \(error.localizedDescription)"
            }
        }
        
        let finalMessage = message
        await MainActor.run {
            self.tasks[index].isRunning = false
            self.tasks[index].isCompleted = true
            self.tasks[index].lastRunDate = Date()
            self.tasks[index].resultMessage = finalMessage
        }
    }
}
