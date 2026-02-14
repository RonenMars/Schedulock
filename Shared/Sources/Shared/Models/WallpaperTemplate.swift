import Foundation
import SwiftData

/// A wallpaper template definition with its design settings.
@Model
public final class WallpaperTemplate {
    public var id: UUID
    public var name: String
    public var templateTypeRaw: String
    public var isBuiltIn: Bool
    public var settingsData: Data

    public var templateType: TemplateType {
        get { TemplateType(rawValue: templateTypeRaw) ?? .minimal }
        set { templateTypeRaw = newValue.rawValue }
    }

    public var settings: DesignSettings {
        get {
            (try? JSONDecoder().decode(DesignSettings.self, from: settingsData))
                ?? .default
        }
        set {
            settingsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    public init(
        id: UUID = UUID(),
        name: String,
        templateType: TemplateType,
        isBuiltIn: Bool = false,
        settings: DesignSettings = .default
    ) {
        self.id = id
        self.name = name
        self.templateTypeRaw = templateType.rawValue
        self.isBuiltIn = isBuiltIn
        self.settingsData = (try? JSONEncoder().encode(settings)) ?? Data()
    }
}
