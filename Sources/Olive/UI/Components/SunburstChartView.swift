import SwiftUI

public struct SunburstSlice: Identifiable {
    public var id: UUID { node.id }
    public let node: DiskNode
    public let level: Int // 1 or 2
    public let startAngle: Angle
    public let endAngle: Angle
    public let color: Color
}

public struct SunburstChartView: View {
    public let rootNode: DiskNode
    public let onSelectNode: (DiskNode) -> Void
    
    @State private var hoveredNode: DiskNode?
    @State private var hoverLocation: CGPoint = .zero
    
    private let sliceColors: [Color] = [
        Theme.accentOlive,
        Theme.accentSage,
        Theme.accentCyan,
        Theme.accentViolet,
        Theme.accentAmber,
        Theme.accentRose,
        Color(red: 0.2, green: 0.6, blue: 0.9),
        Color(red: 0.9, green: 0.4, blue: 0.8),
        Color(red: 0.4, green: 0.8, blue: 0.3)
    ]
    
    public init(rootNode: DiskNode, onSelectNode: @escaping (DiskNode) -> Void) {
        self.rootNode = rootNode
        self.onSelectNode = onSelectNode
    }
    
    public var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size / 2 * 0.92
            
            let centerRadius = radius * 0.32
            let ring1Radius = radius * 0.64
            let ring2Radius = radius * 0.96
            
            let slices = computeSlices(center: center, centerRadius: centerRadius, ring1Radius: ring1Radius, ring2Radius: ring2Radius)
            
            ZStack {
                // Canvas drawing for high performance 60fps rendering
                Canvas { context, canvasSize in
                    for slice in slices {
                        var path = Path()
                        let innerR = slice.level == 1 ? centerRadius : ring1Radius
                        let outerR = slice.level == 1 ? ring1Radius : ring2Radius
                        
                        path.addArc(
                            center: center,
                            radius: outerR,
                            startAngle: slice.startAngle,
                            endAngle: slice.endAngle,
                            clockwise: false
                        )
                        path.addArc(
                            center: center,
                            radius: innerR,
                            startAngle: slice.endAngle,
                            endAngle: slice.startAngle,
                            clockwise: true
                        )
                        path.closeSubpath()
                        
                        let isHovered = hoveredNode?.id == slice.node.id
                        let fillColor = isHovered ? slice.color.opacity(0.95) : slice.color.opacity(0.72)
                        
                        context.fill(path, with: .color(fillColor))
                        context.stroke(path, with: .color(Theme.backgroundDark), lineWidth: 2)
                    }
                }
                
                // Center Circle (Current Root)
                Circle()
                    .fill(Theme.surfaceCard)
                    .overlay(Circle().stroke(Theme.borderSubtle, lineWidth: 1.5))
                    .frame(width: centerRadius * 2, height: centerRadius * 2)
                    .overlay(
                        VStack(spacing: 3) {
                            Text(rootNode.name.isEmpty ? "Root" : rootNode.name)
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .lineLimit(1)
                                .padding(.horizontal, 8)
                            
                            Text(ByteFormatter.format(rootNode.sizeBytes))
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .monospacedDigit()
                                .foregroundStyle(Theme.accentOlive)
                        }
                    )
                
                // Hover Tooltip / Detail Overlay
                if let hovered = hoveredNode {
                    VStack(spacing: 2) {
                        Text(hovered.name)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .lineLimit(1)
                        Text("\(ByteFormatter.format(hovered.sizeBytes)) · \(String(format: "%.1f%%", hovered.percentageOfParent))")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(Theme.accentOlive)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.backgroundDark.opacity(0.9)).overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.borderFocus, lineWidth: 1)))
                    .offset(y: -radius * 0.98)
                }
            }
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    hoverLocation = location
                    hoveredNode = findNode(at: location, center: center, slices: slices, centerRadius: centerRadius, ring2Radius: ring2Radius)
                case .ended:
                    hoveredNode = nil
                }
            }
            .onTapGesture {
                if let hovered = hoveredNode, hovered.isDirectory && !hovered.children.isEmpty {
                    onSelectNode(hovered)
                }
            }
        }
    }
    
    private func computeSlices(
        center: CGPoint,
        centerRadius: CGFloat,
        ring1Radius: CGFloat,
        ring2Radius: CGFloat
    ) -> [SunburstSlice] {
        var slices: [SunburstSlice] = []
        guard rootNode.sizeBytes > 0 else { return [] }
        
        var currentAngle = Angle.degrees(0)
        let totalSize = Double(rootNode.sizeBytes)
        
        for (i, child) in rootNode.children.enumerated() {
            let proportion = Double(child.sizeBytes) / totalSize
            let sweepDegrees = proportion * 360.0
            let endAngle = currentAngle + Angle.degrees(sweepDegrees)
            let color = sliceColors[i % sliceColors.count]
            
            if sweepDegrees > 1.0 { // Skip micro slivers < 1 deg
                slices.append(SunburstSlice(
                    node: child,
                    level: 1,
                    startAngle: currentAngle,
                    endAngle: endAngle,
                    color: color
                ))
                
                // Ring 2: Grandchildren
                if child.isDirectory && child.sizeBytes > 0 && !child.children.isEmpty {
                    var grandCurrentAngle = currentAngle
                    let childTotal = Double(child.sizeBytes)
                    for (gi, grandChild) in child.children.enumerated() {
                        let gProportion = Double(grandChild.sizeBytes) / childTotal
                        let gSweep = gProportion * sweepDegrees
                        let gEnd = grandCurrentAngle + Angle.degrees(gSweep)
                        
                        if gSweep > 1.5 {
                            slices.append(SunburstSlice(
                                node: grandChild,
                                level: 2,
                                startAngle: grandCurrentAngle,
                                endAngle: gEnd,
                                color: color.opacity(0.85 - Double(gi % 3) * 0.15)
                            ))
                        }
                        grandCurrentAngle = gEnd
                    }
                }
            }
            
            currentAngle = endAngle
        }
        
        return slices
    }
    
    private func findNode(
        at point: CGPoint,
        center: CGPoint,
        slices: [SunburstSlice],
        centerRadius: CGFloat,
        ring2Radius: CGFloat
    ) -> DiskNode? {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        
        guard distance >= centerRadius && distance <= ring2Radius else {
            return nil
        }
        
        var angleRad = atan2(dy, dx)
        if angleRad < 0 {
            angleRad += 2 * .pi
        }
        let angleDeg = angleRad * 180.0 / .pi
        
        for slice in slices {
            let startDeg = slice.startAngle.degrees.truncatingRemainder(dividingBy: 360)
            let endDeg = slice.endAngle.degrees.truncatingRemainder(dividingBy: 360)
            
            let matchLevel = (slice.level == 1 && distance < (centerRadius + (ring2Radius - centerRadius) * 0.5)) ||
                             (slice.level == 2 && distance >= (centerRadius + (ring2Radius - centerRadius) * 0.5))
            
            if matchLevel {
                if startDeg <= endDeg {
                    if angleDeg >= startDeg && angleDeg <= endDeg {
                        return slice.node
                    }
                } else { // Wraps around 360
                    if angleDeg >= startDeg || angleDeg <= endDeg {
                        return slice.node
                    }
                }
            }
        }
        
        return nil
    }
}
