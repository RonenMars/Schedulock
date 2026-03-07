import XCTest
@testable import Schedulock

/// Tests for Google Calendar API DTOs: decoding, date parsing, and event conversion.
final class GoogleCalendarModelsTests: XCTestCase {

    // MARK: - GCalEventList Decoding

    func testDecodeEventListWithAllFields() throws {
        let json = """
        {
            "kind": "calendar#events",
            "summary": "user@gmail.com",
            "nextPageToken": "pageToken123",
            "nextSyncToken": null,
            "items": [
                {
                    "id": "evt1",
                    "status": "confirmed",
                    "summary": "Team Standup",
                    "start": { "dateTime": "2024-03-15T10:00:00-07:00" },
                    "end": { "dateTime": "2024-03-15T10:30:00-07:00" }
                }
            ]
        }
        """.data(using: .utf8)!

        let list = try JSONDecoder().decode(GCalEventList.self, from: json)

        XCTAssertEqual(list.kind, "calendar#events")
        XCTAssertEqual(list.summary, "user@gmail.com")
        XCTAssertEqual(list.nextPageToken, "pageToken123")
        XCTAssertNil(list.nextSyncToken)
        XCTAssertEqual(list.items?.count, 1)
        XCTAssertEqual(list.items?.first?.id, "evt1")
    }

    func testDecodeEventListFinalPage() throws {
        let json = """
        {
            "kind": "calendar#events",
            "nextSyncToken": "syncToken_abc",
            "items": []
        }
        """.data(using: .utf8)!

        let list = try JSONDecoder().decode(GCalEventList.self, from: json)

        XCTAssertNil(list.nextPageToken)
        XCTAssertEqual(list.nextSyncToken, "syncToken_abc")
        XCTAssertEqual(list.items?.count, 0)
    }

    func testDecodeEventListNilItems() throws {
        let json = """
        { "kind": "calendar#events" }
        """.data(using: .utf8)!

        let list = try JSONDecoder().decode(GCalEventList.self, from: json)
        XCTAssertNil(list.items)
    }

    // MARK: - GCalEvent Decoding

    func testDecodeTimedEvent() throws {
        let json = """
        {
            "id": "abc123",
            "status": "confirmed",
            "summary": "Sprint Planning",
            "location": "Room 42",
            "start": { "dateTime": "2024-03-15T10:00:00-07:00" },
            "end": { "dateTime": "2024-03-15T11:00:00-07:00" },
            "colorId": "9",
            "updated": "2024-03-14T18:00:00Z"
        }
        """.data(using: .utf8)!

        let event = try JSONDecoder().decode(GCalEvent.self, from: json)

        XCTAssertEqual(event.id, "abc123")
        XCTAssertEqual(event.status, "confirmed")
        XCTAssertEqual(event.summary, "Sprint Planning")
        XCTAssertEqual(event.location, "Room 42")
        XCTAssertEqual(event.colorId, "9")
        XCTAssertNotNil(event.start?.dateTime)
        XCTAssertNil(event.start?.date)
    }

    func testDecodeAllDayEvent() throws {
        let json = """
        {
            "id": "allday1",
            "status": "confirmed",
            "summary": "Company Holiday",
            "start": { "date": "2024-03-15" },
            "end": { "date": "2024-03-16" }
        }
        """.data(using: .utf8)!

        let event = try JSONDecoder().decode(GCalEvent.self, from: json)

        XCTAssertEqual(event.id, "allday1")
        XCTAssertNil(event.start?.dateTime)
        XCTAssertEqual(event.start?.date, "2024-03-15")
        XCTAssertTrue(event.start?.representsAllDay ?? false)
    }

    func testDecodeCancelledEventMinimalFields() throws {
        let json = """
        {
            "id": "cancelled1",
            "status": "cancelled"
        }
        """.data(using: .utf8)!

        let event = try JSONDecoder().decode(GCalEvent.self, from: json)

        XCTAssertEqual(event.id, "cancelled1")
        XCTAssertEqual(event.status, "cancelled")
        XCTAssertNil(event.summary)
        XCTAssertNil(event.start)
        XCTAssertNil(event.end)
    }

    func testDecodeOrganizer() throws {
        let json = """
        {
            "id": "org1",
            "status": "confirmed",
            "summary": "Meeting",
            "start": { "dateTime": "2024-03-15T10:00:00Z" },
            "end": { "dateTime": "2024-03-15T11:00:00Z" },
            "organizer": {
                "email": "user@example.com",
                "displayName": "Test User",
                "self": true
            }
        }
        """.data(using: .utf8)!

        let event = try JSONDecoder().decode(GCalEvent.self, from: json)

        XCTAssertEqual(event.organizer?.email, "user@example.com")
        XCTAssertEqual(event.organizer?.displayName, "Test User")
        XCTAssertEqual(event.organizer?.self_, true)
    }

    // MARK: - GCalDateTime Parsing

    func testParseDateTimeWithoutFractionalSeconds() {
        let dt = GCalDateTime(dateTime: "2024-03-15T10:00:00-07:00", date: nil, timeZone: nil)
        let parsed = dt.toDate()
        XCTAssertNotNil(parsed, "Should parse RFC 3339 without fractional seconds")
    }

    func testParseDateTimeWithFractionalSeconds() {
        let dt = GCalDateTime(dateTime: "2024-03-15T10:00:00.000-07:00", date: nil, timeZone: nil)
        let parsed = dt.toDate()
        XCTAssertNotNil(parsed, "Should parse RFC 3339 with fractional seconds")
    }

    func testParseDateTimeUTC() {
        let dt = GCalDateTime(dateTime: "2024-03-15T17:00:00Z", date: nil, timeZone: nil)
        let parsed = dt.toDate()
        XCTAssertNotNil(parsed, "Should parse UTC timestamp")
    }

    func testParseDateTimeUTCWithFractional() {
        let dt = GCalDateTime(dateTime: "2024-03-15T17:00:00.123Z", date: nil, timeZone: nil)
        let parsed = dt.toDate()
        XCTAssertNotNil(parsed, "Should parse UTC timestamp with fractional seconds")
    }

    func testParseDateOnly() {
        let dt = GCalDateTime(dateTime: nil, date: "2024-03-15", timeZone: nil)
        let parsed = dt.toDate()
        XCTAssertNotNil(parsed, "Should parse date-only string")
    }

    func testParseDateTimeNilBoth() {
        let dt = GCalDateTime(dateTime: nil, date: nil, timeZone: nil)
        XCTAssertNil(dt.toDate(), "Should return nil when both dateTime and date are nil")
    }

    func testRepresentsAllDay() {
        let allDay = GCalDateTime(dateTime: nil, date: "2024-03-15", timeZone: nil)
        XCTAssertTrue(allDay.representsAllDay)

        let timed = GCalDateTime(dateTime: "2024-03-15T10:00:00Z", date: nil, timeZone: nil)
        XCTAssertFalse(timed.representsAllDay)

        let both = GCalDateTime(dateTime: "2024-03-15T10:00:00Z", date: "2024-03-15", timeZone: nil)
        XCTAssertFalse(both.representsAllDay, "dateTime takes precedence")
    }

    // MARK: - GCalEvent -> GoogleCalendarEvent Conversion

    func testConvertTimedEvent() {
        let gcalEvent = GCalEvent(
            id: "evt1",
            status: "confirmed",
            summary: "Sprint Review",
            location: "Room B",
            start: GCalDateTime(dateTime: "2024-03-15T14:00:00Z", date: nil, timeZone: nil),
            end: GCalDateTime(dateTime: "2024-03-15T15:00:00Z", date: nil, timeZone: nil),
            colorId: nil,
            organizer: nil,
            updated: nil
        )

        let local = gcalEvent.toLocalEvent(calendarId: "primary")

        XCTAssertNotNil(local)
        XCTAssertEqual(local?.id, "evt1")
        XCTAssertEqual(local?.summary, "Sprint Review")
        XCTAssertEqual(local?.location, "Room B")
        XCTAssertEqual(local?.calendarId, "primary")
        XCTAssertEqual(local?.status, "confirmed")
        XCTAssertFalse(local?.isAllDay ?? true)
        XCTAssertFalse(local?.isCancelled ?? true)
    }

    func testConvertAllDayEvent() {
        let gcalEvent = GCalEvent(
            id: "allday",
            status: "confirmed",
            summary: "Vacation",
            location: nil,
            start: GCalDateTime(dateTime: nil, date: "2024-03-15", timeZone: nil),
            end: GCalDateTime(dateTime: nil, date: "2024-03-16", timeZone: nil),
            colorId: nil,
            organizer: nil,
            updated: nil
        )

        let local = gcalEvent.toLocalEvent(calendarId: "primary")

        XCTAssertNotNil(local)
        XCTAssertTrue(local?.isAllDay ?? false)
    }

    func testConvertCancelledEventWithMissingDates() {
        let gcalEvent = GCalEvent(
            id: "cancelled1",
            status: "cancelled",
            summary: nil,
            location: nil,
            start: nil,
            end: nil,
            colorId: nil,
            organizer: nil,
            updated: nil
        )

        let local = gcalEvent.toLocalEvent(calendarId: "primary")

        XCTAssertNotNil(local, "Cancelled events should convert even without dates")
        XCTAssertTrue(local?.isCancelled ?? false)
        XCTAssertEqual(local?.startDate, .distantPast)
        XCTAssertEqual(local?.summary, "")
    }

    func testConvertNonCancelledEventWithMissingDates() {
        let gcalEvent = GCalEvent(
            id: "broken",
            status: "confirmed",
            summary: "Broken Event",
            location: nil,
            start: nil,
            end: nil,
            colorId: nil,
            organizer: nil,
            updated: nil
        )

        let local = gcalEvent.toLocalEvent(calendarId: "primary")
        XCTAssertNil(local, "Non-cancelled events with missing dates should return nil")
    }

    func testConvertEventDefaultSummary() {
        let gcalEvent = GCalEvent(
            id: "noname",
            status: "confirmed",
            summary: nil,
            location: nil,
            start: GCalDateTime(dateTime: "2024-03-15T10:00:00Z", date: nil, timeZone: nil),
            end: GCalDateTime(dateTime: "2024-03-15T11:00:00Z", date: nil, timeZone: nil),
            colorId: nil,
            organizer: nil,
            updated: nil
        )

        let local = gcalEvent.toLocalEvent(calendarId: "primary")
        XCTAssertEqual(local?.summary, "Untitled")
    }

    // MARK: - GoogleCalendarEvent Codable Round-Trip

    func testGoogleCalendarEventCodable() throws {
        let event = GoogleCalendarEvent(
            id: "roundtrip",
            summary: "Test Event",
            startDate: Date(timeIntervalSince1970: 1710500000),
            endDate: Date(timeIntervalSince1970: 1710503600),
            isAllDay: false,
            location: "Office",
            calendarId: "primary",
            status: "confirmed"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(event)
        let decoded = try decoder.decode(GoogleCalendarEvent.self, from: data)

        XCTAssertEqual(decoded.id, event.id)
        XCTAssertEqual(decoded.summary, event.summary)
        XCTAssertEqual(decoded.startDate, event.startDate)
        XCTAssertEqual(decoded.endDate, event.endDate)
        XCTAssertEqual(decoded.isAllDay, event.isAllDay)
        XCTAssertEqual(decoded.location, event.location)
        XCTAssertEqual(decoded.calendarId, event.calendarId)
        XCTAssertEqual(decoded.status, event.status)
    }

    func testIsCancelledProperty() {
        let confirmed = GoogleCalendarEvent(
            id: "1", summary: "A", startDate: Date(), endDate: Date(),
            isAllDay: false, location: nil, calendarId: "primary", status: "confirmed"
        )
        let cancelled = GoogleCalendarEvent(
            id: "2", summary: "B", startDate: Date(), endDate: Date(),
            isAllDay: false, location: nil, calendarId: "primary", status: "cancelled"
        )
        let tentative = GoogleCalendarEvent(
            id: "3", summary: "C", startDate: Date(), endDate: Date(),
            isAllDay: false, location: nil, calendarId: "primary", status: "tentative"
        )

        XCTAssertFalse(confirmed.isCancelled)
        XCTAssertTrue(cancelled.isCancelled)
        XCTAssertFalse(tentative.isCancelled)
    }
}
