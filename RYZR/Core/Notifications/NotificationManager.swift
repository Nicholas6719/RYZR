import Foundation
import UserNotifications
import SwiftData

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // MARK: - Permission
    @discardableResult
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            print("[NotificationManager] auth error: \(error)")
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    // MARK: - Scheduling
    /// Full reschedule of every enabled meal window using Claude-sourced
    /// content (with fallback copy if Claude fails or is unauthorized).
    func rescheduleAllNudges(windows: [MealWindowTime], context: ModelContext) async {
        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional else {
            // Permission denied — silently skip.
            cancelAllNudges()
            return
        }

        cancelAllNudges()
        for window in windows where window.isEnabled {
            await scheduleSingleNudge(window: window, context: context)
        }
    }

    /// Legacy signature kept for the Phase 1 stub call sites.
    func rescheduleAllNudges(from windows: [MealWindowTime]) {
        // Fire-and-forget reschedule without Claude content. Profile / onboarding
        // callers go through this; the richer version runs at app-active and
        // after-meal-logged events.
        Task { [weak self] in
            guard let self else { return }
            let status = await self.authorizationStatus()
            guard status == .authorized || status == .provisional else {
                self.cancelAllNudges()
                return
            }
            self.cancelAllNudges()
            for window in windows where window.isEnabled {
                await self.scheduleSingleNudge(window: window, context: nil)
            }
        }
    }

    func cancelAllNudges() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// Called from SnapResultView after a meal logs so remaining windows use
    /// fresh remaining-macro math in their Claude prompt.
    func rescheduleForTodayChange(context: ModelContext) async {
        let windows = (try? context.fetch(FetchDescriptor<MealWindowTime>())) ?? []
        await rescheduleAllNudges(windows: windows, context: context)
    }

    // MARK: - Single nudge
    private func scheduleSingleNudge(window: MealWindowTime, context: ModelContext?) async {
        let content: UNMutableNotificationContent
        if let context {
            content = await buildNotificationContent(for: window, context: context)
        } else {
            content = UNMutableNotificationContent()
            content.title = fallbackTitle(for: window)
            content.body = fallbackBody(for: window)
            content.sound = .default
            content.userInfo = ["mealWindow": window.label, "isFavourite": false, "favouriteName": ""]
        }

        var components = DateComponents()
        components.hour = window.hour
        components.minute = window.minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "ryzr.nudge.\(window.label.lowercased())",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("[NotificationManager] schedule error for \(window.label): \(error)")
        }
    }

    // MARK: - Content building
    private func buildNotificationContent(
        for window: MealWindowTime,
        context: ModelContext
    ) async -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.userInfo = [
            "mealWindow": window.label,
            "isFavourite": false,
            "favouriteName": ""
        ]

        guard let profile = (try? context.fetch(FetchDescriptor<UserProfile>()))?.first else {
            content.title = fallbackTitle(for: window)
            content.body = fallbackBody(for: window)
            return content
        }

        let today = DailyNutritionManager.recomputeToday(context: context)
        let remainingCals   = max(0, profile.dailyCalorieTarget - today.totalCalories)
        let remainingProt   = max(0, Double(profile.dailyProteinGrams) - today.totalProtein)
        let remainingCarbs  = max(0, Double(profile.dailyCarbsGrams) - today.totalCarbs)
        let remainingFat    = max(0, Double(profile.dailyFatGrams) - today.totalFat)

        let favourites = (try? context.fetch(FetchDescriptor<FavouriteMeal>())) ?? []
        let preferred  = (try? context.fetch(FetchDescriptor<PreferredFood>())) ?? []

        guard profile.aiSuggestionsEnabled else {
            content.title = fallbackTitle(for: window)
            content.body = fallbackBody(for: window)
            return content
        }

        let suggestion = await MealSuggestionService.shared.generateSuggestion(
            mealWindow: window.label,
            remainingCalories: remainingCals,
            remainingProtein: remainingProt,
            remainingCarbs: remainingCarbs,
            remainingFat: remainingFat,
            favourites: favourites,
            preferredFoods: preferred
        )

        guard let s = suggestion else {
            content.title = fallbackTitle(for: window)
            content.body = fallbackBody(for: window)
            return content
        }

        content.title = "\(s.emoji) \(s.mealName)"
        content.body = "\(s.reason) — \(s.estimatedCalories) cal · \(Int(s.estimatedProtein.rounded()))g protein"
        content.userInfo = [
            "mealWindow": window.label,
            "isFavourite": s.isFavourite,
            "favouriteName": s.favouriteName ?? ""
        ]
        return content
    }

    private func fallbackTitle(for window: MealWindowTime) -> String {
        "Time for \(window.label)"
    }

    private func fallbackBody(for window: MealWindowTime) -> String {
        "Time for \(window.label)! Log your meal in RYZR."
    }
}

// MARK: - Delegate (app-level)
final class RYZRNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = RYZRNotificationDelegate()

    // Show banner while app is foregrounded so the user sees it.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
                                @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    // Deep-link into Snap tab on tap.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let info = response.notification.request.content.userInfo
        let mealWindow = info["mealWindow"] as? String
        let isFavourite = info["isFavourite"] as? Bool ?? false
        let favouriteName = info["favouriteName"] as? String

        Task { @MainActor in
            AppRouter.shared.handleNudgeTap(
                mealWindow: mealWindow,
                isFavourite: isFavourite,
                favouriteName: (favouriteName?.isEmpty == false) ? favouriteName : nil
            )
        }
        completionHandler()
    }
}
