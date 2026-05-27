import AuthenticationServices
import Foundation

/// Persistence + state for Sign in with Apple. The UI lives in
/// `SettingsView` using SwiftUI's `SignInWithAppleButton`; this type just
/// handles the result and remembers it across launches.
///
/// We're not running a backend, so the credential identifier is used purely
/// as a stable local user ID. If we ever add cloud sync or a paid tier, the
/// identifier becomes the primary key tying a device to that account.
final class AppleSignInController: ObservableObject {
    @Published var userIdentifier: String?
    @Published var displayName: String?
    @Published var email: String?
    @Published var lastError: String?

    private static let userIDKey = "AppleSignIn.userIdentifier"
    private static let displayNameKey = "AppleSignIn.displayName"
    private static let emailKey = "AppleSignIn.email"

    init() {
        let defaults = UserDefaults.standard
        self.userIdentifier = defaults.string(forKey: Self.userIDKey)
        self.displayName    = defaults.string(forKey: Self.displayNameKey)
        self.email          = defaults.string(forKey: Self.emailKey)
    }

    var isSignedIn: Bool { userIdentifier != nil }

    /// Apple returns `fullName` and `email` only on the first sign-in for
    /// this Apple ID + app pair. Subsequent silent sign-ins give us the
    /// stable `user` identifier only, so we never overwrite cached fields
    /// with nil.
    func handle(authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        let defaults = UserDefaults.standard

        userIdentifier = credential.user
        defaults.set(credential.user, forKey: Self.userIDKey)

        if let name = credential.fullName {
            let formatter = PersonNameComponentsFormatter()
            let formatted = formatter.string(from: name)
            if !formatted.isEmpty {
                displayName = formatted
                defaults.set(formatted, forKey: Self.displayNameKey)
            }
        }
        if let email = credential.email {
            self.email = email
            defaults.set(email, forKey: Self.emailKey)
        }
        lastError = nil
    }

    func handle(error: Error) {
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            lastError = nil
        } else {
            lastError = (error as NSError).localizedDescription
        }
    }

    func signOut() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Self.userIDKey)
        defaults.removeObject(forKey: Self.displayNameKey)
        defaults.removeObject(forKey: Self.emailKey)
        userIdentifier = nil
        displayName = nil
        email = nil
        lastError = nil
    }
}
