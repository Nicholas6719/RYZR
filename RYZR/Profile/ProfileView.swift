import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var context
    let profile: UserProfile

    @Query private var favourites: [FavouriteMeal]
    @Query private var mealWindows: [MealWindowTime]

    @State private var showAvatarPicker = false
    @State private var editingField: ProfileField?
    @State private var editingCard: EditableCard?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerRow
                        metricsRow
                        nutritionGoalsCard
                        fitnessGoalsCard
                        foodPreferencesCard
                        mealWindowsCard
                        connectedAppsCard
                        favouritesSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAvatarPicker) {
            AvatarPickerSheet(selection: Binding(
                get: { profile.avatarEmoji },
                set: { newVal in
                    profile.avatarEmoji = newVal
                    try? context.save()
                }
            ))
        }
        .sheet(item: $editingField) { field in
            EditFieldSheet(field: field, profile: profile) { recalc() }
        }
        .sheet(item: $editingCard) { card in
            EditCardSheet(card: card, profile: profile) { recalc() }
        }
    }

    // MARK: - Header
    private var headerRow: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                Text(profile.avatarEmoji)
                    .font(.system(size: 34))
                    .frame(width: 64, height: 64)
                    .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.rAccentMint.opacity(0.4), lineWidth: 1)
                    }
                Circle()
                    .fill(Color.rAccentMint)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.rBackground, lineWidth: 2))
                    .offset(x: 3, y: 3)
            }
            .onTapGesture { showAvatarPicker = true }

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name.isEmpty ? "Your Profile" : profile.name)
                    .font(.rSyne(.bold, size: 24))
                    .foregroundStyle(Color.rTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("Member since \(memberSinceLabel)")
                    .font(.rSans(.regular, size: 13))
                    .foregroundStyle(Color.rAccentMint)
            }

            Spacer()

            Button {
                showAvatarPicker = true
            } label: {
                Text("Edit")
                    .font(.rSans(.semibold, size: 14))
                    .foregroundStyle(Color.rTextPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.rBorder, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
        }
    }

    private var memberSinceLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f.string(from: Date())
    }

    // MARK: - Metrics row
    private var metricsRow: some View {
        HStack(spacing: 10) {
            metricTile(label: "Height", action: { editingField = .height }) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(profile.heightFeet)")
                        .font(.rMono(.medium, size: 22))
                        .foregroundStyle(Color.rTextPrimary)
                    Text("'")
                        .font(.rSans(.regular, size: 10))
                        .foregroundStyle(Color.rMuted)
                    Text("ft")
                        .font(.rSans(.regular, size: 10))
                        .foregroundStyle(Color.rMuted)
                        .offset(y: -4)
                    Spacer().frame(width: 4)
                    Text("\(profile.heightInches)")
                        .font(.rMono(.medium, size: 22))
                        .foregroundStyle(Color.rTextPrimary)
                    Text("\"")
                        .font(.rSans(.regular, size: 10))
                        .foregroundStyle(Color.rMuted)
                    Text("in")
                        .font(.rSans(.regular, size: 10))
                        .foregroundStyle(Color.rMuted)
                        .offset(y: -4)
                }
            }
            metricTile(label: "Weight", action: { editingField = .currentWeight }) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(Int(profile.currentWeightLbs.rounded()))")
                        .font(.rMono(.medium, size: 22))
                        .foregroundStyle(Color.rTextPrimary)
                    Text("lb")
                        .font(.rSans(.regular, size: 10))
                        .foregroundStyle(Color.rMuted)
                        .offset(y: -4)
                }
            }
            metricTile(label: "Goal Wt.", action: { editingField = .goalWeight }) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(Int(profile.goalWeightLbs.rounded()))")
                        .font(.rMono(.medium, size: 22))
                        .foregroundStyle(Color.rAccentMint)
                    Text("lb")
                        .font(.rSans(.regular, size: 10))
                        .foregroundStyle(Color.rMuted)
                        .offset(y: -4)
                }
            }
        }
    }

    private func metricTile<Value: View>(label: String, action: @escaping () -> Void, @ViewBuilder value: () -> Value) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                value()
                Text(label)
                    .font(.rSans(.regular, size: 12))
                    .foregroundStyle(Color.rMuted2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.rBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Nutrition goals
    private var nutritionGoalsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "NUTRITION GOALS")
            ProfileCard(
                headerEmoji: "🥗",
                headerTitle: "Daily Targets",
                editAction: { editingCard = .nutrition }
            ) {
                ProfileRow(label: "Calorie Target", value: "\(profile.dailyCalorieTarget)", unit: "cal/day", valueColor: .rOrangeCals)
                ProfileDivider()
                ProfileRow(label: "Protein", value: "\(profile.dailyProteinGrams)", unit: "g/day", valueColor: .rAccentMint)
                ProfileDivider()
                ProfileRow(label: "Carbohydrates", value: "\(profile.dailyCarbsGrams)", unit: "g/day", valueColor: .rBlueCarbs)
                ProfileDivider()
                ProfileRow(label: "Fat", value: "\(profile.dailyFatGrams)", unit: "g/day", valueColor: .rOrangeCals)
            }
        }
    }

    // MARK: - Fitness goals
    private var fitnessGoalsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "FITNESS GOALS")
            ProfileCard(
                headerEmoji: "🏋️",
                headerTitle: "Workout Targets",
                editAction: { editingCard = .fitness }
            ) {
                ProfileRow(label: "Workouts Per Week", value: "\(profile.workoutsPerWeek)", unit: "sessions", valueColor: .rTextPrimary)
                ProfileDivider()
                ProfileRow(label: "Primary Goal", value: profile.primaryGoal, unit: nil, valueColor: .rTextPrimary)
                ProfileDivider()
                ProfileRow(label: "Activity Level", value: profile.activityLevel, unit: nil, valueColor: .rTextPrimary)
            }
        }
    }

    // MARK: - Food preferences
    private var foodPreferencesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "FOOD PREFERENCES")
            ProfileCard(
                headerEmoji: "🍽️",
                headerTitle: "Diet & Allergies",
                editAction: { editingCard = .food }
            ) {
                ProfileRow(label: "Diet Type", value: profile.dietType, unit: nil, valueColor: .rTextPrimary)
                ProfileDivider()
                ProfileRow(
                    label: "Allergies",
                    value: profile.allergies.isEmpty ? "None" : profile.allergies.joined(separator: ", "),
                    unit: nil,
                    valueColor: .rTextPrimary
                )
                ProfileDivider()
                HStack {
                    Text("AI Suggestions")
                        .font(.rSans(.medium, size: 14))
                        .foregroundStyle(Color.rTextPrimary)
                    Spacer()
                    HStack(spacing: 4) {
                        Text(profile.aiSuggestionsEnabled ? "On" : "Off")
                            .font(.rSans(.semibold, size: 13))
                            .foregroundStyle(profile.aiSuggestionsEnabled ? Color.rAccentMint : Color.rMuted2)
                        if profile.aiSuggestionsEnabled {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.rAccentMint)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
    }

    // MARK: - Meal windows
    private var mealWindowsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "MEAL NOTIFICATION WINDOWS")
            ProfileCard(
                headerEmoji: "🔔",
                headerTitle: "Nudge Times",
                editAction: { editingCard = .windows }
            ) {
                ForEach(Array(orderedWindows.enumerated()), id: \.element.id) { idx, window in
                    mealWindowRow(window)
                    if idx < orderedWindows.count - 1 { ProfileDivider() }
                }
            }
        }
    }

    private func mealWindowRow(_ window: MealWindowTime) -> some View {
        HStack(spacing: 12) {
            Text(emojiFor(window.label))
                .font(.system(size: 20))
                .frame(width: 36, height: 36)
                .background(Color.rSurface3, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(window.label)
                    .font(.rSans(.semibold, size: 15))
                    .foregroundStyle(Color.rTextPrimary)
                Text(window.isEnabled ? "Nudge on" : "Off")
                    .font(.rSans(.regular, size: 12))
                    .foregroundStyle(window.isEnabled ? Color.rMuted2 : Color.rMuted)
            }

            Spacer()

            Text(timeString(hour: window.hour, minute: window.minute))
                .font(.rMono(.medium, size: 16))
                .foregroundStyle(window.isEnabled ? Color.rAccentMint : Color.rMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func emojiFor(_ label: String) -> String {
        switch label.lowercased() {
        case "breakfast": return "🍳"
        case "lunch": return "🥗"
        case "dinner": return "🍽️"
        default: return "⏰"
        }
    }

    private func timeString(hour: Int, minute: Int) -> String {
        var c = DateComponents(); c.hour = hour; c.minute = minute
        guard let d = Calendar.current.date(from: c) else { return "--:--" }
        let f = DateFormatter(); f.dateFormat = "h:mm a"
        return f.string(from: d)
    }

    private var orderedWindows: [MealWindowTime] {
        let order = ["Breakfast", "Lunch", "Dinner"]
        return mealWindows.sorted {
            (order.firstIndex(of: $0.label) ?? 99) < (order.firstIndex(of: $1.label) ?? 99)
        }
    }

    // MARK: - Connected apps
    private var connectedAppsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "CONNECTED APPS")
            VStack(spacing: 0) {
                connectedRow(icon: "heart.fill", name: "Apple Health", status: "Not linked", connected: false)
                ProfileDivider()
                connectedRow(icon: "applewatch", name: "Apple Watch", status: "Not linked", connected: false)
                ProfileDivider()
                connectedRow(icon: "scalemass.fill", name: "Smart Scale", status: "Not linked", connected: false)
            }
            .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.rBorder, lineWidth: 1)
            }
        }
    }

    private func connectedRow(icon: String, name: String, status: String, connected: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(connected ? Color.rAccentMint : Color.rMuted2)
                .frame(width: 44, height: 44)
                .background(Color.rSurface3, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(name)
                .font(.rSans(.semibold, size: 15))
                .foregroundStyle(Color.rTextPrimary)

            Spacer()

            Text(status)
                .font(.rSans(.medium, size: 12))
                .foregroundStyle(connected ? Color.rAccentMint : Color.rMuted2)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    connected ? Color.rAccentMint.opacity(0.12) : Color.rSurface3,
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Favourites
    private var favouritesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "SAVED FAVOURITES")
            if favourites.isEmpty {
                Text("No favourites yet. Snap a meal to save one.")
                    .font(.rSans(.regular, size: 13))
                    .foregroundStyle(Color.rMuted2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.rBorder, lineWidth: 1)
                    }
            } else {
                VStack(spacing: 10) {
                    ForEach(favourites) { fav in
                        favouriteRow(fav)
                    }
                }
            }
        }
    }

    private func favouriteRow(_ fav: FavouriteMeal) -> some View {
        HStack(spacing: 12) {
            Text(fav.emoji)
                .font(.system(size: 22))
                .frame(width: 44, height: 44)
                .background(Color.rSurface3, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(fav.name)
                    .font(.rSans(.semibold, size: 15))
                    .foregroundStyle(Color.rTextPrimary)
                Text("P\(Int(fav.protein.rounded()))g · C\(Int(fav.carbs.rounded()))g · F\(Int(fav.fat.rounded()))g · \(fav.calories) cal")
                    .font(.rMono(.regular, size: 11))
                    .foregroundStyle(Color.rMuted2)
            }

            Spacer()

            Text("FAV")
                .font(.rMono(.medium, size: 10))
                .tracking(1)
                .foregroundStyle(Color.rYellowStreak)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.rYellowStreak.opacity(0.15), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .padding(14)
        .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.rBorder, lineWidth: 1)
        }
    }

    // MARK: - Helpers
    private func recalc() {
        MacroCalculator.apply(MacroCalculator.compute(profile: profile), to: profile)
        try? context.save()
        NotificationManager.shared.rescheduleAllNudges(from: orderedWindows)
    }
}

// MARK: - Reusable pieces
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.rMono(.medium, size: 11))
            .tracking(1.5)
            .foregroundStyle(Color.rMuted2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProfileCard<Content: View>: View {
    let headerEmoji: String
    let headerTitle: String
    let editAction: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Text(headerEmoji).font(.system(size: 18))
                    Text(headerTitle)
                        .font(.rSans(.semibold, size: 16))
                        .foregroundStyle(Color.rTextPrimary)
                }
                Spacer()
                Button(action: editAction) {
                    Text("Edit")
                        .font(.rSans(.semibold, size: 14))
                        .foregroundStyle(Color.rAccentMint)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            ProfileDivider()

            content()
        }
        .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.rBorder, lineWidth: 1)
        }
    }
}

struct ProfileDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.rBorder)
            .frame(height: 1)
    }
}

struct ProfileRow: View {
    let label: String
    let value: String
    let unit: String?
    let valueColor: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.rSans(.medium, size: 14))
                .foregroundStyle(Color.rTextPrimary)
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.rMono(.medium, size: 16))
                    .foregroundStyle(valueColor)
                if let unit {
                    Text(unit)
                        .font(.rSans(.regular, size: 12))
                        .foregroundStyle(Color.rMuted2)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Editable field sheet (metric tiles)
enum ProfileField: String, Identifiable {
    case height, currentWeight, goalWeight
    var id: String { rawValue }
}

private struct EditFieldSheet: View {
    let field: ProfileField
    let profile: UserProfile
    let onChange: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var intValue: Int = 0
    @State private var secondaryInt: Int = 0
    @State private var doubleValue: Double = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rBackground.ignoresSafeArea()
                VStack(spacing: 20) {
                    content
                        .padding(.horizontal, 20)
                    Spacer()
                    Button("Save") { save() }
                        .buttonStyle(RPrimaryButton())
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
                .padding(.top, 18)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.tint(Color.rMuted2)
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear(perform: load)
    }

    private var title: String {
        switch field {
        case .height: return "Height"
        case .currentWeight: return "Current Weight"
        case .goalWeight: return "Goal Weight"
        }
    }

    @ViewBuilder private var content: some View {
        switch field {
        case .height:
            HStack(spacing: 10) {
                inputCard(value: $intValue, suffix: "ft")
                inputCard(value: $secondaryInt, suffix: "in")
            }
        case .currentWeight, .goalWeight:
            inputCardDouble(value: $doubleValue, suffix: "lbs")
        }
    }

    private func inputCard(value: Binding<Int>, suffix: String) -> some View {
        HStack {
            TextField("", value: value, format: .number)
                .keyboardType(.numberPad)
                .font(.rMono(.medium, size: 22))
                .foregroundStyle(Color.rTextPrimary)
            Text(suffix)
                .font(.rSans(.regular, size: 14))
                .foregroundStyle(Color.rMuted)
        }
        .padding(16)
        .rCard()
    }

    private func inputCardDouble(value: Binding<Double>, suffix: String) -> some View {
        HStack {
            TextField("", value: value, format: .number.precision(.fractionLength(0...1)))
                .keyboardType(.decimalPad)
                .font(.rMono(.medium, size: 22))
                .foregroundStyle(Color.rTextPrimary)
            Text(suffix)
                .font(.rSans(.regular, size: 14))
                .foregroundStyle(Color.rMuted)
        }
        .padding(16)
        .rCard()
    }

    private func load() {
        switch field {
        case .height:
            intValue = profile.heightFeet
            secondaryInt = profile.heightInches
        case .currentWeight: doubleValue = profile.currentWeightLbs
        case .goalWeight: doubleValue = profile.goalWeightLbs
        }
    }

    private func save() {
        switch field {
        case .height:
            profile.heightFeet = max(0, intValue)
            profile.heightInches = max(0, min(11, secondaryInt))
            onChange()
        case .currentWeight:
            profile.currentWeightLbs = max(0, doubleValue)
            onChange()
        case .goalWeight:
            profile.goalWeightLbs = max(0, doubleValue)
            try? context.save()
        }
        dismiss()
    }
}

// MARK: - Card-level edit sheets
enum EditableCard: String, Identifiable {
    case nutrition, fitness, food, windows
    var id: String { rawValue }
}

private struct EditCardSheet: View {
    let card: EditableCard
    @Bindable var profile: UserProfile
    let onChange: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        body(for: card)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { save() }
                        .tint(Color.rAccentMint)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var title: String {
        switch card {
        case .nutrition: return "Daily Targets"
        case .fitness:   return "Workout Targets"
        case .food:      return "Diet & Allergies"
        case .windows:   return "Nudge Times"
        }
    }

    @ViewBuilder private func body(for card: EditableCard) -> some View {
        switch card {
        case .nutrition:
            numberCard(title: "Calorie Target", value: $profile.dailyCalorieTarget, color: .rOrangeCals, suffix: "cal/day")
            numberCard(title: "Protein", value: $profile.dailyProteinGrams, color: .rAccentMint, suffix: "g/day")
            numberCard(title: "Carbs", value: $profile.dailyCarbsGrams, color: .rBlueCarbs, suffix: "g/day")
            numberCard(title: "Fat", value: $profile.dailyFatGrams, color: .rOrangeCals, suffix: "g/day")
        case .fitness:
            stepperCard(title: "Workouts Per Week", value: $profile.workoutsPerWeek, range: 1...7)
            optionCard(title: "Primary Goal", options: PrimaryGoal.allCases.map(\.rawValue), selection: $profile.primaryGoal)
            optionCard(title: "Activity Level", options: ActivityLevel.allCases.map(\.rawValue), selection: $profile.activityLevel)
        case .food:
            optionCard(title: "Diet Type", options: ["None", "Vegetarian", "Vegan", "Paleo", "Keto", "Other"], selection: $profile.dietType)
            chipsCard(
                title: "Allergies",
                options: ["Gluten", "Dairy", "Nuts", "Shellfish", "Soy", "Eggs"],
                selected: profile.allergies,
                toggle: { opt in
                    if profile.allergies.contains(opt) {
                        profile.allergies.removeAll { $0 == opt }
                    } else {
                        profile.allergies.append(opt)
                    }
                }
            )
            toggleCard(title: "AI Suggestions", isOn: $profile.aiSuggestionsEnabled)
        case .windows:
            WindowsEditor()
        }
    }

    private func numberCard(title: String, value: Binding<Int>, color: Color, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.rSans(.medium, size: 13))
                .foregroundStyle(Color.rMuted2)
            HStack {
                TextField("", value: value, format: .number)
                    .keyboardType(.numberPad)
                    .font(.rMono(.medium, size: 22))
                    .foregroundStyle(color)
                Text(suffix)
                    .font(.rSans(.regular, size: 13))
                    .foregroundStyle(Color.rMuted)
            }
        }
        .padding(14)
        .rCard()
    }

    private func stepperCard(title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(title)
                .font(.rSans(.medium, size: 14))
                .foregroundStyle(Color.rTextPrimary)
            Spacer()
            HStack(spacing: 12) {
                Button {
                    if value.wrappedValue > range.lowerBound { value.wrappedValue -= 1 }
                } label: {
                    Image(systemName: "minus")
                        .foregroundStyle(Color.rTextPrimary)
                        .frame(width: 32, height: 32)
                        .background(Color.rSurface3, in: Circle())
                }
                Text("\(value.wrappedValue)")
                    .font(.rMono(.medium, size: 18))
                    .foregroundStyle(Color.rAccentMint)
                    .frame(minWidth: 24)
                Button {
                    if value.wrappedValue < range.upperBound { value.wrappedValue += 1 }
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.rTextPrimary)
                        .frame(width: 32, height: 32)
                        .background(Color.rSurface3, in: Circle())
                }
            }
        }
        .padding(14)
        .rCard()
    }

    private func optionCard(title: String, options: [String], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.rSans(.medium, size: 13))
                .foregroundStyle(Color.rMuted2)
            VStack(spacing: 6) {
                ForEach(options, id: \.self) { opt in
                    let on = selection.wrappedValue == opt
                    Button {
                        selection.wrappedValue = opt
                    } label: {
                        HStack {
                            Text(opt)
                                .font(.rSans(.medium, size: 14))
                                .foregroundStyle(Color.rTextPrimary)
                            Spacer()
                            if on {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color.rAccentMint)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(on ? Color.rAccentDim : Color.rSurface3,
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(on ? Color.rAccentMint : Color.rBorder, lineWidth: on ? 1.5 : 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .rCard()
    }

    private func chipsCard(title: String, options: [String], selected: [String], toggle: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.rSans(.medium, size: 13))
                .foregroundStyle(Color.rMuted2)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(options, id: \.self) { opt in
                    let on = selected.contains(opt)
                    Button { toggle(opt) } label: {
                        Text(opt)
                            .font(.rSans(.medium, size: 13))
                            .foregroundStyle(on ? Color.rBackground : Color.rTextPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(on ? Color.rAccentMint : Color.rSurface3, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .rCard()
    }

    private func toggleCard(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.rSans(.medium, size: 14))
                .foregroundStyle(Color.rTextPrimary)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.rAccentMint)
        }
        .padding(14)
        .rCard()
    }

    private func save() {
        if card == .fitness || card == .nutrition {
            try? context.save()
            onChange()
        } else {
            try? context.save()
        }
        dismiss()
    }
}

private struct WindowsEditor: View {
    @Environment(\.modelContext) private var context
    @Query private var mealWindows: [MealWindowTime]

    var body: some View {
        ForEach(ordered) { w in
            WindowEditRow(window: w) {
                try? context.save()
                NotificationManager.shared.rescheduleAllNudges(from: ordered)
            }
        }
    }

    private var ordered: [MealWindowTime] {
        let order = ["Breakfast", "Lunch", "Dinner"]
        return mealWindows.sorted { (order.firstIndex(of: $0.label) ?? 99) < (order.firstIndex(of: $1.label) ?? 99) }
    }
}

private struct WindowEditRow: View {
    @Bindable var window: MealWindowTime
    let onCommit: () -> Void

    var body: some View {
        HStack {
            Text(window.label)
                .font(.rSans(.semibold, size: 15))
                .foregroundStyle(Color.rTextPrimary)
            Spacer()
            DatePicker(
                "",
                selection: Binding(
                    get: {
                        var c = DateComponents(); c.hour = window.hour; c.minute = window.minute
                        return Calendar.current.date(from: c) ?? Date()
                    },
                    set: { d in
                        let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                        window.hour = c.hour ?? 0
                        window.minute = c.minute ?? 0
                        onCommit()
                    }
                ),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .disabled(!window.isEnabled)

            Toggle("", isOn: Binding(
                get: { window.isEnabled },
                set: { window.isEnabled = $0; onCommit() }
            ))
            .labelsHidden()
            .tint(Color.rAccentMint)
        }
        .padding(14)
        .rCard()
    }
}

// MARK: - Avatar picker
private struct AvatarPickerSheet: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss

    private let options = ["🧑","🧔","👩","👨","🧑‍🦱","👩‍🦰","👨‍🦰","🧑‍🦳","🧑‍🦲","👦","👧","🧑‍💼","🧑‍🎓","🧑‍🚀","🧑‍🍳","🧑‍⚕️","🦸","🦸‍♀️","🧘","🧘‍♀️","🏋️","🏋️‍♀️","🚴","🚴‍♀️","🏃","🏃‍♀️","🤸","🤸‍♀️","🥷","💪","🔥","⚡","🌟","🚀","🎯","🏆","🥇","💯","😎","🤖"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rBackground.ignoresSafeArea()
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                        ForEach(options, id: \.self) { emoji in
                            Button {
                                selection = emoji
                                dismiss()
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 28))
                                    .frame(width: 50, height: 50)
                                    .background(
                                        selection == emoji ? Color.rAccentDim : Color.rSurface2,
                                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    )
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(selection == emoji ? Color.rAccentMint : Color.rBorder,
                                                          lineWidth: selection == emoji ? 1.5 : 1)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Choose Avatar")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}
