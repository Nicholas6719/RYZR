import Foundation
import SwiftData

@MainActor
enum DailyNutritionManager {

    /// Inserts a Meal record, then recomputes today's DailyNutrition from all
    /// logged meals. Always sums from source records so nothing drifts.
    static func logMeal(_ meal: Meal, context: ModelContext) {
        context.insert(meal)
        _ = recomputeToday(context: context)
        try? context.save()
    }

    /// Returns today's DailyNutrition, creating a zeroed record if needed.
    static func todayRecord(context: ModelContext) -> DailyNutrition {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let fetch = FetchDescriptor<DailyNutrition>(
            predicate: #Predicate<DailyNutrition> { $0.date == startOfDay }
        )
        if let existing = try? context.fetch(fetch).first {
            return existing
        }
        let record = DailyNutrition(date: startOfDay)
        context.insert(record)
        return record
    }

    @discardableResult
    static func recomputeToday(context: ModelContext) -> DailyNutrition {
        let record = todayRecord(context: context)
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: Date())
        guard let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay) else {
            return record
        }

        let descriptor = FetchDescriptor<Meal>(
            predicate: #Predicate<Meal> { $0.loggedAt >= startOfDay && $0.loggedAt < endOfDay }
        )
        let meals = (try? context.fetch(descriptor)) ?? []

        record.totalCalories = meals.reduce(0) { $0 + $1.calories }
        record.totalProtein  = meals.reduce(0) { $0 + $1.protein }
        record.totalCarbs    = meals.reduce(0) { $0 + $1.carbs }
        record.totalFat      = meals.reduce(0) { $0 + $1.fat }
        return record
    }
}
