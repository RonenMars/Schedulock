import UIKit
import CoreGraphics

/// Split View template renderer: Image on top, solid panel for agenda below.
/// Features:
/// - Split canvas: top portion for image, bottom for agenda
/// - Configurable split ratio (default 0.55)
/// - Accent top-border on the agenda panel
/// - Day name + date header
/// - Events listed with calendar color bars + time + title
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
        if let bgImage = backgroundImage, let cgImage = bgImage.cgImage {
            context.saveGState()

            // Clip to top portion
            context.clip(to: CGRect(x: 0, y: 0, width: size.width, height: splitY))

            // Draw image (aspect-fill to top portion)
            let imageAspect = CGFloat(cgImage.width) / CGFloat(cgImage.height)
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
                let drawY = 0.0 // Anchor to top
                drawRect = CGRect(x: 0, y: drawY, width: size.width, height: drawHeight)
            }

            context.draw(cgImage, in: drawRect)
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
        let calendar = Calendar.current
        let dayName = date.formatted(.dateTime.weekday(.wide))
        let dateNumber = calendar.component(.day, from: date)
        let monthName = date.formatted(.dateTime.month(.abbreviated))

        let headerFont = TextRenderer.font(from: settings.fontFamily, size: 28, weight: .bold)
        let headerText = "\(dayName), \(monthName) \(dateNumber)"

        let headerY = splitY + 30
        let headerRect = CGRect(
            x: 40,
            y: headerY,
            width: size.width - 80,
            height: 40
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

        let eventFont = TextRenderer.font(from: settings.fontFamily, size: 15, weight: .regular)
        let timeFont = TextRenderer.font(from: settings.fontFamily, size: 14, weight: .medium)
        let eventHeight: CGFloat = 32
        let eventPadding: CGFloat = 4
        let startY = headerY + 60

        // Calculate available space
        let bottomPadding: CGFloat = 40
        let availableHeight = size.height - startY - bottomPadding
        let maxEvents = min(events.count, Int(availableHeight / (eventHeight + eventPadding)))

        for (index, event) in events.prefix(maxEvents).enumerated() {
            let eventY = startY + (CGFloat(index) * (eventHeight + eventPadding))

            // Draw calendar color bar (4pt wide, 20pt tall)
            let barColor = settings.useCalendarColors ? event.calendarColor : ColorUtils.color(from: settings.accentColor)
            context.saveGState()
            context.setFillColor(barColor.cgColor)
            context.fill(CGRect(x: 40, y: eventY + 4, width: 4, height: 20))
            context.restoreGState()

            // Format time
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = event.isAllDay ? "All day" : "h:mm a"
            let timeString = event.isAllDay ? "All day" : timeFormatter.string(from: event.startTime)

            // Draw time (60pt wide)
            let timeRect = CGRect(
                x: 56,
                y: eventY,
                width: 70,
                height: eventHeight
            )

            TextRenderer.drawText(
                timeString,
                in: context,
                rect: timeRect,
                font: timeFont,
                color: ColorUtils.withOpacity(textColor, opacity: 0.7),
                alignment: .left,
                shadow: shadow
            )

            // Draw event title
            let titleRect = CGRect(
                x: 136,
                y: eventY,
                width: size.width - 176,
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
