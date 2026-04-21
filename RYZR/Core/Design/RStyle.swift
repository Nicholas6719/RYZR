import SwiftUI

struct RCardStyle: ViewModifier {
    var fill: Color = .rSurface2
    var radius: CGFloat = 16
    var border: Bool = true

    func body(content: Content) -> some View {
        content
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                if border {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(Color.rBorder, lineWidth: 1)
                }
            }
    }
}

extension View {
    func rCard(fill: Color = .rSurface2, radius: CGFloat = 16, border: Bool = true) -> some View {
        modifier(RCardStyle(fill: fill, radius: radius, border: border))
    }
}

struct RPrimaryButton: ButtonStyle {
    var color: Color = .rAccentMint
    var textColor: Color = .rBackground
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rSyne(.bold, size: 16))
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(configuration.isPressed ? 0.8 : 1.0),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct RGhostButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rSans(.medium, size: 16))
            .foregroundStyle(Color.rMuted2)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.rBorder, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
