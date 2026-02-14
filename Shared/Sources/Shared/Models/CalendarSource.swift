import Foundation
import SwiftData

/// Represents a user-selected calendar from EventKit.
@Model
public final class CalendarSource {
    /// EKCalendar identifier
    @Attribute(.unique)
    public var id: String
    public var name: String
    public var colorHex: String
    public var isEnabled: Bool

    public init(
        id: String,
        name: String,
        colorHex: String,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.isEnabled = isEnabled
    }
}
