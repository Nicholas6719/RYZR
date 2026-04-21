import SwiftUI
import SwiftData

struct SnapPlaceholderView: View {
    @Query(sort: \Meal.loggedAt, order: .reverse) private var recentMeals: [Meal]

    var body: some View {
        ZStack {
            Color.rBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    viewfinder
                    shutter
                        .padding(.top, 4)
                    recentMealsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Snap a Meal")
                .font(.rSyne(.extrabold, size: 30))
                .foregroundStyle(Color.rTextPrimary)
            Text("Photo → AI → Instant nutrition")
                .font(.rSans(.regular, size: 14))
                .foregroundStyle(Color.rMuted2)
        }
    }

    private var viewfinder: some View {
        ZStack {
            // Dashed border
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                .foregroundStyle(Color.rAccentMint.opacity(0.35))

            // Corner brackets
            ForEach(0..<4) { idx in
                CornerBracket(index: idx)
                    .stroke(Color.rAccentMint, lineWidth: 2)
                    .frame(width: 28, height: 28)
                    .frame(maxWidth: .infinity, maxHeight: .infinity,
                           alignment: bracketAlignment(idx))
                    .padding(14)
            }

            VStack(spacing: 12) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.rAccentMint)
                    .frame(width: 68, height: 68)
                    .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.rAccentMint.opacity(0.3), lineWidth: 1)
                    }
                Text("Tap to take photo")
                    .font(.rSans(.semibold, size: 16))
                    .foregroundStyle(Color.rTextPrimary)
                Text("AI identifies every item instantly")
                    .font(.rSans(.regular, size: 13))
                    .foregroundStyle(Color.rMuted2)
            }
        }
        .frame(height: 260)
        .background(Color.rSurface2.opacity(0.4),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func bracketAlignment(_ idx: Int) -> Alignment {
        switch idx {
        case 0: return .topLeading
        case 1: return .topTrailing
        case 2: return .bottomLeading
        default: return .bottomTrailing
        }
    }

    private var shutter: some View {
        HStack {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.rAccentMint.opacity(0.2))
                    .frame(width: 84, height: 84)
                    .blur(radius: 12)
                Circle()
                    .fill(Color.rAccentMint)
                    .frame(width: 68, height: 68)
                    .overlay(Circle().stroke(Color.rBackground, lineWidth: 4))
                    .overlay {
                        Circle()
                            .stroke(Color.rAccentMint, lineWidth: 2)
                            .frame(width: 78, height: 78)
                    }
                Circle()
                    .stroke(Color.rBackground, lineWidth: 3)
                    .frame(width: 22, height: 22)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }

    private var recentMealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT MEALS")
                .font(.rMono(.medium, size: 11))
                .tracking(1.5)
                .foregroundStyle(Color.rMuted2)

            if recentMeals.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(samples, id: \.name) { s in
                            sampleCard(emoji: s.emoji, name: s.name, cal: s.cal)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(recentMeals.prefix(8)) { m in
                            sampleCard(emoji: m.emoji, name: m.name, cal: m.calories)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }

    private func sampleCard(emoji: String, name: String, cal: Int) -> some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 30))
                .frame(width: 52, height: 52)
                .background(Color.rSurface3, in: Circle())
            Text(name)
                .font(.rSans(.semibold, size: 13))
                .foregroundStyle(Color.rTextPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            HStack(spacing: 3) {
                Text("\(cal)")
                    .font(.rMono(.medium, size: 13))
                Text("cal")
                    .font(.rMono(.regular, size: 11))
            }
            .foregroundStyle(Color.rOrangeCals)
        }
        .frame(width: 120, height: 150)
        .padding(.vertical, 10)
        .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.rBorder, lineWidth: 1)
        }
    }

    private let samples: [(emoji: String, name: String, cal: Int)] = [
        ("🍳", "Eggs & Toast", 420),
        ("🥗", "Chicken Bowl", 620),
        ("🍌", "Banana", 105),
        ("🍫", "Protein Bar", 210)
    ]
}

private struct CornerBracket: Shape {
    let index: Int
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        switch index {
        case 0: // top-left: down then right
            p.move(to: CGPoint(x: 0, y: h))
            p.addLine(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: w, y: 0))
        case 1: // top-right
            p.move(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: w, y: 0))
            p.addLine(to: CGPoint(x: w, y: h))
        case 2: // bottom-left
            p.move(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: 0, y: h))
            p.addLine(to: CGPoint(x: w, y: h))
        default: // bottom-right
            p.move(to: CGPoint(x: 0, y: h))
            p.addLine(to: CGPoint(x: w, y: h))
            p.addLine(to: CGPoint(x: w, y: 0))
        }
        return p
    }
}
