import SwiftUI

public struct MetricGaugeView: View {
    public let title: String
    public let value: Double // 0 - 100
    public let unit: String
    public let subtitle: String
    public let iconName: String
    public let gradient: LinearGradient
    
    public init(
        title: String,
        value: Double,
        unit: String = "%",
        subtitle: String = "",
        iconName: String,
        gradient: LinearGradient = Theme.oliveGradient
    ) {
        self.title = title
        self.value = min(100.0, max(0.0, value))
        self.unit = unit
        self.subtitle = subtitle
        self.iconName = iconName
        self.gradient = gradient
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(title, systemImage: iconName)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text(String(format: "%.1f%@", value, unit))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(value > 85 ? Theme.accentRose : (value > 70 ? Theme.accentAmber : Theme.accentOlive))
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 10)
                    
                    Capsule()
                        .fill(gradient)
                        .frame(width: max(8, geo.size.width * CGFloat(value / 100.0)), height: 10)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)
                }
            }
            .frame(height: 10)
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .glassCard()
    }
}
