import SwiftUI

extension Color {
    static let rBackground    = Color(hex: 0x05080E)
    static let rSurface       = Color(hex: 0x0B0F1A)
    static let rSurface2      = Color(hex: 0x111826)
    static let rSurface3      = Color(hex: 0x181F30)
    static let rBorder        = Color.white.opacity(0.07)
    static let rAccentMint    = Color(hex: 0x3EFFA2)
    static let rAccentDim     = Color(hex: 0x3EFFA2).opacity(0.12)
    static let rOrangeCals    = Color(hex: 0xFF7A35)
    static let rBlueCarbs     = Color(hex: 0x4A9EFF)
    static let rPurpleGym     = Color(hex: 0xA67CFF)
    static let rPurpleGymDim  = Color(hex: 0xA67CFF).opacity(0.08)
    static let rYellowStreak  = Color(hex: 0xFFD23F)
    static let rRedCancel     = Color(hex: 0xFF4D6D)
    static let rTextPrimary   = Color(hex: 0xE8F0FF)
    static let rMuted         = Color(hex: 0x5A6E92)
    static let rMuted2        = Color(hex: 0x8A9BBF)

    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
