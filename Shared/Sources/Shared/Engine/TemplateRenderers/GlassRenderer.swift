import UIKit
import CoreGraphics
import Foundation

/// Glass template renderer: Floating translucent card with today's agenda.
/// Features a centered glass card with semi-transparent background and simulated blur effect.
public struct GlassRenderer: WallpaperRenderer {
    public let templateType: TemplateType = .glass

    public init() {}

    public func render(
        context: CGContext,
        size: CGSize,
        backgroundImage: UIImage?,
        events: [CalendarEvent],
        settings: DesignSettings,
        date: Date
    ) {
        // 1. Draw background image
        if let backgroundImage = backgroundImage {
            drawBackgroundImage(context: context, size: size, image: backgroundImage)
        } else {
            drawFallbackGradient(context: context, size: size, settings: settings)
        }

        // 2. Draw glass card with events
        drawGlassCard(context: context, size: size, events: events, settings: settings)
    }

    // MARK: - Background Rendering

    private func drawBackgroundImage(context: CGContext, size: CGSize, image: UIImage) {
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

        UIGraphicsPushContext(context)
        image.draw(in: drawRect)
        UIGraphicsPopContext()
    }

    private func drawFallbackGradient(context: CGContext, size: CGSize, settings: DesignSettings) {
        let cardColor = ColorUtils.color(from: settings.cardBackground)
        let darkerColor = ColorUtils.adjustBrightness(of: cardColor, by: -0.3)

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

    // MARK: - Glass Card Rendering

    private func drawGlassCard(context: CGContext, size: CGSize, events: [CalendarEvent], settings: DesignSettings) {
        let cardPadding = size.width * 0.08
        let cardWidth = size.width - (cardPadding * 2)

        // Calculate card height based on number of events
        let headerHeight: CGFloat = size.height * 0.05
        let eventLineHeight: CGFloat = size.height * 0.035
        let eventCount = min(events.count, 6)
        let eventsHeight = CGFloat(eventCount) * eventLineHeight
        let cardInternalPadding: CGFloat = size.height * 0.04
        let cardHeight = headerHeight + eventsHeight + (cardInternalPadding * 2)

        // Center the card vertically
        let cardY = (size.height - cardHeight) / 2 + (size.height * 0.05)
        let cardRect = CGRect(
            x: cardPadding,
            y: cardY,
            width: cardWidth,
            height: cardHeight
        )

        // 1. Draw glass card background with blur simulation
        drawCardBackground(context: context, rect: cardRect, settings: settings)

        // 2. Draw card header
        drawCardHeader(
            context: context,
            cardRect: cardRect,
            headerHeight: headerHeight,
            padding: cardInternalPadding,
            settings: settings
        )

        // 3. Draw events list
        drawCardEvents(
            context: context,
            cardRect: cardRect,
            events: events,
            headerHeight: headerHeight,
            padding: cardInternalPadding,
            lineHeight: eventLineHeight,
            settings: settings
        )
    }

    private func drawCardBackground(context: CGContext, rect: CGRect, settings: DesignSettings) {
        // Create rounded rect path
        let cornerRadius: CGFloat = 20.0
        let path = CGPath(
            roundedRect: rect,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )

        // Draw semi-transparent background
        let cardColor = ColorUtils.color(from: settings.cardBackground)
        let glassColor = cardColor.withAlphaComponent(settings.overlayOpacity)

        context.setFillColor(glassColor.cgColor)
        context.addPath(path)
        context.fillPath()

        // Draw lighter overlay for blur simulation
        let blurOverlayColor = UIColor.white.withAlphaComponent(0.05)
        context.setFillColor(blurOverlayColor.cgColor)
        context.addPath(path)
        context.fillPath()

        // Draw border for glass effect
        let borderColor = UIColor.white.withAlphaComponent(0.2)
        context.setStrokeColor(borderColor.cgColor)
        context.setLineWidth(1.0)
        context.addPath(path)
        context.strokePath()
    }

    private func drawCardHeader(
        context: CGContext,
        cardRect: CGRect,
        headerHeight: CGFloat,
        padding: CGFloat,
        settings: DesignSettings
    ) {
        let headerText = "TODAY'S AGENDA"
        let fontSize = headerHeight * 0.5
        let font = TextRenderer.font(from: settings.fontFamily, size: fontSize, weight: .semibold)
        let textColor = ColorUtils.color(from: settings.textColor).withAlphaComponent(0.7)

        let headerRect = CGRect(
            x: cardRect.minX + padding,
            y: cardRect.minY + padding,
            width: cardRect.width - (padding * 2),
            height: headerHeight
        )

        TextRenderer.drawText(
            headerText,
            in: context,
            rect: headerRect,
            font: font,
            color: textColor,
            alignment: .center
        )
    }

    private func drawCardEvents(
        context: CGContext,
        cardRect: CGRect,
        events: [CalendarEvent],
        headerHeight: CGFloat,
        padding: CGFloat,
        lineHeight: CGFloat,
        settings: DesignSettings
    ) {
        let fontSize = lineHeight * 0.5
        let font = TextRenderer.font(from: settings.fontFamily, size: fontSize, weight: .regular)
        let textColor = ColorUtils.color(from: settings.textColor)

        let eventsStartY = cardRect.minY + padding + headerHeight + (padding * 0.5)
        let dotRadius: CGFloat = 4.0
        let dotSpacing: CGFloat = 12.0

        // Display up to 6 events
        let displayEvents = Array(events.prefix(6))

        for (index, event) in displayEvents.enumerated() {
            let y = eventsStartY + (CGFloat(index) * lineHeight)

            // Draw calendar color dot
            let dotX = cardRect.minX + padding
            let dotY = y + (lineHeight / 2)
            let dotCenter = CGPoint(x: dotX + dotRadius, y: dotY)

            let dotColor = settings.useCalendarColors ? event.calendarColor : ColorUtils.color(from: settings.accentColor)
            context.setFillColor(dotColor.cgColor)
            context.addArc(
                center: dotCenter,
                radius: dotRadius,
                startAngle: 0,
                endAngle: .pi * 2,
                clockwise: true
            )
            context.fillPath()

            // Draw title
            let textX = dotX + (dotRadius * 2) + dotSpacing
            let textWidth = cardRect.width - (padding * 2) - (dotRadius * 2) - dotSpacing

            let textRect = CGRect(
                x: textX,
                y: y,
                width: textWidth,
                height: lineHeight
            )

            TextRenderer.drawText(
                event.truncatedTitle,
                in: context,
                rect: textRect,
                font: font,
                color: textColor,
                alignment: .left
            )
        }
    }
}
