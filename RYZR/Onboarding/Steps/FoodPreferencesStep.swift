import SwiftUI

struct FoodPreferencesStep: View {
    @Bindable var draft: OnboardingDraft
    let next: () -> Void
    let back: () -> Void

    @State private var selectedCategory: String = FoodCatalog.categories.first ?? "Protein"

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(spacing: 0) {
            StepHeader(title: "Foods you enjoy", back: back)

            Text("We'll use these for meal suggestions")
                .font(.rSans(.regular, size: 13))
                .foregroundStyle(Color.rMuted2)
                .padding(.top, 2)
                .padding(.bottom, 10)

            tabBar
                .padding(.bottom, 10)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(FoodCatalog.items(in: selectedCategory)) { food in
                        tile(for: food)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }

            Button("Continue", action: next)
                .buttonStyle(RPrimaryButton())
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
        }
    }

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(FoodCatalog.categories, id: \.self) { cat in
                    VStack(spacing: 6) {
                        Text(cat)
                            .font(.rSans(.semibold, size: 14))
                            .foregroundStyle(selectedCategory == cat ? Color.rAccentMint : Color.rMuted2)
                        Rectangle()
                            .fill(selectedCategory == cat ? Color.rAccentMint : Color.clear)
                            .frame(height: 2)
                    }
                    .onTapGesture {
                        withAnimation { selectedCategory = cat }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func tile(for food: CatalogFood) -> some View {
        let isSelected = draft.selectedFoods.contains(food.key)
        return Button {
            if isSelected { draft.selectedFoods.remove(food.key) }
            else { draft.selectedFoods.insert(food.key) }
        } label: {
            VStack(spacing: 6) {
                Text(food.emoji).font(.system(size: 30))
                Text(food.name)
                    .font(.rSans(.medium, size: 12))
                    .foregroundStyle(Color.rTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.rAccentDim : Color.rSurface2,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.rAccentMint)
                        .padding(4)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? Color.rAccentMint : Color.rBorder,
                                  lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}
