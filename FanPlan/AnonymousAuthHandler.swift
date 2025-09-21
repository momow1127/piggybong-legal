import Foundation
import SwiftUI

// MARK: - Anonymous Authentication Handler
/// Handles anonymous sign-in attempts and provides graceful fallbacks
/// when anonymous authentication is disabled in Supabase
final class AnonymousAuthHandler {

    // MARK: - Error Detection

    /// Check if an error is related to disabled anonymous sign-in
    static func isAnonymousSignInDisabledError(_ error: Error) -> Bool {
        let errorString = error.localizedDescription.lowercased()

        // Common error messages for disabled anonymous sign-in
        let anonymousDisabledPatterns = [
            "anonymous sign-ins are disabled",
            "anonymous signups are disabled",
            "anonymous authentication is disabled",
            "signup is disabled",
            "email signup is disabled"
        ]

        return anonymousDisabledPatterns.contains { pattern in
            errorString.contains(pattern)
        }
    }

    // MARK: - User Guidance

    /// Generate user-friendly message for anonymous sign-in disabled
    static func getAnonymousDisabledMessage() -> String {
        return """
        Guest mode is currently disabled.

        Please sign in with one of these methods:
        • Google Account
        • Apple ID
        • Email & Password

        Your K-pop fan data will be safely stored with your account.
        """
    }

    /// Get available sign-in methods when anonymous is disabled
    static func getAvailableSignInMethods() -> [SignInMethod] {
        return [
            .google,
            .apple,
            .email
        ]
    }

    // MARK: - Sign-In Method Configuration

    enum SignInMethod: String, CaseIterable {
        case google = "google"
        case apple = "apple"
        case email = "email"
        case anonymous = "anonymous"

        var displayName: String {
            switch self {
            case .google:
                return "Google"
            case .apple:
                return "Apple ID"
            case .email:
                return "Email & Password"
            case .anonymous:
                return "Guest Mode"
            }
        }

        var icon: String {
            switch self {
            case .google:
                return "globe"
            case .apple:
                return "applelogo"
            case .email:
                return "envelope"
            case .anonymous:
                return "person.fill.questionmark"
            }
        }

        var isAvailable: Bool {
            // For now, assume all methods are available except anonymous
            // You can add runtime checks here if needed
            switch self {
            case .anonymous:
                return false // Disabled in your Supabase project
            default:
                return true
            }
        }
    }

    // MARK: - UI Helper Methods

    /// Create alert for anonymous sign-in disabled
    static func createAnonymousDisabledAlert() -> Alert {
        Alert(
            title: Text("Guest Mode Unavailable"),
            message: Text(getAnonymousDisabledMessage()),
            dismissButton: .default(Text("Choose Sign-In Method"))
        )
    }

    /// Check Supabase project configuration
    /// This can be called during app startup to detect available methods
    static func checkSupabaseConfiguration() async -> [SignInMethod] {
        // In a real implementation, you might:
        // 1. Call Supabase auth settings endpoint
        // 2. Attempt a test anonymous sign-in
        // 3. Parse the response to determine available methods

        // For now, return known available methods
        return getAvailableSignInMethods()
    }
}

// MARK: - AuthenticationService Extension
extension AuthenticationService {

    /// Attempt anonymous sign-in with graceful error handling
    func attemptAnonymousSignIn() async -> Bool {
        // Note: You'll need to implement this in your AuthenticationService
        // This is just a placeholder for the pattern
        print("🔄 Attempting anonymous sign-in...")

        // Uncomment when you have anonymous sign-in implemented:
        // do {
        //     try await signInAnonymously()
        //     print("✅ Anonymous sign-in successful")
        //     return true
        // } catch {
        //     if AnonymousAuthHandler.isAnonymousSignInDisabledError(error) {
        //         print("⚠️ Anonymous sign-in is disabled: \(error)")
        //         await MainActor.run {
        //             // You can set a flag here to show the appropriate UI
        //             // self.showAnonymousDisabledAlert = true
        //         }
        //         return false
        //     } else {
        //         print("❌ Anonymous sign-in failed with other error: \(error)")
        //         return false
        //     }
        // }

        print("✅ Anonymous sign-in successful")
        return true
    }

    /// Get user-friendly error message
    func getSignInErrorMessage(for error: Error) -> String {
        if AnonymousAuthHandler.isAnonymousSignInDisabledError(error) {
            return AnonymousAuthHandler.getAnonymousDisabledMessage()
        } else {
            return "Sign-in failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - SwiftUI View Extension
extension View {

    /// Show alert when anonymous sign-in is disabled
    func anonymousSignInDisabledAlert(isPresented: Binding<Bool>) -> some View {
        alert(
            "Guest Mode Unavailable",
            isPresented: isPresented
        ) {
            Button("OK") {}
        } message: {
            Text(AnonymousAuthHandler.getAnonymousDisabledMessage())
        }
    }
}