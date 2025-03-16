// AppTheme.swift - Create this new file for app-wide styling
import SwiftUI

// App-wide theme constants
struct AppTheme {
    // Helper method to create Color from hex
    static func colorFromHex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // Colors
    static let accentColor = colorFromHex("ffa8c9")
    static let secondaryColor = colorFromHex("d8c2ff")
    static let tertiaryColor = colorFromHex("c2ffdb")
    static let cardBackground = colorFromHex("f8e6ee")
    
    // Gradients
    static let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [Color.white, colorFromHex("fff5f8")]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Text styles
    static let titleFont = Font.system(size: 28, weight: .bold)
    static let headlineFont = Font.system(size: 18, weight: .semibold)
    static let bodyFont = Font.system(size: 16, weight: .regular)
    static let captionFont = Font.system(size: 14, weight: .medium)
    
    // Corner radius
    static let cornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 24
    
    // Shadow
    static let shadowColor = Color.black.opacity(0.1)
    static let shadowRadius: CGFloat = 8
    static let shadowX: CGFloat = 0
    static let shadowY: CGFloat = 4
    
    // Button styles
    static func primaryButtonStyle() -> some View {
        return AnyView(
            ZStack {
                accentColor
                    .cornerRadius(buttonCornerRadius)
                    .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        )
    }
    
    static func secondaryButtonStyle() -> some View {
        return AnyView(
            ZStack {
                RoundedRectangle(cornerRadius: buttonCornerRadius)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: buttonCornerRadius)
                            .stroke(accentColor, lineWidth: 2)
                    )
                    .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
            }
        )
    }
}
