import SwiftUI
import SwiftData
import UIKit

struct SnapView: View {
    @Environment(\.modelContext) private var context
    var quickLogFavourite: FavouriteMeal?
    let onSwitchTab: (RTab) -> Void
    let onConsumeQuickLog: () -> Void

    @State private var camera = CameraViewModel()
    @State private var state: SnapState = .camera
    @State private var errorMessage: String?
    @State private var pendingPhoto: UIImage?
    @State private var items: [IdentifiedFood] = []
    @State private var toast: String?

    enum SnapState: Equatable {
        case camera
        case analyzing
        case result
        case error(String)
        case quickLog
    }

    var body: some View {
        ZStack {
            Color.rBackground.ignoresSafeArea()

            content

            if let toast {
                VStack {
                    ToastPill(text: toast)
                        .padding(.top, 12)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            if quickLogFavourite != nil {
                state = .quickLog
            }
        }
        .onChange(of: quickLogFavourite) { _, newValue in
            state = (newValue != nil) ? .quickLog : .camera
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .camera:
            SnapCameraView(
                camera: camera,
                isAnalyzing: false,
                onCapture: { image in
                    pendingPhoto = image
                    Task { await analyze(image: image) }
                }
            )
        case .analyzing:
            SnapCameraView(
                camera: camera,
                isAnalyzing: true,
                onCapture: { _ in }
            )
        case .result:
            if let photo = pendingPhoto {
                SnapResultView(
                    photo: photo,
                    items: $items,
                    onLog: {
                        resetToCamera()
                    },
                    onScanAgain: {
                        resetToCamera()
                    },
                    onShowToast: { message in showToast(message) }
                )
            } else {
                errorState("Something went wrong — try again.")
            }
        case .error(let msg):
            errorState(msg)
        case .quickLog:
            if let fav = quickLogFavourite {
                QuickLogView(
                    favourite: fav,
                    onLog: {
                        logFavourite(fav)
                        onConsumeQuickLog()
                        resetToCamera()
                    },
                    onScanInstead: {
                        onConsumeQuickLog()
                        state = .camera
                    }
                )
            } else {
                SnapCameraView(camera: camera, isAnalyzing: false, onCapture: { _ in })
            }
        }
    }

    // MARK: - Actions
    private func analyze(image: UIImage) async {
        state = .analyzing
        guard let jpeg = image.jpegData(compressionQuality: 0.8) else {
            state = .error("Couldn't encode photo — try again.")
            return
        }
        do {
            let recognised = try await GeminiService.shared.identifyFoods(in: jpeg)
            let enriched = await NutritionLookupService.shared.enrich(recognised)
            items = enriched
            state = .result
        } catch let error as GeminiError {
            state = .error(error.localizedDescription)
        } catch {
            state = .error("Couldn't reach AI — try again.")
        }
    }

    private func resetToCamera() {
        items = []
        pendingPhoto = nil
        state = .camera
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.bubble.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.rRedCancel)
            Text(message)
                .font(.rSans(.medium, size: 15))
                .foregroundStyle(Color.rTextPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button("Try Again") {
                state = .camera
                errorMessage = nil
            }
            .buttonStyle(RPrimaryButton())
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
    }

    private func logFavourite(_ fav: FavouriteMeal) {
        let meal = Meal(
            name: fav.name,
            emoji: fav.emoji,
            loggedAt: Date(),
            calories: fav.calories,
            protein: fav.protein,
            carbs: fav.carbs,
            fat: fav.fat
        )
        DailyNutritionManager.logMeal(meal, context: context)
        Task { await NotificationManager.shared.rescheduleForTodayChange(context: context) }
        showToast("Logged \(fav.name) ✓")
    }

    private func showToast(_ message: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { toast = message }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation { toast = nil }
        }
    }
}

// MARK: - Toast
private struct ToastPill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.rSans(.medium, size: 13))
            .foregroundStyle(Color.rTextPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.rSurface3, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.rAccentMint, lineWidth: 1))
    }
}

// MARK: - Quick log view
private struct QuickLogView: View {
    let favourite: FavouriteMeal
    let onLog: () -> Void
    let onScanInstead: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Quick Log")
                    .font(.rSyne(.extrabold, size: 28))
                    .foregroundStyle(Color.rTextPrimary)
                Text("From your favourites")
                    .font(.rSans(.regular, size: 13))
                    .foregroundStyle(Color.rMuted2)
            }

            favouriteCard

            Spacer()

            VStack(spacing: 10) {
                Button("Log This Meal ✓", action: onLog)
                    .buttonStyle(RPrimaryButton())
                Button("↩ Scan Instead", action: onScanInstead)
                    .font(.rSans(.medium, size: 14))
                    .foregroundStyle(Color.rMuted2)
                    .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 24)
    }

    private var favouriteCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Text(favourite.emoji)
                    .font(.system(size: 28))
                    .frame(width: 56, height: 56)
                    .background(Color.rSurface3, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(favourite.name)
                        .font(.rSyne(.bold, size: 18))
                        .foregroundStyle(Color.rTextPrimary)
                    Text("Saved favourite")
                        .font(.rSans(.regular, size: 12))
                        .foregroundStyle(Color.rYellowStreak)
                }
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                macro(label: "CAL", value: "\(favourite.calories)", color: .rOrangeCals)
                macro(label: "PROTEIN", value: "\(Int(favourite.protein.rounded()))g", color: .rAccentMint)
                macro(label: "CARBS", value: "\(Int(favourite.carbs.rounded()))g", color: .rBlueCarbs)
                macro(label: "FAT", value: "\(Int(favourite.fat.rounded()))g", color: .rOrangeCals)
            }
        }
        .padding(16)
        .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.rBorder, lineWidth: 1)
        }
    }

    private func macro(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.rMono(.medium, size: 18))
                .foregroundStyle(color)
            Text(label)
                .font(.rMono(.medium, size: 10))
                .tracking(1.2)
                .foregroundStyle(Color.rMuted2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.rSurface3, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
