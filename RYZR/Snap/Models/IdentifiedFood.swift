import Foundation

enum NutritionSource: String, Codable {
    case openFoodFacts
    case usda
    case estimated
}

struct IdentifiedFood: Identifiable, Hashable {
    let id: UUID
    var name: String
    var emoji: String
    var portionDescription: String
    var estimatedGrams: Double
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var nutritionSource: NutritionSource

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String,
        portionDescription: String,
        estimatedGrams: Double,
        calories: Int = 0,
        protein: Double = 0,
        carbs: Double = 0,
        fat: Double = 0,
        nutritionSource: NutritionSource = .estimated
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.portionDescription = portionDescription
        self.estimatedGrams = estimatedGrams
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.nutritionSource = nutritionSource
    }
}
