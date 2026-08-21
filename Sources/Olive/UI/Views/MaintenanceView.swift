import SwiftUI

public struct MaintenanceView: View {
    @Bindable var maintenance = MaintenanceService.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("macOS Maintenance")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text("Run built-in system repair scripts to optimize performance and fix system glitches.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                VStack(spacing: 14) {
                    ForEach(maintenance.tasks) { task in
                        taskCard(task: task)
                    }
                }
            }
            .padding(24)
        }
    }
    
    private func taskCard(task: MaintenanceTaskItem) -> some View {
        HStack(spacing: 16) {
            Image(systemName: task.taskId.iconName)
                .font(.title2)
                .foregroundStyle(Theme.accentOlive)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.white.opacity(0.06)))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.taskId.title)
                    .font(.system(.headline, design: .rounded))
                Text(task.taskId.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let msg = task.resultMessage {
                    Text(msg)
                        .font(.caption2.bold())
                        .foregroundStyle(task.isCompleted ? Theme.accentSage : Theme.accentAmber)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            Button {
                Task {
                    await maintenance.executeTask(task.taskId)
                }
            } label: {
                HStack(spacing: 6) {
                    if task.isRunning {
                        ProgressView().controlSize(.small)
                    } else if task.isCompleted {
                        Image(systemName: "checkmark")
                    }
                    Text(task.isRunning ? "Running..." : (task.isCompleted ? "Re-run" : "Execute"))
                }
                .frame(minWidth: 80)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accentOlive)
            .disabled(task.isRunning)
        }
        .glassCard()
    }
}
