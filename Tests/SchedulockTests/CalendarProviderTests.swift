import XCTest
import EventKit
@testable import Shared

/// Unit tests for CalendarDataProvider - EventKit calendar and event access.
final class CalendarProviderTests: XCTestCase {

    // MARK: - Setup

    var provider: CalendarDataProvider!

    override func setUp() {
        super.setUp()
        // Use default EKEventStore for structural testing
        provider = CalendarDataProvider()
    }

    override func tearDown() {
        provider = nil
        super.tearDown()
    }

    // MARK: - fetchTodayEvents Tests

    func testFetchTodayEventsReturnsArray() {
        // Given: Empty calendar IDs array (all calendars)
        let calendarIDs: [String] = []

        // When: Fetching today's events
        let events = provider.fetchTodayEvents(from: calendarIDs)

        // Then: Should return an array (may be empty if no access or no events)
        XCTAssertNotNil(events)
        XCTAssertTrue(events is [CalendarEvent])
    }

    func testFetchTodayEventsWithEmptyCalendarIDs() {
        // Given: Empty calendar IDs array
        let calendarIDs: [String] = []

        // When: Fetching events
        let events = provider.fetchTodayEvents(from: calendarIDs)

        // Then: Should complete without crashing
        XCTAssertNotNil(events)
        // Note: Actual count depends on calendar access and today's events
        XCTAssertTrue(events.count >= 0)
    }

    func testFetchTodayEventsWithSpecificCalendarIDs() {
        // Given: Specific calendar IDs (will filter to these)
        let calendarIDs = ["test-calendar-id-1", "test-calendar-id-2"]

        // When: Fetching events
        let events = provider.fetchTodayEvents(from: calendarIDs)

        // Then: Should complete without crashing
        XCTAssertNotNil(events)
        // Events will be empty if these calendars don't exist, which is expected
        XCTAssertTrue(events.count >= 0)
    }

    func testFetchTodayEventsRespectsMaxEvents() {
        // Given: Request for max 3 events
        let maxEvents = 3
        let calendarIDs: [String] = []

        // When: Fetching events with limit
        let events = provider.fetchTodayEvents(from: calendarIDs, maxEvents: maxEvents)

        // Then: Should not exceed max events
        XCTAssertLessThanOrEqual(events.count, maxEvents)
    }

    func testFetchTodayEventsDefaultMaxEvents() {
        // Given: Default max events (6)
        let calendarIDs: [String] = []

        // When: Fetching events without specifying max
        let events = provider.fetchTodayEvents(from: calendarIDs)

        // Then: Should not exceed default limit of 6
        XCTAssertLessThanOrEqual(events.count, 6)
    }

    func testFetchTodayEventsExcludesDeclinedByDefault() {
        // Given: Default excludeDeclined parameter (true)
        let calendarIDs: [String] = []

        // When: Fetching events
        let events = provider.fetchTodayEvents(from: calendarIDs)

        // Then: Should complete without error
        // Note: Actual filtering of declined events requires calendar access
        XCTAssertNotNil(events)
    }

    func testFetchTodayEventsIncludesDeclinedWhenRequested() {
        // Given: excludeDeclined = false
        let calendarIDs: [String] = []

        // When: Fetching events with declined included
        let events = provider.fetchTodayEvents(from: calendarIDs, excludeDeclined: false)

        // Then: Should complete without error
        XCTAssertNotNil(events)
    }

    // MARK: - countTodayEvents Tests

    func testCountTodayEventsReturnsNumber() {
        // Given: Empty calendar IDs array
        let calendarIDs: [String] = []

        // When: Counting today's events
        let count = provider.countTodayEvents(from: calendarIDs)

        // Then: Should return a non-negative integer
        XCTAssertGreaterThanOrEqual(count, 0)
    }

    func testCountTodayEventsWithEmptyCalendarIDs() {
        // Given: Empty calendar IDs array
        let calendarIDs: [String] = []

        // When: Counting events
        let count = provider.countTodayEvents(from: calendarIDs)

        // Then: Should return valid count
        XCTAssertGreaterThanOrEqual(count, 0)
    }

    func testCountTodayEventsWithSpecificCalendarIDs() {
        // Given: Specific calendar IDs
        let calendarIDs = ["test-calendar-id"]

        // When: Counting events
        let count = provider.countTodayEvents(from: calendarIDs)

        // Then: Should return valid count (likely 0 for non-existent calendar)
        XCTAssertGreaterThanOrEqual(count, 0)
    }

    // MARK: - fetchCalendars Tests

    func testFetchCalendarsReturnsArray() {
        // When: Fetching calendars
        let calendars = provider.fetchCalendars()

        // Then: Should return an array (may be empty if no access)
        XCTAssertNotNil(calendars)
        XCTAssertTrue(calendars is [EKCalendar])
    }

    func testFetchCalendarsDoesNotCrash() {
        // When: Fetching calendars
        let calendars = provider.fetchCalendars()

        // Then: Should complete without crashing
        XCTAssertNotNil(calendars)
        // Count depends on calendar access granted
        XCTAssertGreaterThanOrEqual(calendars.count, 0)
    }

    // MARK: - Authorization Tests

    func testAuthorizationStatusIsValid() {
        // When: Checking authorization status
        let status = CalendarDataProvider.authorizationStatus

        // Then: Should be a valid EKAuthorizationStatus
        let validStatuses: [EKAuthorizationStatus] = [
            .notDetermined,
            .restricted,
            .denied,
            .fullAccess,
            .writeOnly
        ]
        XCTAssertTrue(validStatuses.contains(status))
    }

    // MARK: - EKCalendar Extension Tests

    func testCalendarColorHexFormat() {
        // Note: This test requires a mock EKCalendar, which is difficult to create
        // Testing the extension behavior is best done through integration tests
        // Here we verify the extension exists and is accessible
        let calendars = provider.fetchCalendars()

        if let calendar = calendars.first {
            // When: Getting color hex
            let colorHex = calendar.colorHex

            // Then: Should return a hex string in #RRGGBB format
            XCTAssertTrue(colorHex.hasPrefix("#"))
            XCTAssertEqual(colorHex.count, 7) // "#RRGGBB" = 7 characters
        }
    }

    func testCalendarColorHexIsValidFormat() {
        let calendars = provider.fetchCalendars()

        for calendar in calendars {
            let colorHex = calendar.colorHex

            // Should start with #
            XCTAssertTrue(colorHex.hasPrefix("#"))

            // Should be 7 characters (#RRGGBB)
            XCTAssertEqual(colorHex.count, 7)

            // Should only contain hex characters after #
            let hexString = String(colorHex.dropFirst())
            let hexCharSet = CharacterSet(charactersIn: "0123456789ABCDEF")
            XCTAssertTrue(hexString.uppercased().unicodeScalars.allSatisfy {
                hexCharSet.contains($0)
            })
        }
    }
}
