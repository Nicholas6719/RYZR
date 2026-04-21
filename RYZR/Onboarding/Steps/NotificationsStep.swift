import SwiftUI

struct NotificationsStep: View {
    let next: () -> Void
    let back: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            StepHeader(title: "Stay on track", back: back)

            VStack(spacing: 18) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.rAccentMint)
                    .padding(.top, 24)

                Text("RYZR sends meal nudges at your chosen times based on what you've eaten that day. Notifications work even when the app is closed.")
                    .font(.rSans(.regular, size: 15))
                    .foregroundStyle(Color.rMuted2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            Spacer()

            VStack(spacing: 10) {
                Button("Enable Notifications") {
                    Task {
                        _ = await NotificationManager.shared.requestPermission()
                        next()
                    }
                }
                .buttonStyle(RPrimaryButton())

                Button("Maybe Later", action: next)
                    .buttonStyle(RGhostButton())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
}
