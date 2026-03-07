import XCTest
@testable import Schedulock

/// Tests for CalendarSyncStore: event persistence, cache clearing, today filtering.
final class CalendarSyncStoreTests: XCTestCase {

    private var store: CalendarSyncStore!
    private var defaults: UserDefaults!
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        let suiteName = "CalendarSyncStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        tempDirectory = FileManager.default.temporaryDirectory.appending(path: suiteName)
        store = CalendarSyncStore(defaults: defaults, eventsDirectory: tempDirectory)
    }

    override func tearDown() {
        store = nil
        defaults.removePersistentDomain(forName: defaults.description)
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Last Sync Date

    func testLastSyncDateInitiallyNil() {
        XCTAssertNil(store.lastSyncDate)
    }

    func testLastSyncDatePersistence() {
        let date = Date(timeIntervalSince1970: 1710500000)
        store.lastSyncDate = date
        XCTAssertEqual(store.lastSyncDate?.timeIntervalSince1970 ?? 0, date.timeIntervalSince1970, accuracy: 1.0)
    }

    // MARK: - Event Cache

    func testLoadEventsEmptyInitially() {
        let events = store.loadEvents()
        XCTAssertTrue(events.isEmpty)
    }

    func testReplaceAllEvents() {
        let events = [
            makeEvent(id: "1", summary: "Meeting"),
            makeEvent(id: "2", summary: "Lunch"),
        ]

        store.replaceAllEvents(events)
        let loaded = store.loadEvents()

        XCTAssertEqual(loaded.count, 2)
        XCTAssertTrue(loaded.contains { $0.id == "1" })
        XCTAssertTrue(loaded.contains { $0.id == "2" })
    }

    func testReplaceAllEventsOverwrites() {
        store.replaceAllEvents([makeEvent(id: "old", summary: "Old")])
        store.replaceAllEvents([makeEvent(id: "new", summary: "New")])

        let loaded = store.loadEvents()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.id, "new")
    }

    // MARK: - Clear All

    func testClearAllRemovesEverything() {
        store.lastSyncDate = Date()
        store.replaceAllEvents([makeEvent(id: "1", summary: "Event")])

        store.clearAll()

        XCTAssertNil(store.lastSyncDate)
        XCTAssertTrue(store.loadEvents().isEmpty)
    }

    // MARK: - Today Events Filtering

    func testTodayEventsFiltersToToday() {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let midToday = startOfToday.addingTimeInterval(12 * 3600)
        let yesterday = startOfToday.addingTimeInterval(-24 * 3600)
        let tomorrow = startOfToday.addingTimeInterval(36 * 3600)

        store.replaceAllEvents([
            makeEvent(id: "today", summary: "Today", start: midToday, end: midToday.addingTimeInterval(3600)),
            makeEvent(id: "yesterday", summary: "Yesterday", start: yesterday, end: yesterday.addingTimeInterval(3600)),
            makeEvent(id: "tomorrow", summary: "Tomorrow", start: tomorrow, end: tomorrow.addingTimeInterval(3600)),
        ])

        let today = store.todayEvents()
        XCTAssertEqual(today.count, 1)
        XCTAssertEqual(today.first?.id, "today")
    }

    func testTodayEventsExcludesCancelled() {
        let now = Date()
        store.replaceAllEvents([
            GoogleCalendarEvent(
                id: "cancelled", summary: "Cancelled", startDate: now, endDate: now.addingTimeInterval(3600),
                isAllDay: false, location: nil, calendarId: "primary", status: "cancelled"
            ),
        ])

        let today = store.todayEvents()
        XCTAssertTrue(today.isEmpty)
    }

    func testTodayEventsRespectsMaxEvents() {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        let events = (0..<10).map { i in
            makeEvent(
                id: "evt\(i)", summary: "Event \(i)",
                start: startOfToday.addingTimeInterval(Double(i) * 3600 + 3600),
                end: startOfToday.addingTimeInterval(Double(i) * 3600 + 7200)
            )
        }
        store.replaceAllEvents(events)

        let limited = store.todayEvents(maxEvents: 3)
        XCTAssertEqual(limited.count, 3)
    }

    // MARK: - Helpers

    private func makeEvent(
        id: String,
        summary: String,
        start: Date? = nil,
        end: Date? = nil,
        calendarId: String = "primary"
    ) -> GoogleCalendarEvent {
        let startDate = start ?? Date()
        let endDate = end ?? startDate.addingTimeInterval(3600)
        return GoogleCalendarEvent(
            id: id,
            summary: summary,
            startDate: startDate,
            endDate: endDate,
            isAllDay: false,
            location: nil,
            calendarId: calendarId,
            status: "confirmed"
        )
    }
}
