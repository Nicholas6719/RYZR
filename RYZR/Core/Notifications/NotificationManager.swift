import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            print("[NotificationManager] auth error: \(error)")
            return false
        }
    }

    func scheduleMealNudge(for windowLabel: String, at hour: Int, minute: Int) {
        print("[NotificationManager] stub schedule \(windowLabel) at \(hour):\(String(format: "%02d", minute))")
    }

    func cancelAllNudges() {
        print("[NotificationManager] stub cancel all")
    }

    func rescheduleAllNudges(from windows: [MealWindowTime]) {
        cancelAllNudges()
        for window in windows where window.isEnabled {
            scheduleMealNudge(for: window.label, at: window.hour, minute: window.minute)
        }
    }
}
