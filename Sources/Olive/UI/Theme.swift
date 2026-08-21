import SwiftUI

public enum Theme {
    // Olive Palette
    public static let accentOlive = Color(red: 0.52, green: 0.80, blue: 0.09) // #84CC16
    public static let accentSage = Color(red: 0.06, green: 0.73, blue: 0.51)  // #10B981
    public static let accentAmber = Color(red: 0.96, green: 0.62, blue: 0.04) // #F59E0B
    public static let accentRose = Color(red: 0.96, green: 0.25, blue: 0.37)  // #F43F5E
    public static let accentViolet = Color(red: 0.55, green: 0.36, blue: 0.96) // #8B5CF6
    public static let accentCyan = Color(red: 0.02, green: 0.71, blue: 0.83)   // #06B6D4
    
    // Backgrounds & Surfaces
    public static let backgroundDark = Color(red: 0.05, green: 0.07, blue: 0.09)
    public static let surfaceCard = Color.white.opacity(0.06)
    public static let borderSubtle = Color.white.opacity(0.12)
    public static let borderFocus = Color.white.opacity(0.24)
    
    // Gradients
    public static let oliveGradient = LinearGradient(
        colors: [Color(red: 0.52, green: 0.80, blue: 0.09), Color(red: 0.06, green: 0.73, blue: 0.51)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let amberGradient = LinearGradient(
        colors: [Color(red: 0.96, green: 0.62, blue: 0.04), Color(red: 0.96, green: 0.40, blue: 0.10)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let roseGradient = LinearGradient(
        colors: [Color(red: 0.96, green: 0.25, blue: 0.37), Color(red: 0.88, green: 0.12, blue: 0.45)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
