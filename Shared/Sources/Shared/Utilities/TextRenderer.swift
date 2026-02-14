import UIKit
import CoreText

/// Text layout and rendering utilities for Core Graphics contexts.
/// Uses Core Text for high-quality text rendering with advanced typography.
public struct TextRenderer {
    // MARK: - Text Drawing

    /// Draws text into a CGContext at the specified rect.
    /// Supports alignment, custom fonts, and optional shadow effects.
    public static func drawText(
        _ text: String,
        in context: CGContext,
        rect: CGRect,
        font: UIFont,
        color: UIColor,
        alignment: NSTextAlignment,
        shadow: (color: UIColor, offset: CGSize, blur: CGFloat)? = nil
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = .byWordWrapping

        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]

        if let shadow = shadow {
            let nsShadow = NSShadow()
            nsShadow.shadowColor = shadow.color
            nsShadow.shadowOffset = shadow.offset
            nsShadow.shadowBlurRadius = shadow.blur
            attributes[.shadow] = nsShadow
        }

        let attributedString = NSAttributedString(string: text, attributes: attributes)
        drawAttributedText(attributedString, in: context, rect: rect)
    }

    /// Draws attributed text with Core Text.
    /// This method provides the most control over text rendering.
    public static func drawAttributedText(
        _ attributedString: NSAttributedString,
        in context: CGContext,
        rect: CGRect
    ) {
        context.saveGState()
        defer { context.restoreGState() }

        // Flip coordinate system for Core Text (uses bottom-left origin)
        context.textMatrix = .identity
        context.translateBy(x: 0, y: rect.maxY)
        context.scaleBy(x: 1.0, y: -1.0)

        let path = CGPath(rect: CGRect(x: rect.minX, y: 0, width: rect.width, height: rect.height), transform: nil)
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: attributedString.length), path, nil)

        CTFrameDraw(frame, context)
    }

    // MARK: - Font Creation

    /// Creates a font from FontFamily enum at the given size.
    /// Falls back to system font if the requested font is unavailable.
    public static func font(from family: FontFamily, size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let fontName = family.fontName

        // Handle SF Pro specially (system font)
        if family == .sfPro {
            return UIFont.systemFont(ofSize: size, weight: weight)
        }

        // Try loading custom font
        if let customFont = UIFont(name: fontName, size: size) {
            return customFont
        }

        // Map weight to font variants for common fonts
        let weightedFontName: String
        switch weight {
        case .bold, .heavy, .black:
            weightedFontName = "\(fontName)-Bold"
        case .medium, .semibold:
            weightedFontName = "\(fontName)-Medium"
        case .light, .thin, .ultraLight:
            weightedFontName = "\(fontName)-Light"
        default:
            weightedFontName = fontName
        }

        if let weightedFont = UIFont(name: weightedFontName, size: size) {
            return weightedFont
        }

        // Fallback to system font with requested weight
        print("Warning: Font '\(fontName)' not available, falling back to system font")
        return UIFont.systemFont(ofSize: size, weight: weight)
    }

    // MARK: - Text Measurement

    /// Measures text size for layout calculations.
    /// Uses Core Text for accurate measurement including line spacing and kerning.
    public static func measureText(
        _ text: String,
        font: UIFont,
        maxWidth: CGFloat
    ) -> CGSize {
        let attributedString = NSAttributedString(
            string: text,
            attributes: [.font: font]
        )

        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        let constraints = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)

        let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRange(location: 0, length: attributedString.length),
            nil,
            constraints,
            nil
        )

        return CGSize(
            width: ceil(suggestedSize.width),
            height: ceil(suggestedSize.height)
        )
    }

    // MARK: - Convenience Methods

    /// Converts TextAlignment enum to NSTextAlignment.
    public static func nsTextAlignment(from alignment: TextAlignment) -> NSTextAlignment {
        switch alignment {
        case .left:   return .left
        case .center: return .center
        case .right:  return .right
        }
    }

    /// Creates a standard shadow configuration for readable text on wallpapers.
    public static func standardTextShadow(strength: CGFloat) -> (color: UIColor, offset: CGSize, blur: CGFloat) {
        return (
            color: UIColor.black.withAlphaComponent(strength),
            offset: CGSize(width: 0, height: 1),
            blur: strength * 3
        )
    }
}
