import Foundation

/// Available font families for wallpaper text rendering.
public enum FontFamily: String, Codable, CaseIterable, Sendable {
    case sfPro
    case avenir
    case georgia
    case futura
    case menlo
    case didot

    public var displayName: String {
        switch self {
        case .sfPro:   return "SF Pro"
        case .avenir:  return "Avenir"
        case .georgia: return "Georgia"
        case .futura:  return "Futura"
        case .menlo:   return "Menlo"
        case .didot:   return "Didot"
        }
    }

    public var fontName: String {
        switch self {
        case .sfPro:   return ".SFUI-Regular"
        case .avenir:  return "Avenir"
        case .georgia: return "Georgia"
        case .futura:  return "Futura-Medium"
        case .menlo:   return "Menlo-Regular"
        case .didot:   return "Didot"
        }
    }
}
