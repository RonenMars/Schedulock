import AppIntents

struct GenerateWallpaperIntent: AppIntent {
    static var title: LocalizedStringResource = "Generate Today's Wallpaper"
    static var description: IntentDescription = "Generates a fresh lock screen wallpaper with today's agenda."

    @Parameter(title: "Template")
    var templateName: String?

    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        // Placeholder — full implementation in Phase 6
        let placeholderData = Data()
        let file = IntentFile(data: placeholderData, filename: "wallpaper.png", type: .png)
        return .result(value: file)
    }
}
