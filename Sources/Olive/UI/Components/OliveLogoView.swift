import SwiftUI

public struct OliveLogoView: View {
    public var size: CGFloat
    public var glow: Bool
    
    public init(size: CGFloat = 28, glow: Bool = true) {
        self.size = size
        self.glow = glow
    }
    
    public var body: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            let scale = min(w, h) / 100.0
            
            // 1. Shadow / Glow
            if glow {
                let glowRect = CGRect(x: 10 * scale, y: 15 * scale, width: 80 * scale, height: 80 * scale)
                context.fill(Path(ellipseIn: glowRect), with: .color(Theme.accentOlive.opacity(0.2)))
            }
            
            // 2. Olive Fruit Body (Tilted Smooth Oval)
            var olivePath = Path()
            let oliveRect = CGRect(x: 22 * scale, y: 25 * scale, width: 56 * scale, height: 65 * scale)
            olivePath.addEllipse(in: oliveRect)
            
            let oliveGradient = Gradient(colors: [
                Color(red: 0.65, green: 0.88, blue: 0.18), // Bright Lime Glow
                Color(red: 0.40, green: 0.65, blue: 0.08), // Rich Olive
                Color(red: 0.22, green: 0.40, blue: 0.05)  // Deep Forest Olive
            ])
            
            context.fill(
                olivePath,
                with: .linearGradient(
                    oliveGradient,
                    startPoint: CGPoint(x: 35 * scale, y: 25 * scale),
                    endPoint: CGPoint(x: 65 * scale, y: 90 * scale)
                )
            )
            
            // 3. Gloss Reflection
            var glossPath = Path()
            let glossRect = CGRect(x: 30 * scale, y: 35 * scale, width: 16 * scale, height: 26 * scale)
            glossPath.addEllipse(in: glossRect)
            context.fill(glossPath, with: .color(Color.white.opacity(0.35)))
            
            // 4. Stem & Leaf
            var leafPath = Path()
            leafPath.move(to: CGPoint(x: 50 * scale, y: 28 * scale))
            leafPath.addQuadCurve(
                to: CGPoint(x: 82 * scale, y: 12 * scale),
                control: CGPoint(x: 62 * scale, y: 10 * scale)
            )
            leafPath.addQuadCurve(
                to: CGPoint(x: 50 * scale, y: 28 * scale),
                control: CGPoint(x: 70 * scale, y: 26 * scale)
            )
            
            let leafGradient = Gradient(colors: [
                Color(red: 0.52, green: 0.82, blue: 0.15),
                Color(red: 0.28, green: 0.55, blue: 0.08)
            ])
            
            context.fill(
                leafPath,
                with: .linearGradient(
                    leafGradient,
                    startPoint: CGPoint(x: 50 * scale, y: 28 * scale),
                    endPoint: CGPoint(x: 82 * scale, y: 12 * scale)
                )
            )
        }
        .frame(width: size, height: size)
    }
}
