import Foundation

/// The six built-in wallpaper template styles.
public enum TemplateType: String, Codable, CaseIterable, Sendable {
    case minimal
    case glass
    case gradient
    case editorial
    case neon
    case split

    public var displayName: String {
        switch self {
        case .minimal:   return "Minimal"
        case .glass:     return "Frosted Glass"
        case .gradient:  return "Gradient Band"
        case .editorial: return "Editorial"
        case .neon:      return "Neon Glow"
        case .split:     return "Split View"
        }
    }
}
