import SwiftUI
import SwiftData
import UIKit

@main
struct RYZRApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                UserProfile.self,
                MealWindowTime.self,
                DailyNutrition.self,
                Meal.self,
                FavouriteMeal.self,
                PreferredFood.self,
                WorkoutPlan.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        Self.logRegisteredFonts()
        Self.installNotificationDelegate()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }

    private static func logRegisteredFonts() {
        #if DEBUG
        let syneNames = UIFont.fontNames(forFamilyName: "Syne")
        let sansNames = UIFont.fontNames(forFamilyName: "DM Sans")
        let monoNames = UIFont.fontNames(forFamilyName: "DM Mono")
        print("RYZR Fonts — Syne: \(syneNames)")
        print("RYZR Fonts — DM Sans: \(sansNames)")
        print("RYZR Fonts — DM Mono: \(monoNames)")
        #endif
    }

    private static func installNotificationDelegate() {
        UNUserNotificationCenter.current().delegate = RYZRNotificationDelegate.shared
    }
}
