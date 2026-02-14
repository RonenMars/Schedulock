import UIKit
import CoreGraphics

/// Color conversion and gradient utilities for wallpaper rendering.
public struct ColorUtils {
    // MARK: - Hex Conversion

    /// Converts hex string to UIColor.
    /// Supports formats: #RGB, #RRGGBB, #RRGGBBAA
    /// - Parameter hex: Hex color string (with or without # prefix)
    /// - Returns: UIColor, or white if parsing fails
    public static func color(from hex: String) -> UIColor {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            print("Warning: Invalid hex color '\(hex)', falling back to white")
            return .white
        }

        let length = hexSanitized.count
        let r, g, b, a: CGFloat

        switch length {
        case 3: // #RGB
            r = CGFloat((rgb & 0xF00) >> 8) / 15.0
            g = CGFloat((rgb & 0x0F0) >> 4) / 15.0
            b = CGFloat(rgb & 0x00F) / 15.0
            a = 1.0

        case 6: // #RRGGBB
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            a = 1.0

        case 8: // #RRGGBBAA
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0

        default:
            print("Warning: Invalid hex color length '\(hex)', falling back to white")
            return .white
        }

        return UIColor(red: r, green: g, blue: b, alpha: a)
    }

    /// Converts UIColor to hex string.
    /// - Parameter color: The color to convert
    /// - Returns: Hex string in #RRGGBB format (or #RRGGBBAA if alpha < 1)
    public static func hex(from color: UIColor) -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        color.getRed(&r, green: &g, blue: &b, alpha: &a)

        let red = Int(round(r * 255))
        let green = Int(round(g * 255))
        let blue = Int(round(b * 255))

        if a < 1.0 {
            let alpha = Int(round(a * 255))
            return String(format: "#%02X%02X%02X%02X", red, green, blue, alpha)
        } else {
            return String(format: "#%02X%02X%02X", red, green, blue)
        }
    }

    // MARK: - Gradient Generation

    /// Creates a gradient CGImage for overlay effects.
    /// Used for creating smooth color transitions in wallpaper backgrounds.
    /// - Parameters:
    ///   - colors: Array of colors to interpolate between
    ///   - size: Size of the gradient image to generate
    ///   - startPoint: Gradient start point (0,0 = top-left, 1,1 = bottom-right)
    ///   - endPoint: Gradient end point
    /// - Returns: CGImage with the rendered gradient, or nil on failure
    public static func gradientImage(
        colors: [UIColor],
        size: CGSize,
        startPoint: CGPoint = CGPoint(x: 0.5, y: 0),
        endPoint: CGPoint = CGPoint(x: 0.5, y: 1)
    ) -> CGImage? {
        guard !colors.isEmpty, size.width > 0, size.height > 0 else { return nil }

        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        let cgColors = colors.map { $0.cgColor } as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: cgColors,
            locations: nil
        ) else {
            return nil
        }

        let start = CGPoint(
            x: startPoint.x * size.width,
            y: startPoint.y * size.height
        )
        let end = CGPoint(
            x: endPoint.x * size.width,
            y: endPoint.y * size.height
        )

        context.drawLinearGradient(
            gradient,
            start: start,
            end: end,
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )

        return context.makeImage()
    }

    // MARK: - Color Manipulation

    /// Adjusts color brightness.
    /// - Parameters:
    ///   - color: The base color
    ///   - amount: Brightness adjustment (-1.0 to 1.0, where 0 = no change)
    /// - Returns: Adjusted color
    public static func adjustBrightness(of color: UIColor, by amount: CGFloat) -> UIColor {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

        let newBrightness = max(0, min(1, b + amount))
        return UIColor(hue: h, saturation: s, brightness: newBrightness, alpha: a)
    }

    /// Adjusts color opacity.
    /// - Parameters:
    ///   - color: The base color
    ///   - opacity: New opacity (0.0 to 1.0)
    /// - Returns: Color with adjusted opacity
    public static func withOpacity(_ color: UIColor, opacity: CGFloat) -> UIColor {
        return color.withAlphaComponent(max(0, min(1, opacity)))
    }

    /// Blends two colors using linear interpolation.
    /// - Parameters:
    ///   - color1: First color
    ///   - color2: Second color
    ///   - ratio: Blend ratio (0.0 = all color1, 1.0 = all color2)
    /// - Returns: Blended color
    public static func blend(_ color1: UIColor, with color2: UIColor, ratio: CGFloat) -> UIColor {
        let clampedRatio = max(0, min(1, ratio))

        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        return UIColor(
            red: r1 + (r2 - r1) * clampedRatio,
            green: g1 + (g2 - g1) * clampedRatio,
            blue: b1 + (b2 - b1) * clampedRatio,
            alpha: a1 + (a2 - a1) * clampedRatio
        )
    }
}
