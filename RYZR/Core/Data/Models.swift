import Foundation
import SwiftData

@Model
final class UserProfile {
    var name: String = ""
    var age: Int = 25
    var sex: String = "Male"
    var heightFeet: Int = 5
    var heightInches: Int = 8
    var currentWeightLbs: Double = 160
    var goalWeightLbs: Double = 160
    var primaryGoal: String = "Maintain"
    var activityLevel: String = "Moderately Active"
    var workoutsPerWeek: Int = 3
    var dailyCalorieTarget: Int = 2000
    var dailyProteinGrams: Int = 150
    var dailyCarbsGrams: Int = 200
    var dailyFatGrams: Int = 67
    var dietType: String = "None"
    var allergies: [String] = []
    var aiSuggestionsEnabled: Bool = true
    var avatarEmoji: String = "🧑"
    var onboardingComplete: Bool = false

    init() {}
}

@Model
final class MealWindowTime {
    var label: String = ""
    var hour: Int = 0
    var minute: Int = 0
    var isEnabled: Bool = true

    init(label: String, hour: Int, minute: Int, isEnabled: Bool = true) {
        self.label = label
        self.hour = hour
        self.minute = minute
        self.isEnabled = isEnabled
    }
}

@Model
final class DailyNutrition {
    var date: Date = Date()
    var totalCalories: Int = 0
    var totalProtein: Double = 0
    var totalCarbs: Double = 0
    var totalFat: Double = 0

    init(date: Date) {
        self.date = date
    }
}

@Model
final class Meal {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = "🍽️"
    var loggedAt: Date = Date()
    var calories: Int = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    var isFavourite: Bool = false
    var photoData: Data?

    init(name: String, emoji: String, loggedAt: Date = Date(), calories: Int, protein: Double, carbs: Double, fat: Double) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.loggedAt = loggedAt
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
}

@Model
final class FavouriteMeal {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = "🍽️"
    var calories: Int = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    var createdAt: Date = Date()

    init(name: String, emoji: String, calories: Int, protein: Double, carbs: Double, fat: Double) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.createdAt = Date()
    }
}

@Model
final class PreferredFood {
    var emoji: String = ""
    var name: String = ""
    var category: String = ""

    init(emoji: String, name: String, category: String) {
        self.emoji = emoji
        self.name = name
        self.category = category
    }
}

@Model
final class WorkoutPlan {
    var id: UUID = UUID()
    var name: String = ""
    var scheduledDayOfWeek: Int = 0
    var exercises: [String] = []
    var estimatedMinutes: Int = 0
    var isCompleted: Bool = false
    var completedAt: Date?

    init(name: String, scheduledDayOfWeek: Int, exercises: [String], estimatedMinutes: Int) {
        self.id = UUID()
        self.name = name
        self.scheduledDayOfWeek = scheduledDayOfWeek
        self.exercises = exercises
        self.estimatedMinutes = estimatedMinutes
    }
}
