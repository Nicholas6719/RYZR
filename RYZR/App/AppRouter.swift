import Foundation
import SwiftUI
import SwiftData
import Observation

/// App-wide router shared across RootView and the UNUserNotificationCenter
/// delegate. Holds the selected tab and any pending quick-log favourite
/// produced by a notification tap.
@Observable
@MainActor
final class AppRouter {
    static let shared = AppRouter()

    var selectedTab: RTab = .home

    /// Populated by the notification delegate when a nudge is tapped with
    /// `isFavourite: true`. RootView observes this and hands it to SnapView.
    var pendingFavouriteName: String? = nil
    var pendingMealWindow: String? = nil

    private init() {}

    func handleNudgeTap(mealWindow: String?, isFavourite: Bool, favouriteName: String?) {
        selectedTab = .snap
        pendingMealWindow = mealWindow
        if isFavourite, let name = favouriteName, !name.isEmpty {
            pendingFavouriteName = name
        } else {
            pendingFavouriteName = nil
        }
    }

    func consumeQuickLog() {
        pendingFavouriteName = nil
    }
}
