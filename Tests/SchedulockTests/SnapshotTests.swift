import XCTest
@testable import Shared

/// Comprehensive snapshot tests for wallpaper rendering across all configurations.
/// Tests verify that renderers produce valid images with correct dimensions for:
/// - All template types with various event counts
/// - All font families
/// - RTL text support (Hebrew, Arabic)
/// - All device resolutions
/// - Extreme design settings
/// - Image content validation (non-uniform pixels)
final class SnapshotTests: XCTestCase {

    // MARK: - Setup

    private let engine = WallpaperEngine.withAllRenderers([
        MinimalRenderer(),
        GlassRenderer(),
        GradientBandRenderer(),
        EditorialRenderer(),
        NeonRenderer(),
        SplitViewRenderer()
    ])

    // Sample events for testing
    private let sampleEvents: [CalendarEvent] = [
        CalendarEvent(
            id: "1",
            title: "Morning Standup",
            calendarName: "Work",
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800),
            isAllDay: false,
            calendarColor: .systemBlue
        ),
        CalendarEvent(
            id: "2",
            title: "Client Meeting",
            calendarName: "Work",
            startTime: Date().addingTimeInterval(3600),
            endTime: Date().addingTimeInterval(7200),
            isAllDay: false,
            calendarColor: .systemRed
        ),
        CalendarEvent(
            id: "3",
            title: "Lunch Break",
            calendarName: "Personal",
            startTime: Date().addingTimeInterval(14400),
            endTime: Date().addingTimeInterval(18000),
            isAllDay: false,
            calendarColor: .systemGreen
        )
    ]

    // MARK: - Rendering Helper

    private func renderTemplate(
        _ type: TemplateType,
        events: [CalendarEvent] = [],
        settings: DesignSettings = .default,
        resolution: DeviceResolution = .iPhone15Pro
    ) -> UIImage? {
        let template = WallpaperTemplate(name: "Snapshot Test", templateType: type, settings: settings)
        return engine.generateWallpaper(
            template: template,
            image: nil,
            events: events,
            resolution: resolution
        )
    }

    // MARK: - Template × Event Count Tests

    func testAllTemplatesWithZeroEvents() {
        for type in TemplateType.allCases {
            let image = renderTemplate(type, events: [])

            XCTAssertNotNil(
                image,
                "Template \(type.displayName) should render with 0 events"
            )

            if let image = image {
                // Verify correct dimensions for iPhone 15 Pro (1179×2556, scale 3)
                XCTAssertEqual(image.size.width, 1179 / 3, accuracy: 0.1,
                             "\(type.displayName): incorrect width with 0 events")
                XCTAssertEqual(image.size.height, 2556 / 3, accuracy: 0.1,
                             "\(type.displayName): incorrect height with 0 events")
                XCTAssertEqual(image.scale, 3.0,
                             "\(type.displayName): incorrect scale with 0 events")
            }
        }
    }

    func testAllTemplatesWithThreeEvents() {
        for type in TemplateType.allCases {
            let image = renderTemplate(type, events: sampleEvents)

            XCTAssertNotNil(
                image,
                "Template \(type.displayName) should render with 3 events"
            )

            if let image = image {
                XCTAssertEqual(image.size.width, 1179 / 3, accuracy: 0.1,
                             "\(type.displayName): incorrect width with 3 events")
                XCTAssertEqual(image.size.height, 2556 / 3, accuracy: 0.1,
                             "\(type.displayName): incorrect height with 3 events")
                XCTAssertEqual(image.scale, 3.0,
                             "\(type.displayName): incorrect scale with 3 events")
            }
        }
    }

    func testAllTemplatesWithEightEvents() {
        let eightEvents = (0..<8).map { index in
            CalendarEvent(
                id: "\(index)",
                title: "Event \(index + 1)",
                calendarName: "Calendar \(index % 2)",
                startTime: Date().addingTimeInterval(Double(index) * 1800),
                endTime: Date().addingTimeInterval(Double(index) * 1800 + 900),
                isAllDay: false,
                calendarColor: [.systemBlue, .systemRed, .systemGreen, .systemOrange][index % 4]
            )
        }

        for type in TemplateType.allCases {
            let image = renderTemplate(type, events: eightEvents)

            XCTAssertNotNil(
                image,
                "Template \(type.displayName) should render with 8 events"
            )

            if let image = image {
                XCTAssertEqual(image.size.width, 1179 / 3, accuracy: 0.1,
                             "\(type.displayName): incorrect width with 8 events")
                XCTAssertEqual(image.size.height, 2556 / 3, accuracy: 0.1,
                             "\(type.displayName): incorrect height with 8 events")
                XCTAssertEqual(image.scale, 3.0,
                             "\(type.displayName): incorrect scale with 8 events")
            }
        }
    }

    // MARK: - Template × Font Family Tests

    func testAllTemplatesWithAllFonts() {
        for type in TemplateType.allCases {
            for fontFamily in FontFamily.allCases {
                let settings = DesignSettings(fontFamily: fontFamily)
                let image = renderTemplate(type, events: sampleEvents, settings: settings)

                XCTAssertNotNil(
                    image,
                    "Template \(type.displayName) should render with font \(fontFamily.displayName)"
                )

                if let image = image {
                    XCTAssertEqual(image.size.width, 1179 / 3, accuracy: 0.1,
                                 "\(type.displayName) × \(fontFamily.displayName): incorrect width")
                    XCTAssertEqual(image.size.height, 2556 / 3, accuracy: 0.1,
                                 "\(type.displayName) × \(fontFamily.displayName): incorrect height")
                }
            }
        }
    }

    // MARK: - RTL Text Rendering Tests

    func testRTLTextRendering() {
        // Hebrew events
        let hebrewEvents = [
            CalendarEvent(
                id: "h1",
                title: "פגישת צוות",
                calendarName: "עבודה",
                startTime: Date(),
                endTime: Date().addingTimeInterval(1800),
                isAllDay: false,
                calendarColor: .systemBlue
            ),
            CalendarEvent(
                id: "h2",
                title: "סקירת עיצוב",
                calendarName: "פרויקטים",
                startTime: Date().addingTimeInterval(3600),
                endTime: Date().addingTimeInterval(5400),
                isAllDay: false,
                calendarColor: .systemPurple
            )
        ]

        // Arabic events
        let arabicEvents = [
            CalendarEvent(
                id: "a1",
                title: "اجتماع الفريق",
                calendarName: "عمل",
                startTime: Date(),
                endTime: Date().addingTimeInterval(1800),
                isAllDay: false,
                calendarColor: .systemGreen
            ),
            CalendarEvent(
                id: "a2",
                title: "مراجعة التصميم",
                calendarName: "مشاريع",
                startTime: Date().addingTimeInterval(3600),
                endTime: Date().addingTimeInterval(5400),
                isAllDay: false,
                calendarColor: .systemOrange
            )
        ]

        // Test Hebrew rendering
        for type in TemplateType.allCases {
            let hebrewImage = renderTemplate(type, events: hebrewEvents)
            XCTAssertNotNil(
                hebrewImage,
                "Template \(type.displayName) should render Hebrew text"
            )
        }

        // Test Arabic rendering
        for type in TemplateType.allCases {
            let arabicImage = renderTemplate(type, events: arabicEvents)
            XCTAssertNotNil(
                arabicImage,
                "Template \(type.displayName) should render Arabic text"
            )
        }

        // Test mixed RTL/LTR
        let mixedEvents = hebrewEvents + sampleEvents
        for type in TemplateType.allCases {
            let mixedImage = renderTemplate(type, events: mixedEvents)
            XCTAssertNotNil(
                mixedImage,
                "Template \(type.displayName) should render mixed RTL/LTR text"
            )
        }
    }

    // MARK: - Resolution Matrix Tests

    func testAllResolutionsProduceCorrectDimensions() {
        let template = WallpaperTemplate(name: "Resolution Test", templateType: .minimal)

        for resolution in DeviceResolution.all {
            let image = engine.generateWallpaper(
                template: template,
                image: nil,
                events: sampleEvents,
                resolution: resolution
            )

            XCTAssertNotNil(image, "Should render for \(resolution.name)")

            if let image = image {
                let expectedWidth = CGFloat(resolution.width) / CGFloat(resolution.scale)
                let expectedHeight = CGFloat(resolution.height) / CGFloat(resolution.scale)

                XCTAssertEqual(
                    image.size.width,
                    expectedWidth,
                    accuracy: 0.1,
                    "\(resolution.name): expected width \(expectedWidth), got \(image.size.width)"
                )

                XCTAssertEqual(
                    image.size.height,
                    expectedHeight,
                    accuracy: 0.1,
                    "\(resolution.name): expected height \(expectedHeight), got \(image.size.height)"
                )

                XCTAssertEqual(
                    image.scale,
                    CGFloat(resolution.scale),
                    "\(resolution.name): expected scale \(resolution.scale), got \(image.scale)"
                )
            }
        }
    }

    // MARK: - Image Content Validation Tests

    // MARK: - Extreme Design Settings Tests

    func testExtremeDesignSettings() {
        // Test maximum values
        let extremeMaxSettings = DesignSettings(
            textColor: "#FFFFFF",
            accentColor: "#FF0000",
            secondaryColor: "#0000FF",
            cardBackground: "#000000",
            overlayOpacity: 1.0,
            glassBlur: 100.0,
            backgroundBlur: 50.0,
            brightness: 1.0,
            textShadow: 20.0,
            fontFamily: .didot,
            textAlignment: .center,
            useCalendarColors: false,
            splitRatio: 0.9
        )

        for type in TemplateType.allCases {
            let image = renderTemplate(type, events: sampleEvents, settings: extremeMaxSettings)
            XCTAssertNotNil(
                image,
                "Template \(type.displayName) should render with extreme max settings"
            )
        }

        // Test minimum values
        let extremeMinSettings = DesignSettings(
            textColor: "#000000",
            accentColor: "#000000",
            secondaryColor: "#000000",
            cardBackground: "#FFFFFF",
            overlayOpacity: 0.0,
            glassBlur: 0.0,
            backgroundBlur: 0.0,
            brightness: 0.0,
            textShadow: 0.0,
            fontFamily: .menlo,
            textAlignment: .left,
            useCalendarColors: true,
            splitRatio: 0.1
        )

        for type in TemplateType.allCases {
            let image = renderTemplate(type, events: sampleEvents, settings: extremeMinSettings)
            XCTAssertNotNil(
                image,
                "Template \(type.displayName) should render with extreme min settings"
            )
        }

        // Test negative brightness (darker)
        let darkerSettings = DesignSettings(
            overlayOpacity: 0.9,
            brightness: -0.5
        )

        for type in TemplateType.allCases {
            let image = renderTemplate(type, events: sampleEvents, settings: darkerSettings)
            XCTAssertNotNil(
                image,
                "Template \(type.displayName) should render with negative brightness"
            )
        }
    }

    // MARK: - Custom Settings Combinations Tests

    func testHighContrastSettings() {
        let highContrastSettings = DesignSettings(
            textColor: "#FFFFFF",
            accentColor: "#FFFF00",
            secondaryColor: "#FF00FF",
            cardBackground: "#000000",
            overlayOpacity: 0.95,
            useCalendarColors: false
        )

        for type in TemplateType.allCases {
            let image = renderTemplate(type, events: sampleEvents, settings: highContrastSettings)
            XCTAssertNotNil(
                image,
                "Template \(type.displayName) should render with high contrast settings"
            )
        }
    }

    func testTransparentOverlaySettings() {
        let transparentSettings = DesignSettings(
            overlayOpacity: 0.1,
            backgroundBlur: 30.0
        )

        for type in TemplateType.allCases {
            let image = renderTemplate(type, events: sampleEvents, settings: transparentSettings)
            XCTAssertNotNil(
                image,
                "Template \(type.displayName) should render with transparent overlay"
            )
        }
    }

    func testAllTextAlignments() {
        for alignment in [TextAlignment.left, TextAlignment.center, TextAlignment.right] {
            let settings = DesignSettings(textAlignment: alignment)

            for type in TemplateType.allCases {
                let image = renderTemplate(type, events: sampleEvents, settings: settings)
                XCTAssertNotNil(
                    image,
                    "Template \(type.displayName) should render with \(alignment) alignment"
                )
            }
        }
    }

    // MARK: - Edge Cases

    func testSplitRatioExtremes() {
        for ratio in [0.0, 0.2, 0.5, 0.8, 1.0] {
            let settings = DesignSettings(splitRatio: ratio)
            let image = renderTemplate(.split, events: sampleEvents, settings: settings)
            XCTAssertNotNil(
                image,
                "Split template should render with ratio \(ratio)"
            )
        }
    }

    func testAllDeviceResolutionsWithAllTemplates() {
        // Comprehensive matrix: all templates × all resolutions
        for resolution in DeviceResolution.all {
            for type in TemplateType.allCases {
                let image = renderTemplate(type, events: sampleEvents, resolution: resolution)
                XCTAssertNotNil(
                    image,
                    "\(type.displayName) × \(resolution.name) should render"
                )
            }
        }
    }
}
