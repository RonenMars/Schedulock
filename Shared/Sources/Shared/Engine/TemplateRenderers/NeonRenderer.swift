import UIKit
import CoreGraphics

/// Neon template renderer: Dark, moody, with glowing accent text. Perfect for OLED.
/// Features:
/// - Dark background with optional darkened image overlay
/// - Events in rounded pill containers with calendar color indicators
public struct NeonRenderer: WallpaperRenderer {
    public let templateType: TemplateType = .neon

    public init() {}

    public func render(
        context: CGContext,
        size: CGSize,
        backgroundImage: UIImage?,
        events: [CalendarEvent],
        settings: DesignSettings,
        date: Date
    ) {
        // 1. Draw dark background
        context.saveGState()
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        context.restoreGState()

        // 2. Optionally draw darkened background image
        if let bgImage = backgroundImage {
            context.saveGState()
            context.setAlpha(1.0 - settings.overlayOpacity)
            UIGraphicsPushContext(context)
            bgImage.draw(in: CGRect(origin: .zero, size: size))
            UIGraphicsPopContext()
            context.restoreGState()
        }

        // 3. Get colors
        let textColor = ColorUtils.color(from: settings.textColor)
        let cardBackground = ColorUtils.color(from: settings.cardBackground)

        // 4. Draw events in pill containers
        drawPillEvents(
            in: context,
            events: events,
            size: size,
            settings: settings,
            textColor: textColor,
            cardBackground: cardBackground
        )
    }

    private func drawPillEvents(
        in context: CGContext,
        events: [CalendarEvent],
        size: CGSize,
        settings: DesignSettings,
        textColor: UIColor,
        cardBackground: UIColor
    ) {
        guard !events.isEmpty else { return }

        let scale = size.width / 390.0
        let pillHeight: CGFloat = 44 * scale
        let pillPadding: CGFloat = 8 * scale
        let bottomPadding: CGFloat = 30 * scale
        let horizontalMargin: CGFloat = 15 * scale
        let cornerRadius: CGFloat = 16 * scale
        let circleRadius: CGFloat = 6 * scale
        let innerPadding: CGFloat = 16 * scale
        let eventFont = TextRenderer.font(from: settings.fontFamily, size: 15 * scale, weight: .medium)
        let maxEvents = min(events.count, 6)

        let startY = size.height - bottomPadding - (CGFloat(maxEvents) * (pillHeight + pillPadding))

        for (index, event) in events.prefix(maxEvents).enumerated() {
            let pillY = startY + (CGFloat(index) * (pillHeight + pillPadding))

            // Draw rounded pill background
            let pillRect = CGRect(
                x: horizontalMargin,
                y: pillY,
                width: size.width - horizontalMargin * 2,
                height: pillHeight
            )

            context.saveGState()
            let pillPath = CGPath(
                roundedRect: pillRect,
                cornerWidth: cornerRadius,
                cornerHeight: cornerRadius,
                transform: nil
            )
            context.addPath(pillPath)
            context.setFillColor(cardBackground.cgColor)
            context.fillPath()
            context.restoreGState()

            // Draw calendar color circle
            let circleColor = settings.useCalendarColors ? event.calendarColor : ColorUtils.color(from: settings.accentColor)
            let circleX = pillRect.minX + innerPadding
            let circleY = pillRect.midY

            context.saveGState()
            context.setFillColor(circleColor.cgColor)
            context.fillEllipse(in: CGRect(
                x: circleX - circleRadius,
                y: circleY - circleRadius,
                width: circleRadius * 2,
                height: circleRadius * 2
            ))
            context.restoreGState()

            // Draw event title
            let titleRect = CGRect(
                x: circleX + innerPadding,
                y: pillY,
                width: pillRect.width - innerPadding * 3,
                height: pillHeight
            )

            TextRenderer.drawText(
                event.truncatedTitle,
                in: context,
                rect: titleRect,
                font: eventFont,
                color: textColor,
                alignment: .left,
                shadow: nil
            )
        }
    }
}
