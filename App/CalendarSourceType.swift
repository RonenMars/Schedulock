import Foundation

/// Which calendar backend provides events for wallpaper rendering.
/// Persisted via @AppStorage("calendarSource").
enum CalendarSourceType: String, CaseIterable, Identifiable {
    case apple  = "apple"
    case google = "google"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .apple:  return "Apple Calendar"
        case .google: return "Google Calendar"
        }
    }

    var iconName: String {
        switch self {
        case .apple:  return "apple.logo"
        case .google: return "globe"
        }
    }
}
