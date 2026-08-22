import SwiftUI

public struct SunburstSlice: Identifiable {
    public var id: String { "\(node.id)-\(level)-\(startAngle.degrees)" }
    public let node: DiskNode
    public let level: Int // 1 or 2
    public let startAngle: Angle
    public let endAngle: Angle
    public let color: Color
    public let isOtherGroup: Bool
}

public struct SunburstChartView: View {
    public let rootNode: DiskNode
    public let onSelectNode: (DiskNode) -> Void
    
    @State private var hoveredSlice: SunburstSlice?
    @State private var hoverLocation: CGPoint = .zero
    @Environment(\.colorScheme) var colorScheme
    
    private let palette: [Color] = [
        Color(red: 0.52, green: 0.80, blue: 0.09), // Vibrant Olive (#84CC16)
        Color(red: 0.06, green: 0.73, blue: 0.51), // Fresh Emerald (#10B981)
        Color(red: 0.05, green: 0.65, blue: 0.91), // Sky Ocean (#0EA5E9)
        Color(red: 0.55, green: 0.36, blue: 0.96), // Nebula Violet (#8B5CF6)
        Color(red: 0.96, green: 0.62, blue: 0.04), // Warm Amber (#F59E0B)
        Color(red: 0.96, green: 0.25, blue: 0.37), // Neon Rose (#F43F5E)
        Color(red: 0.08, green: 0.72, blue: 0.65), // Mint Teal (#14B8A6)
        Color(red: 0.39, green: 0.40, blue: 0.95), // Royal Indigo (#6366F1)
        Color(red: 0.98, green: 0.45, blue: 0.09)  // Flame Orange (#F97316)
    ]
    
    public init(rootNode: DiskNode, onSelectNode: @escaping (DiskNode) -> Void) {
        self.rootNode = rootNode
        self.onSelectNode = onSelectNode
    }
    
    public var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size / 2 * 0.90
            
            let centerRadius = radius * 0.34
            let ring1Inner = centerRadius + 6
            let ring1Outer = radius * 0.64
            let ring2Inner = ring1Outer + 6
            let ring2Outer = radius * 0.96
            
            let slices = computeSlices(
                center: center,
                centerRadius: centerRadius,
                ring1Inner: ring1Inner,
                ring1Outer: ring1Outer,
                ring2Inner: ring2Inner,
                ring2Outer: ring2Outer
            )
            
            ZStack {
                // High-performance Canvas rendering with smooth sector gaps
                Canvas { context, canvasSize in
                    for slice in slices {
                        let isHovered = hoveredSlice?.node.id == slice.node.id
                        
                        let baseInner = slice.level == 1 ? ring1Inner : ring2Inner
                        let baseOuter = slice.level == 1 ? ring1Outer : ring2Outer
                        
                        // Expand hovered sector slightly outward for blooming effect
                        let innerR = isHovered ? baseInner - 1 : baseInner
                        let outerR = isHovered ? baseOuter + 4 : baseOuter
                        
                        // Apply angular padding to separate adjacent slices cleanly
                        let angularPadding = Angle.degrees(0.8)
                        let startA = slice.startAngle + angularPadding
                        let endA = slice.endAngle - angularPadding
                        
                        guard endA.degrees > startA.degrees else { continue }
                        
                        var path = Path()
                        path.addArc(
                            center: center,
                            radius: outerR,
                            startAngle: startA,
                            endAngle: endA,
                            clockwise: false
                        )
                        path.addArc(
                            center: center,
                            radius: innerR,
                            startAngle: endA,
                            endAngle: startA,
                            clockwise: true
                        )
                        path.closeSubpath()
                        
                        // Fill Color with gradient opacity
                        let sliceColor = slice.color
                        let fillOpacity = isHovered ? 1.0 : (slice.isOtherGroup ? 0.40 : 0.82)
                        
                        context.fill(path, with: .color(sliceColor.opacity(fillOpacity)))
                        
                        // Subtle illuminated border
                        let borderColor = isHovered
                            ? Color.white.opacity(0.8)
                            : (colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08))
                        context.stroke(path, with: .color(borderColor), lineWidth: isHovered ? 1.5 : 0.75)
                    }
                }
                
                // Center Hub (Glassmorphic Root Info)
                centerHub(centerRadius: centerRadius)
            }
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    hoverLocation = location
                    hoveredSlice = findSlice(
                        at: location,
                        center: center,
                        slices: slices,
                        ring1Inner: ring1Inner,
                        ring1Outer: ring1Outer,
                        ring2Inner: ring2Inner,
                        ring2Outer: ring2Outer
                    )
                case .ended:
                    hoveredSlice = nil
                }
            }
            .onTapGesture {
                if let slice = hoveredSlice, !slice.isOtherGroup, slice.node.isDirectory && !slice.node.children.isEmpty {
                    onSelectNode(slice.node)
                }
            }
        }
    }
    
    // MARK: - Center Hub
    private func centerHub(centerRadius: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Theme.surfaceCard(for: colorScheme))
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.08),
                    radius: 12,
                    x: 0,
                    y: 4
                )
                .overlay(
                    Circle().stroke(Theme.cardBorder(for: colorScheme), lineWidth: 1.5)
                )
                .frame(width: centerRadius * 2, height: centerRadius * 2)
            
            VStack(spacing: 4) {
                if let hovered = hoveredSlice?.node {
                    // Hover Details
                    Image(systemName: hovered.isDirectory ? "folder.fill" : "doc.fill")
                        .font(.caption)
                        .foregroundStyle(hoveredSlice?.color ?? Theme.accentOlive)
                    
                    Text(hovered.name)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                    
                    Text(ByteFormatter.format(hovered.sizeBytes))
                        .font(.system(.caption, design: .rounded, weight: .heavy))
                        .monospacedDigit()
                        .foregroundStyle(hoveredSlice?.color ?? Theme.accentOlive)
                    
                    Text("\(String(format: "%.1f%%", hovered.percentageOfParent))")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                } else {
                    // Current Directory Info
                    Image(systemName: "internaldrive.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.accentOlive)
                    
                    Text(rootNode.name.isEmpty ? "Root" : rootNode.name)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                    
                    Text(ByteFormatter.format(rootNode.sizeBytes))
                        .font(.system(.caption, design: .rounded, weight: .heavy))
                        .monospacedDigit()
                        .foregroundStyle(Theme.accentOlive)
                }
            }
        }
    }
    
    // MARK: - Compute Slices with Small-Item Aggregation
    private func computeSlices(
        center: CGPoint,
        centerRadius: CGFloat,
        ring1Inner: CGFloat,
        ring1Outer: CGFloat,
        ring2Inner: CGFloat,
        ring2Outer: CGFloat
    ) -> [SunburstSlice] {
        var slices: [SunburstSlice] = []
        guard rootNode.sizeBytes > 0 else { return [] }
        
        var currentAngle = Angle.degrees(0)
        let totalSize = Double(rootNode.sizeBytes)
        
        // Sort children largest to smallest
        let sortedChildren = rootNode.children.sorted { $0.sizeBytes > $1.sizeBytes }
        
        var otherChildren: [DiskNode] = []
        var otherBytes: UInt64 = 0
        
        for (i, child) in sortedChildren.enumerated() {
            let proportion = Double(child.sizeBytes) / totalSize
            let sweepDegrees = proportion * 360.0
            
            // If item is too small (< 2.5 degrees) or exceeds top 12 items, aggregate into "Other"
            if sweepDegrees < 2.5 || i >= 12 {
                otherChildren.append(child)
                otherBytes += child.sizeBytes
                continue
            }
            
            let endAngle = currentAngle + Angle.degrees(sweepDegrees)
            let baseColor = palette[i % palette.count]
            
            // Level 1 Ring Slice
            slices.append(SunburstSlice(
                node: child,
                level: 1,
                startAngle: currentAngle,
                endAngle: endAngle,
                color: baseColor,
                isOtherGroup: false
            ))
            
            // Level 2 Ring: Children of this branch
            if child.isDirectory && child.sizeBytes > 0 && !child.children.isEmpty {
                let sortedGrandchildren = child.children.sorted { $0.sizeBytes > $1.sizeBytes }
                var grandCurrentAngle = currentAngle
                let childTotal = Double(child.sizeBytes)
                
                var grandOtherBytes: UInt64 = 0
                
                for (gi, grandChild) in sortedGrandchildren.enumerated() {
                    let gProportion = Double(grandChild.sizeBytes) / childTotal
                    let gSweep = gProportion * sweepDegrees
                    
                    if gSweep < 2.0 || gi >= 8 {
                        grandOtherBytes += grandChild.sizeBytes
                        continue
                    }
                    
                    let gEnd = grandCurrentAngle + Angle.degrees(gSweep)
                    let shadeColor = baseColor.opacity(max(0.45, 0.90 - Double(gi) * 0.08))
                    
                    slices.append(SunburstSlice(
                        node: grandChild,
                        level: 2,
                        startAngle: grandCurrentAngle,
                        endAngle: gEnd,
                        color: shadeColor,
                        isOtherGroup: false
                    ))
                    grandCurrentAngle = gEnd
                }
                
                // Aggregate small grandchildren into a clean "Other" slice for this branch
                if grandOtherBytes > 0 {
                    let otherProportion = Double(grandOtherBytes) / childTotal
                    let otherSweep = otherProportion * sweepDegrees
                    if otherSweep >= 1.5 {
                        let otherNode = DiskNode(
                            name: "Other files (\(sortedGrandchildren.count) items)",
                            path: child.path,
                            isDirectory: false,
                            sizeBytes: grandOtherBytes,
                            parent: child
                        )
                        slices.append(SunburstSlice(
                            node: otherNode,
                            level: 2,
                            startAngle: grandCurrentAngle,
                            endAngle: endAngle,
                            color: baseColor.opacity(0.35),
                            isOtherGroup: true
                        ))
                    }
                }
            }
            
            currentAngle = endAngle
        }
        
        // Aggregate top-level small items into a single smooth "Other" slice
        if otherBytes > 0 {
            let otherProportion = Double(otherBytes) / totalSize
            let otherSweep = otherProportion * 360.0
            if otherSweep >= 2.0 {
                let otherRootNode = DiskNode(
                    name: "Other items (\(otherChildren.count) folders/files)",
                    path: rootNode.path,
                    isDirectory: false,
                    sizeBytes: otherBytes,
                    parent: rootNode
                )
                slices.append(SunburstSlice(
                    node: otherRootNode,
                    level: 1,
                    startAngle: currentAngle,
                    endAngle: Angle.degrees(360),
                    color: Color.gray.opacity(0.4),
                    isOtherGroup: true
                ))
            }
        }
        
        return slices
    }
    
    // MARK: - Find Hovered Slice
    private func findSlice(
        at point: CGPoint,
        center: CGPoint,
        slices: [SunburstSlice],
        ring1Inner: CGFloat,
        ring1Outer: CGFloat,
        ring2Inner: CGFloat,
        ring2Outer: CGFloat
    ) -> SunburstSlice? {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        
        guard (distance >= ring1Inner && distance <= ring1Outer) || (distance >= ring2Inner && distance <= ring2Outer) else {
            return nil
        }
        
        let targetLevel = distance <= ring1Outer ? 1 : 2
        
        var angleRad = atan2(dy, dx)
        if angleRad < 0 {
            angleRad += 2 * .pi
        }
        let angleDeg = angleRad * 180.0 / .pi
        
        for slice in slices where slice.level == targetLevel {
            let startDeg = slice.startAngle.degrees.truncatingRemainder(dividingBy: 360)
            let endDeg = slice.endAngle.degrees.truncatingRemainder(dividingBy: 360)
            
            if startDeg <= endDeg {
                if angleDeg >= startDeg && angleDeg <= endDeg {
                    return slice
                }
            } else {
                if angleDeg >= startDeg || angleDeg <= endDeg {
                    return slice
                }
            }
        }
        
        return nil
    }
}
