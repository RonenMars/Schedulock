import EventKit
import UIKit

/// Provides calendar data from EventKit, converting to rendering-friendly CalendarEvent structs.
public class CalendarDataProvider {
    private let store: EKEventStore

    public init(store: EKEventStore = EKEventStore()) {
        self.store = store
    }

    // MARK: - Access

    /// Requests full calendar access (iOS 17+).
    /// Returns true if access was granted.
    public func requestAccess() async throws -> Bool {
        try await store.requestFullAccessToEvents()
    }

    /// Current authorization status.
    public static var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    // MARK: - Refresh

    /// Asks the system to refresh calendar sources if stale.
    /// Does not guarantee a network sync but nudges the OS to check.
    public func refreshSourcesIfNecessary() {
        store.refreshSourcesIfNecessary()
    }

    /// Resets the event store, discarding all cached data, then refreshes sources.
    /// Use for aggressive reload when entering calendar-related screens.
    public func resetAndRefresh() {
        store.reset()
        store.refreshSourcesIfNecessary()
    }

    // MARK: - Calendars

    /// Fetches all calendars for events, grouped by source (account).
    public func fetchCalendars() -> [EKCalendar] {
        store.calendars(for: .event)
    }

    /// Fetches calendars grouped by their source (iCloud, Google, etc.).
    public func fetchCalendarsGroupedBySource() -> [(source: String, calendars: [EKCalendar])] {
        let calendars = fetchCalendars()
        let grouped = Dictionary(grouping: calendars) { $0.source.title }
        return grouped
            .sorted { $0.key < $1.key }
            .map { (source: $0.key, calendars: $0.value.sorted { $0.title < $1.title }) }
    }

    // MARK: - Events

    /// Fetches today's events from the specified calendar IDs.
    /// - Parameters:
    ///   - calendarIDs: EKCalendar identifiers to fetch from. Empty = all calendars.
    ///   - excludeDeclined: Whether to filter out declined events (default: true).
    ///   - maxEvents: Maximum number of events to return (default: 6).
    public func fetchTodayEvents(
        from calendarIDs: [String],
        excludeDeclined: Bool = true,
        maxEvents: Int = 6
    ) -> [CalendarEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let selectedCalendars: [EKCalendar]?
        if calendarIDs.isEmpty {
            selectedCalendars = nil
        } else {
            selectedCalendars = fetchCalendars().filter { calendarIDs.contains($0.calendarIdentifier) }
        }

        let predicate = store.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: selectedCalendars
        )

        let ekEvents = store.events(matching: predicate)

        let filtered = ekEvents.filter { event in
            if excludeDeclined {
                let isDeclined = event.attendees?.contains { $0.isCurrentUser && $0.participantStatus == .declined } ?? false
                if isDeclined { return false }
            }
            return true
        }

        // Sort: all-day first, then by start time
        let sorted = filtered.sorted { a, b in
            if a.isAllDay != b.isAllDay { return a.isAllDay }
            return a.startDate < b.startDate
        }

        return sorted
            .prefix(maxEvents)
            .map { convertToCalendarEvent($0) }
    }

    /// Counts today's events from the specified calendar IDs.
    public func countTodayEvents(from calendarIDs: [String]) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return 0
        }

        let selectedCalendars: [EKCalendar]?
        if calendarIDs.isEmpty {
            selectedCalendars = nil
        } else {
            selectedCalendars = fetchCalendars().filter { calendarIDs.contains($0.calendarIdentifier) }
        }

        let predicate = store.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: selectedCalendars
        )

        return store.events(matching: predicate).count
    }

    // MARK: - Conversion

    private func convertToCalendarEvent(_ event: EKEvent) -> CalendarEvent {
        CalendarEvent(
            id: event.eventIdentifier,
            title: event.title ?? "Untitled",
            calendarName: event.calendar.title,
            startTime: event.startDate,
            endTime: event.endDate,
            isAllDay: event.isAllDay,
            calendarColor: UIColor(cgColor: event.calendar.cgColor),
            location: event.location
        )
    }
}

// MARK: - UIColor hex conversion for calendar colors

extension EKCalendar {
    /// Returns the calendar color as a hex string.
    public var colorHex: String {
        let color = UIColor(cgColor: cgColor)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: nil)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
