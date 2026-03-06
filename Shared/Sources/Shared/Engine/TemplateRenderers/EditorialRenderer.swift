import UIKit
import CoreGraphics

/// Editorial template renderer: Bold typographic statement where the date IS the design.
/// Features:
/// - Massive 86pt date number (day of month)
/// - Uppercase day name and month below the date
/// - Accent bar separator (horizontal line)
/// - Events bottom-aligned with calendar color bars
public struct EditorialRenderer: WallpaperRenderer {
    public let templateType: TemplateType = .editorial

    public init() {}

    public func render(
        context: CGContext,
        size: CGSize,
        backgroundImage: UIImage?,
        events: [CalendarEvent],
        settings: DesignSettings,
        date: Date
    ) {
        // 1. Draw background image if provided
        if let bgImage = backgroundImage {
            UIGraphicsPushContext(context)
            bgImage.draw(in: CGRect(origin: .zero, size: size))
            UIGraphicsPopContext()
        }

        // 2. Get colors
        let textColor = ColorUtils.color(from: settings.textColor)
        let accentColor = ColorUtils.color(from: settings.accentColor)

        // 3. Create shadow for text
        let shadow = TextRenderer.standardTextShadow(strength: settings.textShadow)

        // 4. Extract date components
        let calendar = Calendar.current
        let dateNumber = calendar.component(.day, from: date)
        let dayName = date.formatted(.dateTime.weekday(.wide)).uppercased()
        let monthName = date.formatted(.dateTime.month(.wide)).uppercased()

        // 5. Draw massive date number, scaled to canvas resolution
        let scale = size.width / 390.0
        let dateFont = TextRenderer.font(from: settings.fontFamily, size: 86 * scale, weight: .bold)
        let dateText = "\(dateNumber)"

        // Position date number in upper third
        let dateY = size.height * 0.15
        let dateRect = CGRect(
            x: 40 * scale,
            y: dateY,
            width: size.width - 80 * scale,
            height: 120 * scale
        )

        TextRenderer.drawText(
            dateText,
            in: context,
            rect: dateRect,
            font: dateFont,
            color: textColor,
            alignment: .left,
            shadow: shadow
        )

        // 6. Draw day name below date
        let dayFont = TextRenderer.font(from: settings.fontFamily, size: 24 * scale, weight: .medium)
        let dayRect = CGRect(
            x: 40 * scale,
            y: dateY + 100 * scale,
            width: size.width - 80 * scale,
            height: 30 * scale
        )

        TextRenderer.drawText(
            dayName,
            in: context,
            rect: dayRect,
            font: dayFont,
            color: textColor,
            alignment: .left,
            shadow: shadow
        )

        // 7. Draw month name below day
        let monthRect = CGRect(
            x: 40 * scale,
            y: dateY + 135 * scale,
            width: size.width - 80 * scale,
            height: 30 * scale
        )

        TextRenderer.drawText(
            monthName,
            in: context,
            rect: monthRect,
            font: dayFont,
            color: textColor,
            alignment: .left,
            shadow: shadow
        )

        // 8. Draw accent bar separator (horizontal line)
        let barY = dateY + 180 * scale
        let barWidth = size.width * 0.4

        context.saveGState()
        context.setFillColor(accentColor.cgColor)
        context.fill(CGRect(x: 40 * scale, y: barY, width: barWidth, height: 4 * scale))
        context.restoreGState()

        // 9. Draw events at bottom
        drawEvents(
            in: context,
            events: events,
            size: size,
            settings: settings,
            textColor: textColor,
            shadow: shadow
        )
    }

    private func drawEvents(
        in context: CGContext,
        events: [CalendarEvent],
        size: CGSize,
        settings: DesignSettings,
        textColor: UIColor,
        shadow: (color: UIColor, offset: CGSize, blur: CGFloat)
    ) {
        guard !events.isEmpty else { return }

        let scale = size.width / 390.0
        let eventFont = TextRenderer.font(from: settings.fontFamily, size: 16 * scale, weight: .regular)
        let eventHeight: CGFloat = 28 * scale
        let bottomPadding: CGFloat = 60 * scale
        let maxEvents = min(events.count, 8)

        let startY = size.height - bottomPadding - (CGFloat(maxEvents) * eventHeight)

        for (index, event) in events.prefix(maxEvents).enumerated() {
            let eventY = startY + (CGFloat(index) * eventHeight)

            // Draw calendar color bar
            let barColor = settings.useCalendarColors ? event.calendarColor : ColorUtils.color(from: settings.accentColor)
            context.saveGState()
            context.setFillColor(barColor.cgColor)
            context.fill(CGRect(x: 40 * scale, y: eventY + 4 * scale, width: 4 * scale, height: 16 * scale))
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
