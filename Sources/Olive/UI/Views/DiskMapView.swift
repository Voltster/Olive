import SwiftUI
import AppKit

public struct DiskItem: Identifiable {
    public var id: String { path }
    public let name: String
    public let path: String
    public let sizeBytes: UInt64
    public let isDirectory: Bool
}

public struct DiskMapView: View {
    @State private var diskItems: [DiskItem] = []
    @State private var isScanning: Bool = false
    @State private var selectedPath: String = FileManager.default.homeDirectoryForCurrentUser.path
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Disk Space Analyzer")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text("Explore folder storage and pinpoint large disk space consumers.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    scanCurrentDirectory()
                } label: {
                    HStack {
                        if isScanning {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(isScanning ? "Scanning..." : "Scan Folder")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accentOlive)
                .disabled(isScanning)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            // Path Breadcrumb
            HStack {
                Image(systemName: "folder")
                    .foregroundStyle(Theme.accentOlive)
                Text(selectedPath)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(1)
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
            .padding(.horizontal, 24)
            
            // Directory Breakdown List
            if isScanning {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Analyzing folder sizes...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if diskItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.accentOlive)
                    Text("Click 'Scan Folder' to explore disk usage.")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(diskItems) { item in
                    HStack {
                        Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                            .foregroundStyle(item.isDirectory ? Theme.accentOlive : Theme.accentCyan)
                        
                        Text(item.name)
                            .font(.system(.body, design: .rounded))
                        
                        Spacer()
                        
                        Text(ByteFormatter.format(item.sizeBytes))
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .monospacedDigit()
                        
                        Button {
                            NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: "")
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
        }
        .onAppear {
            if diskItems.isEmpty {
                scanCurrentDirectory()
            }
        }
    }
    
    private func scanCurrentDirectory() {
        isScanning = true
        let target = selectedPath
        
        Task.detached(priority: .userInitiated) {
            let fm = FileManager.default
            let url = URL(fileURLWithPath: target)
            var items: [DiskItem] = []
            
            if let contents = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) {
                for fileURL in contents {
                    let isDir = (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                    let size = CleanerService.shared.directorySize(at: fileURL)
                    
                    items.append(DiskItem(
                        name: fileURL.lastPathComponent,
                        path: fileURL.path,
                        sizeBytes: size,
                        isDirectory: isDir
                    ))
                }
            }
            
            let sorted = items.sorted { $0.sizeBytes > $1.sizeBytes }
            await MainActor.run {
                self.diskItems = sorted
                self.isScanning = false
            }
        }
    }
}
