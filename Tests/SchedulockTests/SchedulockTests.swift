import XCTest
@testable import Shared

final class SchedulockTests: XCTestCase {
    func testDesignSettingsRoundTrip() throws {
        let settings = DesignSettings(
            textColor: "#FFFFFF",
            accentColor: "#6C63FF",
            fontFamily: .futura,
            splitRatio: 0.6
        )
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(DesignSettings.self, from: data)
        XCTAssertEqual(settings, decoded)
    }

    func testTemplateTypeCases() {
        XCTAssertEqual(TemplateType.allCases.count, 6)
    }

    func testCalendarEventTruncation() {
        let shortEvent = CalendarEvent(
            id: "1", title: "Standup", calendarName: "Work",
            startTime: Date(), endTime: Date(),
            isAllDay: false, calendarColor: .blue
        )
        XCTAssertEqual(shortEvent.truncatedTitle, "Standup")

        let longTitle = String(repeating: "A", count: 50)
        let longEvent = CalendarEvent(
            id: "2", title: longTitle, calendarName: "Work",
            startTime: Date(), endTime: Date(),
            isAllDay: false, calendarColor: .red
        )
        XCTAssertEqual(longEvent.truncatedTitle.count, 33) // 32 chars + ellipsis
    }
}
