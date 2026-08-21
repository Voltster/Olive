import SwiftUI
import AppKit

public struct CleanerView: View {
    @Bindable var cleanerService = CleanerService.shared
    @State private var selectedCategoryForReview: ScanCategorySummary?
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
                        HStack(spacing: 6) {
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
        .sheet(item: $selectedCategoryForReview) { summary in
            categoryDetailSheet(summary: summary)
        }
        .alert("Cleanup Complete!", isPresented: $showingCelebration) {
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
                Text("\(summary.items.count) items · \(ByteFormatter.format(summary.totalSizeBytes))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                selectedCategoryForReview = summary
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                    Text("Inspect")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
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
    
    private func categoryDetailSheet(summary: ScanCategorySummary) -> some View {
        guard let currentIdx = cleanerService.summaries.firstIndex(where: { $0.category == summary.category }) else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: summary.category.iconName)
                        .font(.title)
                        .foregroundStyle(Theme.accentOlive)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(summary.category.rawValue)
                            .font(.title2.bold())
                        Text(summary.category.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Done") {
                        selectedCategoryForReview = nil
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accentOlive)
                }
                
                HStack {
                    Text("\(cleanerService.summaries[currentIdx].items.count) items found · Selected: \(ByteFormatter.format(cleanerService.summaries[currentIdx].selectedSizeBytes))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button("Select All") {
                        for i in 0..<cleanerService.summaries[currentIdx].items.count {
                            cleanerService.summaries[currentIdx].items[i].isSelected = true
                        }
                        cleanerService.summaries[currentIdx].isSelected = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("Deselect All") {
                        for i in 0..<cleanerService.summaries[currentIdx].items.count {
                            cleanerService.summaries[currentIdx].items[i].isSelected = false
                        }
                        cleanerService.summaries[currentIdx].isSelected = false
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                Divider()
                
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(0..<cleanerService.summaries[currentIdx].items.count, id: \.self) { itemIdx in
                            let item = cleanerService.summaries[currentIdx].items[itemIdx]
                            HStack(spacing: 12) {
                                Toggle("", isOn: Binding(
                                    get: { cleanerService.summaries[currentIdx].items[itemIdx].isSelected },
                                    set: { val in
                                        cleanerService.summaries[currentIdx].items[itemIdx].isSelected = val
                                    }
                                ))
                                .toggleStyle(.checkbox)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.system(.body, design: .rounded, weight: .semibold))
                                    Text(item.path)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Text(ByteFormatter.format(item.sizeBytes))
                                    .font(.caption.monospacedDigit().bold())
                                
                                Button {
                                    NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: "")
                                } label: {
                                    Image(systemName: "arrow.up.forward.square")
                                }
                                .buttonStyle(.plain)
                                .help("Reveal in Finder")
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
                        }
                    }
                }
                .frame(maxHeight: 340)
            }
            .padding(24)
            .frame(minWidth: 580, minHeight: 480)
        )
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
