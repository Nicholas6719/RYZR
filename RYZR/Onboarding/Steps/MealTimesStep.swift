import SwiftUI

struct MealTimesStep: View {
    @Bindable var draft: OnboardingDraft
    let next: () -> Void
    let back: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            StepHeader(title: "When do you usually eat?", back: back)

            ScrollView {
                VStack(spacing: 14) {
                    row(label: "Breakfast",
                        hour: $draft.breakfastHour,
                        minute: $draft.breakfastMinute,
                        enabled: $draft.breakfastEnabled)
                    row(label: "Lunch",
                        hour: $draft.lunchHour,
                        minute: $draft.lunchMinute,
                        enabled: $draft.lunchEnabled)
                    row(label: "Dinner",
                        hour: $draft.dinnerHour,
                        minute: $draft.dinnerMinute,
                        enabled: $draft.dinnerEnabled)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }

            Button("Continue", action: next)
                .buttonStyle(RPrimaryButton())
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
        }
    }

    private func row(label: String, hour: Binding<Int>, minute: Binding<Int>, enabled: Binding<Bool>) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.rSans(.semibold, size: 16))
                    .foregroundStyle(Color.rTextPrimary)
                Spacer()
                DatePicker(
                    "",
                    selection: Binding(
                        get: { dateFrom(hour: hour.wrappedValue, minute: minute.wrappedValue) },
                        set: { newValue in
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                            hour.wrappedValue = comps.hour ?? 0
                            minute.wrappedValue = comps.minute ?? 0
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .colorInvert()
                .colorMultiply(Color.rTextPrimary)
                .disabled(!enabled.wrappedValue)

                Toggle("", isOn: enabled)
                    .labelsHidden()
                    .tint(Color.rAccentMint)
            }
            .padding(16)
        }
        .rCard()
    }

    private func dateFrom(hour: Int, minute: Int) -> Date {
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? Date()
    }
}
