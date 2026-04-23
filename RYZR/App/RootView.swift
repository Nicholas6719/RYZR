import SwiftUI
import SwiftData
import UIKit

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if let profile = profiles.first, profile.onboardingComplete {
                MainTabView(profile: profile)
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(.dark)
        .tint(.rAccentMint)
    }
}

enum RTab: Hashable { case home, snap, gym, progress, profile }

struct MainTabView: View {
    @Environment(\.modelContext) private var context
    @Bindable private var router = AppRouter.shared
    @Query private var favourites: [FavouriteMeal]

    let profile: UserProfile

    init(profile: UserProfile) {
        self.profile = profile
        Self.configureTabBarAppearance()
    }

    var body: some View {
        TabView(selection: $router.selectedTab) {
            Tab("Home", systemImage: "house.fill", value: RTab.home) {
                HomeView(profile: profile, switchTab: { router.selectedTab = $0 })
            }
            Tab("Snap", systemImage: "camera.fill", value: RTab.snap) {
                SnapView(
                    quickLogFavourite: pendingFavourite,
                    onSwitchTab: { router.selectedTab = $0 },
                    onConsumeQuickLog: { router.consumeQuickLog() }
                )
            }
            Tab("Gym", systemImage: "dumbbell.fill", value: RTab.gym) {
                PlaceholderTab(title: "Gym")
            }
            Tab("Progress", systemImage: "chart.bar.fill", value: RTab.progress) {
                PlaceholderTab(title: "Progress")
            }
            Tab("Profile", systemImage: "person.fill", value: RTab.profile) {
                ProfileView(profile: profile)
            }
        }
        .tint(.rAccentMint)
        .task {
            // Kick off permission + reschedule when the app first renders.
            await NotificationManager.shared.requestPermission()
            let windows = (try? context.fetch(FetchDescriptor<MealWindowTime>())) ?? []
            await NotificationManager.shared.rescheduleAllNudges(windows: windows, context: context)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    let windows = (try? context.fetch(FetchDescriptor<MealWindowTime>())) ?? []
                    await NotificationManager.shared.rescheduleAllNudges(windows: windows, context: context)
                }
            }
        }
    }

    @Environment(\.scenePhase) private var scenePhase

    private var pendingFavourite: FavouriteMeal? {
        guard let name = router.pendingFavouriteName else { return nil }
        return favourites.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame })
    }

    private static func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.rSurface)
        appearance.shadowColor = UIColor(Color.rBorder)

        let mintAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.rAccentMint),
            .font: UIFont(name: "DMSans-Medium", size: 11) ?? UIFont.systemFont(ofSize: 11, weight: .medium)
        ]
        let mutedAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.rMuted),
            .font: UIFont(name: "DMSans-Regular", size: 11) ?? UIFont.systemFont(ofSize: 11, weight: .regular)
        ]

        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.rMuted)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = mutedAttrs
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.rAccentMint)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = mintAttrs

        appearance.inlineLayoutAppearance.normal.iconColor = UIColor(Color.rMuted)
        appearance.inlineLayoutAppearance.normal.titleTextAttributes = mutedAttrs
        appearance.inlineLayoutAppearance.selected.iconColor = UIColor(Color.rAccentMint)
        appearance.inlineLayoutAppearance.selected.titleTextAttributes = mintAttrs

        appearance.compactInlineLayoutAppearance.normal.iconColor = UIColor(Color.rMuted)
        appearance.compactInlineLayoutAppearance.normal.titleTextAttributes = mutedAttrs
        appearance.compactInlineLayoutAppearance.selected.iconColor = UIColor(Color.rAccentMint)
        appearance.compactInlineLayoutAppearance.selected.titleTextAttributes = mintAttrs

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

struct PlaceholderTab: View {
    let title: String
    var body: some View {
        ZStack {
            Color.rBackground.ignoresSafeArea()
            VStack(spacing: 12) {
                Text(title)
                    .font(.rSyne(.extrabold, size: 36))
                    .foregroundStyle(Color.rMuted2)
                Text("Coming in a future update")
                    .font(.rSans(.regular, size: 14))
                    .foregroundStyle(Color.rMuted)
            }
        }
    }
}
