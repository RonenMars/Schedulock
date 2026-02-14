import UIKit
import CoreGraphics

/// Neon template renderer: Dark, moody, with glowing accent text. Perfect for OLED.
/// Features:
/// - Dark background with optional darkened image overlay
/// - Clock in accent color with multi-layered glow effect
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
        if let bgImage = backgroundImage, let cgImage = bgImage.cgImage {
            context.saveGState()
            context.setAlpha(1.0 - settings.overlayOpacity)
            context.draw(cgImage, in: CGRect(origin: .zero, size: size))
            context.restoreGState()
        }

        // 3. Get colors
        let textColor = ColorUtils.color(from: settings.textColor)
        let accentColor = ColorUtils.color(from: settings.accentColor)
        let cardBackground = ColorUtils.color(from: settings.cardBackground)

        // 4. Format time from date
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm"
        let timeString = timeFormatter.string(from: date)

        // 5. Draw clock with glowing effect
        drawGlowingClock(
            in: context,
            time: timeString,
            size: size,
            accentColor: accentColor,
            settings: settings
        )

        // 6. Draw events in pill containers
        drawPillEvents(
            in: context,
            events: events,
            size: size,
            settings: settings,
            textColor: textColor,
            cardBackground: cardBackground
        )
    }

    private func drawGlowingClock(
        in context: CGContext,
        time: String,
        size: CGSize,
        accentColor: UIColor,
        settings: DesignSettings
    ) {
        let clockFont = TextRenderer.font(from: settings.fontFamily, size: 72, weight: .bold)

        // Position clock in upper center
        let clockY = size.height * 0.25
        let clockRect = CGRect(
            x: 0,
            y: clockY,
            width: size.width,
            height: 100
        )

        // Draw multiple layers for glow effect
        // Layer 1: Innermost glow (blur 4pt, alpha 0.8)
        context.saveGState()
        context.setShadow(
            offset: CGSize.zero,
            blur: 4,
            color: accentColor.withAlphaComponent(0.8).cgColor
        )
        TextRenderer.drawText(
            time,
            in: context,
            rect: clockRect,
            font: clockFont,
            color: accentColor,
            alignment: .center,
            shadow: nil
        )
        context.restoreGState()

        // Layer 2: Middle glow (blur 12pt, alpha 0.4)
        context.saveGState()
        context.setShadow(
            offset: CGSize.zero,
            blur: 12,
            color: accentColor.withAlphaComponent(0.4).cgColor
        )
        TextRenderer.drawText(
            time,
            in: context,
            rect: clockRect,
            font: clockFont,
            color: accentColor,
            alignment: .center,
            shadow: nil
        )
        context.restoreGState()

        // Layer 3: Outer glow (blur 24pt, alpha 0.2)
        context.saveGState()
        context.setShadow(
            offset: CGSize.zero,
            blur: 24,
            color: accentColor.withAlphaComponent(0.2).cgColor
        )
        TextRenderer.drawText(
            time,
            in: context,
            rect: clockRect,
            font: clockFont,
            color: accentColor,
            alignment: .center,
            shadow: nil
        )
        context.restoreGState()
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

        let eventFont = TextRenderer.font(from: settings.fontFamily, size: 15, weight: .medium)
        let pillHeight: CGFloat = 40
        let pillPadding: CGFloat = 12
        let bottomPadding: CGFloat = 80
        let maxEvents = min(events.count, 6)

        let startY = size.height - bottomPadding - (CGFloat(maxEvents) * (pillHeight + pillPadding))

        for (index, event) in events.prefix(maxEvents).enumerated() {
            let pillY = startY + (CGFloat(index) * (pillHeight + pillPadding))

            // Draw rounded pill background (16pt corner radius)
            let pillRect = CGRect(
                x: 40,
                y: pillY,
                width: size.width - 80,
                height: pillHeight
            )

            context.saveGState()
            let pillPath = CGPath(
                roundedRect: pillRect,
                cornerWidth: 16,
                cornerHeight: 16,
                transform: nil
            )
            context.addPath(pillPath)
            context.setFillColor(cardBackground.cgColor)
            context.fillPath()
            context.restoreGState()

            // Draw calendar color circle (6px radius)
            let circleColor = settings.useCalendarColors ? event.calendarColor : ColorUtils.color(from: settings.accentColor)
            let circleX = pillRect.minX + 16
            let circleY = pillRect.midY

            context.saveGState()
            context.setFillColor(circleColor.cgColor)
            context.fillEllipse(in: CGRect(
                x: circleX - 6,
                y: circleY - 6,
                width: 12,
                height: 12
            ))
            context.restoreGState()

            // Draw event title
            let titleRect = CGRect(
                x: circleX + 16,
                y: pillY,
                width: pillRect.width - 48,
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
