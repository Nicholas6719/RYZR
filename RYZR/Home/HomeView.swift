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
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Greeting
    private var greeting: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(dateLineString)
                .font(.rMono(.medium, size: 11))
                .foregroundStyle(Color.rMuted2)
                .tracking(1.5)

            HStack(spacing: 0) {
                Text("\(timeOfDayGreeting), ")
                    .foregroundStyle(Color.rTextPrimary)
                Text(profile.name.isEmpty ? "friend" : profile.name)
                    .foregroundStyle(Color.rAccentMint)
                Text(" 👋")
                    .foregroundStyle(Color.rTextPrimary)
            }
            .font(.rSyne(.bold, size: 24))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
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
        HStack(alignment: .center, spacing: 20) {
            CalorieRing(
                consumed: consumedCalories,
                target: max(profile.dailyCalorieTarget, 1)
            )
            .frame(width: 132, height: 132)

            VStack(spacing: 14) {
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
        .padding(.vertical, 8)
    }

    // MARK: - Workout card
    private var todaysWorkout: WorkoutPlan? {
        let weekday = Calendar.current.component(.weekday, from: Date()) - 1
        return workouts.first { $0.scheduledDayOfWeek == weekday && !$0.isCompleted }
    }

    private var workoutCard: some View {
        Group {
            if let w = todaysWorkout {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TODAY")
                            .font(.rMono(.medium, size: 10))
                            .tracking(1.2)
                            .foregroundStyle(Color.rPurpleGym)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.rPurpleGym.opacity(0.18),
                                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                        Text(w.name)
                            .font(.rSyne(.bold, size: 20))
                            .foregroundStyle(Color.rTextPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Text("\(w.exercises.count) exercises · ~\(w.estimatedMinutes) min")
                            .font(.rSans(.regular, size: 13))
                            .foregroundStyle(Color.rMuted2)
                    }
                    Spacer()
                    Button("Start") { switchTab(.gym) }
                        .buttonStyle(PurpleStartButton())
                }
                .padding(16)
                .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.rPurpleGym.opacity(0.08))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.rBorder, lineWidth: 1)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Rest Day 💪")
                        .font(.rSyne(.bold, size: 20))
                        .foregroundStyle(Color.rTextPrimary)
                    Text("Schedule a workout in the Gym tab")
                        .font(.rSans(.regular, size: 13))
                        .foregroundStyle(Color.rMuted2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.rPurpleGym.opacity(0.08))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.rBorder, lineWidth: 1)
                }
            }
        }
    }

    // MARK: - Meals
    private var nextUnloggedMealLabel: String {
        let labels = ["Breakfast", "Lunch", "Dinner"]
        let existing = Set(todaysMeals.compactMap { $0.name.components(separatedBy: " ").first }
                            .flatMap { _ in labels.filter { label in todaysMeals.contains { $0.name.localizedCaseInsensitiveContains(label) } } })
        return labels.first(where: { !existing.contains($0) }) ?? "a Meal"
    }

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TODAY'S MEALS")
                .font(.rMono(.medium, size: 11))
                .tracking(1.5)
                .foregroundStyle(Color.rMuted2)

            VStack(spacing: 10) {
                ForEach(todaysMeals) { meal in
                    mealRow(meal)
                }

                Button { switchTab(.snap) } label: {
                    HStack {
                        Spacer()
                        Text("+ Log \(nextUnloggedMealLabel.lowercased())")
                            .font(.rSans(.medium, size: 14))
                            .foregroundStyle(Color.rMuted2)
                        Spacer()
                    }
                    .padding(.vertical, 16)
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
            Text(meal.emoji)
                .font(.system(size: 22))
                .frame(width: 44, height: 44)
                .background(Color.rSurface3, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(meal.name)
                    .font(.rSans(.semibold, size: 15))
                    .foregroundStyle(Color.rTextPrimary)
                    .lineLimit(1)
                Text(mealSubtitle(meal))
                    .font(.rSans(.regular, size: 12))
                    .foregroundStyle(Color.rMuted2)
            }
            Spacer()
            HStack(spacing: 4) {
                Text("\(meal.calories)")
                    .font(.rMono(.medium, size: 15))
                Text("cal")
                    .font(.rMono(.regular, size: 12))
            }
            .foregroundStyle(Color.rOrangeCals)
        }
        .padding(14)
        .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.rBorder, lineWidth: 1)
        }
    }

    private func mealSubtitle(_ meal: Meal) -> String {
        let time = formatted(meal.loggedAt)
        let hour = Calendar.current.component(.hour, from: meal.loggedAt)
        let label: String
        switch hour {
        case ..<11:   label = "Breakfast"
        case 11..<16: label = "Lunch"
        case 16..<21: label = "Dinner"
        default:      label = "Snack"
        }
        return "\(label) · \(time)"
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
                VStack(alignment: .leading, spacing: 4) {
                    Text("Snap a Meal")
                        .font(.rSyne(.bold, size: 20))
                        .foregroundStyle(Color.rAccentMint)
                    Text("Photo → AI → Instant nutrition")
                        .font(.rSans(.regular, size: 13))
                        .foregroundStyle(Color.rMuted2)
                }
                Spacer()
                Image(systemName: "camera.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.rBackground)
                    .frame(width: 52, height: 52)
                    .background(Color.rAccentMint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(18)
            .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.rAccentMint.opacity(0.10))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.rAccentMint.opacity(0.25), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct PurpleStartButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rSans(.semibold, size: 15))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.rPurpleGym.opacity(configuration.isPressed ? 0.8 : 1),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Calorie Ring
struct CalorieRing: View {
    let consumed: Int
    let target: Int

    private var progress: Double { min(1.0, Double(consumed) / Double(max(target, 1))) }
    private var remaining: Int { max(0, target - consumed) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.rSurface3, lineWidth: 14)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Color.rAccentMint, Color.rBlueCarbs]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * progress)
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.85), value: progress)

            VStack(spacing: 2) {
                Text(formatted(consumed))
                    .font(.rMono(.medium, size: 28))
                    .foregroundStyle(Color.rTextPrimary)
                    .contentTransition(.numericText())
                Text("calories")
                    .font(.rSans(.regular, size: 11))
                    .foregroundStyle(Color.rMuted2)
                Text("\(remaining) left")
                    .font(.rMono(.medium, size: 12))
                    .foregroundStyle(Color.rAccentMint)
                    .padding(.top, 2)
            }
        }
    }

    private func formatted(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

struct MacroBar: View {
    let label: String
    let value: Double
    let target: Double
    let color: Color

    private var fraction: Double { min(1.0, value / max(target, 1)) }

    var body: some View {
        VStack(spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.rSans(.medium, size: 13))
                    .foregroundStyle(Color.rTextPrimary)
                Spacer()
                HStack(spacing: 2) {
                    Text("\(Int(value.rounded()))")
                        .foregroundStyle(Color.rTextPrimary)
                    Text("/ \(Int(target.rounded()))g")
                        .foregroundStyle(Color.rMuted2)
                }
                .font(.rMono(.regular, size: 12))
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
            .frame(height: 6)
        }
    }
}
