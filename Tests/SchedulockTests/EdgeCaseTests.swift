import XCTest
@testable import Shared

/// Comprehensive edge case tests for Schedulock wallpaper rendering engine.
/// Tests boundary conditions, empty states, volume stress, and extreme parameter values.
final class EdgeCaseTests: XCTestCase {

    // Test engine with all renderers
    private let engine = WallpaperEngine.withAllRenderers([
        MinimalRenderer(), GlassRenderer(), GradientBandRenderer(),
        EditorialRenderer(), NeonRenderer(), SplitViewRenderer()
    ])

    private let testResolution = DeviceResolution.iPhone15Pro
    private let testDate = Date()

    // MARK: - Empty/Missing Data Tests

    func testRenderWithNoEvents() {
        // All templates should render successfully with empty event array
        for templateType in TemplateType.allCases {
            let template = WallpaperTemplate(
                name: "Test \(templateType.displayName)",
                templateType: templateType
            )

            let result = engine.generateWallpaper(
                template: template,
                image: nil,
                events: [],
                resolution: testResolution,
                date: testDate
            )

            XCTAssertNotNil(result, "\(templateType.displayName) should render with no events")
        }
    }

    func testRenderWithNoCalendars() {
        // Empty calendar IDs list - should still render without crashing
        let template = WallpaperTemplate(name: "Empty Calendars", templateType: .minimal)

        let result = engine.generateWallpaper(
            template: template,
            image: nil,
            events: [],
            resolution: testResolution,
            date: testDate
        )

        XCTAssertNotNil(result, "Should render with no calendar IDs")
    }

    func testRenderWithNilBackgroundImage() {
        // Should use gradient fallback when no background image provided
        let template = WallpaperTemplate(name: "No Image", templateType: .minimal)

        let events = [
            CalendarEvent(
                id: "1",
                title: "Meeting",
                calendarName: "Work",
                startTime: testDate,
                endTime: testDate.addingTimeInterval(3600),
                isAllDay: false,
                calendarColor: .blue
            )
        ]

        let result = engine.generateWallpaper(
            template: template,
            image: nil, // Explicitly nil
            events: events,
            resolution: testResolution,
            date: testDate
        )

        XCTAssertNotNil(result, "Should render with nil background image using fallback gradient")
    }

    // MARK: - Title Edge Cases

    func testVeryLongTitle() {
        let longTitle = String(repeating: "A", count: 150)
        let event = CalendarEvent(
            id: "1",
            title: longTitle,
            calendarName: "Work",
            startTime: testDate,
            endTime: testDate.addingTimeInterval(3600),
            isAllDay: false,
            calendarColor: .blue
        )

        // Should truncate properly
        XCTAssertEqual(event.truncatedTitle.count, 33) // 32 + ellipsis
        XCTAssertTrue(event.truncatedTitle.hasSuffix("…"))

        // Should render without crashing
        let template = WallpaperTemplate(name: "Long Title", templateType: .minimal)
        let result = engine.generateWallpaper(
            template: template,
            image: nil,
            events: [event],
            resolution: testResolution,
            date: testDate
        )

        XCTAssertNotNil(result, "Should render event with 150 character title")
    }

    func testEmptyTitle() {
        let event = CalendarEvent(
            id: "1",
            title: "",
            calendarName: "Work",
            startTime: testDate,
            endTime: testDate.addingTimeInterval(3600),
            isAllDay: false,
            calendarColor: .blue
        )

        XCTAssertEqual(event.truncatedTitle, "")

        let template = WallpaperTemplate(name: "Empty Title", templateType: .minimal)
        let result = engine.generateWallpaper(
            template: template,
            image: nil,
            events: [event],
            resolution: testResolution,
            date: testDate
        )

        XCTAssertNotNil(result, "Should render event with empty title")
    }

    func testTitleWithOnlySpaces() {
        let event = CalendarEvent(
            id: "1",
            title: "     ",
            calendarName: "Work",
            startTime: testDate,
            endTime: testDate.addingTimeInterval(3600),
            isAllDay: false,
            calendarColor: .blue
        )

        XCTAssertEqual(event.truncatedTitle, "     ")

        let template = WallpaperTemplate(name: "Whitespace Title", templateType: .editorial)
        let result = engine.generateWallpaper(
            template: template,
            image: nil,
            events: [event],
            resolution: testResolution,
            date: testDate
        )

        XCTAssertNotNil(result, "Should render event with whitespace-only title")
    }

    func testTitleWithEmoji() {
        let event = CalendarEvent(
            id: "1",
            title: "🎉 Party 🎊",
            calendarName: "Personal",
            startTime: testDate,
            endTime: testDate.addingTimeInterval(3600),
            isAllDay: false,
            calendarColor: .systemPink
        )

        let template = WallpaperTemplate(name: "Emoji Title", templateType: .neon)
        let result = engine.generateWallpaper(
            template: template,
            image: nil,
            events: [event],
            resolution: testResolution,
            date: testDate
        )

        XCTAssertNotNil(result, "Should render event with emoji in title")
    }

    func testTitleWithSpecialChars() {
        let specialTitles = [
            "Meeting \"with quotes\"",
            "Cost & Expenses",
            "<html> tags </html>",
            "Line\nBreak\nTest",
            "Tab\tSeparated\tValues"
        ]

        for specialTitle in specialTitles {
            let event = CalendarEvent(
                id: "special",
                title: specialTitle,
                calendarName: "Work",
                startTime: testDate,
                endTime: testDate.addingTimeInterval(3600),
                isAllDay: false,
                calendarColor: .blue
            )

            let template = WallpaperTemplate(name: "Special Chars", templateType: .glass)
            let result = engine.generateWallpaper(
                template: template,
                image: nil,
                events: [event],
                resolution: testResolution,
                date: testDate
            )

            XCTAssertNotNil(result, "Should render event with special characters: \(specialTitle)")
        }
    }

    func testTitleWithUnicodeRTL() {
        let hebrewEvent = CalendarEvent(
            id: "1",
            title: "פגישה",
            calendarName: "Work",
            startTime: testDate,
            endTime: testDate.addingTimeInterval(3600),
            isAllDay: false,
            calendarColor: .blue
        )

        let arabicEvent = CalendarEvent(
            id: "2",
            title: "اجتماع",
            calendarName: "Work",
            startTime: testDate.addingTimeInterval(3600),
            endTime: testDate.addingTimeInterval(7200),
            isAllDay: false,
            calendarColor: .green
        )

        let template = WallpaperTemplate(name: "RTL Text", templateType: .minimal)
        let result = engine.generateWallpaper(
            template: template,
            image: nil,
            events: [hebrewEvent, arabicEvent],
            resolution: testResolution,
            date: testDate
        )

        XCTAssertNotNil(result, "Should render events with Hebrew and Arabic text")
    }

    // MARK: - Time Edge Cases

    func testMidnightRolloverEvents() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 23
        components.minute = 59
        components.second = 0

        guard let startTime = calendar.date(from: components) else {
            XCTFail("Failed to create midnight test date")
            return
        }

        let endTime = startTime.addingTimeInterval(120) // 2 minutes, crosses midnight

        let event = CalendarEvent(
            id: "midnight",
            title: "Midnight Event",
            calendarName: "Work",
            startTime: startTime,
            endTime: endTime,
            isAllDay: false,
            calendarColor: .purple
        )

        let template = WallpaperTemplate(name: "Midnight Rollover", templateType: .gradient)
        let result = engine.generateWallpaper(
            template: template,
            image: nil,
            events: [event],
            resolution: testResolution,
            date: startTime
        )

        XCTAssertNotNil(result, "Should render event crossing midnight boundary")
    }

    func testZeroDurationEvent() {
        let event = CalendarEvent(
            id: "zero",
            title: "Zero Duration",
            calendarName: "Work",
            startTime: testDate,
            endTime: testDate, // Same as start
            isAllDay: false,
            calendarColor: .blue
        )

        let template = WallpaperTemplate(name: "Zero Duration", templateType: .editorial)
        let result = engine.generateWallpaper(
            template: template,
            image: nil,
            events: [event],
            resolution: testResolution,
            date: testDate
        )

        XCTAssertNotNil(result, "Should render event with zero duration")
    }

    func testMultiDayEvent() {
        let startTime = testDate
        let endTime = testDate.addingTimeInterval(86400 * 3) // 3 days

        let event = CalendarEvent(
            id: "multiday",
            title: "Multi-Day Conference",
            calendarName: "Work",
            startTime: startTime,
            endTime: endTime,
            isAllDay: true,
            calendarColor: .orange
        )

        let template = WallpaperTemplate(name: "Multi-Day", templateType: .split)
        let result = engine.generateWallpaper(
            template: template,
            image: nil,
            events: [event],
            resolution: testResolution,
            date: testDate
        )

        XCTAssertNotNil(result, "Should render multi-day event")
    }

    func testAllDayOnlyEvents() {
        let allDayEvents = (0..<5).map { i in
            CalendarEvent(
                id: "allday-\(i)",
                title: "All Day Event \(i)",
                calendarName: "Work",
                startTime: testDate.addingTimeInterval(Double(i) * 86400),
                endTime: testDate.addingTimeInterval(Double(i) * 86400),
                isAllDay: true,
                calendarColor: .systemTeal
            )
        }

        let template = WallpaperTemplate(name: "All Day Only", templateType: .minimal)
        let result = engine.generateWallpaper(
            template: template,
            image: nil,
            events: allDayEvents,
            resolution: testResolution,
            date: testDate
        )

        XCTAssertNotNil(result, "Should render only all-day events")
    }

    func testEventsInThePast() {
        let pastEvents = (0..<5).map { i in
            CalendarEvent(
                id: "past-\(i)",
                title: "Past Event \(i)",
                calendarName: "Work",
                startTime: testDate.addingTimeInterval(-3600 * Double(i + 1)), // 1-5 hours ago
                endTime: testDate.addingTimeInterval(-3600 * Double(i)),
                isAllDay: false,
                calendarColor: .gray
            )
        }

        let template = WallpaperTemplate(name: "All Past", templateType: .glass)
        let result = engine.generateWallpaper(
            template: template,
            image: nil,
            events: pastEvents,
            resolution: testResolution,
            date: testDate
        )

        XCTAssertNotNil(result, "Should render all past events")
    }

    // MARK: - Volume Stress Tests

    func testOneHundredEvents() {
        let hundredEvents = (0..<100).map { i in
            CalendarEvent(
                id: "event-\(i)",
                title: "Event Number \(i)",
                calendarName: "Work",
                startTime: testDate.addingTimeInterval(Double(i) * 1800), // 30 min apart
                endTime: testDate.addingTimeInterval(Double(i) * 1800 + 1800),
                isAllDay: false,
                calendarColor: .blue
            )
        }

        let template = WallpaperTemplate(name: "100 Events", templateType: .minimal)
        let result = engine.generateWallpaper(
            template: template,
            image: nil,
            events: hundredEvents,
            resolution: testResolution,
            date: testDate
        )

        XCTAssertNotNil(result, "Should handle 100 events without crashing")
    }

    func testFiftyAllDayEvents() {
        let fiftyAllDay = (0..<50).map { i in
            CalendarEvent(
                id: "allday-\(i)",
                title: "All Day \(i)",
                calendarName: "Calendar \(i % 3)",
                startTime: testDate.addingTimeInterval(Double(i) * 86400),
                endTime: testDate.addingTimeInterval(Double(i) * 86400),
                isAllDay: true,
                calendarColor: [.red, .green, .blue, .orange, .purple][i % 5]
            )
        }

        let template = WallpaperTemplate(name: "50 All Day", templateType: .gradient)
        let result = engine.generateWallpaper(
            template: template,
            image: nil,
            events: fiftyAllDay,
            resolution: testResolution,
            date: testDate
        )

        XCTAssertNotNil(result, "Should handle 50 all-day events")
    }

    func testSingleEvent() {
        let singleEvent = CalendarEvent(
            id: "single",
            title: "Only Event",
            calendarName: "Work",
            startTime: testDate,
            endTime: testDate.addingTimeInterval(3600),
            isAllDay: false,
            calendarColor: .blue
        )

        for templateType in TemplateType.allCases {
            let template = WallpaperTemplate(
                name: "Single Event",
                templateType: templateType
            )

            let result = engine.generateWallpaper(
                template: template,
                image: nil,
                events: [singleEvent],
                resolution: testResolution,
                date: testDate
            )

            XCTAssertNotNil(result, "\(templateType.displayName) should render single event")
        }
    }

    // MARK: - DesignSettings Extremes

    func testZeroOpacity() {
        let settings = DesignSettings(overlayOpacity: 0.0)
        let template = WallpaperTemplate(
            name: "Zero Opacity",
            templateType: .minimal,
            settings: settings
        )

        let result = engine.generateWallpaper(
            template: template,
            image: nil,
            events: [sampleEvent()],
            resolution: testResolution,
            date: testDate
        )

        XCTAssertNotNil(result, "Should render with zero overlay opacity")
    }

    func testFullOpacity() {
        let settings = DesignSettings(overlayOpacity: 1.0)
        let template = WallpaperTemplate(
            name: "Full Opacity",
            templateType: .glass,
            settings: settings
        )

        let result = engine.generateWallpaper(
            template: template,
            image: nil,
            events: [sampleEvent()],
            resolution: testResolution,
            date: testDate
        )

        XCTAssertNotNil(result, "Should render with full overlay opacity")
    }

    func testMaxBlur() {
        let settings = DesignSettings(
            glassBlur: 50.0,
            backgroundBlur: 30.0
        )
        let template = WallpaperTemplate(
            name: "Max Blur",
            templateType: .glass,
            settings: settings
        )

        let result = engine.generateWallpaper(
            template: template,
            image: nil,
            events: [sampleEvent()],
            resolution: testResolution,
            date: testDate
        )

        XCTAssertNotNil(result, "Should render with maximum blur values")
    }

    func testZeroBlur() {
        let settings = DesignSettings(
            glassBlur: 0.0,
            backgroundBlur: 0.0
        )
        let template = WallpaperTemplate(
            name: "Zero Blur",
            templateType: .glass,
            settings: settings
        )

        let result = engine.generateWallpaper(
            template: template,
            image: nil,
            events: [sampleEvent()],
            resolution: testResolution,
            date: testDate
        )

        XCTAssertNotNil(result, "Should render with zero blur")
    }

    func testExtremeBrightness() {
        // Test minimum brightness
        let darkSettings = DesignSettings(brightness: -0.5)
        let darkTemplate = WallpaperTemplate(
            name: "Dark Extreme",
            templateType: .editorial,
            settings: darkSettings
        )

        let darkResult = engine.generateWallpaper(
            template: darkTemplate,
            image: nil,
            events: [sampleEvent()],
            resolution: testResolution,
            date: testDate
        )

        XCTAssertNotNil(darkResult, "Should render with minimum brightness (-0.5)")

        // Test maximum brightness
        let brightSettings = DesignSettings(brightness: 0.5)
        let brightTemplate = WallpaperTemplate(
            name: "Bright Extreme",
            templateType: .editorial,
            settings: brightSettings
        )

        let brightResult = engine.generateWallpaper(
            template: brightTemplate,
            image: nil,
            events: [sampleEvent()],
            resolution: testResolution,
            date: testDate
        )

        XCTAssertNotNil(brightResult, "Should render with maximum brightness (+0.5)")
    }

    func testZeroTextShadow() {
        let settings = DesignSettings(textShadow: 0.0)
        let template = WallpaperTemplate(
            name: "No Shadow",
            templateType: .minimal,
            settings: settings
        )

        let result = engine.generateWallpaper(
            template: template,
            image: nil,
            events: [sampleEvent()],
            resolution: testResolution,
            date: testDate
        )

        XCTAssertNotNil(result, "Should render with zero text shadow")
    }

    func testMaxTextShadow() {
        let settings = DesignSettings(textShadow: 10.0)
        let template = WallpaperTemplate(
            name: "Max Shadow",
            templateType: .neon,
            settings: settings
        )

        let result = engine.generateWallpaper(
            template: template,
            image: nil,
            events: [sampleEvent()],
            resolution: testResolution,
            date: testDate
        )

        XCTAssertNotNil(result, "Should render with maximum text shadow")
    }

    func testExtremeSplitRatio() {
        // Test minimum split ratio
        let minSettings = DesignSettings(splitRatio: 0.3)
        let minTemplate = WallpaperTemplate(
            name: "Min Split",
            templateType: .split,
            settings: minSettings
        )

        let minResult = engine.generateWallpaper(
            template: minTemplate,
            image: nil,
            events: [sampleEvent()],
            resolution: testResolution,
            date: testDate
        )

        XCTAssertNotNil(minResult, "Should render with minimum split ratio (0.3)")

        // Test maximum split ratio
        let maxSettings = DesignSettings(splitRatio: 0.8)
        let maxTemplate = WallpaperTemplate(
            name: "Max Split",
            templateType: .split,
            settings: maxSettings
        )

        let maxResult = engine.generateWallpaper(
            template: maxTemplate,
            image: nil,
            events: [sampleEvent()],
            resolution: testResolution,
            date: testDate
        )

        XCTAssertNotNil(maxResult, "Should render with maximum split ratio (0.8)")
    }

    // MARK: - Resolution Boundaries

    func testSmallestDevice() {
        let smallDevice = DeviceResolution.iPhoneSE3
        let template = WallpaperTemplate(name: "Small Device", templateType: .minimal)

        let result = engine.generateWallpaper(
            template: template,
            image: nil,
            events: [sampleEvent()],
            resolution: smallDevice,
            date: testDate
        )

        XCTAssertNotNil(result, "Should render at smallest device resolution (iPhone SE3)")
        XCTAssertEqual(result?.size.width, CGFloat(smallDevice.width))
        XCTAssertEqual(result?.size.height, CGFloat(smallDevice.height))
        XCTAssertEqual(result?.scale, CGFloat(smallDevice.scale))
    }

    func testLargestDevice() {
        let largeDevice = DeviceResolution.iPhone16ProMax
        let template = WallpaperTemplate(name: "Large Device", templateType: .gradient)

        let result = engine.generateWallpaper(
            template: template,
            image: nil,
            events: [sampleEvent()],
            resolution: largeDevice,
            date: testDate
        )

        XCTAssertNotNil(result, "Should render at largest device resolution (iPhone 16 Pro Max)")
        XCTAssertEqual(result?.size.width, CGFloat(largeDevice.width))
        XCTAssertEqual(result?.size.height, CGFloat(largeDevice.height))
        XCTAssertEqual(result?.scale, CGFloat(largeDevice.scale))
    }

    // MARK: - CalendarEvent Boundary Tests

    func testTruncatedTitleExactly32Chars() {
        let exactTitle = String(repeating: "X", count: 32)
        let event = CalendarEvent(
            id: "exact",
            title: exactTitle,
            calendarName: "Work",
            startTime: testDate,
            endTime: testDate.addingTimeInterval(3600),
            isAllDay: false,
            calendarColor: .blue
        )

        XCTAssertEqual(event.truncatedTitle, exactTitle)
        XCTAssertEqual(event.truncatedTitle.count, 32)
        XCTAssertFalse(event.truncatedTitle.hasSuffix("…"))
    }

    func testTruncatedTitle33Chars() {
        let title = String(repeating: "Y", count: 33)
        let event = CalendarEvent(
            id: "over",
            title: title,
            calendarName: "Work",
            startTime: testDate,
            endTime: testDate.addingTimeInterval(3600),
            isAllDay: false,
            calendarColor: .blue
        )

        XCTAssertEqual(event.truncatedTitle.count, 33) // 32 + ellipsis
        XCTAssertTrue(event.truncatedTitle.hasSuffix("…"))
        XCTAssertEqual(String(event.truncatedTitle.dropLast()).count, 32)
    }

    func testTruncatedTitle31Chars() {
        let title = String(repeating: "Z", count: 31)
        let event = CalendarEvent(
            id: "under",
            title: title,
            calendarName: "Work",
            startTime: testDate,
            endTime: testDate.addingTimeInterval(3600),
            isAllDay: false,
            calendarColor: .blue
        )

        XCTAssertEqual(event.truncatedTitle, title)
        XCTAssertEqual(event.truncatedTitle.count, 31)
        XCTAssertFalse(event.truncatedTitle.hasSuffix("…"))
    }

    // MARK: - Helper Methods

    private func sampleEvent() -> CalendarEvent {
        CalendarEvent(
            id: "sample",
            title: "Sample Event",
            calendarName: "Work",
            startTime: testDate,
            endTime: testDate.addingTimeInterval(3600),
            isAllDay: false,
            calendarColor: .blue
        )
    }
}
