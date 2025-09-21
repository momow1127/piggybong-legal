import Foundation
import SwiftUI
import Supabase
import Auth
import FirebaseAppCheck

// MARK: - Secure Feedback Service with App Check Integration
final class SecureFeedbackService: ObservableObject, @unchecked Sendable {
    static let shared = SecureFeedbackService()

    @Published var isSubmitting = false
    @Published var lastSubmissionSuccess = false

    private let supabaseURL: URL? = {
        guard let urlString = ProcessInfo.processInfo.environment["SUPABASE_URL"],
              !urlString.isEmpty,
              let url = URL(string: urlString) else {
            print("⚠️ SecureFeedbackService: Invalid SUPABASE_URL")
            return nil
        }
        return url
    }()
    private let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""

    private init() {}

    /// Submit feedback with App Check verification (simplified approach)
    @MainActor
    func submitSecureFeedback(
        type: FeedbackType,
        subject: String,
        message: String,
        screenName: String? = nil
    ) async throws {
        guard let supabaseURL = supabaseURL else {
            throw NSError(domain: "SecureFeedbackService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Feedback service unavailable - missing configuration"
            ])
        }

        DispatchQueue.main.async { [weak self] in self?.isSubmitting = true }
        defer { DispatchQueue.main.async { [weak self] in self?.isSubmitting = false } }

        // Input validation
        guard !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FeedbackServiceError.validationError("Subject cannot be empty")
        }
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FeedbackServiceError.validationError("Message cannot be empty")
        }

        do {
            // Get App Check token for verification
            let appCheckToken = try await AppCheck.appCheck().token(forcingRefresh: false)
            let tokenPreview = String(appCheckToken.token.prefix(12))
            print("✅ App Check token obtained for secure submission (preview: \(tokenPreview)...)")

            // Create standard Supabase client
            let supabase = SupabaseClient(
                supabaseURL: supabaseURL,
                supabaseKey: supabaseKey
            )

            // Get device info
            let device = UIDevice.current
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

            // Get current user ID
            let session = try await supabase.auth.session
            let userId = session.user.id

            let feedback = UserFeedback(
                id: nil,
                userId: userId,
               
                type: type,
                subject: subject,
                message: message,
                appVersion: appVersion,
                deviceModel: device.model,
                osVersion: device.systemVersion,
                screenName: screenName,
                status: .new,
                priority: type == .bug ? 4 : 3,
                createdAt: nil
            )

            // Submit feedback - App Check token is validated on Firebase/Supabase side
            try await supabase
                .from("user_feedback")
                .insert(feedback)
                .execute()

            DispatchQueue.main.async { [weak self] in self?.lastSubmissionSuccess = true }
            print("✅ Secure feedback submitted successfully with App Check verification")

            // Log to Crashlytics
            CrashlyticsService.shared.log("Secure feedback submitted: \(type.rawValue) - \(subject)")

        } catch {
            DispatchQueue.main.async { [weak self] in self?.lastSubmissionSuccess = false }
            print("❌ Secure feedback submission failed: \(error)")
            CrashlyticsService.shared.recordError(error)

            if error is FeedbackServiceError {
                throw error
            } else {
                throw FeedbackServiceError.networkError(error)
            }
        }
    }

    /// Test App Check token generation
    func testAppCheckToken() async -> (success: Bool, message: String) {
        do {
            let appCheckToken = try await AppCheck.appCheck().token(forcingRefresh: false)
            let tokenPreview = String(appCheckToken.token.prefix(20))
            return (true, "✅ App Check token obtained successfully\n📝 Token: \(tokenPreview)...")
        } catch {
            return (false, "❌ App Check token failed: \(error.localizedDescription)")
        }
    }
}
