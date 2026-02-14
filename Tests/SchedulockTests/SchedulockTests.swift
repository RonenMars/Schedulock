import XCTest
@testable import Shared

/// Unit tests for core Schedulock data models and utilities.
final class SchedulockTests: XCTestCase {

    // MARK: - DesignSettings Tests

    func testDesignSettingsRoundTrip() throws {
        let settings = DesignSettings(
            textColor: "#FFFFFF",
            accentColor: "#6C63FF",
            secondaryColor: "#E040FB",
            cardBackground: "#0F1014",
            overlayOpacity: 0.4,
            glassBlur: 20.0,
            backgroundBlur: 0.0,
            brightness: 0.0,
            textShadow: 2.0,
            fontFamily: .futura,
            textAlignment: .left,
            useCalendarColors: true,
            splitRatio: 0.6
        )

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(DesignSettings.self, from: data)

        // Verify ALL fields are preserved
        XCTAssertEqual(settings.textColor, decoded.textColor)
        XCTAssertEqual(settings.accentColor, decoded.accentColor)
        XCTAssertEqual(settings.secondaryColor, decoded.secondaryColor)
        XCTAssertEqual(settings.cardBackground, decoded.cardBackground)
        XCTAssertEqual(settings.overlayOpacity, decoded.overlayOpacity)
        XCTAssertEqual(settings.glassBlur, decoded.glassBlur)
        XCTAssertEqual(settings.backgroundBlur, decoded.backgroundBlur)
        XCTAssertEqual(settings.brightness, decoded.brightness)
        XCTAssertEqual(settings.textShadow, decoded.textShadow)
        XCTAssertEqual(settings.fontFamily, decoded.fontFamily)
        XCTAssertEqual(settings.textAlignment, decoded.textAlignment)
        XCTAssertEqual(settings.useCalendarColors, decoded.useCalendarColors)
        XCTAssertEqual(settings.splitRatio, decoded.splitRatio)

        // Verify equality operator works
        XCTAssertEqual(settings, decoded)
    }

    func testDesignSettingsDefaultValues() {
        let defaults = DesignSettings.default

        XCTAssertEqual(defaults.textColor, "#E8E8ED")
        XCTAssertEqual(defaults.accentColor, "#6C63FF")
        XCTAssertEqual(defaults.secondaryColor, "#E040FB")
        XCTAssertEqual(defaults.cardBackground, "#0F1014")
        XCTAssertEqual(defaults.overlayOpacity, 0.4)
        XCTAssertEqual(defaults.glassBlur, 20.0)
        XCTAssertEqual(defaults.backgroundBlur, 0.0)
        XCTAssertEqual(defaults.brightness, 0.0)
        XCTAssertEqual(defaults.textShadow, 2.0)
        XCTAssertEqual(defaults.fontFamily, .sfPro)
        XCTAssertEqual(defaults.textAlignment, .left)
        XCTAssertTrue(defaults.useCalendarColors)
        XCTAssertEqual(defaults.splitRatio, 0.55)
    }

    func testDesignSettingsWithAllFontFamilies() throws {
        for fontFamily in FontFamily.allCases {
            let settings = DesignSettings(fontFamily: fontFamily)
            let data = try JSONEncoder().encode(settings)
            let decoded = try JSONDecoder().decode(DesignSettings.self, from: data)

            XCTAssertEqual(settings.fontFamily, decoded.fontFamily,
                          "Font family \(fontFamily.displayName) not preserved")
        }
    }

    func testDesignSettingsWithAllTextAlignments() throws {
        for alignment in TextAlignment.allCases {
            let settings = DesignSettings(textAlignment: alignment)
            let data = try JSONEncoder().encode(settings)
            let decoded = try JSONDecoder().decode(DesignSettings.self, from: data)

            XCTAssertEqual(settings.textAlignment, decoded.textAlignment,
                          "Text alignment \(alignment) not preserved")
        }
    }

    // MARK: - TemplateType Tests

    func testTemplateTypeCases() {
        XCTAssertEqual(TemplateType.allCases.count, 6)

        let expectedTypes: Set<TemplateType> = [
            .minimal, .glass, .gradient, .editorial, .neon, .split
        ]
        XCTAssertEqual(Set(TemplateType.allCases), expectedTypes)
    }

    func testTemplateTypeDisplayNames() {
        XCTAssertEqual(TemplateType.minimal.displayName, "Minimal")
        XCTAssertEqual(TemplateType.glass.displayName, "Frosted Glass")
        XCTAssertEqual(TemplateType.gradient.displayName, "Gradient Band")
        XCTAssertEqual(TemplateType.editorial.displayName, "Editorial")
        XCTAssertEqual(TemplateType.neon.displayName, "Neon Glow")
        XCTAssertEqual(TemplateType.split.displayName, "Split View")
    }

    func testTemplateTypeRawValues() {
        XCTAssertEqual(TemplateType.minimal.rawValue, "minimal")
        XCTAssertEqual(TemplateType.glass.rawValue, "glass")
        XCTAssertEqual(TemplateType.gradient.rawValue, "gradient")
        XCTAssertEqual(TemplateType.editorial.rawValue, "editorial")
        XCTAssertEqual(TemplateType.neon.rawValue, "neon")
        XCTAssertEqual(TemplateType.split.rawValue, "split")
    }

    func testTemplateTypeCodable() throws {
        for type in TemplateType.allCases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(TemplateType.self, from: data)
            XCTAssertEqual(type, decoded)
        }
    }

    // MARK: - FontFamily Tests

    func testFontFamilyAllCasesHaveFontNames() {
        for fontFamily in FontFamily.allCases {
            XCTAssertFalse(fontFamily.fontName.isEmpty,
                          "Font family \(fontFamily.displayName) has empty fontName")
        }
    }

    func testFontFamilyDisplayNames() {
        XCTAssertEqual(FontFamily.sfPro.displayName, "SF Pro")
        XCTAssertEqual(FontFamily.avenir.displayName, "Avenir")
        XCTAssertEqual(FontFamily.georgia.displayName, "Georgia")
        XCTAssertEqual(FontFamily.futura.displayName, "Futura")
        XCTAssertEqual(FontFamily.menlo.displayName, "Menlo")
        XCTAssertEqual(FontFamily.didot.displayName, "Didot")
    }

    func testFontFamilyFontNames() {
        XCTAssertEqual(FontFamily.sfPro.fontName, ".SFUI-Regular")
        XCTAssertEqual(FontFamily.avenir.fontName, "Avenir")
        XCTAssertEqual(FontFamily.georgia.fontName, "Georgia")
        XCTAssertEqual(FontFamily.futura.fontName, "Futura-Medium")
        XCTAssertEqual(FontFamily.menlo.fontName, "Menlo-Regular")
        XCTAssertEqual(FontFamily.didot.fontName, "Didot")
    }

    func testFontFamilyCount() {
        XCTAssertEqual(FontFamily.allCases.count, 6)
    }

    // MARK: - CalendarEvent Tests

    func testCalendarEventTruncation() {
        let shortEvent = CalendarEvent(
            id: "1",
            title: "Standup",
            calendarName: "Work",
            startTime: Date(),
            endTime: Date(),
            isAllDay: false,
            calendarColor: .blue
        )
        XCTAssertEqual(shortEvent.truncatedTitle, "Standup")

        let longTitle = String(repeating: "A", count: 50)
        let longEvent = CalendarEvent(
            id: "2",
            title: longTitle,
            calendarName: "Work",
            startTime: Date(),
            endTime: Date(),
            isAllDay: false,
            calendarColor: .red
        )
        XCTAssertEqual(longEvent.truncatedTitle.count, 33) // 32 chars + ellipsis
        XCTAssertTrue(longEvent.truncatedTitle.hasSuffix("…"))
    }

    func testCalendarEventTruncationExactly32Chars() {
        let exactTitle = String(repeating: "X", count: 32)
        let event = CalendarEvent(
            id: "1",
            title: exactTitle,
            calendarName: "Work",
            startTime: Date(),
            endTime: Date(),
            isAllDay: false,
            calendarColor: .blue
        )
        XCTAssertEqual(event.truncatedTitle, exactTitle)
        XCTAssertEqual(event.truncatedTitle.count, 32)
    }

    func testCalendarEventTruncation33Chars() {
        let title = String(repeating: "Y", count: 33)
        let event = CalendarEvent(
            id: "1",
            title: title,
            calendarName: "Work",
            startTime: Date(),
            endTime: Date(),
            isAllDay: false,
            calendarColor: .blue
        )
        XCTAssertEqual(event.truncatedTitle.count, 33) // 32 + ellipsis
        XCTAssertTrue(event.truncatedTitle.hasSuffix("…"))
    }

    func testCalendarEventTruncationEmptyString() {
        let event = CalendarEvent(
            id: "1",
            title: "",
            calendarName: "Work",
            startTime: Date(),
            endTime: Date(),
            isAllDay: false,
            calendarColor: .blue
        )
        XCTAssertEqual(event.truncatedTitle, "")
    }

    func testCalendarEventTruncationUnicode() {
        // Test with emoji and unicode characters
        let unicodeTitle = "🎉 Meeting with café ☕️ discussion 📝 about résumé review"
        let event = CalendarEvent(
            id: "1",
            title: unicodeTitle,
            calendarName: "Work",
            startTime: Date(),
            endTime: Date(),
            isAllDay: false,
            calendarColor: .blue
        )

        let truncated = event.truncatedTitle
        XCTAssertTrue(truncated.count <= 33, "Unicode title should be truncated")

        if unicodeTitle.count > 32 {
            XCTAssertTrue(truncated.hasSuffix("…"), "Long unicode title should have ellipsis")
        }
    }

    func testCalendarEventProperties() {
        let start = Date()
        let end = start.addingTimeInterval(3600)

        let event = CalendarEvent(
            id: "test-123",
            title: "Team Meeting",
            calendarName: "Work Calendar",
            startTime: start,
            endTime: end,
            isAllDay: false,
            calendarColor: .systemPurple,
            location: "Conference Room A"
        )

        XCTAssertEqual(event.id, "test-123")
        XCTAssertEqual(event.title, "Team Meeting")
        XCTAssertEqual(event.calendarName, "Work Calendar")
        XCTAssertEqual(event.startTime, start)
        XCTAssertEqual(event.endTime, end)
        XCTAssertFalse(event.isAllDay)
        XCTAssertEqual(event.calendarColor, .systemPurple)
        XCTAssertEqual(event.location, "Conference Room A")
    }

    // MARK: - DeviceResolution Tests

    func testDeviceResolutionPresets() {
        XCTAssertEqual(DeviceResolution.iPhoneSE3.width, 750)
        XCTAssertEqual(DeviceResolution.iPhoneSE3.height, 1334)
        XCTAssertEqual(DeviceResolution.iPhoneSE3.scale, 2)

        XCTAssertEqual(DeviceResolution.iPhone15Pro.width, 1179)
        XCTAssertEqual(DeviceResolution.iPhone15Pro.height, 2556)
        XCTAssertEqual(DeviceResolution.iPhone15Pro.scale, 3)

        XCTAssertEqual(DeviceResolution.iPhone16ProMax.width, 1320)
        XCTAssertEqual(DeviceResolution.iPhone16ProMax.height, 2868)
        XCTAssertEqual(DeviceResolution.iPhone16ProMax.scale, 3)
    }

    func testDeviceResolutionSizeCalculation() {
        let resolution = DeviceResolution.iPhone15Pro
        let size = resolution.size

        XCTAssertEqual(size.width, CGFloat(resolution.width))
        XCTAssertEqual(size.height, CGFloat(resolution.height))
    }

    func testDeviceResolutionAllCount() {
        XCTAssertEqual(DeviceResolution.all.count, 6)
    }

    func testDeviceResolutionNames() {
        XCTAssertEqual(DeviceResolution.iPhoneSE3.name, "iPhone SE 3")
        XCTAssertEqual(DeviceResolution.iPhone14.name, "iPhone 14/15")
        XCTAssertEqual(DeviceResolution.iPhone15Pro.name, "iPhone 15 Pro")
        XCTAssertEqual(DeviceResolution.iPhone15ProMax.name, "iPhone 15 Pro Max")
        XCTAssertEqual(DeviceResolution.iPhone16Pro.name, "iPhone 16 Pro")
        XCTAssertEqual(DeviceResolution.iPhone16ProMax.name, "iPhone 16 Pro Max")
    }

    // MARK: - WallpaperTemplate Tests

    func testWallpaperTemplateInitialization() {
        let template = WallpaperTemplate(
            name: "My Template",
            templateType: .minimal
        )

        XCTAssertEqual(template.name, "My Template")
        XCTAssertEqual(template.templateType, .minimal)
        XCTAssertFalse(template.isBuiltIn)
        XCTAssertEqual(template.settings, .default)
    }

    func testWallpaperTemplateWithCustomSettings() {
        let customSettings = DesignSettings(
            textColor: "#FF0000",
            accentColor: "#00FF00"
        )

        let template = WallpaperTemplate(
            name: "Custom Template",
            templateType: .neon,
            isBuiltIn: true,
            settings: customSettings
        )

        XCTAssertEqual(template.name, "Custom Template")
        XCTAssertEqual(template.templateType, .neon)
        XCTAssertTrue(template.isBuiltIn)
        XCTAssertEqual(template.settings.textColor, "#FF0000")
        XCTAssertEqual(template.settings.accentColor, "#00FF00")
    }

    func testWallpaperTemplateSettingsPersistence() throws {
        let settings = DesignSettings(
            textColor: "#AABBCC",
            fontFamily: .didot,
            splitRatio: 0.75
        )

        var template = WallpaperTemplate(
            name: "Test",
            templateType: .split,
            settings: settings
        )

        // Verify settings are stored correctly
        XCTAssertEqual(template.settings.textColor, "#AABBCC")
        XCTAssertEqual(template.settings.fontFamily, .didot)
        XCTAssertEqual(template.settings.splitRatio, 0.75)

        // Modify settings
        let newSettings = DesignSettings(
            textColor: "#DDEEFF",
            fontFamily: .georgia
        )
        template.settings = newSettings

        XCTAssertEqual(template.settings.textColor, "#DDEEFF")
        XCTAssertEqual(template.settings.fontFamily, .georgia)
    }
}
