import Foundation

/// All customizable visual settings for a wallpaper template.
/// Stored as a Codable value within WallpaperTemplate.
public struct DesignSettings: Codable, Sendable, Equatable {
    // MARK: - Colors (hex strings)
    public var textColor: String
    public var accentColor: String
    public var secondaryColor: String
    public var cardBackground: String

    // MARK: - Effects
    public var overlayOpacity: Double
    public var glassBlur: Double
    public var backgroundBlur: Double
    public var brightness: Double
    public var textShadow: Double

    // MARK: - Typography
    public var fontFamily: FontFamily
    public var textAlignment: TextAlignment

    // MARK: - Behavior
    public var useCalendarColors: Bool
    public var splitRatio: Double

    public init(
        textColor: String = "#E8E8ED",
        accentColor: String = "#6C63FF",
        secondaryColor: String = "#E040FB",
        cardBackground: String = "#0F1014",
        overlayOpacity: Double = 0.4,
        glassBlur: Double = 20.0,
        backgroundBlur: Double = 0.0,
        brightness: Double = 0.0,
        textShadow: Double = 2.0,
        fontFamily: FontFamily = .sfPro,
        textAlignment: TextAlignment = .left,
        useCalendarColors: Bool = true,
        splitRatio: Double = 0.55
    ) {
        self.textColor = textColor
        self.accentColor = accentColor
        self.secondaryColor = secondaryColor
        self.cardBackground = cardBackground
        self.overlayOpacity = overlayOpacity
        self.glassBlur = glassBlur
        self.backgroundBlur = backgroundBlur
        self.brightness = brightness
        self.textShadow = textShadow
        self.fontFamily = fontFamily
        self.textAlignment = textAlignment
        self.useCalendarColors = useCalendarColors
        self.splitRatio = splitRatio
    }

    public static let `default` = DesignSettings()
}
