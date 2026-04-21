import SwiftUI

struct WelcomeStep: View {
    let next: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 14) {
                Text("RYZR")
                    .font(.rSyne(.extrabold, size: 72))
                    .foregroundStyle(Color.rAccentMint)
                    .tracking(-1)

                Text("Your body. Your rules.")
                    .font(.rSans(.regular, size: 18))
                    .foregroundStyle(Color.rMuted2)
            }

            Spacer()

            Button("Get Started", action: next)
                .buttonStyle(RPrimaryButton())
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
        }
    }
}
