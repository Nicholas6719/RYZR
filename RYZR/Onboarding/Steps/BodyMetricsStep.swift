import SwiftUI

struct BodyMetricsStep: View {
    @Bindable var draft: OnboardingDraft
    let next: () -> Void
    let back: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            StepHeader(title: "Your body", back: back)

            ScrollView {
                VStack(spacing: 18) {
                    ageField
                    sexToggle
                    heightField
                    weightField(label: "Current Weight", value: $draft.currentWeightLbs)
                    weightField(label: "Goal Weight", value: $draft.goalWeightLbs)

                    HStack {
                        Spacer()
                        Text("~\(draft.targets.calories) cal/day")
                            .font(.rMono(.medium, size: 16))
                            .foregroundStyle(Color.rAccentMint)
                        Spacer()
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }

            Button("Continue", action: next)
                .buttonStyle(RPrimaryButton())
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
        }
    }

    private var ageField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Age")
                .font(.rSans(.medium, size: 14))
                .foregroundStyle(Color.rMuted2)

            TextField("", value: $draft.age, format: .number)
                .keyboardType(.numberPad)
                .font(.rMono(.medium, size: 20))
                .foregroundStyle(Color.rTextPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .rCard()
        }
    }

    private var sexToggle: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sex")
                .font(.rSans(.medium, size: 14))
                .foregroundStyle(Color.rMuted2)

            HStack(spacing: 10) {
                ForEach(Sex.allCases) { s in
                    Button {
                        draft.sex = s.rawValue
                    } label: {
                        Text(s.rawValue)
                            .font(.rSans(.semibold, size: 15))
                            .foregroundStyle(draft.sex == s.rawValue ? Color.rBackground : Color.rTextPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(draft.sex == s.rawValue ? Color.rAccentMint : Color.rSurface2,
                                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.rBorder, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var heightField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Height")
                .font(.rSans(.medium, size: 14))
                .foregroundStyle(Color.rMuted2)

            HStack(spacing: 10) {
                HStack {
                    TextField("", value: $draft.heightFeet, format: .number)
                        .keyboardType(.numberPad)
                        .font(.rMono(.medium, size: 20))
                        .foregroundStyle(Color.rTextPrimary)
                    Text("ft")
                        .font(.rSans(.regular, size: 14))
                        .foregroundStyle(Color.rMuted)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .rCard()

                HStack {
                    TextField("", value: $draft.heightInches, format: .number)
                        .keyboardType(.numberPad)
                        .font(.rMono(.medium, size: 20))
                        .foregroundStyle(Color.rTextPrimary)
                    Text("in")
                        .font(.rSans(.regular, size: 14))
                        .foregroundStyle(Color.rMuted)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .rCard()
            }
        }
    }

    private func weightField(label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.rSans(.medium, size: 14))
                .foregroundStyle(Color.rMuted2)

            HStack {
                TextField("", value: value, format: .number.precision(.fractionLength(0...1)))
                    .keyboardType(.decimalPad)
                    .font(.rMono(.medium, size: 20))
                    .foregroundStyle(Color.rTextPrimary)
                Text("lbs")
                    .font(.rSans(.regular, size: 14))
                    .foregroundStyle(Color.rMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .rCard()
        }
    }
}
