import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @State private var draft = OnboardingDraft()
    @State private var step: Int = 0
    private let totalSteps = 7

    var body: some View {
        ZStack {
            Color.rBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                if step > 0 {
                    ProgressDots(current: step, total: totalSteps - 1)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                }

                Group {
                    switch step {
                    case 0: WelcomeStep(next: advance)
                    case 1: AboutGoalsStep(draft: draft, next: advance, back: back)
                    case 2: BodyMetricsStep(draft: draft, next: advance, back: back)
                    case 3: FoodPreferencesStep(draft: draft, next: advance, back: back)
                    case 4: MealTimesStep(draft: draft, next: advance, back: back)
                    case 5: NotificationsStep(next: advance, back: back)
                    case 6: ReadyStep(draft: draft, finish: finish)
                    default: EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .preferredColorScheme(.dark)
    }

    private func advance() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            step = min(step + 1, totalSteps - 1)
        }
    }

    private func back() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            step = max(step - 1, 0)
        }
    }

    private func finish() {
        let descriptor = FetchDescriptor<UserProfile>()
        let profile: UserProfile
        if let existing = try? context.fetch(descriptor).first {
            profile = existing
        } else {
            profile = UserProfile()
            context.insert(profile)
        }

        profile.name = draft.name
        profile.age = draft.age
        profile.sex = draft.sex
        profile.heightFeet = draft.heightFeet
        profile.heightInches = draft.heightInches
        profile.currentWeightLbs = draft.currentWeightLbs
        profile.goalWeightLbs = draft.goalWeightLbs
        profile.primaryGoal = draft.primaryGoal
        profile.activityLevel = draft.activityLevel
        profile.workoutsPerWeek = draft.workoutsPerWeek

        let targets = draft.targets
        MacroCalculator.apply(targets, to: profile)

        // Preferred foods
        let foodsDescriptor = FetchDescriptor<PreferredFood>()
        if let existing = try? context.fetch(foodsDescriptor) {
            for f in existing { context.delete(f) }
        }
        for key in draft.selectedFoods {
            if let item = FoodCatalog.byKey[key] {
                context.insert(PreferredFood(emoji: item.emoji, name: item.name, category: item.category))
            }
        }

        // Meal windows
        let windowsDescriptor = FetchDescriptor<MealWindowTime>()
        if let existing = try? context.fetch(windowsDescriptor) {
            for w in existing { context.delete(w) }
        }
        context.insert(MealWindowTime(label: "Breakfast", hour: draft.breakfastHour, minute: draft.breakfastMinute, isEnabled: draft.breakfastEnabled))
        context.insert(MealWindowTime(label: "Lunch", hour: draft.lunchHour, minute: draft.lunchMinute, isEnabled: draft.lunchEnabled))
        context.insert(MealWindowTime(label: "Dinner", hour: draft.dinnerHour, minute: draft.dinnerMinute, isEnabled: draft.dinnerEnabled))

        profile.onboardingComplete = true

        try? context.save()

        let windows = (try? context.fetch(FetchDescriptor<MealWindowTime>())) ?? []
        NotificationManager.shared.rescheduleAllNudges(from: windows)

        Task { await HealthKitManager.shared.requestPermissions() }
    }
}

private struct ProgressDots: View {
    let current: Int
    let total: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i <= current - 1 ? Color.rAccentMint : Color.rSurface3)
                    .frame(width: i == current - 1 ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: current)
            }
        }
        .padding(.horizontal, 20)
    }
}
