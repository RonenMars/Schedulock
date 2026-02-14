import AppIntents
import UIKit

public struct GenerateWallpaperIntent: AppIntent {
    public static var title: LocalizedStringResource = "Generate Today's Wallpaper"
    public static var description: IntentDescription = "Generates a fresh lock screen wallpaper with today's agenda."

    @Parameter(title: "Template")
    public var templateName: String?

    public init() {}

    public func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let engine = WallpaperEngine.withAllRenderers([
            MinimalRenderer(), GlassRenderer(), GradientBandRenderer(),
            EditorialRenderer(), NeonRenderer(), SplitViewRenderer()
        ])

        // Load settings
        let defaults = AppGroupManager.userDefaults
        let templateTypeRaw = templateName ?? defaults.string(forKey: "defaultTemplateType") ?? "minimal"
        let templateType = TemplateType(rawValue: templateTypeRaw) ?? .minimal

        // Fetch events
        let provider = CalendarDataProvider()
        let calendarIDs = defaults.stringArray(forKey: "enabledCalendarIDs") ?? []
        let events = provider.fetchTodayEvents(from: calendarIDs)

        // Load background image
        let imagePath = AppGroupManager.imagesDirectory.appending(path: "background-processed.jpg")
        let backgroundImage = UIImage(contentsOfFile: imagePath.path())

        // Generate
        let template = WallpaperTemplate(name: templateType.displayName, templateType: templateType)
        guard let wallpaper = engine.generateWallpaper(
            template: template, image: backgroundImage, events: events,
            resolution: .iPhone15Pro
        ) else {
            throw GenerationError.renderFailed
        }

        guard let pngData = wallpaper.pngData() else {
            throw GenerationError.exportFailed
        }

        // Save to App Group
        AppGroupManager.ensureDirectoriesExist()
        let outputPath = AppGroupManager.wallpaperDirectory.appending(path: "current.png")
        try pngData.write(to: outputPath)

        let file = IntentFile(data: pngData, filename: "wallpaper.png", type: .png)
        return .result(value: file)
    }

    public enum GenerationError: Error, CustomLocalizedStringResourceConvertible {
        case renderFailed, exportFailed
        public var localizedStringResource: LocalizedStringResource {
            switch self {
            case .renderFailed: return "Failed to render wallpaper"
            case .exportFailed: return "Failed to export wallpaper"
            }
        }
    }
}
