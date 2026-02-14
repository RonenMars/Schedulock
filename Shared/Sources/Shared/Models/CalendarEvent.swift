import Foundation
import UIKit

/// A simplified calendar event for rendering on wallpapers.
/// Decoupled from EventKit so the Shared package doesn't need EventKit dependency.
public struct CalendarEvent: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let calendarName: String
    public let startTime: Date
    public let endTime: Date
    public let isAllDay: Bool
    public let calendarColor: UIColor
    public let location: String?

    public init(
        id: String,
        title: String,
        calendarName: String,
        startTime: Date,
        endTime: Date,
        isAllDay: Bool,
        calendarColor: UIColor,
        location: String? = nil
    ) {
        self.id = id
        self.title = title
        self.calendarName = calendarName
        self.startTime = startTime
        self.endTime = endTime
        self.isAllDay = isAllDay
        self.calendarColor = calendarColor
        self.location = location
    }

    /// Title truncated to the display limit.
    public var truncatedTitle: String {
        if title.count > 32 {
            return String(title.prefix(32)) + "…"
        }
        return title
    }
}
