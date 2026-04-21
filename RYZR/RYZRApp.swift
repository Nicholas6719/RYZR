import SwiftUI
import SwiftData

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
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
