import Foundation

struct MacroTargets: Equatable {
    var calories: Int
    var proteinGrams: Int
    var carbsGrams: Int
    var fatGrams: Int
}

enum PrimaryGoal: String, CaseIterable, Identifiable {
    case fatLoss = "Fat Loss"
    case muscleGain = "Muscle Gain"
    case maintain = "Maintain"
    case generalHealth = "General Health"
    var id: String { rawValue }
}

enum ActivityLevel: String, CaseIterable, Identifiable {
    case sedentary = "Sedentary"
    case lightlyActive = "Lightly Active"
    case moderatelyActive = "Moderately Active"
    case veryActive = "Very Active"
    case extremelyActive = "Extremely Active"
    var id: String { rawValue }

    var multiplier: Double {
        switch self {
        case .sedentary:        return 1.2
        case .lightlyActive:    return 1.375
        case .moderatelyActive: return 1.55
        case .veryActive:       return 1.725
        case .extremelyActive:  return 1.9
        }
    }
}

enum Sex: String, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    var id: String { rawValue }
}

enum MacroCalculator {
    static func compute(
        age: Int,
        sex: String,
        heightFeet: Int,
        heightInches: Int,
        weightLbs: Double,
        activity: String,
        goal: String
    ) -> MacroTargets {
        let weightKg = weightLbs / 2.2046
        let heightCm = Double((heightFeet * 12) + heightInches) * 2.54

        let bmr: Double
        if sex == Sex.female.rawValue {
            bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) - 161
        } else {
            bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) + 5
        }

        let multiplier = ActivityLevel(rawValue: activity)?.multiplier ?? 1.55
        let tdee = bmr * multiplier

        var targetCals = tdee
        switch PrimaryGoal(rawValue: goal) {
        case .fatLoss:    targetCals = tdee - 500
        case .muscleGain: targetCals = tdee + 300
        default:          break
        }

        let caloriesInt = max(1200, Int(targetCals.rounded()))

        let protein = Int((Double(caloriesInt) * 0.30 / 4).rounded())
        let carbs   = Int((Double(caloriesInt) * 0.40 / 4).rounded())
        let fat     = Int((Double(caloriesInt) * 0.30 / 9).rounded())

        return MacroTargets(calories: caloriesInt, proteinGrams: protein, carbsGrams: carbs, fatGrams: fat)
    }

    static func compute(profile: UserProfile) -> MacroTargets {
        compute(
            age: profile.age,
            sex: profile.sex,
            heightFeet: profile.heightFeet,
            heightInches: profile.heightInches,
            weightLbs: profile.currentWeightLbs,
            activity: profile.activityLevel,
            goal: profile.primaryGoal
        )
    }

    static func apply(_ targets: MacroTargets, to profile: UserProfile) {
        profile.dailyCalorieTarget = targets.calories
        profile.dailyProteinGrams  = targets.proteinGrams
        profile.dailyCarbsGrams    = targets.carbsGrams
        profile.dailyFatGrams      = targets.fatGrams
    }
}
