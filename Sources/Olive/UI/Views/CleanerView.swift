import SwiftUI

public struct CleanerView: View {
    @Bindable var cleanerService = CleanerService.shared
    @State private var showingReviewSheet: Bool = false
    @State private var showingCelebration: Bool = false
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("System Cleanup")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        Text("Reclaim disk space safely. Inspect items and approve before cleaning.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        Task {
                            await cleanerService.scanAll()
                        }
                    } label: {
                        HStack {
                            if cleanerService.isScanning {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                            Text(cleanerService.isScanning ? "Scanning..." : "Scan Now")
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accentOlive)
                    .disabled(cleanerService.isScanning || cleanerService.isCleaning)
                }
                
                // Status Bar
                if cleanerService.isScanning {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(cleanerService.statusMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.0f%%", cleanerService.scanProgress * 100))
                                .font(.caption.monospacedDigit())
                        }
                        ProgressView(value: cleanerService.scanProgress)
                            .tint(Theme.accentOlive)
                    }
                    .glassCard()
                }
                
                // Results Grid
                if !cleanerService.summaries.isEmpty {
                    VStack(spacing: 14) {
                        ForEach(cleanerService.summaries) { summary in
                            categoryRow(summary: summary)
                        }
                    }
                    
                    // Bottom Clean Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Selected for Safe Removal")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(ByteFormatter.format(cleanerService.totalSelectedBytes))
                                .font(.system(.title, design: .rounded, weight: .bold))
                                .foregroundStyle(Theme.accentOlive)
                        }
                        
                        Spacer()
                        
                        Button {
                            Task {
                                let report = await cleanerService.cleanSelectedItems()
                                if report.bytesFreed > 0 {
                                    showingCelebration = true
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if cleanerService.isCleaning {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "trash.fill")
                                }
                                Text(cleanerService.isCleaning ? "Cleaning..." : "Clean Selected")
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.accentRose)
                        .disabled(cleanerService.totalSelectedBytes == 0 || cleanerService.isCleaning)
                    }
                    .glassCard(cornerRadius: 18)
                } else if !cleanerService.isScanning {
                    emptyScanPlaceholder
                }
            }
            .padding(24)
        }
        .alert("Cleanup Complete! 🫒", isPresented: $showingCelebration) {
            Button("Done", role: .cancel) {}
        } message: {
            if let report = cleanerService.lastReport {
                Text("Successfully freed \(ByteFormatter.format(report.bytesFreed)) across \(report.itemsRemovedCount) items. All files were moved safely to your macOS Trash.")
            }
        }
    }
    
    private func categoryRow(summary: ScanCategorySummary) -> some View {
        HStack(spacing: 16) {
            Image(systemName: summary.category.iconName)
                .font(.title2)
                .foregroundStyle(Theme.accentOlive)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.white.opacity(0.06)))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.category.rawValue)
                    .font(.system(.headline, design: .rounded))
                Text("\(summary.items.count) items found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(ByteFormatter.format(summary.totalSizeBytes))
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .monospacedDigit()
            
            Toggle("", isOn: Binding(
                get: { summary.isSelected },
                set: { newVal in
                    if let idx = cleanerService.summaries.firstIndex(where: { $0.category == summary.category }) {
                        cleanerService.summaries[idx].isSelected = newVal
                        for i in 0..<cleanerService.summaries[idx].items.count {
                            cleanerService.summaries[idx].items[i].isSelected = newVal
                        }
                    }
                }
            ))
            .toggleStyle(.switch)
            .tint(Theme.accentOlive)
        }
        .glassCard()
    }
    
    private var emptyScanPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accentOlive)
            
            Text("Ready to Clean Your Mac")
                .font(.system(.title2, design: .rounded, weight: .bold))
            
            Text("Click 'Scan Now' to safely discover caches, outdated logs, old Xcode DerivedData, and app remnants.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
            
            Button("Scan System Now") {
                Task {
                    await cleanerService.scanAll()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accentOlive)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .glassCard(cornerRadius: 18)
    }
}
