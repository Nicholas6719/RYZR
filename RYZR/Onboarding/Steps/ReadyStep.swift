import SwiftUI

struct ReadyStep: View {
    @Bindable var draft: OnboardingDraft
    let finish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            title

            ScrollView {
                summaryCard
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
            }

            Button("Let's go 🚀", action: finish)
                .buttonStyle(RPrimaryButton())
                .font(.rSyne(.bold, size: 17))
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
        }
    }

    private var title: some View {
        let name = draft.name.trimmingCharacters(in: .whitespaces)
        return HStack(spacing: 6) {
            Text("You're all set, ")
                .foregroundStyle(Color.rTextPrimary)
            Text(name.isEmpty ? "friend" : name)
                .foregroundStyle(Color.rAccentMint)
            Text(" 🚀")
                .foregroundStyle(Color.rTextPrimary)
        }
        .font(.rSyne(.extrabold, size: 22))
        .padding(.horizontal, 20)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily Calorie Target")
                    .font(.rSans(.medium, size: 13))
                    .foregroundStyle(Color.rMuted2)
                Text("\(draft.targets.calories)")
                    .font(.rMono(.medium, size: 44))
                    .foregroundStyle(Color.rOrangeCals)
            }

            Divider().background(Color.rBorder)

            macroRow(label: "Protein", grams: draft.targets.proteinGrams, color: .rAccentMint)
            macroRow(label: "Carbs", grams: draft.targets.carbsGrams, color: .rBlueCarbs)
            macroRow(label: "Fat", grams: draft.targets.fatGrams, color: .rOrangeCals)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.rSurface2, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.rBorder, lineWidth: 1)
        }
    }

    private func macroRow(label: String, grams: Int, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.rSans(.medium, size: 15))
                .foregroundStyle(Color.rTextPrimary)
            Spacer()
            Text("\(grams)g")
                .font(.rMono(.medium, size: 18))
                .foregroundStyle(color)
        }
    }
}
