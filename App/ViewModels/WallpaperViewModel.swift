import SwiftUI
import SwiftData
import Shared

@Observable
final class WallpaperViewModel {
    private let engine: WallpaperEngine

    var currentWallpaper: UIImage?
    var selectedTemplateType: TemplateType = .minimal
    var designSettings: DesignSettings = .default
    var backgroundImage: UIImage?
    var isGenerating = false

    /// Sample events for previews when no real calendar data is available.
    static let sampleEvents: [CalendarEvent] = [
        CalendarEvent(
            id: "1", title: "Team Standup", calendarName: "Work",
            startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
            endTime: Calendar.current.date(bySettingHour: 9, minute: 30, second: 0, of: Date())!,
            isAllDay: false, calendarColor: .systemBlue
        ),
        CalendarEvent(
            id: "2", title: "Design Review", calendarName: "Work",
            startTime: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: Date())!,
            endTime: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!,
            isAllDay: false, calendarColor: .systemBlue
        ),
        CalendarEvent(
            id: "3", title: "Lunch with Alex", calendarName: "Personal",
            startTime: Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: Date())!,
            endTime: Calendar.current.date(bySettingHour: 13, minute: 30, second: 0, of: Date())!,
            isAllDay: false, calendarColor: .systemGreen
        ),
    ]

    init() {
        self.engine = WallpaperEngine.withAllRenderers([
            MinimalRenderer(),
            GlassRenderer(),
            GradientBandRenderer(),
            EditorialRenderer(),
            NeonRenderer(),
            SplitViewRenderer(),
        ])
    }

    /// Generates a wallpaper preview at a small resolution for UI display.
    func generatePreview(
        templateType: TemplateType,
        settings: DesignSettings,
        events: [CalendarEvent]? = nil
    ) -> UIImage? {
        let template = WallpaperTemplate(
            name: templateType.displayName,
            templateType: templateType,
            settings: settings
        )

        // Use a smaller resolution for previews (1/3 of iPhone 15 Pro)
        let previewResolution = DeviceResolution(width: 393, height: 852, scale: 1, name: "Preview")

        return engine.generateWallpaper(
            template: template,
            image: backgroundImage,
            events: events ?? Self.sampleEvents,
            resolution: previewResolution
        )
    }

    /// Generates a full-resolution wallpaper for export.
    func generateFullResolution(
        events: [CalendarEvent],
        resolution: DeviceResolution = .iPhone15Pro
    ) -> UIImage? {
        isGenerating = true
        defer { isGenerating = false }

        let template = WallpaperTemplate(
            name: selectedTemplateType.displayName,
            templateType: selectedTemplateType,
            settings: designSettings
        )

        let image = engine.generateWallpaper(
            template: template,
            image: backgroundImage,
            events: events,
            resolution: resolution
        )

        currentWallpaper = image
        return image
    }
}
