import SwiftUI
import SwiftData
import UIKit

struct SnapCameraView: View {
    @Bindable var camera: CameraViewModel
    @Query(sort: \Meal.loggedAt, order: .reverse) private var recentMeals: [Meal]

    let isAnalyzing: Bool
    let onCapture: (UIImage) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                viewfinder
                if isAnalyzing {
                    loadingState
                } else {
                    shutter
                }
                recentMealsStrip
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .task { await camera.prepareIfNeeded() }
        .onDisappear { camera.stop() }
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Snap a Meal")
                .font(.rSyne(.extrabold, size: 30))
                .foregroundStyle(Color.rTextPrimary)
            Text("Photo → AI → Instant nutrition")
                .font(.rSans(.regular, size: 13))
                .foregroundStyle(Color.rMuted2)
        }
    }

    // MARK: - Viewfinder
    private var viewfinder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.rSurface2.opacity(0.4))

            previewOrOverlay
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                .foregroundStyle(Color.rAccentMint.opacity(0.5))

            ForEach(0..<4) { idx in
                CornerBracket(index: idx)
                    .stroke(Color.rAccentMint, lineWidth: 3)
                    .frame(width: 20, height: 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: bracketAlignment(idx))
                    .padding(12)
            }
        }
        .frame(height: 280)
    }

    @ViewBuilder private var previewOrOverlay: some View {
        switch camera.status {
        case .running:
            CameraPreviewView(session: camera.session)
        case .unauthorized:
            VStack(spacing: 10) {
                Image(systemName: "camera.slash")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.rMuted2)
                Text("Camera access required")
                    .font(.rSans(.medium, size: 14))
                    .foregroundStyle(Color.rMuted2)
                Text("Enable camera in Settings to snap meals.")
                    .font(.rSans(.regular, size: 12))
                    .foregroundStyle(Color.rMuted)
                    .multilineTextAlignment(.center)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.plain)
                .font(.rSans(.semibold, size: 13))
                .foregroundStyle(Color.rAccentMint)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .configuring, .idle:
            VStack(spacing: 10) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.rAccentMint)
                    .frame(width: 60, height: 60)
                    .background(Color.rSurface3, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                Text("Preparing camera…")
                    .font(.rSans(.medium, size: 14))
                    .foregroundStyle(Color.rMuted2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let msg):
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.rRedCancel)
                Text(msg)
                    .font(.rSans(.medium, size: 13))
                    .foregroundStyle(Color.rMuted2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func bracketAlignment(_ idx: Int) -> Alignment {
        switch idx {
        case 0: return .topLeading
        case 1: return .topTrailing
        case 2: return .bottomLeading
        default: return .bottomTrailing
        }
    }

    // MARK: - Shutter
    private var shutter: some View {
        HStack {
            Spacer()
            Button {
                Task { await capture() }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.rAccentMint.opacity(0.28))
                        .frame(width: 96, height: 96)
                        .blur(radius: 10)
                    Circle()
                        .fill(Color.rAccentMint)
                        .frame(width: 72, height: 72)
                        .shadow(color: Color.rAccentMint.opacity(0.5), radius: 8)
                    Circle()
                        .fill(Color.rBackground)
                        .frame(width: 20, height: 20)
                }
            }
            .buttonStyle(.plain)
            .disabled(camera.status != .running)
            .opacity(camera.status == .running ? 1 : 0.5)
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var loadingState: some View {
        VStack(spacing: 8) {
            ProgressView()
                .tint(Color.rAccentMint)
                .scaleEffect(1.4)
                .padding(8)
            Text("Identifying food…")
                .font(.rSans(.medium, size: 13))
                .foregroundStyle(Color.rMuted2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private func capture() async {
        do {
            let img = try await camera.capturePhoto()
            onCapture(img)
        } catch {
            // Swallow — SnapView surfaces user-visible errors once analysis fails
        }
    }

    // MARK: - Recent Meals
    private var recentMealsStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RECENT MEALS")
                .font(.rMono(.medium, size: 11))
                .tracking(1.5)
                .foregroundStyle(Color.rMuted2)

            if recentMeals.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(samples, id: \.name) { s in
                            recentCard(emoji: s.emoji, name: s.name, cal: s.cal)
                        }
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(recentMeals.prefix(8)) { m in
                            recentCard(emoji: m.emoji, name: m.name, cal: m.calories)
                        }
                    }
                }
            }
        }
    }

    private func recentCard(emoji: String, name: String, cal: Int) -> some View {
        VStack(spacing: 6) {
            Text(emoji).font(.system(size: 26))
            Text(name)
                .font(.rSans(.medium, size: 12))
                .foregroundStyle(Color.rTextPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            HStack(spacing: 2) {
                Text("\(cal)").font(.rMono(.medium, size: 11))
                Text("cal").font(.rMono(.regular, size: 10))
            }
            .foregroundStyle(Color.rOrangeCals)
        }
        .frame(width: 90, height: 100)
        .padding(.vertical, 8)
        .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
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

struct CornerBracket: Shape {
    let index: Int
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        switch index {
        case 0:
            p.move(to: CGPoint(x: 0, y: h))
            p.addLine(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: w, y: 0))
        case 1:
            p.move(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: w, y: 0))
            p.addLine(to: CGPoint(x: w, y: h))
        case 2:
            p.move(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: 0, y: h))
            p.addLine(to: CGPoint(x: w, y: h))
        default:
            p.move(to: CGPoint(x: 0, y: h))
            p.addLine(to: CGPoint(x: w, y: h))
            p.addLine(to: CGPoint(x: w, y: 0))
        }
        return p
    }
}
