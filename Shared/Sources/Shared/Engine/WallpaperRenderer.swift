import UIKit
import CoreGraphics

/// Device resolution registry for all supported iPhone models.
/// Used to generate wallpapers at exact device-native resolutions.
public struct DeviceResolution: Sendable {
    public let width: Int
    public let height: Int
    public let scale: Int
    public let name: String

    public init(width: Int, height: Int, scale: Int, name: String) {
        self.width = width
        self.height = height
        self.scale = scale
        self.name = name
    }

    public var size: CGSize {
        CGSize(width: width, height: height)
    }

    // MARK: - Device Presets

    public static let iPhoneSE3 = DeviceResolution(
        width: 750,
        height: 1334,
        scale: 2,
        name: "iPhone SE 3"
    )

    public static let iPhone14 = DeviceResolution(
        width: 1170,
        height: 2532,
        scale: 3,
        name: "iPhone 14/15"
    )

    public static let iPhone15Pro = DeviceResolution(
        width: 1179,
        height: 2556,
        scale: 3,
        name: "iPhone 15 Pro"
    )

    public static let iPhone15ProMax = DeviceResolution(
        width: 1290,
        height: 2796,
        scale: 3,
        name: "iPhone 15 Pro Max"
    )

    public static let iPhone16Pro = DeviceResolution(
        width: 1206,
        height: 2622,
        scale: 3,
        name: "iPhone 16 Pro"
    )

    public static let iPhone16ProMax = DeviceResolution(
        width: 1320,
        height: 2868,
        scale: 3,
        name: "iPhone 16 Pro Max"
    )

    public static let all: [DeviceResolution] = [
        .iPhoneSE3,
        .iPhone14,
        .iPhone15Pro,
        .iPhone15ProMax,
        .iPhone16Pro,
        .iPhone16ProMax
    ]
}

/// Core rendering protocol that all 6 wallpaper templates must conform to.
/// Each template renderer receives a CGContext and draws directly into it.
public protocol WallpaperRenderer: Sendable {
    /// The template type this renderer handles
    var templateType: TemplateType { get }

    /// Render the wallpaper into the provided CGContext.
    ///
    /// - Parameters:
    ///   - context: The CGContext to draw into (pre-sized to target resolution)
    ///   - size: The target size for the wallpaper
    ///   - backgroundImage: Optional background image (processed/resized by caller)
    ///   - events: Array of calendar events to render (sorted by start time)
    ///   - settings: Design settings for colors, effects, typography
    ///   - date: The date being rendered (for header/date display)
    func render(
        context: CGContext,
        size: CGSize,
        backgroundImage: UIImage?,
        events: [CalendarEvent],
        settings: DesignSettings,
        date: Date
    )
}
