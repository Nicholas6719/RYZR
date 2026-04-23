import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum GeminiError: Error, LocalizedError {
    case missingKey
    case network(Error)
    case quotaExceeded
    case badResponse(Int)
    case emptyResponse
    case parsing

    var errorDescription: String? {
        switch self {
        case .missingKey:       return "Add your Gemini API key in APIKeys.swift."
        case .network:          return "Couldn't reach AI — check your connection."
        case .quotaExceeded:    return "Daily recognition limit reached. Try again tomorrow."
        case .badResponse(let c):return "AI returned an error (\(c))."
        case .emptyResponse:    return "No food detected — try a clearer photo."
        case .parsing:          return "Couldn't read the AI response."
        }
    }
}

@MainActor
final class GeminiService {
    static let shared = GeminiService()

    private let model = "gemini-2.0-flash-lite"
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models"

    private let systemPrompt = """
    You are a food recognition assistant. Analyse this photo and identify every distinct food item visible.

    For each item return a JSON array. Each element must have exactly these fields:
    - "name": string — specific food name (e.g. "Grilled Chicken Breast", not just "Chicken")
    - "emoji": string — single most relevant emoji
    - "portionDescription": string — estimated portion (e.g. "1 medium piece ~150g", "2 tablespoons")
    - "estimatedGrams": number — numeric gram estimate

    Return ONLY the raw JSON array. No markdown, no backticks, no explanation. Example:
    [{"name":"Scrambled Eggs","emoji":"🥚","portionDescription":"2 large eggs ~100g","estimatedGrams":100},{"name":"Sourdough Toast","emoji":"🍞","portionDescription":"1 thick slice ~45g","estimatedGrams":45}]
    """

    func identifyFoods(in jpegData: Data) async throws -> [IdentifiedFood] {
        let key = APIKeys.gemini
        guard !key.isEmpty, !key.contains("YOUR_") else { throw GeminiError.missingKey }

        guard let url = URL(string: "\(endpoint)/\(model):generateContent?key=\(key)") else {
            throw GeminiError.network(URLError(.badURL))
        }

        let base64 = jpegData.base64EncodedString()
        let payload: [String: Any] = [
            "contents": [[
                "role": "user",
                "parts": [
                    ["text": systemPrompt],
                    ["inline_data": ["mime_type": "image/jpeg", "data": base64]]
                ]
            ]],
            "generationConfig": [
                "temperature": 0.2,
                "maxOutputTokens": 800,
                "responseMimeType": "application/json"
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.timeoutInterval = 30

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw GeminiError.network(error)
        }

        guard let http = response as? HTTPURLResponse else { throw GeminiError.badResponse(-1) }
        if http.statusCode == 429 { throw GeminiError.quotaExceeded }
        guard (200..<300).contains(http.statusCode) else { throw GeminiError.badResponse(http.statusCode) }

        let text = try Self.extractText(from: data)
        let items = Self.parseItems(from: text)
        if items.isEmpty { throw GeminiError.emptyResponse }
        return items
    }

    // MARK: - Parsing helpers

    private static func extractText(from data: Data) throws -> String {
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = root["candidates"] as? [[String: Any]],
            let first = candidates.first,
            let content = first["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]]
        else { throw GeminiError.parsing }

        let joined = parts.compactMap { $0["text"] as? String }.joined()
        guard !joined.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GeminiError.emptyResponse
        }
        return joined
    }

    /// Parse the model's text response into IdentifiedFood items.
    /// Tolerant of markdown fences or surrounding prose — finds the first `[` / last `]`.
    static func parseItems(from text: String) -> [IdentifiedFood] {
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            let start = cleaned.firstIndex(of: "["),
            let end = cleaned.lastIndex(of: "]"),
            start < end
        else {
            return []
        }

        let slice = String(cleaned[start...end])
        guard let data = slice.data(using: .utf8) else { return [] }
        guard let array = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] else {
            return []
        }

        return array.compactMap { dict -> IdentifiedFood? in
            guard
                let name = (dict["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                !name.isEmpty
            else { return nil }

            let emoji = (dict["emoji"] as? String) ?? "🍽️"
            let portion = (dict["portionDescription"] as? String) ?? ""
            let grams: Double = {
                if let n = dict["estimatedGrams"] as? Double { return n }
                if let n = dict["estimatedGrams"] as? Int { return Double(n) }
                if let s = dict["estimatedGrams"] as? String, let n = Double(s) { return n }
                return 100
            }()

            return IdentifiedFood(
                name: name,
                emoji: emoji,
                portionDescription: portion,
                estimatedGrams: max(1, grams)
            )
        }
    }
}
