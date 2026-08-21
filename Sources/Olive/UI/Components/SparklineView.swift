import SwiftUI

public struct SparklineView: View {
    public let dataPoints: [Double]
    public let lineColor: Color
    
    public init(dataPoints: [Double], lineColor: Color = Theme.accentOlive) {
        self.dataPoints = dataPoints
        self.lineColor = lineColor
    }
    
    public var body: some View {
        GeometryReader { geo in
            Path { path in
                guard dataPoints.count > 1 else { return }
                
                let stepX = geo.size.width / CGFloat(dataPoints.count - 1)
                let maxVal = (dataPoints.max() ?? 100.0) == 0 ? 100.0 : (dataPoints.max() ?? 100.0)
                
                for (index, val) in dataPoints.enumerated() {
                    let normY = (1.0 - CGFloat(val / maxVal)) * geo.size.height
                    let pt = CGPoint(x: CGFloat(index) * stepX, y: max(2, min(geo.size.height - 2, normY)))
                    
                    if index == 0 {
                        path.move(to: pt)
                    } else {
                        path.addLine(to: pt)
                    }
                }
            }
            .stroke(lineColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}
