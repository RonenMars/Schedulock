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
    private(set) var backgroundImageVersion: Int = 0
    private(set) var cachedPreviews: [TemplateType: UIImage] = [:]
    private(set) var previewsVersion: Int = -1
    var isGenerating = false
    private var isWarmingPreviews = false

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

    /// Sets the background image and bumps the version so observers can react.
    func setBackgroundImage(_ image: UIImage?) {
        backgroundImage = image
        backgroundImageVersion += 1
    }

    /// Pre-generates all template previews in parallel and caches them.
    func warmPreviews(settingsMap: [TemplateType: DesignSettings]) async {
        guard !isWarmingPreviews else { return }
        isWarmingPreviews = true
        defer { isWarmingPreviews = false }
        let targetVersion = backgroundImageVersion
        await withTaskGroup(of: (TemplateType, UIImage?).self) { group in
            for type in TemplateType.allCases {
                let settings = settingsMap[type] ?? .default
                group.addTask { [self] in
                    let image = await self.generatePreviewAsync(templateType: type, settings: settings)
                    return (type, image)
                }
            }
            for await (type, image) in group {
                if let image { cachedPreviews[type] = image }
            }
        }
        previewsVersion = targetVersion
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

        // Use standard iPhone logical resolution for previews
        let previewResolution = DeviceResolution(width: 393, height: 852, scale: 1, name: "Preview")

        return engine.generateWallpaper(
            template: template,
            image: backgroundImage,
            events: events ?? Self.sampleEvents,
            resolution: previewResolution
        )
    }

    /// Generates a preview on a background thread to avoid blocking the main thread.
    func generatePreviewAsync(templateType: TemplateType, settings: DesignSettings) async -> UIImage? {
        // Capture values on the calling (main) thread before dispatching
        let capturedEngine = engine
        let capturedBackground = backgroundImage
        let capturedEvents = Self.sampleEvents

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let template = WallpaperTemplate(
                    name: templateType.displayName,
                    templateType: templateType,
                    settings: settings
                )
                let previewResolution = DeviceResolution(width: 393, height: 852, scale: 1, name: "Preview")
                let image = capturedEngine.generateWallpaper(
                    template: template,
                    image: capturedBackground,
                    events: capturedEvents,
                    resolution: previewResolution
                )
                continuation.resume(returning: image)
            }
        }
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
