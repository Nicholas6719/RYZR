import SwiftUI

enum RFont {
    static func syne(_ weight: Weight = .bold, size: CGFloat) -> Font {
        Font.custom(weight.syneName, size: size)
    }

    static func dmSans(_ weight: Weight = .regular, size: CGFloat) -> Font {
        Font.custom(weight.dmSansName, size: size)
    }

    static func dmMono(_ weight: Weight = .regular, size: CGFloat) -> Font {
        Font.custom(weight == .medium ? "DMMono-Medium" : "DMMono-Regular", size: size)
    }

    enum Weight {
        case light, regular, medium, semibold, bold, extrabold

        var syneName: String {
            switch self {
            case .light, .regular:   return "Syne-Regular"
            case .medium:            return "Syne-Medium"
            case .semibold:          return "Syne-SemiBold"
            case .bold:              return "Syne-Bold"
            case .extrabold:         return "Syne-ExtraBold"
            }
        }

        var dmSansName: String {
            switch self {
            case .light:     return "DMSans-Light"
            case .regular:   return "DMSans-Regular"
            case .medium:    return "DMSans-Medium"
            case .semibold:  return "DMSans-SemiBold"
            case .bold:      return "DMSans-Bold"
            case .extrabold: return "DMSans-ExtraBold"
            }
        }
    }
}

extension Font {
    static func rSyne(_ weight: RFont.Weight = .bold, size: CGFloat) -> Font { RFont.syne(weight, size: size) }
    static func rSans(_ weight: RFont.Weight = .regular, size: CGFloat) -> Font { RFont.dmSans(weight, size: size) }
    static func rMono(_ weight: RFont.Weight = .regular, size: CGFloat) -> Font { RFont.dmMono(weight, size: size) }
}
