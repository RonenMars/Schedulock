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
        if let bgImage = backgroundImage, let cgImage = bgImage.cgImage {
            context.saveGState()
            context.draw(cgImage, in: CGRect(origin: .zero, size: size))
            context.restoreGState()
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

        // 5. Draw massive date number (86pt, bold)
        let dateFont = TextRenderer.font(from: settings.fontFamily, size: 86, weight: .bold)
        let dateText = "\(dateNumber)"

        // Position date number in upper third
        let dateY = size.height * 0.15
        let dateRect = CGRect(
            x: 40,
            y: dateY,
            width: size.width - 80,
            height: 120
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

        // 6. Draw day name below date (24pt)
        let dayFont = TextRenderer.font(from: settings.fontFamily, size: 24, weight: .medium)
        let dayRect = CGRect(
            x: 40,
            y: dateY + 100,
            width: size.width - 80,
            height: 30
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

        // 7. Draw month name below day (24pt)
        let monthRect = CGRect(
            x: 40,
            y: dateY + 135,
            width: size.width - 80,
            height: 30
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

        // 8. Draw accent bar separator (horizontal line, 4pt tall)
        let barY = dateY + 180
        let barWidth = size.width * 0.4

        context.saveGState()
        context.setFillColor(accentColor.cgColor)
        context.fill(CGRect(x: 40, y: barY, width: barWidth, height: 4))
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

        let eventFont = TextRenderer.font(from: settings.fontFamily, size: 16, weight: .regular)
        let eventHeight: CGFloat = 28
        let bottomPadding: CGFloat = 60
        let maxEvents = min(events.count, 8)

        let startY = size.height - bottomPadding - (CGFloat(maxEvents) * eventHeight)

        for (index, event) in events.prefix(maxEvents).enumerated() {
            let eventY = startY + (CGFloat(index) * eventHeight)

            // Draw calendar color bar (4pt wide, 16pt tall)
            let barColor = settings.useCalendarColors ? event.calendarColor : ColorUtils.color(from: settings.accentColor)
            context.saveGState()
            context.setFillColor(barColor.cgColor)
            context.fill(CGRect(x: 40, y: eventY + 4, width: 4, height: 16))
            context.restoreGState()

            // Draw event title
            let titleRect = CGRect(
                x: 56,
                y: eventY,
                width: size.width - 96,
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
