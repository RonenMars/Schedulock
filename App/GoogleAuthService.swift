import Foundation
import GoogleSignIn
import UIKit

/// Manages Google Sign-In for OAuth access to Google Calendar.
/// Singleton matching the project's BackgroundTaskManager pattern.
final class GoogleAuthService {
    static let shared = GoogleAuthService()

    private static let calendarReadonlyScope = "https://www.googleapis.com/auth/calendar.readonly"

    private init() {}

    // MARK: - State

    /// The currently signed-in Google user, if any.
    var currentUser: GIDGoogleUser? {
        GIDSignIn.sharedInstance.currentUser
    }

    /// Whether a Google account is currently signed in with calendar scope.
    var isSignedIn: Bool {
        guard let user = currentUser else { return false }
        return user.grantedScopes?.contains(Self.calendarReadonlyScope) ?? false
    }

    // MARK: - Restore Previous Sign-In

    /// Attempts to silently restore the previous sign-in session.
    /// Call this on app launch to resume without user interaction.
    /// Returns true if a valid session was restored with calendar scope.
    @discardableResult
    func restorePreviousSignIn() async -> Bool {
        do {
            let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            return user.grantedScopes?.contains(Self.calendarReadonlyScope) ?? false
        } catch {
            print("[GoogleAuth] Restore failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Sign In

    /// Initiates Google Sign-In with the calendar.readonly scope.
    /// Presents the sign-in UI from the given view controller.
    /// - Throws: If sign-in fails or is cancelled by the user.
    func signIn(presenting viewController: UIViewController) async throws {
        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: viewController,
            hint: nil,
            additionalScopes: [Self.calendarReadonlyScope]
        )

        // Verify the calendar scope was actually granted
        guard result.user.grantedScopes?.contains(Self.calendarReadonlyScope) ?? false else {
            throw GoogleAuthError.calendarScopeNotGranted
        }
    }

    // MARK: - Sign Out

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }

    // MARK: - Access Token

    /// Returns a valid access token, refreshing if necessary.
    /// - Throws: If no user is signed in or token refresh fails.
    func validAccessToken() async throws -> String {
        guard let user = currentUser else {
            throw GoogleAuthError.notSignedIn
        }

        // refreshTokensIfNeeded is a no-op if the token is still valid
        let refreshedUser = try await user.refreshTokensIfNeeded()
        return refreshedUser.accessToken.tokenString
    }

    // MARK: - URL Handling

    /// Handles the OAuth callback URL. Call from the app's URL handler.
    /// Returns true if the URL was handled by Google Sign-In.
    @discardableResult
    func handle(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}

// MARK: - AccessTokenProvider Protocol

/// Minimal protocol for auth dependency injection in tests.
/// Production code uses GoogleAuthService.shared; tests can substitute a fake.
protocol AccessTokenProvider {
    var isSignedIn: Bool { get }
    func validAccessToken() async throws -> String
}

extension GoogleAuthService: AccessTokenProvider {}

// MARK: - Errors

enum GoogleAuthError: LocalizedError {
    case notSignedIn
    case calendarScopeNotGranted

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "No Google account is signed in."
        case .calendarScopeNotGranted:
            return "Calendar access was not granted. Please sign in again and allow calendar access."
        }
    }
}
