import Foundation
import Observation

@Observable
final class OnboardingDraft {
    var name: String = ""
    var primaryGoal: String = PrimaryGoal.maintain.rawValue
    var activityLevel: String = ActivityLevel.moderatelyActive.rawValue
    var workoutsPerWeek: Int = 3

    var age: Int = 25
    var sex: String = Sex.male.rawValue
    var heightFeet: Int = 5
    var heightInches: Int = 8
    var currentWeightLbs: Double = 160
    var goalWeightLbs: Double = 160

    var selectedFoods: Set<String> = []

    var breakfastHour: Int = 8
    var breakfastMinute: Int = 0
    var breakfastEnabled: Bool = true
    var lunchHour: Int = 12
    var lunchMinute: Int = 0
    var lunchEnabled: Bool = true
    var dinnerHour: Int = 18
    var dinnerMinute: Int = 0
    var dinnerEnabled: Bool = true

    var targets: MacroTargets {
        MacroCalculator.compute(
            age: age,
            sex: sex,
            heightFeet: heightFeet,
            heightInches: heightInches,
            weightLbs: currentWeightLbs,
            activity: activityLevel,
            goal: primaryGoal
        )
    }
}
