import Foundation

struct CatalogFood: Identifiable, Hashable {
    let emoji: String
    let name: String
    let category: String
    var id: String { "\(category)|\(name)" }
    var key: String { id }
}

enum FoodCatalog {
    static let categories: [String] = ["Protein", "Carbs", "Vegetables", "Fruits", "Fats & Snacks"]

    static let items: [CatalogFood] = [
        // Protein
        CatalogFood(emoji: "🍗", name: "Chicken", category: "Protein"),
        CatalogFood(emoji: "🥩", name: "Steak", category: "Protein"),
        CatalogFood(emoji: "🐟", name: "Salmon", category: "Protein"),
        CatalogFood(emoji: "🥚", name: "Eggs", category: "Protein"),
        CatalogFood(emoji: "🫘", name: "Beans", category: "Protein"),
        CatalogFood(emoji: "🧀", name: "Cheese", category: "Protein"),
        CatalogFood(emoji: "🍤", name: "Shrimp", category: "Protein"),
        CatalogFood(emoji: "🐄", name: "Ground Beef", category: "Protein"),
        // Carbs
        CatalogFood(emoji: "🍚", name: "Rice", category: "Carbs"),
        CatalogFood(emoji: "🍞", name: "Bread", category: "Carbs"),
        CatalogFood(emoji: "🥔", name: "Potato", category: "Carbs"),
        CatalogFood(emoji: "🍝", name: "Pasta", category: "Carbs"),
        CatalogFood(emoji: "🌽", name: "Corn", category: "Carbs"),
        CatalogFood(emoji: "🥣", name: "Oats", category: "Carbs"),
        CatalogFood(emoji: "🫓", name: "Wrap", category: "Carbs"),
        CatalogFood(emoji: "🍠", name: "Sweet Potato", category: "Carbs"),
        // Vegetables
        CatalogFood(emoji: "🥦", name: "Broccoli", category: "Vegetables"),
        CatalogFood(emoji: "🥗", name: "Salad", category: "Vegetables"),
        CatalogFood(emoji: "🥕", name: "Carrots", category: "Vegetables"),
        CatalogFood(emoji: "🫑", name: "Peppers", category: "Vegetables"),
        CatalogFood(emoji: "🧅", name: "Onion", category: "Vegetables"),
        CatalogFood(emoji: "🥬", name: "Spinach", category: "Vegetables"),
        CatalogFood(emoji: "🍅", name: "Tomato", category: "Vegetables"),
        CatalogFood(emoji: "🥒", name: "Cucumber", category: "Vegetables"),
        // Fruits
        CatalogFood(emoji: "🍌", name: "Banana", category: "Fruits"),
        CatalogFood(emoji: "🍎", name: "Apple", category: "Fruits"),
        CatalogFood(emoji: "🫐", name: "Blueberries", category: "Fruits"),
        CatalogFood(emoji: "🍓", name: "Strawberries", category: "Fruits"),
        CatalogFood(emoji: "🍊", name: "Orange", category: "Fruits"),
        CatalogFood(emoji: "🥭", name: "Mango", category: "Fruits"),
        CatalogFood(emoji: "🍇", name: "Grapes", category: "Fruits"),
        CatalogFood(emoji: "🍋", name: "Lemon", category: "Fruits"),
        // Fats & Snacks
        CatalogFood(emoji: "🥑", name: "Avocado", category: "Fats & Snacks"),
        CatalogFood(emoji: "🥜", name: "Peanut Butter", category: "Fats & Snacks"),
        CatalogFood(emoji: "🫒", name: "Olive Oil", category: "Fats & Snacks"),
        CatalogFood(emoji: "🌰", name: "Nuts", category: "Fats & Snacks"),
        CatalogFood(emoji: "🧈", name: "Butter", category: "Fats & Snacks"),
        CatalogFood(emoji: "🍫", name: "Dark Chocolate", category: "Fats & Snacks"),
        CatalogFood(emoji: "🥛", name: "Milk", category: "Fats & Snacks"),
        CatalogFood(emoji: "🍦", name: "Yogurt", category: "Fats & Snacks")
    ]

    static let byKey: [String: CatalogFood] = {
        Dictionary(uniqueKeysWithValues: items.map { ($0.key, $0) })
    }()

    static func items(in category: String) -> [CatalogFood] {
        items.filter { $0.category == category }
    }
}
