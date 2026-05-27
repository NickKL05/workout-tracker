import AuthenticationServices
import HealthKit
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appleSignIn = AppleSignInController()

    @AppStorage("Settings.syncToAppleHealth") private var syncToAppleHealth = false
    @State private var healthError: String?
    @State private var requestingHealthAuth = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        accountSection
                        healthSection
                        aboutSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Account

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Account")
            Card {
                if appleSignIn.isSignedIn {
                    signedInBlock
                } else {
                    signedOutBlock
                }
            }
            Text("Signing in stores a stable identifier on this device only. We don't run a server today; this just keeps your slot warm for future cloud sync.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var signedOutBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Not signed in")
                    .font(.title)
                    .foregroundStyle(Theme.textPrimary)
                Text("Tap below to sign in with your Apple ID.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case .success(let auth):     appleSignIn.handle(authorization: auth)
                case .failure(let error):    appleSignIn.handle(error: error)
                }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 48)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))

            if let err = appleSignIn.lastError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var signedInBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(appleSignIn.displayName ?? "Signed in")
                    .font(.title)
                    .foregroundStyle(Theme.textPrimary)
                if let email = appleSignIn.email {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                if let id = appleSignIn.userIdentifier {
                    Text("ID: \(String(id.prefix(12)))…")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }
            }
            Button(role: .destructive) {
                appleSignIn.signOut()
            } label: {
                Text("Sign out")
            }
            .secondaryButton()
        }
    }

    // MARK: - Health

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Apple Health")
            Card {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle(isOn: $syncToAppleHealth) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Save sessions to Apple Health")
                                .font(.bodyMd)
                                .foregroundStyle(Theme.textPrimary)
                            Text("Each finished workout is written as an Apple Health workout. Whoop, Strava, and the Fitness app can read from there.")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .tint(Theme.accent)
                    .disabled(requestingHealthAuth || !HealthKitManager.shared.isHealthDataAvailable)
                    .onChange(of: syncToAppleHealth) { _, newValue in
                        guard newValue else { return }
                        requestingHealthAuth = true
                        Task {
                            defer { requestingHealthAuth = false }
                            do {
                                try await HealthKitManager.shared.requestAuthorization()
                                healthError = nil
                            } catch {
                                syncToAppleHealth = false
                                healthError = error.localizedDescription
                            }
                        }
                    }

                    if !HealthKitManager.shared.isHealthDataAvailable {
                        Text("Apple Health isn't available on this device.")
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                    } else if let healthError {
                        Text(healthError)
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                    }
                }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "About")
            Card {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Version").font(.bodyMd).foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text(versionString)
                            .font(.mono)
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
            }
        }
    }

    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }
}
