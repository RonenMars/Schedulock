import UIKit
import CoreGraphics
import Foundation

/// Gradient Band template renderer: Strong color statement with gradient strip at bottom.
/// Features background image in upper portion with a vibrant gradient band at the bottom for events.
public struct GradientBandRenderer: WallpaperRenderer {
    public let templateType: TemplateType = .gradient

    public init() {}

    public func render(
        context: CGContext,
        size: CGSize,
        backgroundImage: UIImage?,
        events: [CalendarEvent],
        settings: DesignSettings,
        date: Date
    ) {
        // Calculate band height based on number of events
        let eventLineHeight: CGFloat = size.height * 0.04
        let eventCount = min(events.count, 5)
        let bandPadding: CGFloat = size.height * 0.04
        let bandHeight = (CGFloat(eventCount) * eventLineHeight) + (bandPadding * 2)

        // 1. Draw background image in upper portion
        if let backgroundImage = backgroundImage {
            drawBackgroundImage(
                context: context,
                size: size,
                image: backgroundImage,
                bottomCutoff: bandHeight
            )
        } else {
            drawFallbackBackground(
                context: context,
                size: size,
                settings: settings,
                bottomCutoff: bandHeight
            )
        }

        // 2. Draw gradient band at bottom
        drawGradientBand(
            context: context,
            size: size,
            bandHeight: bandHeight,
            settings: settings
        )

        // 3. Draw events in the band
        drawEvents(
            context: context,
            size: size,
            events: events,
            bandHeight: bandHeight,
            bandPadding: bandPadding,
            lineHeight: eventLineHeight,
            settings: settings
        )
    }

    // MARK: - Background Rendering

    private func drawBackgroundImage(
        context: CGContext,
        size: CGSize,
        image: UIImage,
        bottomCutoff: CGFloat
    ) {
        let availableHeight = size.height - bottomCutoff
        let imageAspect = image.size.width / image.size.height
        let canvasAspect = size.width / availableHeight

        let drawRect: CGRect
        if imageAspect > canvasAspect {
            // Image is wider - fit height and crop width
            let drawHeight = availableHeight
            let drawWidth = drawHeight * imageAspect
            let xOffset = (size.width - drawWidth) / 2
            drawRect = CGRect(x: xOffset, y: 0, width: drawWidth, height: drawHeight)
        } else {
            // Image is taller - fit width and crop height
            let drawWidth = size.width
            let drawHeight = drawWidth / imageAspect
            let yOffset = (availableHeight - drawHeight) / 2
            drawRect = CGRect(x: 0, y: yOffset, width: drawWidth, height: drawHeight)
        }

        context.saveGState()
        context.clip(to: CGRect(x: 0, y: 0, width: size.width, height: availableHeight))
        UIGraphicsPushContext(context)
        image.draw(in: drawRect)
        UIGraphicsPopContext()
        context.restoreGState()
    }

    private func drawFallbackBackground(
        context: CGContext,
        size: CGSize,
        settings: DesignSettings,
        bottomCutoff: CGFloat
    ) {
        let availableHeight = size.height - bottomCutoff
        let cardColor = ColorUtils.color(from: settings.cardBackground)
        let darkerColor = ColorUtils.adjustBrightness(of: cardColor, by: -0.2)

        let colors = [darkerColor.cgColor, cardColor.cgColor] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: colors,
            locations: nil
        ) else { return }

        context.saveGState()
        context.clip(to: CGRect(x: 0, y: 0, width: size.width, height: availableHeight))
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: size.width / 2, y: 0),
            end: CGPoint(x: size.width / 2, y: availableHeight),
            options: []
        )
        context.restoreGState()
    }

    // MARK: - Gradient Band Rendering

    private func drawGradientBand(
        context: CGContext,
        size: CGSize,
        bandHeight: CGFloat,
        settings: DesignSettings
    ) {
        let bandY = size.height - bandHeight
        let bandRect = CGRect(x: 0, y: bandY, width: size.width, height: bandHeight)

        // Create gradient from accent color to secondary color
        let accentColor = ColorUtils.color(from: settings.accentColor)
        let secondaryColor = ColorUtils.color(from: settings.secondaryColor)

        let colors = [accentColor.cgColor, secondaryColor.cgColor] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: colors,
            locations: nil
        ) else { return }

        context.saveGState()
        context.clip(to: bandRect)
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: bandY + bandHeight / 2),
            end: CGPoint(x: size.width, y: bandY + bandHeight / 2),
            options: []
        )
        context.restoreGState()
    }

    // MARK: - Events Rendering

    private func drawEvents(
        context: CGContext,
        size: CGSize,
        events: [CalendarEvent],
        bandHeight: CGFloat,
        bandPadding: CGFloat,
        lineHeight: CGFloat,
        settings: DesignSettings
    ) {
        let bandY = size.height - bandHeight
        let padding = size.width * 0.08
        let fontSize = lineHeight * 0.5
        let font = TextRenderer.font(from: settings.fontFamily, size: fontSize, weight: .medium)
        let textColor = ColorUtils.color(from: settings.textColor)
        let shadow = TextRenderer.standardTextShadow(strength: settings.textShadow / 10.0)

        let dotRadius: CGFloat = 5.0
        let dotSpacing: CGFloat = 12.0

        // Display up to 5 events
        let displayEvents = Array(events.prefix(5))

        for (index, event) in displayEvents.enumerated() {
            let y = bandY + bandPadding + (CGFloat(index) * lineHeight)

            // Draw dot marker
            let dotX = padding
            let dotY = y + (lineHeight / 2)
            let dotCenter = CGPoint(x: dotX + dotRadius, y: dotY)

            let dotColor = settings.useCalendarColors ? event.calendarColor : textColor
            context.setFillColor(dotColor.cgColor)
            context.addArc(
                center: dotCenter,
                radius: dotRadius,
                startAngle: 0,
                endAngle: .pi * 2,
                clockwise: true
            )
            context.fillPath()

            // Draw event title
            let titleX = dotX + (dotRadius * 2) + dotSpacing
            let titleWidth = size.width - titleX - padding
            let titleRect = CGRect(
                x: titleX,
                y: y,
                width: titleWidth,
                height: lineHeight
            )

            TextRenderer.drawText(
                event.truncatedTitle,
                in: context,
                rect: titleRect,
                font: font,
                color: textColor,
                alignment: .left,
                shadow: shadow
            )
        }
    }
}
