import XCTest
@testable import Shared

/// Comprehensive rendering pipeline tests.
/// Verifies that all 6 template renderers generate valid wallpapers.
final class RenderingTests: XCTestCase {
    // Create engine with all 6 built-in renderers registered
    let engine = WallpaperEngine.withAllRenderers([
        MinimalRenderer(),
        GlassRenderer(),
        GradientBandRenderer(),
        EditorialRenderer(),
        NeonRenderer(),
        SplitViewRenderer()
    ])

    // Sample event data for testing
    let sampleEvents: [CalendarEvent] = [
        CalendarEvent(
            id: "1",
            title: "Morning Standup",
            calendarName: "Work",
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800), // 30 min
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

    // MARK: - Individual Template Tests

    func testMinimalRendererOutput() {
        let template = WallpaperTemplate(name: "Test Minimal", templateType: .minimal)
        let image = engine.generateWallpaper(
            template: template,
            image: nil,
            events: sampleEvents,
            resolution: .iPhone15Pro
        )

        XCTAssertNotNil(image, "Minimal renderer should generate non-nil image")
        if let image = image {
            XCTAssertEqual(image.size.width, 1179 / 3, accuracy: 0.1) // scale = 3
            XCTAssertEqual(image.size.height, 2556 / 3, accuracy: 0.1)
            XCTAssertEqual(image.scale, 3.0)
        }
    }

    func testGlassRendererOutput() {
        let template = WallpaperTemplate(name: "Test Glass", templateType: .glass)
        let image = engine.generateWallpaper(
            template: template,
            image: nil,
            events: sampleEvents,
            resolution: .iPhone15Pro
        )

        XCTAssertNotNil(image, "Glass renderer should generate non-nil image")
        if let image = image {
            XCTAssertEqual(image.size.width, 1179 / 3, accuracy: 0.1)
            XCTAssertEqual(image.size.height, 2556 / 3, accuracy: 0.1)
            XCTAssertEqual(image.scale, 3.0)
        }
    }

    func testGradientRendererOutput() {
        let template = WallpaperTemplate(name: "Test Gradient", templateType: .gradient)
        let image = engine.generateWallpaper(
            template: template,
            image: nil,
            events: sampleEvents,
            resolution: .iPhone15Pro
        )

        XCTAssertNotNil(image, "Gradient renderer should generate non-nil image")
        if let image = image {
            XCTAssertEqual(image.size.width, 1179 / 3, accuracy: 0.1)
            XCTAssertEqual(image.size.height, 2556 / 3, accuracy: 0.1)
            XCTAssertEqual(image.scale, 3.0)
        }
    }

    func testEditorialRendererOutput() {
        let template = WallpaperTemplate(name: "Test Editorial", templateType: .editorial)
        let image = engine.generateWallpaper(
            template: template,
            image: nil,
            events: sampleEvents,
            resolution: .iPhone15Pro
        )

        XCTAssertNotNil(image, "Editorial renderer should generate non-nil image")
        if let image = image {
            XCTAssertEqual(image.size.width, 1179 / 3, accuracy: 0.1)
            XCTAssertEqual(image.size.height, 2556 / 3, accuracy: 0.1)
            XCTAssertEqual(image.scale, 3.0)
        }
    }

    func testNeonRendererOutput() {
        let template = WallpaperTemplate(name: "Test Neon", templateType: .neon)
        let image = engine.generateWallpaper(
            template: template,
            image: nil,
            events: sampleEvents,
            resolution: .iPhone15Pro
        )

        XCTAssertNotNil(image, "Neon renderer should generate non-nil image")
        if let image = image {
            XCTAssertEqual(image.size.width, 1179 / 3, accuracy: 0.1)
            XCTAssertEqual(image.size.height, 2556 / 3, accuracy: 0.1)
            XCTAssertEqual(image.scale, 3.0)
        }
    }

    func testSplitViewRendererOutput() {
        let template = WallpaperTemplate(name: "Test Split", templateType: .split)
        let image = engine.generateWallpaper(
            template: template,
            image: nil,
            events: sampleEvents,
            resolution: .iPhone15Pro
        )

        XCTAssertNotNil(image, "Split renderer should generate non-nil image")
        if let image = image {
            XCTAssertEqual(image.size.width, 1179 / 3, accuracy: 0.1)
            XCTAssertEqual(image.size.height, 2556 / 3, accuracy: 0.1)
            XCTAssertEqual(image.scale, 3.0)
        }
    }

    // MARK: - Edge Case Tests

    func testRenderingWithNoEvents() {
        for type in TemplateType.allCases {
            let template = WallpaperTemplate(name: "Test", templateType: type)
            let image = engine.generateWallpaper(
                template: template,
                image: nil,
                events: [],
                resolution: .iPhone15Pro
            )
            XCTAssertNotNil(image, "Template \(type.displayName) should render with 0 events")
        }
    }

    func testRenderingWithManyEvents() {
        // Generate 50 events to test overflow/truncation handling
        let manyEvents = (0..<50).map { index in
            CalendarEvent(
                id: "\(index)",
                title: "Event \(index)",
                calendarName: "Test Calendar",
                startTime: Date().addingTimeInterval(Double(index) * 1800),
                endTime: Date().addingTimeInterval(Double(index) * 1800 + 900),
                isAllDay: false,
                calendarColor: .systemBlue
            )
        }

        for type in TemplateType.allCases {
            let template = WallpaperTemplate(name: "Test", templateType: type)
            let image = engine.generateWallpaper(
                template: template,
                image: nil,
                events: manyEvents,
                resolution: .iPhone15Pro
            )
            XCTAssertNotNil(image, "Template \(type.displayName) should render with 50 events")
        }
    }

    func testRenderingWithAllDayEvents() {
        let allDayEvents = [
            CalendarEvent(
                id: "1",
                title: "All Day Event",
                calendarName: "Personal",
                startTime: Calendar.current.startOfDay(for: Date()),
                endTime: Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400),
                isAllDay: true,
                calendarColor: .systemPurple
            )
        ]

        for type in TemplateType.allCases {
            let template = WallpaperTemplate(name: "Test", templateType: type)
            let image = engine.generateWallpaper(
                template: template,
                image: nil,
                events: allDayEvents,
                resolution: .iPhone15Pro
            )
            XCTAssertNotNil(image, "Template \(type.displayName) should render all-day events")
        }
    }

    // MARK: - Resolution Tests

    func testAllDeviceResolutions() {
        let template = WallpaperTemplate(name: "Test", templateType: .minimal)

        for resolution in DeviceResolution.all {
            let image = engine.generateWallpaper(
                template: template,
                image: nil,
                events: sampleEvents,
                resolution: resolution
            )

            XCTAssertNotNil(image, "Should render for \(resolution.name)")

            if let image = image {
                // Verify image dimensions match resolution (divided by scale)
                let expectedWidth = CGFloat(resolution.width) / CGFloat(resolution.scale)
                let expectedHeight = CGFloat(resolution.height) / CGFloat(resolution.scale)

                XCTAssertEqual(image.size.width, expectedWidth, accuracy: 0.1,
                              "Width mismatch for \(resolution.name)")
                XCTAssertEqual(image.size.height, expectedHeight, accuracy: 0.1,
                              "Height mismatch for \(resolution.name)")
                XCTAssertEqual(image.scale, CGFloat(resolution.scale),
                              "Scale mismatch for \(resolution.name)")
            }
        }
    }

    func testIPhoneSE3Resolution() {
        let template = WallpaperTemplate(name: "Test", templateType: .minimal)
        let image = engine.generateWallpaper(
            template: template,
            image: nil,
            events: sampleEvents,
            resolution: .iPhoneSE3
        )

        XCTAssertNotNil(image)
        if let image = image {
            XCTAssertEqual(image.size.width, 750 / 2, accuracy: 0.1) // scale = 2
            XCTAssertEqual(image.size.height, 1334 / 2, accuracy: 0.1)
            XCTAssertEqual(image.scale, 2.0)
        }
    }

    func testIPhone16ProMaxResolution() {
        let template = WallpaperTemplate(name: "Test", templateType: .minimal)
        let image = engine.generateWallpaper(
            template: template,
            image: nil,
            events: sampleEvents,
            resolution: .iPhone16ProMax
        )

        XCTAssertNotNil(image)
        if let image = image {
            XCTAssertEqual(image.size.width, 1320 / 3, accuracy: 0.1) // scale = 3
            XCTAssertEqual(image.size.height, 2868 / 3, accuracy: 0.1)
            XCTAssertEqual(image.scale, 3.0)
        }
    }

    // MARK: - Design Settings Tests

    func testCustomDesignSettings() {
        let customSettings = DesignSettings(
            textColor: "#FF0000",
            accentColor: "#00FF00",
            secondaryColor: "#0000FF",
            cardBackground: "#FFFFFF",
            overlayOpacity: 0.8,
            glassBlur: 40.0,
            backgroundBlur: 10.0,
            brightness: 0.2,
            textShadow: 5.0,
            fontFamily: .futura,
            textAlignment: .center,
            useCalendarColors: false,
            splitRatio: 0.7
        )

        let template = WallpaperTemplate(
            name: "Custom Test",
            templateType: .minimal,
            settings: customSettings
        )

        let image = engine.generateWallpaper(
            template: template,
            image: nil,
            events: sampleEvents,
            resolution: .iPhone15Pro
        )

        XCTAssertNotNil(image, "Should render with custom design settings")
    }

    func testDifferentFontFamilies() {
        for fontFamily in FontFamily.allCases {
            let settings = DesignSettings(fontFamily: fontFamily)
            let template = WallpaperTemplate(
                name: "Font Test",
                templateType: .minimal,
                settings: settings
            )

            let image = engine.generateWallpaper(
                template: template,
                image: nil,
                events: sampleEvents,
                resolution: .iPhone15Pro
            )

            XCTAssertNotNil(image, "Should render with font family: \(fontFamily.displayName)")
        }
    }

    // MARK: - Background Image Tests

    func testRenderingWithBackgroundImage() {
        // Create a simple colored background image
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        UIColor.systemCyan.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let backgroundImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        let template = WallpaperTemplate(name: "Test", templateType: .minimal)
        let image = engine.generateWallpaper(
            template: template,
            image: backgroundImage,
            events: sampleEvents,
            resolution: .iPhone15Pro
        )

        XCTAssertNotNil(image, "Should render with background image")
    }

    // MARK: - Error Handling Tests

    func testUnregisteredTemplateType() {
        // Create an engine with no renderers
        let emptyEngine = WallpaperEngine(renderers: [:])
        let template = WallpaperTemplate(name: "Test", templateType: .minimal)

        let image = emptyEngine.generateWallpaper(
            template: template,
            image: nil,
            events: sampleEvents,
            resolution: .iPhone15Pro
        )

        XCTAssertNil(image, "Should return nil for unregistered template type")
    }

    // MARK: - Integration Tests

    func testRenderAllTemplatesWithAllResolutions() {
        // Comprehensive test: all templates × all resolutions
        for type in TemplateType.allCases {
            let template = WallpaperTemplate(name: "Integration Test", templateType: type)

            for resolution in DeviceResolution.all {
                let image = engine.generateWallpaper(
                    template: template,
                    image: nil,
                    events: sampleEvents,
                    resolution: resolution
                )

                XCTAssertNotNil(
                    image,
                    "Failed: \(type.displayName) × \(resolution.name)"
                )
            }
        }
    }

    func testConcurrentRendering() {
        let expectation = self.expectation(description: "Concurrent rendering")
        expectation.expectedFulfillmentCount = TemplateType.allCases.count

        // Test thread-safety by rendering multiple templates concurrently
        for type in TemplateType.allCases {
            DispatchQueue.global(qos: .userInitiated).async {
                let template = WallpaperTemplate(name: "Concurrent Test", templateType: type)
                let image = self.engine.generateWallpaper(
                    template: template,
                    image: nil,
                    events: self.sampleEvents,
                    resolution: .iPhone15Pro
                )
                XCTAssertNotNil(image, "Concurrent rendering failed for \(type.displayName)")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 10)
    }
}
