import UIKit
import CoreGraphics
import Foundation

/// Minimal template renderer: Let the photo breathe with subtle overlays.
/// Clock and events overlay with subtle gradients for maximum photo visibility.
public struct MinimalRenderer: WallpaperRenderer {
    public let templateType: TemplateType = .minimal

    public init() {}

    public func render(
        context: CGContext,
        size: CGSize,
        backgroundImage: UIImage?,
        events: [CalendarEvent],
        settings: DesignSettings,
        date: Date
    ) {
        // 1. Draw background image (aspect-fill) or fallback gradient
        if let backgroundImage = backgroundImage {
            drawBackgroundImage(context: context, size: size, image: backgroundImage)
        } else {
            drawFallbackGradient(context: context, size: size, settings: settings)
        }

        // 2. Top gradient overlay (black → transparent)
        drawTopGradientOverlay(context: context, size: size, opacity: settings.overlayOpacity)

        // 3. Bottom gradient overlay (transparent → black)
        drawBottomGradientOverlay(context: context, size: size, opacity: settings.overlayOpacity)

        // 4. Draw large clock at top
        drawClock(context: context, size: size, date: date, settings: settings)

        // 5. Draw events at bottom
        drawEvents(context: context, size: size, events: events, settings: settings)
    }

    // MARK: - Background Rendering

    private func drawBackgroundImage(context: CGContext, size: CGSize, image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let imageAspect = image.size.width / image.size.height
        let canvasAspect = size.width / size.height

        let drawRect: CGRect
        if imageAspect > canvasAspect {
            // Image is wider - fit height and crop width
            let drawHeight = size.height
            let drawWidth = drawHeight * imageAspect
            let xOffset = (size.width - drawWidth) / 2
            drawRect = CGRect(x: xOffset, y: 0, width: drawWidth, height: drawHeight)
        } else {
            // Image is taller - fit width and crop height
            let drawWidth = size.width
            let drawHeight = drawWidth / imageAspect
            let yOffset = (size.height - drawHeight) / 2
            drawRect = CGRect(x: 0, y: yOffset, width: drawWidth, height: drawHeight)
        }

        context.draw(cgImage, in: drawRect)
    }

    private func drawFallbackGradient(context: CGContext, size: CGSize, settings: DesignSettings) {
        let cardColor = ColorUtils.color(from: settings.cardBackground)
        let darkerColor = ColorUtils.adjustBrightness(of: cardColor, by: -0.2)

        let colors = [darkerColor.cgColor, cardColor.cgColor] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: colors,
            locations: nil
        ) else { return }

        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: size.width / 2, y: 0),
            end: CGPoint(x: size.width / 2, y: size.height),
            options: []
        )
    }

    // MARK: - Gradient Overlays

    private func drawTopGradientOverlay(context: CGContext, size: CGSize, opacity: Double) {
        let overlayHeight = size.height * 0.35
        let startColor = UIColor.black.withAlphaComponent(opacity).cgColor
        let endColor = UIColor.black.withAlphaComponent(0).cgColor

        let colors = [startColor, endColor] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: colors,
            locations: nil
        ) else { return }

        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: size.width / 2, y: 0),
            end: CGPoint(x: size.width / 2, y: overlayHeight),
            options: []
        )
    }

    private func drawBottomGradientOverlay(context: CGContext, size: CGSize, opacity: Double) {
        let overlayHeight = size.height * 0.4
        let startColor = UIColor.black.withAlphaComponent(0).cgColor
        let endColor = UIColor.black.withAlphaComponent(opacity).cgColor

        let colors = [startColor, endColor] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: colors,
            locations: nil
        ) else { return }

        let startY = size.height - overlayHeight
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: size.width / 2, y: startY),
            end: CGPoint(x: size.width / 2, y: size.height),
            options: []
        )
    }

    // MARK: - Clock Rendering

    private func drawClock(context: CGContext, size: CGSize, date: Date, settings: DesignSettings) {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: date)

        let fontSize = size.height * 0.08
        let font = TextRenderer.font(from: settings.fontFamily, size: fontSize, weight: .bold)
        let textColor = ColorUtils.color(from: settings.textColor)
        let shadow = TextRenderer.standardTextShadow(strength: settings.textShadow / 10.0)

        let padding = size.width * 0.08
        let topPadding = size.height * 0.08
        let textRect = CGRect(
            x: padding,
            y: topPadding,
            width: size.width - (padding * 2),
            height: fontSize * 1.5
        )

        TextRenderer.drawText(
            timeString,
            in: context,
            rect: textRect,
            font: font,
            color: textColor,
            alignment: .left,
            shadow: shadow
        )
    }

    // MARK: - Events Rendering

    private func drawEvents(context: CGContext, size: CGSize, events: [CalendarEvent], settings: DesignSettings) {
        let padding = size.width * 0.08
        let bottomPadding = size.height * 0.05
        let fontSize = size.height * 0.025
        let lineHeight = fontSize * 1.8
        let barWidth: CGFloat = 4.0
        let barSpacing: CGFloat = 12.0

        let font = TextRenderer.font(from: settings.fontFamily, size: fontSize, weight: .medium)
        let textColor = ColorUtils.color(from: settings.textColor)
        let shadow = TextRenderer.standardTextShadow(strength: settings.textShadow / 10.0)

        var currentY = size.height - bottomPadding

        // Display up to 5 events
        let displayEvents = Array(events.prefix(5))

        for event in displayEvents.reversed() {
            currentY -= lineHeight

            // Draw calendar color bar
            let barRect = CGRect(
                x: padding,
                y: currentY + (lineHeight - fontSize) / 2,
                width: barWidth,
                height: fontSize
            )

            let barColor = settings.useCalendarColors ? event.calendarColor : ColorUtils.color(from: settings.accentColor)
            context.setFillColor(barColor.cgColor)
            context.fill(barRect)

            // Draw event title
            let textX = padding + barWidth + barSpacing
            let textRect = CGRect(
                x: textX,
                y: currentY,
                width: size.width - textX - padding,
                height: lineHeight
            )

            TextRenderer.drawText(
                event.truncatedTitle,
                in: context,
                rect: textRect,
                font: font,
                color: textColor,
                alignment: .left,
                shadow: shadow
            )
        }
    }
}
