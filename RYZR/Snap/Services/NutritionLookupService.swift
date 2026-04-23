import Foundation

struct NutritionPer100g {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let source: NutritionSource
}

@MainActor
final class NutritionLookupService {
    static let shared = NutritionLookupService()

    /// Enrich every identified food with calories + macros in parallel.
    func enrich(_ items: [IdentifiedFood]) async -> [IdentifiedFood] {
        await withTaskGroup(of: (Int, IdentifiedFood).self) { group in
            for (index, item) in items.enumerated() {
                group.addTask {
                    let enriched = await NutritionLookupService.shared.enrichOne(item)
                    return (index, enriched)
                }
            }
            var filled: [(Int, IdentifiedFood)] = []
            for await entry in group { filled.append(entry) }
            return filled.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }

    private func enrichOne(_ item: IdentifiedFood) async -> IdentifiedFood {
        if let off = await lookupOpenFoodFacts(query: item.name) {
            return apply(off, to: item)
        }
        if let usda = await lookupUSDA(query: item.name) {
            return apply(usda, to: item)
        }
        if let fallback = Self.fallback(for: item.name) {
            return apply(fallback, to: item)
        }
        var zeroed = item
        zeroed.nutritionSource = .estimated
        zeroed.calories = 0
        return zeroed
    }

    private func apply(_ per100g: NutritionPer100g, to item: IdentifiedFood) -> IdentifiedFood {
        let factor = item.estimatedGrams / 100.0
        var out = item
        out.calories = max(0, Int((per100g.calories * factor).rounded()))
        out.protein  = max(0, (per100g.protein * factor * 10).rounded() / 10)
        out.carbs    = max(0, (per100g.carbs   * factor * 10).rounded() / 10)
        out.fat      = max(0, (per100g.fat     * factor * 10).rounded() / 10)
        out.nutritionSource = per100g.source
        return out
    }

    // MARK: - Open Food Facts
    private func lookupOpenFoodFacts(query: String) async -> NutritionPer100g? {
        let safe = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard !safe.isEmpty else { return nil }
        let urlStr = "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(safe)&search_simple=1&action=process&json=1&page_size=5"
        guard let url = URL(string: urlStr) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard
                let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let products = root["products"] as? [[String: Any]]
            else { return nil }

            for product in products {
                guard let nutriments = product["nutriments"] as? [String: Any] else { continue }
                let kcal = Self.firstNumber(in: nutriments, keys: ["energy-kcal_100g", "energy-kcal", "energy_100g"])
                guard let kcal, kcal > 0 else { continue }
                let protein = Self.firstNumber(in: nutriments, keys: ["proteins_100g", "proteins"]) ?? 0
                let carbs   = Self.firstNumber(in: nutriments, keys: ["carbohydrates_100g", "carbohydrates"]) ?? 0
                let fat     = Self.firstNumber(in: nutriments, keys: ["fat_100g", "fat"]) ?? 0
                return NutritionPer100g(calories: kcal, protein: protein, carbs: carbs, fat: fat, source: .openFoodFacts)
            }
            return nil
        } catch {
            return nil
        }
    }

    // MARK: - USDA FoodData Central
    private func lookupUSDA(query: String) async -> NutritionPer100g? {
        let safe = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard !safe.isEmpty else { return nil }
        let urlStr = "https://api.nal.usda.gov/fdc/v1/foods/search?query=\(safe)&dataType=SR%20Legacy,Survey%20(FNDDS)&pageSize=3&api_key=DEMO_KEY"
        guard let url = URL(string: urlStr) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard
                let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let foods = root["foods"] as? [[String: Any]],
                let first = foods.first,
                let nutrients = first["foodNutrients"] as? [[String: Any]]
            else { return nil }

            var kcal: Double = 0
            var protein: Double = 0
            var carbs: Double = 0
            var fat: Double = 0

            for n in nutrients {
                let name = (n["nutrientName"] as? String)?.lowercased() ?? ""
                let value = (n["value"] as? Double) ?? (n["value"] as? Int).map(Double.init) ?? 0
                if name.contains("energy") && (n["unitName"] as? String)?.lowercased() == "kcal" {
                    kcal = value
                } else if name == "protein" {
                    protein = value
                } else if name.contains("carbohydrate") {
                    carbs = value
                } else if name == "total lipid (fat)" || name == "total fat" {
                    fat = value
                }
            }

            guard kcal > 0 else { return nil }
            return NutritionPer100g(calories: kcal, protein: protein, carbs: carbs, fat: fat, source: .usda)
        } catch {
            return nil
        }
    }

    // MARK: - Fallback table
    private static let fallbackTable: [String: NutritionPer100g] = {
        func e(_ name: String, _ kcal: Double, _ p: Double, _ c: Double, _ f: Double) -> (String, NutritionPer100g) {
            (name.lowercased(), NutritionPer100g(calories: kcal, protein: p, carbs: c, fat: f, source: .estimated))
        }
        let entries: [(String, NutritionPer100g)] = [
            e("chicken", 165, 31, 0, 3.6),
            e("grilled chicken", 165, 31, 0, 3.6),
            e("beef", 250, 26, 0, 15),
            e("ground beef", 254, 17, 0, 20),
            e("salmon", 208, 20, 0, 13),
            e("egg", 155, 13, 1.1, 11),
            e("eggs", 155, 13, 1.1, 11),
            e("rice", 130, 2.7, 28, 0.3),
            e("white rice", 130, 2.7, 28, 0.3),
            e("brown rice", 112, 2.6, 24, 0.9),
            e("bread", 265, 9, 49, 3.2),
            e("toast", 313, 10, 55, 6),
            e("pasta", 131, 5, 25, 1.1),
            e("potato", 77, 2, 17, 0.1),
            e("oats", 389, 17, 66, 7),
            e("banana", 89, 1.1, 23, 0.3),
            e("apple", 52, 0.3, 14, 0.2),
            e("broccoli", 34, 2.8, 7, 0.4),
            e("avocado", 160, 2, 9, 15),
            e("cheese", 402, 25, 1.3, 33),
            e("milk", 42, 3.4, 5, 1),
            e("yogurt", 59, 10, 3.6, 0.4),
            e("peanut butter", 588, 25, 20, 50)
        ]
        return Dictionary(uniqueKeysWithValues: entries)
    }()

    static func fallback(for name: String) -> NutritionPer100g? {
        let key = name.lowercased()
        if let exact = fallbackTable[key] { return exact }
        // try loose containment
        for (token, value) in fallbackTable where key.contains(token) {
            return value
        }
        return nil
    }

    private static func firstNumber(in dict: [String: Any], keys: [String]) -> Double? {
        for key in keys {
            if let n = dict[key] as? Double { return n }
            if let n = dict[key] as? Int { return Double(n) }
            if let s = dict[key] as? String, let n = Double(s) { return n }
        }
        return nil
    }
}
