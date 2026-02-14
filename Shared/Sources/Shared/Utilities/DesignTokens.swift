import SwiftUI

/// Design system color tokens from the Schedulock spec.
public enum DesignTokens {
    // MARK: - Colors
    public static let background   = Color(hex: "#0A0B0F")
    public static let surface      = Color(hex: "#0F1014")
    public static let primary      = Color(hex: "#6C63FF")
    public static let primaryGlow  = Color(hex: "#E040FB")
    public static let textPrimary  = Color(hex: "#E8E8ED")
    public static let textMuted    = Color(hex: "#555555")
    public static let danger       = Color(hex: "#FF3B30")
    public static let success      = Color(hex: "#30D158")

    public static let accentGradient = LinearGradient(
        colors: [primary, primaryGlow],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Corner Radii
    public static let cardRadius: CGFloat = 12
    public static let glassRadius: CGFloat = 20
    public static let phoneFrameRadius: CGFloat = 32

    // MARK: - Spacing (8pt grid)
    public static let spacingXS: CGFloat = 4
    public static let spacingSM: CGFloat = 8
    public static let spacingMD: CGFloat = 16
    public static let spacingLG: CGFloat = 24
    public static let spacingXL: CGFloat = 32
}

// MARK: - Color hex initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
