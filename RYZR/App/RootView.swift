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
    let profile: UserProfile
    @State private var selection: RTab = .home

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house.fill", value: RTab.home) {
                HomeView(profile: profile, switchTab: { selection = $0 })
            }
            Tab("Snap", systemImage: "camera.fill", value: RTab.snap) {
                PlaceholderTab(title: "Snap")
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
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.rSurface)
            appearance.shadowColor = UIColor(Color.rBorder)
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.rMuted)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.rMuted)]
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.rAccentMint)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.rAccentMint)]
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

struct PlaceholderTab: View {
    let title: String
    var body: some View {
        ZStack {
            Color.rBackground.ignoresSafeArea()
            VStack(spacing: 10) {
                Text(title)
                    .font(.rSyne(.bold, size: 28))
                    .foregroundStyle(Color.rMuted2)
                Text("Coming in a future update")
                    .font(.rSans(.regular, size: 14))
                    .foregroundStyle(Color.rMuted)
            }
        }
    }
}
