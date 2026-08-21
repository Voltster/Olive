import SwiftUI
import AppKit

public struct AppIconView: View {
    public let path: String
    public let size: CGFloat
    
    public init(path: String, size: CGFloat = 36) {
        self.path = path
        self.size = size
    }
    
    public var body: some View {
        if FileManager.default.fileExists(atPath: path) {
            let nsImage = NSWorkspace.shared.icon(forFile: path)
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            Image(systemName: "app.dashed")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundStyle(Theme.accentOlive)
        }
    }
}
