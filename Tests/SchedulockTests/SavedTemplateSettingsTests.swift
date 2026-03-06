import XCTest
import SwiftData
@testable import Shared

@MainActor
final class SavedTemplateSettingsTests: XCTestCase {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: SavedTemplateSettings.self, configurations: config)
    }

    func testInitSetsTemplateTypeRaw() throws {
        let container = try makeContainer()
        let record = SavedTemplateSettings(templateTypeRaw: "minimal")
        container.mainContext.insert(record)
        XCTAssertEqual(record.templateTypeRaw, "minimal")
    }

    func testInitDefaultsMatchDesignSettingsDefault() throws {
        let container = try makeContainer()
        let record = SavedTemplateSettings(templateTypeRaw: "glass")
        container.mainContext.insert(record)
        let d = DesignSettings.default
        XCTAssertEqual(record.textColor, d.textColor)
        XCTAssertEqual(record.accentColor, d.accentColor)
        XCTAssertEqual(record.secondaryColor, d.secondaryColor)
        XCTAssertEqual(record.cardBackground, d.cardBackground)
        XCTAssertEqual(record.overlayOpacity, d.overlayOpacity)
        XCTAssertEqual(record.glassBlur, d.glassBlur)
        XCTAssertEqual(record.backgroundBlur, d.backgroundBlur)
        XCTAssertEqual(record.brightness, d.brightness)
        XCTAssertEqual(record.textShadow, d.textShadow)
        XCTAssertEqual(record.fontFamilyRaw, d.fontFamily.rawValue)
        XCTAssertEqual(record.textAlignmentRaw, d.textAlignment.rawValue)
        XCTAssertEqual(record.useCalendarColors, d.useCalendarColors)
        XCTAssertEqual(record.splitRatio, d.splitRatio)
    }

    func testAsDesignSettingsRoundTrip() throws {
        let container = try makeContainer()
        let custom = DesignSettings(
            textColor: "#FF0000", accentColor: "#00FF00", secondaryColor: "#0000FF",
            cardBackground: "#111111", overlayOpacity: 0.7, glassBlur: 15.0,
            backgroundBlur: 5.0, brightness: 0.2, textShadow: 4.0,
            fontFamily: .didot, textAlignment: .center, useCalendarColors: false, splitRatio: 0.4
        )
        let record = SavedTemplateSettings(templateTypeRaw: "neon")
        container.mainContext.insert(record)
        record.apply(custom)

        let result = record.asDesignSettings
        XCTAssertEqual(result.textColor, "#FF0000")
        XCTAssertEqual(result.accentColor, "#00FF00")
        XCTAssertEqual(result.secondaryColor, "#0000FF")
        XCTAssertEqual(result.cardBackground, "#111111")
        XCTAssertEqual(result.overlayOpacity, 0.7)
        XCTAssertEqual(result.glassBlur, 15.0)
        XCTAssertEqual(result.backgroundBlur, 5.0)
        XCTAssertEqual(result.brightness, 0.2)
        XCTAssertEqual(result.textShadow, 4.0)
        XCTAssertEqual(result.fontFamily, .didot)
        XCTAssertEqual(result.textAlignment, .center)
        XCTAssertFalse(result.useCalendarColors)
        XCTAssertEqual(result.splitRatio, 0.4)
    }

    func testAsDesignSettingsFallsBackToDefaultsForUnknownRawValues() throws {
        let container = try makeContainer()
        let record = SavedTemplateSettings(templateTypeRaw: "minimal")
        record.fontFamilyRaw = "unknownFont"
        record.textAlignmentRaw = "unknownAlign"
        container.mainContext.insert(record)
        let result = record.asDesignSettings
        XCTAssertEqual(result.fontFamily, .sfPro)
        XCTAssertEqual(result.textAlignment, .left)
    }

    func testApplyUpdatesAllFields() throws {
        let container = try makeContainer()
        let record = SavedTemplateSettings(templateTypeRaw: "split")
        container.mainContext.insert(record)
        let s = DesignSettings(
            textColor: "#AABBCC", accentColor: "#DDEEFF", secondaryColor: "#112233",
            cardBackground: "#445566", overlayOpacity: 0.3, glassBlur: 10.0,
            backgroundBlur: 2.0, brightness: -0.1, textShadow: 1.5,
            fontFamily: .futura, textAlignment: .right, useCalendarColors: false, splitRatio: 0.65
        )
        record.apply(s)
        XCTAssertEqual(record.textColor, "#AABBCC")
        XCTAssertEqual(record.accentColor, "#DDEEFF")
        XCTAssertEqual(record.secondaryColor, "#112233")
        XCTAssertEqual(record.cardBackground, "#445566")
        XCTAssertEqual(record.overlayOpacity, 0.3)
        XCTAssertEqual(record.glassBlur, 10.0)
        XCTAssertEqual(record.backgroundBlur, 2.0)
        XCTAssertEqual(record.brightness, -0.1)
        XCTAssertEqual(record.textShadow, 1.5)
        XCTAssertEqual(record.fontFamilyRaw, FontFamily.futura.rawValue)
        XCTAssertEqual(record.textAlignmentRaw, TextAlignment.right.rawValue)
        XCTAssertFalse(record.useCalendarColors)
        XCTAssertEqual(record.splitRatio, 0.65)
    }

    func testApplyThenAsDesignSettingsIsIdentity() throws {
        let container = try makeContainer()
        let record = SavedTemplateSettings(templateTypeRaw: "editorial")
        container.mainContext.insert(record)
        for fontFamily in FontFamily.allCases {
            let s = DesignSettings(fontFamily: fontFamily)
            record.apply(s)
            XCTAssertEqual(record.asDesignSettings.fontFamily, fontFamily)
        }
    }
}
