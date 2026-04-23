import Foundation

struct MealSuggestion: Equatable {
    let mealName: String
    let emoji: String
    let estimatedCalories: Int
    let estimatedProtein: Double
    let estimatedCarbs: Double
    let estimatedFat: Double
    let reason: String
    let isFavourite: Bool
    let favouriteName: String?
}

@MainActor
final class MealSuggestionService {
    static let shared = MealSuggestionService()

    private let model = "claude-haiku-4-5"
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    func generateSuggestion(
        mealWindow: String,
        remainingCalories: Int,
        remainingProtein: Double,
        remainingCarbs: Double,
        remainingFat: Double,
        favourites: [FavouriteMeal],
        preferredFoods: [PreferredFood]
    ) async -> MealSuggestion? {
        let key = APIKeys.claude
        guard !key.isEmpty, !key.contains("YOUR_") else { return nil }

        let favouriteBlock: String = favourites.isEmpty
            ? "(none)"
            : favourites.prefix(10).map { f in
                "- \(f.name) (\(f.calories) cal, \(Int(f.protein.rounded()))g P, \(Int(f.carbs.rounded()))g C, \(Int(f.fat.rounded()))g F)"
            }.joined(separator: "\n")

        let preferredBlock: String = preferredFoods.isEmpty
            ? "(none)"
            : preferredFoods.map { "\($0.emoji) \($0.name)" }.joined(separator: ", ")

        let userMessage = """
        Meal window: \(mealWindow)

        Remaining nutrition targets for today:
        - Calories: \(remainingCalories) kcal
        - Protein: \(Int(remainingProtein.rounded()))g
        - Carbs: \(Int(remainingCarbs.rounded()))g
        - Fat: \(Int(remainingFat.rounded()))g

        User's saved favourite meals:
        \(favouriteBlock)

        User's preferred foods: \(preferredBlock)

        Suggest ONE specific meal for this meal window that fits the remaining targets.
        If a favourite meal closely matches the remaining targets, suggest that one by name.

        Respond ONLY with a JSON object — no markdown, no explanation:
        {"mealName":"string","emoji":"string","estimatedCalories":number,"estimatedProtein":number,"estimatedCarbs":number,"estimatedFat":number,"reason":"string (max 12 words)","isFavourite":boolean,"favouriteName":"string or null"}
        """

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 400,
            "temperature": 0.3,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 20

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return nil
            }
            guard
                let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let content = root["content"] as? [[String: Any]]
            else { return nil }

            let text = content.compactMap { $0["text"] as? String }.joined()
            return Self.parse(text)
        } catch {
            return nil
        }
    }

    static func parse(_ text: String) -> MealSuggestion? {
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            let start = cleaned.firstIndex(of: "{"),
            let end = cleaned.lastIndex(of: "}"),
            start < end
        else { return nil }
        let slice = String(cleaned[start...end])

        guard
            let data = slice.data(using: .utf8),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let mealName = dict["mealName"] as? String, !mealName.isEmpty
        else { return nil }

        func num(_ key: String) -> Double {
            if let d = dict[key] as? Double { return d }
            if let i = dict[key] as? Int { return Double(i) }
            if let s = dict[key] as? String, let d = Double(s) { return d }
            return 0
        }

        let emoji = (dict["emoji"] as? String) ?? "🍽️"
        let reason = (dict["reason"] as? String) ?? ""
        let isFav = (dict["isFavourite"] as? Bool) ?? false
        let favName = dict["favouriteName"] as? String

        return MealSuggestion(
            mealName: mealName,
            emoji: emoji,
            estimatedCalories: Int(num("estimatedCalories").rounded()),
            estimatedProtein: num("estimatedProtein"),
            estimatedCarbs: num("estimatedCarbs"),
            estimatedFat: num("estimatedFat"),
            reason: reason,
            isFavourite: isFav,
            favouriteName: (favName == "null" || favName?.isEmpty == true) ? nil : favName
        )
    }
}
