import Foundation
import Shared

/// Persists Google Calendar sync state: cached events (JSON file) and last sync date (UserDefaults).
/// Uses AppGroupManager for storage so widget extensions could read synced events if needed.
final class CalendarSyncStore {

    private let defaults: UserDefaults
    private let lastSyncKey = "googleCalendar.lastSyncDate"

    private let eventsFileURL: URL

    init(
        defaults: UserDefaults = AppGroupManager.userDefaults,
        eventsDirectory: URL = AppGroupManager.containerURL.appending(path: "GoogleCalendar")
    ) {
        self.defaults = defaults
        try? FileManager.default.createDirectory(at: eventsDirectory, withIntermediateDirectories: true)
        self.eventsFileURL = eventsDirectory.appending(path: "events.json")
    }

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - Sync State

    var lastSyncDate: Date? {
        get { defaults.object(forKey: lastSyncKey) as? Date }
        set { defaults.set(newValue, forKey: lastSyncKey) }
    }

    // MARK: - Event Cache

    /// Loads all cached Google Calendar events from disk.
    func loadEvents() -> [GoogleCalendarEvent] {
        guard FileManager.default.fileExists(atPath: eventsFileURL.path()) else {
            return []
        }
        do {
            let data = try Data(contentsOf: eventsFileURL)
            return try decoder.decode([GoogleCalendarEvent].self, from: data)
        } catch {
            print("[CalendarSyncStore] Failed to load events: \(error.localizedDescription)")
            return []
        }
    }

    /// Replaces the entire event cache. Used after a full sync.
    func replaceAllEvents(_ events: [GoogleCalendarEvent]) {
        saveEvents(events)
    }

    /// Wipes all cached data.
    func clearAll() {
        lastSyncDate = nil
        try? FileManager.default.removeItem(at: eventsFileURL)
        print("[CalendarSyncStore] Cleared all sync data")
    }

    // MARK: - Today's Events (for rendering)

    /// Returns cached events for today, sorted by start time (all-day first).
    /// Converts to the shared CalendarEvent type used by the rendering engine.
    func todayEvents(maxEvents: Int = 6) -> [CalendarEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let today = loadEvents().filter { event in
            !event.isCancelled &&
            event.endDate > startOfDay &&
            event.startDate < endOfDay
        }

        let sorted = today.sorted { a, b in
            if a.isAllDay != b.isAllDay { return a.isAllDay }
            return a.startDate < b.startDate
        }

        return Array(sorted.prefix(maxEvents)).map { event in
            CalendarEvent(
                id: event.id,
                title: event.summary,
                calendarName: "Google",
                startTime: event.startDate,
                endTime: event.endDate,
                isAllDay: event.isAllDay,
                calendarColor: .systemBlue,
                location: event.location
            )
        }
    }

    // MARK: - Private

    private func saveEvents(_ events: [GoogleCalendarEvent]) {
        do {
            let data = try encoder.encode(events)
            try data.write(to: eventsFileURL, options: .atomic)
        } catch {
            print("[CalendarSyncStore] Failed to save events: \(error.localizedDescription)")
        }
    }
}
