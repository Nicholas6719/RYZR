import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var context
    let profile: UserProfile

    @Query private var favourites: [FavouriteMeal]
    @Query private var mealWindows: [MealWindowTime]

    @State private var showAvatarPicker = false
    @State private var editingField: ProfileField?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        avatarHeader
                        bodyMetricsSection
                        nutritionGoalsSection
                        fitnessGoalsSection
                        foodPreferencesSection
                        mealNotificationsSection
                        connectedAppsSection
                        favouritesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.rBackground, for: .navigationBar)
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
            EditFieldSheet(field: field, profile: profile) {
                recalc()
            }
        }
    }

    // MARK: - Avatar
    private var avatarHeader: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                Text(profile.avatarEmoji)
                    .font(.system(size: 34))
                    .frame(width: 64, height: 64)
                    .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.rBorder, lineWidth: 1)
                    }
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.rAccentMint, Color.rSurface)
                    .offset(x: 4, y: 4)
            }
            .onTapGesture { showAvatarPicker = true }

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name.isEmpty ? "Your Profile" : profile.name)
                    .font(.rSyne(.bold, size: 20))
                    .foregroundStyle(Color.rTextPrimary)
                Text(profile.primaryGoal)
                    .font(.rSans(.regular, size: 13))
                    .foregroundStyle(Color.rMuted2)
            }
            Spacer()
        }
    }

    // MARK: - Body metrics
    private var bodyMetricsSection: some View {
        Section(title: "Body Metrics") {
            HStack(spacing: 10) {
                metricTile(
                    value: "\(profile.heightFeet) ft \(profile.heightInches) in",
                    label: "Height",
                    action: { editingField = .height }
                )
                metricTile(
                    value: "\(Int(profile.currentWeightLbs.rounded())) lbs",
                    label: "Weight",
                    action: { editingField = .currentWeight }
                )
                metricTile(
                    value: "\(Int(profile.goalWeightLbs.rounded())) lbs",
                    label: "Goal",
                    action: { editingField = .goalWeight }
                )
            }
        }
    }

    private func metricTile(value: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.rMono(.medium, size: 17))
                    .foregroundStyle(Color.rTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.rSans(.regular, size: 11))
                    .foregroundStyle(Color.rMuted2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .rCard()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Nutrition
    private var nutritionGoalsSection: some View {
        Section(title: "Nutrition Goals") {
            VStack(spacing: 0) {
                goalRow(label: "Calorie Target", value: "\(profile.dailyCalorieTarget)", color: .rOrangeCals) {
                    editingField = .calories
                }
                Divider().background(Color.rBorder)
                goalRow(label: "Protein", value: "\(profile.dailyProteinGrams)g", color: .rAccentMint) {
                    editingField = .protein
                }
                Divider().background(Color.rBorder)
                goalRow(label: "Carbs", value: "\(profile.dailyCarbsGrams)g", color: .rBlueCarbs) {
                    editingField = .carbs
                }
                Divider().background(Color.rBorder)
                goalRow(label: "Fat", value: "\(profile.dailyFatGrams)g", color: .rOrangeCals) {
                    editingField = .fat
                }
            }
            .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.rBorder, lineWidth: 1)
            }
        }
    }

    private func goalRow(label: String, value: String, color: Color, tap: @escaping () -> Void) -> some View {
        Button(action: tap) {
            HStack {
                Text(label)
                    .font(.rSans(.medium, size: 15))
                    .foregroundStyle(Color.rTextPrimary)
                Spacer()
                Text(value)
                    .font(.rMono(.medium, size: 16))
                    .foregroundStyle(color)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.rMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Fitness goals
    private var fitnessGoalsSection: some View {
        Section(title: "Fitness Goals") {
            VStack(spacing: 12) {
                HStack {
                    Text("Workouts Per Week")
                        .font(.rSans(.medium, size: 14))
                        .foregroundStyle(Color.rTextPrimary)
                    Spacer()
                    HStack(spacing: 12) {
                        Button {
                            if profile.workoutsPerWeek > 1 {
                                profile.workoutsPerWeek -= 1
                                recalc()
                            }
                        } label: {
                            Image(systemName: "minus")
                                .foregroundStyle(Color.rTextPrimary)
                                .frame(width: 32, height: 32)
                                .background(Color.rSurface3, in: Circle())
                        }
                        Text("\(profile.workoutsPerWeek)")
                            .font(.rMono(.medium, size: 18))
                            .foregroundStyle(Color.rAccentMint)
                            .frame(minWidth: 24)
                        Button {
                            if profile.workoutsPerWeek < 7 {
                                profile.workoutsPerWeek += 1
                                recalc()
                            }
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

                pickerCard(
                    label: "Primary Goal",
                    options: PrimaryGoal.allCases.map(\.rawValue),
                    selection: Binding(
                        get: { profile.primaryGoal },
                        set: { profile.primaryGoal = $0; recalc() }
                    )
                )

                pickerCard(
                    label: "Activity Level",
                    options: ActivityLevel.allCases.map(\.rawValue),
                    selection: Binding(
                        get: { profile.activityLevel },
                        set: { profile.activityLevel = $0; recalc() }
                    )
                )
            }
        }
    }

    private func pickerCard(label: String, options: [String], selection: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(.rSans(.medium, size: 14))
                .foregroundStyle(Color.rTextPrimary)
            Spacer()
            Menu {
                ForEach(options, id: \.self) { opt in
                    Button(opt) { selection.wrappedValue = opt }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selection.wrappedValue)
                        .font(.rSans(.medium, size: 14))
                        .foregroundStyle(Color.rAccentMint)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.rMuted)
                }
            }
        }
        .padding(14)
        .rCard()
    }

    // MARK: - Food preferences
    private var foodPreferencesSection: some View {
        Section(title: "Food Preferences") {
            VStack(spacing: 12) {
                pickerCard(
                    label: "Diet Type",
                    options: ["None", "Vegetarian", "Vegan", "Paleo", "Keto", "Other"],
                    selection: Binding(
                        get: { profile.dietType },
                        set: { profile.dietType = $0; try? context.save() }
                    )
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("Allergies")
                        .font(.rSans(.medium, size: 14))
                        .foregroundStyle(Color.rTextPrimary)

                    FlowChips(
                        options: ["Gluten", "Dairy", "Nuts", "Shellfish", "Soy", "Eggs"],
                        selected: profile.allergies,
                        toggle: { opt in
                            if profile.allergies.contains(opt) {
                                profile.allergies.removeAll { $0 == opt }
                            } else {
                                profile.allergies.append(opt)
                            }
                            try? context.save()
                        }
                    )
                }
                .padding(14)
                .rCard()

                HStack {
                    Text("AI Suggestions")
                        .font(.rSans(.medium, size: 14))
                        .foregroundStyle(Color.rTextPrimary)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { profile.aiSuggestionsEnabled },
                        set: { profile.aiSuggestionsEnabled = $0; try? context.save() }
                    ))
                    .labelsHidden()
                    .tint(Color.rAccentMint)
                }
                .padding(14)
                .rCard()
            }
        }
    }

    // MARK: - Meal notifications
    private var mealNotificationsSection: some View {
        Section(title: "Meal Notification Windows") {
            VStack(spacing: 10) {
                ForEach(orderedWindows) { window in
                    MealWindowRow(window: window) {
                        try? context.save()
                        NotificationManager.shared.rescheduleAllNudges(from: orderedWindows)
                    }
                }
            }
        }
    }

    private var orderedWindows: [MealWindowTime] {
        let order = ["Breakfast", "Lunch", "Dinner"]
        return mealWindows.sorted { order.firstIndex(of: $0.label) ?? 99 < order.firstIndex(of: $1.label) ?? 99 }
    }

    // MARK: - Connected apps
    private var connectedAppsSection: some View {
        Section(title: "Connected Apps") {
            VStack(spacing: 0) {
                connectedRow(icon: "heart.fill", label: "Apple Health", status: "Not Connected")
                Divider().background(Color.rBorder)
                connectedRow(icon: "applewatch", label: "Apple Watch", status: "Not Connected")
                Divider().background(Color.rBorder)
                connectedRow(icon: "scalemass.fill", label: "Smart Scale", status: "Not Connected")
            }
            .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.rBorder, lineWidth: 1)
            }
        }
    }

    private func connectedRow(icon: String, label: String, status: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.rMuted2)
                .frame(width: 24)
            Text(label)
                .font(.rSans(.medium, size: 15))
                .foregroundStyle(Color.rTextPrimary)
            Spacer()
            Text(status)
                .font(.rSans(.regular, size: 13))
                .foregroundStyle(status == "Connected" ? Color.rAccentMint : Color.rMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Favourites
    private var favouritesSection: some View {
        Section(title: "Favourites") {
            if favourites.isEmpty {
                Text("No favourites yet. Snap a meal to save one.")
                    .font(.rSans(.regular, size: 13))
                    .foregroundStyle(Color.rMuted2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .rCard()
            } else {
                VStack(spacing: 8) {
                    ForEach(favourites) { fav in
                        HStack(spacing: 12) {
                            Text(fav.emoji).font(.system(size: 26))
                            Text(fav.name)
                                .font(.rSans(.semibold, size: 15))
                                .foregroundStyle(Color.rTextPrimary)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(fav.calories)")
                                    .font(.rMono(.medium, size: 15))
                                    .foregroundStyle(Color.rOrangeCals)
                                Text("P\(Int(fav.protein.rounded())) C\(Int(fav.carbs.rounded())) F\(Int(fav.fat.rounded()))")
                                    .font(.rMono(.regular, size: 11))
                                    .foregroundStyle(Color.rMuted2)
                            }
                        }
                        .padding(14)
                        .rCard()
                    }
                }
            }
        }
    }

    // MARK: - Helpers
    private func recalc() {
        MacroCalculator.apply(MacroCalculator.compute(profile: profile), to: profile)
        try? context.save()
    }
}

// MARK: - Section wrapper
private struct Section<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.rSyne(.bold, size: 16))
                .foregroundStyle(Color.rTextPrimary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Editable field sheet
enum ProfileField: String, Identifiable {
    case height, currentWeight, goalWeight
    case calories, protein, carbs, fat
    var id: String { rawValue }
}

private struct EditFieldSheet: View {
    let field: ProfileField
    let profile: UserProfile
    let onChange: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var intValue: Int = 0
    @State private var doubleValue: Double = 0
    @State private var secondaryInt: Int = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rBackground.ignoresSafeArea()
                VStack(spacing: 24) {
                    content
                    Spacer()
                    Button("Save") { save() }
                        .buttonStyle(RPrimaryButton())
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
                .padding(.top, 16)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .tint(Color.rMuted2)
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear(perform: load)
    }

    private var title: String {
        switch field {
        case .height:        return "Height"
        case .currentWeight: return "Current Weight"
        case .goalWeight:    return "Goal Weight"
        case .calories:      return "Calorie Target"
        case .protein:       return "Protein (g)"
        case .carbs:         return "Carbs (g)"
        case .fat:           return "Fat (g)"
        }
    }

    @ViewBuilder private var content: some View {
        switch field {
        case .height:
            HStack(spacing: 10) {
                field(label: "ft", intBinding: $intValue)
                field(label: "in", intBinding: $secondaryInt)
            }
            .padding(.horizontal, 20)
        case .currentWeight, .goalWeight:
            HStack {
                TextField("", value: $doubleValue, format: .number.precision(.fractionLength(0...1)))
                    .keyboardType(.decimalPad)
                    .font(.rMono(.medium, size: 26))
                    .foregroundStyle(Color.rTextPrimary)
                Text("lbs")
                    .font(.rSans(.regular, size: 14))
                    .foregroundStyle(Color.rMuted)
            }
            .padding(16)
            .rCard()
            .padding(.horizontal, 20)
        case .calories, .protein, .carbs, .fat:
            HStack {
                TextField("", value: $intValue, format: .number)
                    .keyboardType(.numberPad)
                    .font(.rMono(.medium, size: 26))
                    .foregroundStyle(Color.rTextPrimary)
                if field != .calories {
                    Text("g")
                        .font(.rSans(.regular, size: 14))
                        .foregroundStyle(Color.rMuted)
                } else {
                    Text("cal")
                        .font(.rSans(.regular, size: 14))
                        .foregroundStyle(Color.rMuted)
                }
            }
            .padding(16)
            .rCard()
            .padding(.horizontal, 20)
        }
    }

    private func field(label: String, intBinding: Binding<Int>) -> some View {
        HStack {
            TextField("", value: intBinding, format: .number)
                .keyboardType(.numberPad)
                .font(.rMono(.medium, size: 22))
                .foregroundStyle(Color.rTextPrimary)
            Text(label)
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
        case .goalWeight:    doubleValue = profile.goalWeightLbs
        case .calories:      intValue = profile.dailyCalorieTarget
        case .protein:       intValue = profile.dailyProteinGrams
        case .carbs:         intValue = profile.dailyCarbsGrams
        case .fat:           intValue = profile.dailyFatGrams
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
        case .calories:
            profile.dailyCalorieTarget = max(0, intValue)
            try? context.save()
        case .protein:
            profile.dailyProteinGrams = max(0, intValue)
            try? context.save()
        case .carbs:
            profile.dailyCarbsGrams = max(0, intValue)
            try? context.save()
        case .fat:
            profile.dailyFatGrams = max(0, intValue)
            try? context.save()
        }
        dismiss()
    }
}

// MARK: - Chips
private struct FlowChips: View {
    let options: [String]
    let selected: [String]
    let toggle: (String) -> Void

    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 86), spacing: 8)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(options, id: \.self) { opt in
                let on = selected.contains(opt)
                Button { toggle(opt) } label: {
                    Text(opt)
                        .font(.rSans(.medium, size: 13))
                        .foregroundStyle(on ? Color.rBackground : Color.rTextPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(on ? Color.rAccentMint : Color.rSurface3,
                                    in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
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

// MARK: - Meal window row
private struct MealWindowRow: View {
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
                        var c = DateComponents()
                        c.hour = window.hour
                        c.minute = window.minute
                        return Calendar.current.date(from: c) ?? Date()
                    },
                    set: { newDate in
                        let c = Calendar.current.dateComponents([.hour, .minute], from: newDate)
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
