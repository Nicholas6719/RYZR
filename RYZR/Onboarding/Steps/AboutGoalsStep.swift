import SwiftUI

struct AboutGoalsStep: View {
    @Bindable var draft: OnboardingDraft
    let next: () -> Void
    let back: () -> Void

    private let goals = PrimaryGoal.allCases
    private let activities = ActivityLevel.allCases

    var body: some View {
        VStack(spacing: 0) {
            StepHeader(title: "Let's get to know you", back: back)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    nameField
                    goalsGrid
                    activitySelector
                    workoutsStepper
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }

            Button("Continue", action: next)
                .buttonStyle(RPrimaryButton())
                .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(draft.name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What should we call you?")
                .font(.rSans(.medium, size: 14))
                .foregroundStyle(Color.rMuted2)

            TextField("", text: $draft.name, prompt: Text("Your name").foregroundStyle(Color.rMuted))
                .font(.rSans(.medium, size: 18))
                .foregroundStyle(Color.rTextPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .rCard(fill: .rSurface2)
                .textInputAutocapitalization(.words)
        }
    }

    private var goalsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Primary Goal")
                .font(.rSans(.medium, size: 14))
                .foregroundStyle(Color.rMuted2)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(goals) { goal in
                    GoalCard(goal: goal, selected: draft.primaryGoal == goal.rawValue) {
                        draft.primaryGoal = goal.rawValue
                    }
                }
            }
        }
    }

    private var activitySelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Activity Level")
                .font(.rSans(.medium, size: 14))
                .foregroundStyle(Color.rMuted2)

            VStack(spacing: 8) {
                ForEach(activities) { level in
                    ActivityRow(level: level, selected: draft.activityLevel == level.rawValue) {
                        draft.activityLevel = level.rawValue
                    }
                }
            }
        }
    }

    private var workoutsStepper: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Workouts Per Week")
                .font(.rSans(.medium, size: 14))
                .foregroundStyle(Color.rMuted2)

            HStack {
                Button {
                    if draft.workoutsPerWeek > 1 { draft.workoutsPerWeek -= 1 }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.rTextPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.rSurface2, in: Circle())
                }

                Spacer()
                Text("\(draft.workoutsPerWeek)")
                    .font(.rMono(.medium, size: 32))
                    .foregroundStyle(Color.rAccentMint)
                    .contentTransition(.numericText())
                Spacer()

                Button {
                    if draft.workoutsPerWeek < 7 { draft.workoutsPerWeek += 1 }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.rTextPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.rSurface2, in: Circle())
                }
            }
            .padding(16)
            .rCard()
        }
    }
}

private struct GoalCard: View {
    let goal: PrimaryGoal
    let selected: Bool
    let tap: () -> Void

    var body: some View {
        Button(action: tap) {
            VStack(alignment: .leading, spacing: 6) {
                Text(emoji)
                    .font(.system(size: 28))
                Text(goal.rawValue)
                    .font(.rSans(.semibold, size: 15))
                    .foregroundStyle(Color.rTextPrimary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(selected ? Color.rAccentDim : Color.rSurface2,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(selected ? Color.rAccentMint : Color.rBorder, lineWidth: selected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var emoji: String {
        switch goal {
        case .fatLoss:      return "🔥"
        case .muscleGain:   return "💪"
        case .maintain:     return "⚖️"
        case .generalHealth:return "🌿"
        }
    }
}

private struct ActivityRow: View {
    let level: ActivityLevel
    let selected: Bool
    let tap: () -> Void

    var body: some View {
        Button(action: tap) {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(selected ? Color.rAccentMint : Color.clear)
                    .frame(width: 3)
                Text(level.rawValue)
                    .font(.rSans(.medium, size: 15))
                    .foregroundStyle(Color.rTextPrimary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.rAccentMint)
                        .padding(.trailing, 14)
                }
            }
            .frame(height: 48)
            .background(selected ? Color.rSurface2 : Color.rSurface,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.rBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct StepHeader: View {
    let title: String
    var back: (() -> Void)? = nil

    var body: some View {
        HStack {
            if let back {
                Button(action: back) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.rTextPrimary)
                        .frame(width: 40, height: 40)
                }
            } else {
                Spacer().frame(width: 40, height: 40)
            }
            Spacer()
            Spacer().frame(width: 40, height: 40)
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .overlay {
            Text(title)
                .font(.rSyne(.bold, size: 22))
                .foregroundStyle(Color.rTextPrimary)
                .multilineTextAlignment(.center)
        }
    }
}
