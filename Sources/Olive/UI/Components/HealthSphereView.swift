import SwiftUI

public struct HealthSphereView: View {
    public var healthScore: Int
    public var size: CGFloat = 84
    
    @State private var phase: Double = 0
    
    public init(healthScore: Int, size: CGFloat = 84) {
        self.healthScore = healthScore
        self.size = size
    }
    
    public var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let radius = min(canvasSize.width, canvasSize.height) / 2.2
            
            // 1. Ambient Background Aura
            let auraRect = CGRect(x: center.x - radius * 1.35, y: center.y - radius * 1.35, width: radius * 2.7, height: radius * 2.7)
            let auraGradient = Gradient(colors: [
                Theme.accentOlive.opacity(0.35),
                Theme.accentSage.opacity(0.12),
                Color.clear
            ])
            context.fill(Path(ellipseIn: auraRect), with: .radialGradient(auraGradient, center: center, startRadius: radius * 0.5, endRadius: radius * 1.35))
            
            // 2. Solar Sphere Base
            let sphereRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            let baseGradient = Gradient(colors: [
                Color(red: 0.98, green: 0.85, blue: 0.25), // Bright Solar Core
                Color(red: 0.92, green: 0.55, blue: 0.12), // Deep Orange Mantle
                Color(red: 0.75, green: 0.25, blue: 0.08)  // Crust Edge
            ])
            context.fill(Path(ellipseIn: sphereRect), with: .radialGradient(baseGradient, center: CGPoint(x: center.x - radius * 0.3, y: center.y - radius * 0.3), startRadius: 2, endRadius: radius))
            
            // 3. Solar Flare Flares / Spots
            for i in 0..<8 {
                let angle = Double(i) * (.pi / 4.0) + phase
                let spotOffset = radius * 0.55
                let spotCenter = CGPoint(
                    x: center.x + CGFloat(cos(angle)) * spotOffset,
                    y: center.y + CGFloat(sin(angle)) * spotOffset
                )
                let spotRect = CGRect(x: spotCenter.x - radius * 0.22, y: spotCenter.y - radius * 0.22, width: radius * 0.44, height: radius * 0.44)
                context.fill(Path(ellipseIn: spotRect), with: .color(Color(red: 1.0, green: 0.95, blue: 0.60).opacity(0.25)))
            }
            
            // 4. Specular Atmospheric Rim
            let rimPath = Path(ellipseIn: sphereRect)
            context.stroke(rimPath, with: .color(Color.white.opacity(0.45)), lineWidth: 1.5)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}
