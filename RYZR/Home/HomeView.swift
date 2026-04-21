import SwiftUI
import SwiftData

struct HomeView: View {
    let profile: UserProfile
    let switchTab: (RTab) -> Void

    @Query private var meals: [Meal]
    @Query private var workouts: [WorkoutPlan]

    var body: some View {
        ZStack {
            Color.rBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    greeting
                    ringAndMacros
                    workoutCard
                    mealsSection
                    snapCTA
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Greeting
    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dateLineString)
                .font(.rMono(.medium, size: 11))
                .foregroundStyle(Color.rMuted2)
                .textCase(.uppercase)
                .tracking(1.5)

            HStack(spacing: 4) {
                Text("\(timeOfDayGreeting), ")
                    .foregroundStyle(Color.rTextPrimary)
                Text(profile.name.isEmpty ? "friend" : profile.name)
                    .foregroundStyle(Color.rAccentMint)
                Text(" 👋")
                    .foregroundStyle(Color.rTextPrimary)
            }
            .font(.rSyne(.bold, size: 20))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
    }

    private var dateLineString: String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: Date()).uppercased()
    }

    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case ..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    // MARK: - Ring + macros
    private var todaysMeals: [Meal] {
        let cal = Calendar.current
        return meals.filter { cal.isDateInToday($0.loggedAt) }
                    .sorted { $0.loggedAt < $1.loggedAt }
    }

    private var consumedCalories: Int { todaysMeals.reduce(0) { $0 + $1.calories } }
    private var consumedProtein: Double { todaysMeals.reduce(0) { $0 + $1.protein } }
    private var consumedCarbs: Double { todaysMeals.reduce(0) { $0 + $1.carbs } }
    private var consumedFat: Double { todaysMeals.reduce(0) { $0 + $1.fat } }

    private var ringAndMacros: some View {
        HStack(alignment: .top, spacing: 18) {
            CalorieRing(
                consumed: consumedCalories,
                target: max(profile.dailyCalorieTarget, 1)
            )
            .frame(width: 140)

            VStack(spacing: 10) {
                MacroBar(label: "Protein",
                         value: consumedProtein,
                         target: Double(profile.dailyProteinGrams),
                         color: .rAccentMint)
                MacroBar(label: "Carbs",
                         value: consumedCarbs,
                         target: Double(profile.dailyCarbsGrams),
                         color: .rBlueCarbs)
                MacroBar(label: "Fat",
                         value: consumedFat,
                         target: Double(profile.dailyFatGrams),
                         color: .rOrangeCals)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Workout card
    private var todaysWorkout: WorkoutPlan? {
        let weekday = Calendar.current.component(.weekday, from: Date()) - 1 // 0 = Sunday
        return workouts.first { $0.scheduledDayOfWeek == weekday && !$0.isCompleted }
    }

    private var workoutCard: some View {
        Group {
            if let w = todaysWorkout {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(w.name)
                            .font(.rSyne(.bold, size: 17))
                            .foregroundStyle(Color.rTextPrimary)
                        Text("\(w.exercises.count) exercises · \(w.estimatedMinutes) min")
                            .font(.rSans(.regular, size: 13))
                            .foregroundStyle(Color.rMuted2)
                    }
                    Spacer()
                    Button("Start") { switchTab(.gym) }
                        .buttonStyle(PurpleStartButton())
                }
                .padding(16)
                .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .background(Color.rPurpleGymDim, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.rBorder, lineWidth: 1)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rest Day 💪")
                        .font(.rSyne(.bold, size: 17))
                        .foregroundStyle(Color.rTextPrimary)
                    Text("Schedule a workout in the Gym tab")
                        .font(.rSans(.regular, size: 13))
                        .foregroundStyle(Color.rMuted2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .background(Color.rPurpleGymDim, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.rBorder, lineWidth: 1)
                }
            }
        }
    }

    // MARK: - Meals
    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today's Meals")
                .font(.rSyne(.bold, size: 17))
                .foregroundStyle(Color.rTextPrimary)

            VStack(spacing: 10) {
                ForEach(todaysMeals) { meal in
                    mealRow(meal)
                }

                Button { switchTab(.snap) } label: {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.rAccentMint)
                        Text("Log a Meal")
                            .font(.rSans(.medium, size: 14))
                            .foregroundStyle(Color.rMuted2)
                        Spacer()
                    }
                    .padding(14)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                            .foregroundStyle(Color.rBorder)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func mealRow(_ meal: Meal) -> some View {
        HStack(spacing: 12) {
            Text(meal.emoji).font(.system(size: 28))
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.name)
                    .font(.rSans(.semibold, size: 15))
                    .foregroundStyle(Color.rTextPrimary)
                Text(formatted(meal.loggedAt))
                    .font(.rMono(.regular, size: 12))
                    .foregroundStyle(Color.rMuted2)
            }
            Spacer()
            Text("\(meal.calories)")
                .font(.rMono(.medium, size: 16))
                .foregroundStyle(Color.rOrangeCals)
        }
        .padding(14)
        .rCard()
    }

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    // MARK: - Snap CTA
    private var snapCTA: some View {
        Button { switchTab(.snap) } label: {
            HStack(spacing: 14) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.rAccentMint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Snap a Meal")
                        .font(.rSyne(.bold, size: 17))
                        .foregroundStyle(Color.rTextPrimary)
                    Text("AI-powered food recognition")
                        .font(.rSans(.regular, size: 12))
                        .foregroundStyle(Color.rMuted2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.rMuted)
            }
            .padding(16)
            .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .background(Color.rAccentDim, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.rBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct PurpleStartButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rSans(.semibold, size: 14))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color.rPurpleGym.opacity(configuration.isPressed ? 0.8 : 1),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Calorie Ring
struct CalorieRing: View {
    let consumed: Int
    let target: Int

    private var progress: Double { min(1.0, Double(consumed) / Double(max(target, 1))) }
    private var remaining: Int { max(0, target - consumed) }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color.rSurface3, lineWidth: 14)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [Color.rAccentMint, Color.rBlueCarbs, Color.rAccentMint],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.85), value: progress)

                VStack(spacing: 2) {
                    Text("\(consumed)")
                        .font(.rMono(.medium, size: 26))
                        .foregroundStyle(Color.rTextPrimary)
                        .contentTransition(.numericText())
                    Text("consumed")
                        .font(.rSans(.regular, size: 11))
                        .foregroundStyle(Color.rMuted2)
                }
            }
            .frame(width: 120, height: 120)

            Text("\(remaining) remaining")
                .font(.rMono(.regular, size: 12))
                .foregroundStyle(Color.rAccentMint)
        }
    }
}

struct MacroBar: View {
    let label: String
    let value: Double
    let target: Double
    let color: Color

    private var fraction: Double { min(1.0, value / max(target, 1)) }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.rSans(.medium, size: 13))
                    .foregroundStyle(Color.rTextPrimary)
                Spacer()
                Text("\(Int(value.rounded()))g / \(Int(target.rounded()))g")
                    .font(.rMono(.regular, size: 12))
                    .foregroundStyle(Color.rMuted2)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.rSurface3)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * fraction)
                        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: fraction)
                }
            }
            .frame(height: 8)
        }
    }
}
