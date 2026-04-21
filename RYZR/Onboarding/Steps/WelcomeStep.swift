import SwiftUI

struct WelcomeStep: View {
    let next: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                Text("RYZR")
                    .font(.rSyne(.extrabold, size: 56))
                    .foregroundStyle(Color.rAccentMint)
                    .tracking(-0.5)

                Text("Your body. Your rules.")
                    .font(.rSans(.regular, size: 16))
                    .foregroundStyle(Color.rMuted2)
            }

            Spacer()
            Spacer()

            Button("Get Started", action: next)
                .buttonStyle(RPrimaryButton())
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
        }
    }
}
