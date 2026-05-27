import AuthenticationServices
import SwiftUI

/// Full-screen sign-in wall shown when no Apple ID credential is cached.
/// Replaces the app's content until the user signs in; once they do, the
/// HomeView takes over and stays there for every subsequent launch.
struct SignInGateView: View {
    @EnvironmentObject private var appleSignIn: AppleSignInController

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                branding
                Spacer()
                signInBlock
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
            }
        }
    }

    private var branding: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.surfaceElevated)
                    .frame(width: 96, height: 96)
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
            Text("SplitMax")
                .font(.displayLg)
                .foregroundStyle(Theme.textPrimary)
            Text("Plan your splits. Log every set. Watch the lines climb.")
                .font(.bodyMd)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
        }
    }

    private var signInBlock: some View {
        VStack(spacing: 14) {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case .success(let auth):  appleSignIn.handle(authorization: auth)
                case .failure(let error): appleSignIn.handle(error: error)
                }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))

            if let error = appleSignIn.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Your Apple ID is the only identifier we keep. No password, no email lookup, nothing leaves the device.")
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
