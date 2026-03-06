import UIKit
import CoreGraphics

/// Split View template renderer: Image on top, solid panel for agenda below.
/// Features:
/// - Split canvas: top portion for image, bottom for agenda
/// - Configurable split ratio (default 0.55)
/// - Accent top-border on the agenda panel
/// - Day name + date header
/// - Events listed with calendar color bars + title
public struct SplitViewRenderer: WallpaperRenderer {
    public let templateType: TemplateType = .split

    public init() {}

    public func render(
        context: CGContext,
        size: CGSize,
        backgroundImage: UIImage?,
        events: [CalendarEvent],
        settings: DesignSettings,
        date: Date
    ) {
        // 1. Calculate split boundary
        let splitY = size.height * settings.splitRatio

        // 2. Draw background image in top portion
        if let bgImage = backgroundImage {
            context.saveGState()

            // Clip to top portion
            context.clip(to: CGRect(x: 0, y: 0, width: size.width, height: splitY))

            // Draw image (aspect-fill to top portion)
            let imageAspect = bgImage.size.width / bgImage.size.height
            let targetAspect = size.width / splitY

            let drawRect: CGRect
            if imageAspect > targetAspect {
                // Image is wider - fit height
                let drawWidth = splitY * imageAspect
                let drawX = (size.width - drawWidth) / 2
                drawRect = CGRect(x: drawX, y: 0, width: drawWidth, height: splitY)
            } else {
                // Image is taller - fit width
                let drawHeight = size.width / imageAspect
                drawRect = CGRect(x: 0, y: 0, width: size.width, height: drawHeight)
            }

            UIGraphicsPushContext(context)
            bgImage.draw(in: drawRect)
            UIGraphicsPopContext()
            context.restoreGState()
        }

        // 3. Draw bottom panel with solid background
        let cardBackground = ColorUtils.color(from: settings.cardBackground)
        context.saveGState()
        context.setFillColor(cardBackground.cgColor)
        context.fill(CGRect(x: 0, y: splitY, width: size.width, height: size.height - splitY))
        context.restoreGState()

        // 4. Draw accent top-border (3pt line)
        let accentColor = ColorUtils.color(from: settings.accentColor)
        context.saveGState()
        context.setFillColor(accentColor.cgColor)
        context.fill(CGRect(x: 0, y: splitY, width: size.width, height: 3))
        context.restoreGState()

        // 5. Get colors
        let textColor = ColorUtils.color(from: settings.textColor)
        let shadow = TextRenderer.standardTextShadow(strength: settings.textShadow)

        // 6. Draw date header in bottom panel
        let scale = size.width / 390.0
        let calendar = Calendar.current
        let dayName = date.formatted(.dateTime.weekday(.wide))
        let dateNumber = calendar.component(.day, from: date)
        let monthName = date.formatted(.dateTime.month(.abbreviated))

        let headerFont = TextRenderer.font(from: settings.fontFamily, size: 28 * scale, weight: .bold)
        let headerText = "\(dayName), \(monthName) \(dateNumber)"

        let headerY = splitY + 30 * scale
        let headerRect = CGRect(
            x: 40 * scale,
            y: headerY,
            width: size.width - 80 * scale,
            height: 40 * scale
        )

        TextRenderer.drawText(
            headerText,
            in: context,
            rect: headerRect,
            font: headerFont,
            color: textColor,
            alignment: .left,
            shadow: shadow
        )

        // 7. Draw events below header
        drawEvents(
            in: context,
            events: events,
            size: size,
            splitY: splitY,
            headerY: headerY,
            settings: settings,
            textColor: textColor,
            shadow: shadow
        )
    }

    private func drawEvents(
        in context: CGContext,
        events: [CalendarEvent],
        size: CGSize,
        splitY: CGFloat,
        headerY: CGFloat,
        settings: DesignSettings,
        textColor: UIColor,
        shadow: (color: UIColor, offset: CGSize, blur: CGFloat)
    ) {
        guard !events.isEmpty else { return }

        let scale = size.width / 390.0
        let eventFont = TextRenderer.font(from: settings.fontFamily, size: 15 * scale, weight: .regular)
        let eventHeight: CGFloat = 32 * scale
        let eventPadding: CGFloat = 4 * scale
        let startY = headerY + 60 * scale

        // Calculate available space
        let bottomPadding: CGFloat = 40 * scale
        let availableHeight = size.height - startY - bottomPadding
        let maxEvents = max(0, min(events.count, Int(availableHeight / (eventHeight + eventPadding))))

        for (index, event) in events.prefix(maxEvents).enumerated() {
            let eventY = startY + (CGFloat(index) * (eventHeight + eventPadding))

            // Draw calendar color bar
            let barColor = settings.useCalendarColors ? event.calendarColor : ColorUtils.color(from: settings.accentColor)
            context.saveGState()
            context.setFillColor(barColor.cgColor)
            context.fill(CGRect(x: 40 * scale, y: eventY + 4 * scale, width: 4 * scale, height: 20 * scale))
            context.restoreGState()

            // Draw event title
            let titleRect = CGRect(
                x: 56 * scale,
                y: eventY,
                width: size.width - 96 * scale,
                height: eventHeight
            )

            TextRenderer.drawText(
                event.truncatedTitle,
                in: context,
                rect: titleRect,
                font: eventFont,
                color: textColor,
                alignment: .left,
                shadow: shadow
            )
        }
    }
}
