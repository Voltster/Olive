import SwiftUI
import AppKit

public enum DiskViewMode: String, CaseIterable, Identifiable {
    case sunburst = "Radial Map"
    case largeFiles = "Large & Old Files"
    
    public var id: String { rawValue }
}

public struct DiskMapView: View {
    @State private var viewMode: DiskViewMode = .sunburst
    @State private var rootNode: DiskNode?
    @State private var currentNode: DiskNode?
    @State private var isScanning: Bool = false
    @State private var largeFiles: [DiskItem] = []
    
    private let homePath = FileManager.default.homeDirectoryForCurrentUser.path
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with View Mode Switcher
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Disk Space Analyzer")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text("Explore disk space interactively with radial maps and find space hogs.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Picker("", selection: $viewMode) {
                    ForEach(DiskViewMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 250)
                
                Button {
                    startScan(path: homePath)
                } label: {
                    HStack(spacing: 6) {
                        if isScanning {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(isScanning ? "Scanning..." : "Rescan")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accentOlive)
                .disabled(isScanning)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            // Breadcrumbs Navigation
            if let current = currentNode {
                breadcrumbsBar(for: current)
                    .padding(.horizontal, 24)
            }
            
            // Content Body
            if isScanning {
                VStack(spacing: 14) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Mapping folder hierarchy and measuring disk sectors...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let current = currentNode {
                if viewMode == .sunburst {
                    sunburstLayout(current: current)
                } else {
                    largeFilesLayout
                }
            } else {
                emptyState
            }
        }
        .onAppear {
            if rootNode == nil {
                startScan(path: homePath)
            }
        }
    }
    
    // MARK: - Breadcrumbs Bar
    private func breadcrumbsBar(for node: DiskNode) -> some View {
        var trail: [DiskNode] = []
        var curr: DiskNode? = node
        while let c = curr {
            trail.insert(c, at: 0)
            curr = c.parent
        }
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(trail.enumerated()), id: \.offset) { index, n in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            currentNode = n
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if index == 0 {
                                Image(systemName: "house.fill")
                                    .font(.caption2)
                            }
                            Text(n.name.isEmpty ? "Root" : n.name)
                                .font(.caption.bold())
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(index == trail.count - 1 ? Theme.accentOlive : .secondary)
                    
                    if index < trail.count - 1 {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
        }
    }
    
    // MARK: - Radial Sunburst Layout
    private func sunburstLayout(current: DiskNode) -> some View {
        HStack(spacing: 20) {
            // Sunburst Visualizer Canvas
            VStack {
                SunburstChartView(rootNode: current) { tappedNode in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        currentNode = tappedNode
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(16)
            }
            .glassCard()
            
            // Side Folder List
            VStack(alignment: .leading, spacing: 10) {
                Text("Contents of \(current.name.isEmpty ? "Home" : current.name)")
                    .font(.headline)
                
                List(current.children) { child in
                    HStack(spacing: 12) {
                        Image(systemName: child.isDirectory ? "folder.fill" : "doc.fill")
                            .foregroundStyle(child.isDirectory ? Theme.accentOlive : Theme.accentCyan)
                            .frame(width: 18)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(child.name)
                                .font(.system(.body, design: .rounded))
                                .lineLimit(1)
                            
                            Text(String(format: "%.1f%% of folder", child.percentageOfParent))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(ByteFormatter.format(child.sizeBytes))
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .monospacedDigit()
                        
                        if child.isDirectory && !child.children.isEmpty {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    currentNode = child
                                }
                            } label: {
                                Image(systemName: "chevron.right.circle.fill")
                                    .foregroundStyle(Theme.accentOlive)
                            }
                            .buttonStyle(.plain)
                            .help("Drill into folder")
                        }
                        
                        Button {
                            NSWorkspace.shared.selectFile(child.path, inFileViewerRootedAtPath: "")
                        } label: {
                            Image(systemName: "arrow.up.forward.square")
                        }
                        .buttonStyle(.plain)
                        .help("Reveal in Finder")
                    }
                    .padding(.vertical, 2)
                }
                .listStyle(.plain)
            }
            .frame(width: 340)
            .glassCard()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    
    // MARK: - Large Files Layout
    private var largeFilesLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Large Files Found (>100 MB)")
                    .font(.headline)
                Spacer()
                Text("\(largeFiles.count) files")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            
            if largeFiles.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.accentSage)
                    Text("No extraordinarily large files discovered.")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(largeFiles) { file in
                    HStack(spacing: 14) {
                        Image(systemName: "doc.fill")
                            .foregroundStyle(Theme.accentRose)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(file.name)
                                .font(.system(.body, design: .rounded, weight: .medium))
                            Text(file.path)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Text(ByteFormatter.format(file.sizeBytes))
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(Theme.accentAmber)
                            .monospacedDigit()
                        
                        Button {
                            NSWorkspace.shared.selectFile(file.path, inFileViewerRootedAtPath: "")
                        } label: {
                            Image(systemName: "arrow.up.forward.square")
                        }
                        .buttonStyle(.plain)
                        .help("Reveal in Finder")
                        
                        Button {
                            try? FileManager.default.trashItem(at: URL(fileURLWithPath: file.path), resultingItemURL: nil)
                            largeFiles.removeAll { $0.id == file.id }
                        } label: {
                            Image(systemName: "trash.fill")
                                .foregroundStyle(Theme.accentRose)
                        }
                        .buttonStyle(.plain)
                        .help("Move to Trash")
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
        }
        .padding(.bottom, 24)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "circle.grid.cross.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accentOlive)
            
            Text("No Disk Data Loaded")
                .font(.title2.bold())
            
            Button("Scan Home Directory") {
                startScan(path: homePath)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accentOlive)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Multi-Level Directory Scanner
    private func startScan(path: String) {
        isScanning = true
        
        Task.detached(priority: .userInitiated) {
            let root = DiskNode(name: "Home", path: path, isDirectory: true)
            var bigFiles: [DiskItem] = []
            
            Self.buildTree(node: root, depth: 0, maxDepth: 2, bigFiles: &bigFiles)
            
            let finalBigFiles = bigFiles.sorted { $0.sizeBytes > $1.sizeBytes }
            await MainActor.run {
                self.rootNode = root
                self.currentNode = root
                self.largeFiles = finalBigFiles
                self.isScanning = false
            }
        }
    }
    
    nonisolated private static func buildTree(node: DiskNode, depth: Int, maxDepth: Int, bigFiles: inout [DiskItem]) {
        let fm = FileManager.default
        let url = URL(fileURLWithPath: node.path)
        
        guard let contents = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        
        var totalSize: UInt64 = 0
        var children: [DiskNode] = []
        
        for itemURL in contents {
            let isDir = (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            let size = CleanerService.shared.directorySize(at: itemURL)
            
            if size > 1_000_000 { // Only track items > 1MB
                let child = DiskNode(
                    name: itemURL.lastPathComponent,
                    path: itemURL.path,
                    isDirectory: isDir,
                    sizeBytes: size,
                    parent: node
                )
                
                if isDir && depth < maxDepth {
                    buildTree(node: child, depth: depth + 1, maxDepth: maxDepth, bigFiles: &bigFiles)
                } else if !isDir && size > 100_000_000 { // > 100MB
                    bigFiles.append(DiskItem(
                        name: itemURL.lastPathComponent,
                        path: itemURL.path,
                        sizeBytes: size,
                        isDirectory: false
                    ))
                }
                
                children.append(child)
                totalSize += size
            }
        }
        
        node.children = children.sorted { $0.sizeBytes > $1.sizeBytes }
        node.sizeBytes = max(node.sizeBytes, totalSize)
    }
}
