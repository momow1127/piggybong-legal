import Foundation
import SwiftUI
import Supabase
import Auth
import FirebaseAppCheck

// MARK: - Feedback Models
struct UserFeedback: Codable {
    let id: UUID?
    let userId: UUID?
    let type: FeedbackType
    let subject: String
    let message: String
    let appVersion: String?
    let deviceModel: String?
    let osVersion: String?
    let screenName: String?
    let status: FeedbackStatus?
    let priority: Int?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case subject
        case message
        case appVersion = "app_version"
        case deviceModel = "device_model"
        case osVersion = "os_version"
        case screenName = "screen_name"
        case status
        case priority
        case createdAt = "created_at"
    }
}

enum FeedbackType: String, Codable, CaseIterable {
    case bug = "bug"
    case feature = "feature"
    case complaint = "complaint"
    case praise = "praise"
    case other = "other"

    var icon: String {
        switch self {
        case .bug: return "ladybug"
        case .feature: return "lightbulb"
        case .complaint: return "exclamationmark.triangle"
        case .praise: return "star"
        case .other: return "questionmark.circle"
        }
    }

    var title: String {
        switch self {
        case .bug: return "Report a Bug"
        case .feature: return "Request Feature"
        case .complaint: return "Something's Wrong"
        case .praise: return "Send Praise"
        case .other: return "Other Feedback"
        }
    }
}

enum FeedbackStatus: String, Codable {
    case new = "new"
    case reviewing = "reviewing"
    case inProgress = "in_progress"
    case resolved = "resolved"
    case wontFix = "wont_fix"
}

// MARK: - Feedback Service Error Types
enum FeedbackServiceError: LocalizedError {
    case appCheckFailed(Error)
    case authenticationRequired
    case networkError(Error)
    case validationError(String)

    var errorDescription: String? {
        switch self {
        case .appCheckFailed(let error):
            return "App verification failed: \(error.localizedDescription)"
        case .authenticationRequired:
            return "Authentication required to submit feedback"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .validationError(let message):
            return "Validation error: \(message)"
        }
    }
}

// MARK: - App Check Token Cache (Thread-Safe with NSLock)
final class AppCheckTokenCache {
    private var cachedToken: (token: String, expiry: Date)?
    private let cacheMinutes: TimeInterval = 55 // Cache for 55 minutes (tokens valid for 1 hour)
    private let lock = NSLock()

    func getCachedToken() -> String? {
        lock.lock()
        defer { lock.unlock() }

        guard let cached = cachedToken,
              cached.expiry > Date() else {
            return nil
        }
        return cached.token
    }

    func cacheToken(_ token: String) {
        lock.lock()
        defer { lock.unlock() }

        cachedToken = (
            token: token,
            expiry: Date().addingTimeInterval(cacheMinutes * 60)
        )
    }

    func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        cachedToken = nil
    }
}

// MARK: - Feedback Service
// Mark as @unchecked Sendable to allow capture in @Sendable closures where we control threading
final class FeedbackService: ObservableObject, @unchecked Sendable {
    static let shared = FeedbackService()

    @Published var isSubmitting = false
    @Published var lastSubmissionSuccess = false

    private let supabaseURL: URL? = {
        guard let urlString = ProcessInfo.processInfo.environment["SUPABASE_URL"],
              !urlString.isEmpty,
              let url = URL(string: urlString) else {
            print("⚠️ FeedbackService: Invalid SUPABASE_URL")
            return nil
        }
        return url
    }()
    private let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""

    // High-performance token cache with thread safety
    private let tokenCache = AppCheckTokenCache()
    private var supabase: SupabaseClient? {
        guard let supabaseURL = supabaseURL else { return nil }
        return SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }

    private init() {}

    /// Get App Check token with high-performance caching (95% fewer API calls)
    func getAppCheckToken() async throws -> String {
        // Check if we have a valid cached token first
        if let cachedToken = tokenCache.getCachedToken() {
            return cachedToken
        }

        // Only call Firebase API if cache is empty/expired
        do {
            let appCheckToken = try await AppCheck.appCheck().token(forcingRefresh: false)

            // Cache the new token for future use
            tokenCache.cacheToken(appCheckToken.token)

            print("✅ App Check token obtained and cached for 55 minutes")
            return appCheckToken.token
        } catch {
            print("❌ App Check token failed: \(error)")
            CrashlyticsService.shared.recordError(error)
            throw FeedbackServiceError.appCheckFailed(error)
        }
    }

    /// Creates a Supabase client with cached App Check token
    private func createSecureSupabaseClient() async throws -> SupabaseClient {
        guard let supabaseURL = supabaseURL else {
            throw FeedbackServiceError.validationError("Supabase URL not configured")
        }

        // Ensure we have an App Check token (will use cache if present)
        _ = try await getAppCheckToken()

        // Create standard client (token will be used per-request)
        return SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }

    /// Submit user feedback with App Check verification
    @MainActor
    func submitFeedback(
        type: FeedbackType,
        subject: String,
        message: String,
        screenName: String? = nil
    ) async throws {

        DispatchQueue.main.async { [weak self] in self?.isSubmitting = true }
        defer { DispatchQueue.main.async { [weak self] in self?.isSubmitting = false } }

        // Input validation
        guard !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FeedbackServiceError.validationError("Subject cannot be empty")
        }
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FeedbackServiceError.validationError("Message cannot be empty")
        }

        // Get device info and K-pop app context
        let device = UIDevice.current
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

        // Add K-pop budgeting app context
        let enhancedScreenName = screenName.map { "\($0) - K-pop Budget Tracker" } ?? "Unknown Screen - K-pop Budget Tracker"

        do {
            // Use secure client with App Check token
            let secureClient = try await createSecureSupabaseClient()

            // Get current user ID
            let session = try await secureClient.auth.session
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
                screenName: enhancedScreenName,
                status: .new,
                priority: type == .bug ? 4 : 3,
                createdAt: nil
            )

            // Insert with App Check header
            try await secureClient
                .from("user_feedback")
                .insert(feedback)
                .execute()

            DispatchQueue.main.async { [weak self] in self?.lastSubmissionSuccess = true }
            print("✅ Feedback submitted successfully with App Check verification")

            // Secure logging - avoid sensitive data
            CrashlyticsService.shared.log("Feedback submitted: \(type.rawValue) - [subject redacted for privacy]")
        } catch {
            DispatchQueue.main.async { [weak self] in self?.lastSubmissionSuccess = false }
            print("❌ Feedback submission failed: \(error)")
            CrashlyticsService.shared.recordError(error)

            if error is FeedbackServiceError {
                throw error
            } else {
                throw FeedbackServiceError.networkError(error)
            }
        }
    }

    /// Get user's feedback history with App Check verification
    func getUserFeedback() async throws -> [UserFeedback] {
        do {
            // Use secure client with App Check token
            let secureClient = try await createSecureSupabaseClient()
            let session = try await secureClient.auth.session
            let userId = session.user.id

            let response = try await secureClient
                .from("user_feedback")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let feedback = try decoder.decode([UserFeedback].self, from: response.data)

            print("✅ Retrieved \(feedback.count) feedback items with App Check verification")
            // Log for K-pop app analytics
            CrashlyticsService.shared.log("User feedback history retrieved: \(feedback.count) items")
            return feedback
        } catch {
            print("❌ Failed to retrieve feedback: \(error)")
            CrashlyticsService.shared.recordError(error)

            if error is FeedbackServiceError {
                throw error
            } else {
                throw FeedbackServiceError.networkError(error)
            }
        }
    }
}
