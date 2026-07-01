import SwiftUI
import AuthenticationServices

/// First launch. A single Sign-in-with-Apple button gets the user into the generator
/// in one tap, with zero typing.
struct OnboardingView: View {
    @EnvironmentObject var account: AccountManager
    @Environment(\.colorScheme) private var scheme
    @State private var pulse = false

    var body: some View {
        ZStack {
            CoverCraftBackground()
            VStack(spacing: 0) {
                Spacer(minLength: 20)

                Image(systemName: "doc.text.fill")
                    .font(.system(size: 84, weight: .semibold))
                    .foregroundStyle(Color.covercraftAccent)
                    .scaleEffect(pulse ? 1.04 : 0.96)
                    .animation(.covercraftInOut(duration: 2.4).repeatForever(autoreverses: true), value: pulse)

                Spacer(minLength: 24)

                VStack(spacing: 10) {
                    Text("CoverCraft")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                    Text("Paste the job.\nGet a tailored cover letter in seconds.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer(minLength: 24)

                VStack(spacing: 12) {
                    SignInWithAppleButton(.continue) { request in
                        account.configure(request)
                    } onCompletion: { result in
                        account.handle(result)
                    }
                    .signInWithAppleButtonStyle(scheme == .dark ? .white : .black)
                    .frame(height: 52)
                    .clipShape(Capsule())

                    Text("No ads. Your job search stays private.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 24)
            }
            .padding()
        }
        .onAppear { pulse = true }
    }
}
