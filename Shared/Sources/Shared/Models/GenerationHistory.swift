import Foundation
import SwiftData

/// Record of a wallpaper generation event.
@Model
public final class GenerationHistory {
    public var id: UUID
    public var generatedAt: Date
    public var templateType: String
    public var imagePath: String
    public var eventCount: Int

    public init(
        id: UUID = UUID(),
        generatedAt: Date = Date(),
        templateType: String,
        imagePath: String,
        eventCount: Int
    ) {
        self.id = id
        self.generatedAt = generatedAt
        self.templateType = templateType
        self.imagePath = imagePath
        self.eventCount = eventCount
    }
}
