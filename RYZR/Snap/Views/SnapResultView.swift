import SwiftUI
import SwiftData
import UIKit

struct SnapResultView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]

    let photo: UIImage
    @Binding var items: [IdentifiedFood]
    let onLog: () -> Void
    let onScanAgain: () -> Void
    let onShowToast: (String) -> Void

    @State private var mealName: String = ""
    @State private var proteinAnimated: Bool = false

    private var profile: UserProfile? { profiles.first }

    private var totalCalories: Int { items.reduce(0) { $0 + $1.calories } }
    private var totalProtein: Double { items.reduce(0) { $0 + $1.protein } }
    private var totalCarbs: Double { items.reduce(0) { $0 + $1.carbs } }
    private var totalFat: Double { items.reduce(0) { $0 + $1.fat } }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerRow
                    identifiedItems
                    totalsGrid
                    mealInsightCard
                    Color.clear.frame(height: 180) // stick-button clearance
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            stickyActions
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                proteinAnimated = true
            }
        }
    }

    // MARK: - Header row
    private var headerRow: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text("AI IDENTIFIED")
                    .font(.rMono(.medium, size: 9))
                    .tracking(0.5)
                    .foregroundStyle(Color.rBackground)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.rAccentMint, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .offset(x: -4, y: -4)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Meal name")
                    .font(.rSans(.medium, size: 12))
                    .foregroundStyle(Color.rMuted2)
                TextField("",
                          text: $mealName,
                          prompt: Text("Name this meal…")
                              .foregroundStyle(Color.rMuted))
                    .font(.rSans(.medium, size: 15))
                    .foregroundStyle(Color.rTextPrimary)
                    .tint(Color.rAccentMint)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .rCard()
            }
        }
    }

    // MARK: - Items list
    private var identifiedItems: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ITEMS")
                .font(.rMono(.medium, size: 11))
                .tracking(1.5)
                .foregroundStyle(Color.rMuted2)
            VStack(spacing: 8) {
                ForEach($items) { $item in
                    itemRow(item: item)
                }
            }
        }
    }

    private func itemRow(item: IdentifiedFood) -> some View {
        HStack(spacing: 12) {
            Text(item.emoji)
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(Color.rSurface3, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.rSans(.semibold, size: 14))
                    .foregroundStyle(Color.rTextPrimary)
                    .lineLimit(1)
                Text(item.portionDescription)
                    .font(.rSans(.regular, size: 12))
                    .foregroundStyle(Color.rMuted2)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 2) {
                if item.nutritionSource == .estimated {
                    Text("~\(item.calories)")
                    Text("cal")
                        .font(.rMono(.regular, size: 11))
                }
                else {
                    Text("\(item.calories)")
                    Text("cal")
                        .font(.rMono(.regular, size: 11))
                }
            }
            .font(.rMono(.medium, size: 13))
            .foregroundStyle(item.nutritionSource == .estimated ? Color.rMuted2 : Color.rOrangeCals)
        }
        .padding(12)
        .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.rBorder, lineWidth: 1)
        }
    }

    // MARK: - Totals grid
    private var totalsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            totalPill(value: "\(totalCalories)", label: "CALORIES", color: .rOrangeCals)
            totalPill(value: "\(Int(totalProtein.rounded()))g", label: "PROTEIN", color: .rAccentMint)
            totalPill(value: "\(Int(totalCarbs.rounded()))g", label: "CARBS", color: .rBlueCarbs)
            totalPill(value: "\(Int(totalFat.rounded()))g", label: "FAT", color: .rOrangeCals)
        }
    }

    private func totalPill(value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.rMono(.medium, size: 20))
                .foregroundStyle(color)
            Text(label)
                .font(.rMono(.medium, size: 10))
                .tracking(1.2)
                .foregroundStyle(Color.rMuted2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.rBorder, lineWidth: 1)
        }
    }

    // MARK: - Meal Insight card
    private var mealInsightCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            insightHero
            proteinProgress
            macroPills
        }
        .padding(16)
        .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.rAccentDim)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.rAccentMint.opacity(0.25), lineWidth: 1)
        }
    }

    private var proteinPct: Int {
        guard let goal = profile?.dailyProteinGrams, goal > 0 else { return 0 }
        return Int((totalProtein / Double(goal) * 100).rounded())
    }

    private var insightHero: some View {
        VStack(alignment: .leading, spacing: 6) {
            (
                Text("This meal gives you ")
                    .foregroundStyle(Color.rTextPrimary)
                + Text("\(Int(totalProtein.rounded()))g")
                    .font(.rMono(.medium, size: 22))
                    .foregroundStyle(Color.rAccentMint)
                + Text(" of protein")
                    .foregroundStyle(Color.rTextPrimary)
            )
            .font(.rSans(.semibold, size: 18))

            Text("\(proteinPct)% of your daily protein goal")
                .font(.rSans(.regular, size: 13))
                .foregroundStyle(Color.rMuted2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.rAccentDim, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Protein progress
    private var loggedProteinToday: Double {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return 0 }
        let fetch = FetchDescriptor<Meal>(
            predicate: #Predicate<Meal> { $0.loggedAt >= start && $0.loggedAt < end }
        )
        let meals = (try? context.fetch(fetch)) ?? []
        return meals.reduce(0) { $0 + $1.protein }
    }

    private var proteinGoal: Double {
        Double(profile?.dailyProteinGrams ?? 150)
    }

    private var totalAfterMeal: Double { min(loggedProteinToday + totalProtein, proteinGoal) }
    private var remainingAfterMeal: Double { max(0, proteinGoal - (loggedProteinToday + totalProtein)) }

    private var proteinProgress: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Protein today")
                    .font(.rSans(.medium, size: 13))
                    .foregroundStyle(Color.rTextPrimary)
                Spacer()
                Text("\(Int((loggedProteinToday + totalProtein).rounded()))g / \(Int(proteinGoal.rounded()))g")
                    .font(.rMono(.regular, size: 12))
                    .foregroundStyle(Color.rMuted2)
            }
            GeometryReader { geo in
                let loggedFrac = min(1, loggedProteinToday / max(proteinGoal, 1))
                let addedFrac = min(1 - loggedFrac, totalProtein / max(proteinGoal, 1))
                let animatedAdd = proteinAnimated ? addedFrac : 0
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.rSurface3)
                    HStack(spacing: 0) {
                        Capsule()
                            .fill(Color.rMuted.opacity(0.6))
                            .frame(width: geo.size.width * loggedFrac)
                        Capsule()
                            .fill(Color.rAccentMint)
                            .frame(width: geo.size.width * animatedAdd)
                    }
                    .clipShape(Capsule())
                }
            }
            .frame(height: 8)

            if remainingAfterMeal <= 0 {
                Text("Goal reached! 🎉")
                    .font(.rSans(.semibold, size: 12))
                    .foregroundStyle(Color.rAccentMint)
            } else {
                Text("\(Int(remainingAfterMeal.rounded()))g remaining after this meal")
                    .font(.rSans(.regular, size: 12))
                    .foregroundStyle(Color.rMuted2)
            }
        }
    }

    // MARK: - Macro pills (horizontal scroll)
    private var macroPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                macroPill(value: "\(totalCalories)",
                          pct: pct(Double(totalCalories), goal: Double(profile?.dailyCalorieTarget ?? 2000)),
                          label: "Calories",
                          color: .rOrangeCals)
                macroPill(value: "\(Int(totalProtein.rounded()))g",
                          pct: pct(totalProtein, goal: Double(profile?.dailyProteinGrams ?? 150)),
                          label: "Protein",
                          color: .rAccentMint)
                macroPill(value: "\(Int(totalCarbs.rounded()))g",
                          pct: pct(totalCarbs, goal: Double(profile?.dailyCarbsGrams ?? 200)),
                          label: "Carbs",
                          color: .rBlueCarbs)
                macroPill(value: "\(Int(totalFat.rounded()))g",
                          pct: pct(totalFat, goal: Double(profile?.dailyFatGrams ?? 67)),
                          label: "Fat",
                          color: .rOrangeCals)
            }
        }
    }

    private func pct(_ value: Double, goal: Double) -> Int {
        guard goal > 0 else { return 0 }
        return Int((value / goal * 100).rounded())
    }

    private func macroPill(value: String, pct: Int, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.rMono(.medium, size: 14))
                .foregroundStyle(color)
            Text("\(pct)% of \(label.lowercased()) goal")
                .font(.rSans(.regular, size: 11))
                .foregroundStyle(Color.rMuted2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.rSurface3, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Sticky action buttons
    private var stickyActions: some View {
        VStack(spacing: 8) {
            Button {
                logMeal()
            } label: {
                Text("Log This Meal ✓")
            }
            .buttonStyle(RPrimaryButton())

            Button {
                saveAsFavourite()
            } label: {
                Text("Save as Favourite ⭐")
                    .font(.rSans(.semibold, size: 15))
                    .foregroundStyle(Color.rYellowStreak)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.rYellowStreak.opacity(0.15),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                onScanAgain()
            } label: {
                Text("↩ Scan Again")
                    .font(.rSans(.medium, size: 14))
                    .foregroundStyle(Color.rMuted2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color.rBackground.opacity(0), Color.rBackground.opacity(0.95), Color.rBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        )
    }

    // MARK: - Actions
    private var effectiveName: String {
        let trimmed = mealName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { return trimmed }
        return items.first?.name ?? "Meal"
    }

    private var effectiveEmoji: String {
        items.first?.emoji ?? "🍽️"
    }

    private func logMeal() {
        let meal = Meal(
            name: effectiveName,
            emoji: effectiveEmoji,
            loggedAt: Date(),
            calories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat
        )
        meal.photoData = photo.jpegData(compressionQuality: 0.6)
        DailyNutritionManager.logMeal(meal, context: context)

        // Reschedule nudges for any remaining meal windows today.
        Task { await NotificationManager.shared.rescheduleForTodayChange(context: context) }
        onLog()
    }

    private func saveAsFavourite() {
        let fav = FavouriteMeal(
            name: effectiveName,
            emoji: effectiveEmoji,
            calories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat
        )
        context.insert(fav)
        try? context.save()
        onShowToast("Saved to Favourites ⭐")
    }
}
