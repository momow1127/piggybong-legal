import Foundation
import FirebaseCrashlytics

final class CrashlyticsService: Sendable {
    static let shared = CrashlyticsService()

    private init() {}

    /// Initialize Crashlytics (call this in App startup)
    func configure() {
        // Crashlytics is automatically initialized with Firebase
        print("🔥 Crashlytics configured")
    }

    /// Set user identifier for crash reports
    func setUser(_ userId: String) {
        Crashlytics.crashlytics().setUserID(userId)
        print("📱 [Crashlytics] User ID set: \(userId)")
    }

    /// Log custom events
    func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
        print("📱 [Crashlytics] Log: \(message)")
    }

    /// Record non-fatal errors
    func recordError(_ error: Error, userInfo: [String: Any]? = nil) {
        Crashlytics.crashlytics().record(error: error, userInfo: userInfo)
        print("📱 [Crashlytics] Error recorded: \(error.localizedDescription)")
        if let userInfo = userInfo {
            print("📱 [Crashlytics] UserInfo: \(userInfo)")
        }
    }

    /// Set custom keys for debugging
    func setValue(_ value: Any?, forKey key: String) {
        if let value = value {
            Crashlytics.crashlytics().setCustomValue(value, forKey: key)
            print("📱 [Crashlytics] Set \(key): \(value)")
        }
    }

    /// Track purchase events
    func trackPurchase(amount: Double, currency: String, itemCount: Int) {
        setValue(amount, forKey: "last_purchase_amount")
        setValue(currency, forKey: "last_purchase_currency")
        setValue(itemCount, forKey: "last_purchase_items")
        log("Purchase: \(amount) \(currency) for \(itemCount) items")
    }

    /// Track screen views
    func trackScreen(_ screenName: String) {
        setValue(screenName, forKey: "current_screen")
        log("Screen viewed: \(screenName)")
    }

    // MARK: - Enhanced Error Tracking

    /// Record authentication errors with context
    func recordAuthError(_ error: Error, method: String, step: String) {
        setValue(method, forKey: "auth_method")
        setValue(step, forKey: "auth_step")
        setValue("authentication", forKey: "error_category")
        recordError(error, userInfo: [
            "auth_method": method,
            "auth_step": step,
            "error_category": "authentication"
        ])
    }

    /// Record AI feature errors with context
    func recordAIError(_ error: Error, feature: String, artistName: String? = nil) {
        setValue(feature, forKey: "ai_feature")
        setValue("ai_insights", forKey: "error_category")
        if let artist = artistName {
            setValue(artist, forKey: "ai_artist_context")
        }
        recordError(error, userInfo: [
            "ai_feature": feature,
            "artist_name": artistName ?? "unknown",
            "error_category": "ai_insights"
        ])
    }

    /// Record subscription/payment errors
    func recordPaymentError(_ error: Error, plan: String?, amount: Double? = nil) {
        setValue("payment", forKey: "error_category")
        if let plan = plan {
            setValue(plan, forKey: "subscription_plan")
        }
        if let amount = amount {
            setValue(amount, forKey: "payment_amount")
        }
        recordError(error, userInfo: [
            "subscription_plan": plan ?? "unknown",
            "payment_amount": amount ?? 0.0,
            "error_category": "payment"
        ])
    }

    /// Record API/Network errors with endpoint info
    func recordNetworkError(_ error: Error, endpoint: String, method: String = "GET") {
        setValue(endpoint, forKey: "api_endpoint")
        setValue(method, forKey: "api_method")
        setValue("network", forKey: "error_category")
        recordError(error, userInfo: [
            "api_endpoint": endpoint,
            "api_method": method,
            "error_category": "network"
        ])
    }

    /// Record user action errors (like adding fan activities)
    func recordUserActionError(_ error: Error, action: String, context: [String: Any] = [:]) {
        setValue(action, forKey: "user_action")
        setValue("user_interaction", forKey: "error_category")

        var userInfo = context
        userInfo["user_action"] = action
        userInfo["error_category"] = "user_interaction"

        recordError(error, userInfo: userInfo)
    }

    // MARK: - Breadcrumb Tracking

    /// Track critical user flow progression
    func trackUserFlow(_ flowName: String, step: String, success: Bool = true) {
        let status = success ? "success" : "failure"
        log("UserFlow: \(flowName) - \(step) - \(status)")
        setValue(flowName, forKey: "current_user_flow")
        setValue(step, forKey: "current_flow_step")
    }

    /// Track AI insight interactions for better crash context
    func trackAIInteraction(_ action: String, artistName: String?, insightType: String?) {
        log("AI: \(action) for \(artistName ?? "unknown") - \(insightType ?? "unknown")")
        setValue(action, forKey: "last_ai_action")
        if let artist = artistName {
            setValue(artist, forKey: "last_ai_artist")
        }
        if let type = insightType {
            setValue(type, forKey: "last_ai_insight_type")
        }
    }

    // MARK: - Critical Business Logic Tracking

    /// Set user subscription status for crash context
    func setSubscriptionStatus(isActive: Bool, plan: String? = nil) {
        setValue(isActive, forKey: "is_subscribed")
        if let plan = plan {
            setValue(plan, forKey: "subscription_plan")
        }
    }

    /// Set user onboarding status
    func setOnboardingStatus(completed: Bool, step: String? = nil) {
        setValue(completed, forKey: "onboarding_completed")
        if let step = step {
            setValue(step, forKey: "onboarding_step")
        }
    }

    /// Track artist selection count for context
    func setArtistCount(_ count: Int) {
        setValue(count, forKey: "selected_artists_count")
    }
}