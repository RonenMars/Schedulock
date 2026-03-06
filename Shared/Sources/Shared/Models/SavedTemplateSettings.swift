import Foundation
import SwiftData

/// Persisted per-template styling preferences.
/// One record exists per TemplateType, seeded at first launch.
@Model
public final class SavedTemplateSettings {
    public var templateTypeRaw: String

    // Typography
    public var fontFamilyRaw: String
    public var textShadow: Double

    // Colors
    public var textColor: String
    public var accentColor: String
    public var secondaryColor: String
    public var cardBackground: String
    public var useCalendarColors: Bool

    // Effects
    public var overlayOpacity: Double
    public var glassBlur: Double
    public var backgroundBlur: Double
    public var brightness: Double

    // Layout
    public var textAlignmentRaw: String
    public var splitRatio: Double

    public init(templateTypeRaw: String, defaults: DesignSettings = .default) {
        self.templateTypeRaw = templateTypeRaw
        self.fontFamilyRaw = defaults.fontFamily.rawValue
        self.textShadow = defaults.textShadow
        self.textColor = defaults.textColor
        self.accentColor = defaults.accentColor
        self.secondaryColor = defaults.secondaryColor
        self.cardBackground = defaults.cardBackground
        self.useCalendarColors = defaults.useCalendarColors
        self.overlayOpacity = defaults.overlayOpacity
        self.glassBlur = defaults.glassBlur
        self.backgroundBlur = defaults.backgroundBlur
        self.brightness = defaults.brightness
        self.textAlignmentRaw = defaults.textAlignment.rawValue
        self.splitRatio = defaults.splitRatio
    }

    /// Convert this record to a DesignSettings value.
    public var asDesignSettings: DesignSettings {
        DesignSettings(
            textColor: textColor,
            accentColor: accentColor,
            secondaryColor: secondaryColor,
            cardBackground: cardBackground,
            overlayOpacity: overlayOpacity,
            glassBlur: glassBlur,
            backgroundBlur: backgroundBlur,
            brightness: brightness,
            textShadow: textShadow,
            fontFamily: FontFamily(rawValue: fontFamilyRaw) ?? .sfPro,
            textAlignment: TextAlignment(rawValue: textAlignmentRaw) ?? .left,
            useCalendarColors: useCalendarColors,
            splitRatio: splitRatio
        )
    }

    /// Overwrite all fields from a DesignSettings value.
    public func apply(_ s: DesignSettings) {
        textColor = s.textColor
        accentColor = s.accentColor
        secondaryColor = s.secondaryColor
        cardBackground = s.cardBackground
        overlayOpacity = s.overlayOpacity
        glassBlur = s.glassBlur
        backgroundBlur = s.backgroundBlur
        brightness = s.brightness
        textShadow = s.textShadow
        fontFamilyRaw = s.fontFamily.rawValue
        textAlignmentRaw = s.textAlignment.rawValue
        useCalendarColors = s.useCalendarColors
        splitRatio = s.splitRatio
    }
}
