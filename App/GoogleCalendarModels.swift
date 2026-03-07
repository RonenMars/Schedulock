import Foundation

// MARK: - Google Calendar List Response DTOs

/// Top-level response from GET /users/me/calendarList
struct GCalCalendarList: Codable {
    let kind: String?
    let items: [GCalCalendarListEntry]?
}

/// A single calendar from the user's calendar list.
struct GCalCalendarListEntry: Codable, Identifiable {
    let id: String
    let summary: String?
    let backgroundColor: String?
    let accessRole: String?      // "owner", "writer", "reader", "freeBusyReader"
    let primary: Bool?
    let selected: Bool?
}

// MARK: - Google Calendar API Response DTOs

/// Top-level response from GET /calendars/{calendarId}/events
struct GCalEventList: Codable {
    let kind: String?
    let summary: String?
    let nextPageToken: String?
    let nextSyncToken: String?
    let items: [GCalEvent]?
}

/// A single event resource from the Google Calendar API.
struct GCalEvent: Codable, Identifiable {
    let id: String
    let status: String?          // "confirmed", "tentative", "cancelled"
    let summary: String?
    let location: String?
    let start: GCalDateTime?
    let end: GCalDateTime?
    let colorId: String?
    let organizer: GCalActor?
    let updated: String?         // RFC 3339 timestamp
}

/// Represents either a date-time or an all-day date.
/// Google Calendar uses `dateTime` for timed events and `date` for all-day events.
struct GCalDateTime: Codable {
    let dateTime: String?        // RFC 3339: "2024-03-15T10:00:00-07:00"
    let date: String?            // "2024-03-15" (all-day)
    let timeZone: String?
}

struct GCalActor: Codable {
    let email: String?
    let displayName: String?
    let self_: Bool?

    enum CodingKeys: String, CodingKey {
        case email, displayName
        case self_ = "self"
    }
}

// MARK: - Parsed Local Event (persisted to disk)

/// A locally cached Google Calendar event, stripped to fields needed for rendering.
/// Codable for JSON file persistence.
struct GoogleCalendarEvent: Codable, Identifiable {
    let id: String
    let summary: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let location: String?
    let calendarId: String
    let status: String           // "confirmed", "tentative", "cancelled"

    /// True if this event has been cancelled (should be removed from display).
    var isCancelled: Bool { status == "cancelled" }
}

// MARK: - GCalDateTime Parsing

extension GCalDateTime {
    /// Parses the datetime into a Swift Date.
    /// Returns nil only if both `dateTime` and `date` are missing.
    func toDate() -> Date? {
        if let dateTime {
            return ISO8601DateFormatter.flexibleDate(from: dateTime)
        }
        if let date {
            return ISO8601DateFormatter.dateOnly.date(from: date)
        }
        return nil
    }

    var representsAllDay: Bool {
        date != nil && dateTime == nil
    }
}

// MARK: - ISO 8601 Formatters

extension ISO8601DateFormatter {
    /// Parses full RFC 3339 timestamps with fractional seconds like "2024-03-15T10:00:00.000-07:00"
    static let withFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    /// Parses full RFC 3339 timestamps without fractional seconds like "2024-03-15T10:00:00-07:00"
    static let withoutFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    /// Parses date-only strings like "2024-03-15"
    static let dateOnly: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()

    /// Parses an RFC 3339 timestamp, trying fractional seconds first then falling back.
    static func flexibleDate(from string: String) -> Date? {
        withFractional.date(from: string) ?? withoutFractional.date(from: string)
    }
}

// MARK: - Conversion from API DTO to local model

extension GCalEvent {
    /// Converts a Google Calendar API event to the local cached model.
    /// Returns nil if required date fields are missing.
    func toLocalEvent(calendarId: String) -> GoogleCalendarEvent? {
        // Cancelled events may lack start/end — preserve them with epoch fallback
        // so the sync store can identify and remove them by ID.
        if status == "cancelled" {
            return GoogleCalendarEvent(
                id: id,
                summary: summary ?? "",
                startDate: start?.toDate() ?? .distantPast,
                endDate: end?.toDate() ?? .distantPast,
                isAllDay: start?.representsAllDay ?? false,
                location: location,
                calendarId: calendarId,
                status: status ?? "cancelled"
            )
        }

        guard let startDate = start?.toDate(),
              let endDate = end?.toDate() else {
            return nil
        }

        return GoogleCalendarEvent(
            id: id,
            summary: summary ?? "Untitled",
            startDate: startDate,
            endDate: endDate,
            isAllDay: start?.representsAllDay ?? false,
            location: location,
            calendarId: calendarId,
            status: status ?? "confirmed"
        )
    }
}
