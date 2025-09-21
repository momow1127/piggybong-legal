import Foundation
import SwiftUI
import FirebaseAnalytics
import FirebasePerformance

/// Enhanced trace implementation with Firebase Performance + Analytics integration
class LocalTrace {
    let name: String
    let startTime: Date
    private var attributes: [String: String] = [:]
    private var firebaseTrace: Trace?

    init(name: String) {
        self.name = name
        self.startTime = Date()

        // Create a real Firebase Performance trace
        self.firebaseTrace = Performance.startTrace(name: name)
        print("🚀 Firebase Performance: Started trace '\(name)'")
    }

    func setValue(_ value: String, forAttribute key: String) {
        attributes[key] = value

        // Also set attribute on Firebase Performance trace
        firebaseTrace?.setValue(value, forAttribute: key)
    }

    func stop() {
        let duration = Date().timeIntervalSince(startTime)
        let durationMs = Int(duration * 1000)

        // Stop the Firebase Performance trace
        firebaseTrace?.stop()
        print("🚀 Firebase Performance: Stopped trace '\(name)' (\(String(format: "%.2f", duration))s)")

        // Log to console for debugging
        print("📊 Performance: \(name) completed in \(String(format: "%.2f", duration))s with attributes: \(attributes)")

        // Send performance data to Firebase Analytics (for correlation)
        var analyticsParams: [String: Any] = [
            "duration_ms": durationMs,
            "duration_seconds": String(format: "%.2f", duration)
        ]

        // Add custom attributes
        for (key, value) in attributes {
            analyticsParams[key] = value
        }

        // Log performance event to Firebase Analytics (backup)
        Analytics.logEvent("performance_trace", parameters: analyticsParams)

        // Also log to our AI Analytics service for correlation
        AIInsightAnalyticsService.shared.logPerformanceMetric(
            traceName: name,
            durationMs: durationMs,
            attributes: attributes
        )
    }
}

/// Performance Monitoring Service for tracking key user flows
/// Integrates with Firebase Performance SDK for real performance tracking
class PerformanceService: ObservableObject {
    static let shared = PerformanceService()

    private var activeTraces: [String: LocalTrace] = [:]
    private let tracesLock = NSLock()

    private init() {}

    // MARK: - Authentication Flows

    func startLoginTrace() -> String {
        let traceId = "user_login_\(UUID().uuidString.prefix(8))"
        let trace = LocalTrace(name: "user_login")
        trace.setValue("authentication", forAttribute: "flow_type")

        tracesLock.lock()
        activeTraces[traceId] = trace
        tracesLock.unlock()

        return traceId
    }

    func startSignUpTrace() -> String {
        let traceId = "user_signup_\(UUID().uuidString.prefix(8))"
        let trace = LocalTrace(name: "user_signup")
        trace.setValue("authentication", forAttribute: "flow_type")

        tracesLock.lock()
        activeTraces[traceId] = trace
        tracesLock.unlock()

        return traceId
    }

    func completeAuthTrace(_ traceId: String, success: Bool, method: String) {
        tracesLock.lock()
        guard let trace = activeTraces[traceId] else {
            tracesLock.unlock()
            return
        }
        activeTraces.removeValue(forKey: traceId)
        tracesLock.unlock()

        trace.setValue(success ? "success" : "failure", forAttribute: "result")
        trace.setValue(method, forAttribute: "auth_method") // "apple", "google", "email"
        trace.stop()
    }

    // MARK: - Onboarding Flow

    func startOnboardingTrace() -> String {
        let traceId = "onboarding_\(UUID().uuidString.prefix(8))"
        let trace = LocalTrace(name: "onboarding_flow")
        trace.setValue("user_setup", forAttribute: "flow_type")

        tracesLock.lock()
        activeTraces[traceId] = trace
        tracesLock.unlock()

        return traceId
    }

    func completeOnboardingTrace(_ traceId: String, completed: Bool, stepsCompleted: Int) {
        tracesLock.lock()
        guard let trace = activeTraces[traceId] else {
            tracesLock.unlock()
            return
        }
        activeTraces.removeValue(forKey: traceId)
        tracesLock.unlock()

        trace.setValue(completed ? "completed" : "abandoned", forAttribute: "result")
        trace.setValue(String(stepsCompleted), forAttribute: "steps_completed")
        trace.stop()
    }

    // MARK: - Paywall & Monetization

    func startPaywallTrace() -> String {
        let traceId = "paywall_\(UUID().uuidString.prefix(8))"
        let trace = LocalTrace(name: "paywall_conversion")
        trace.setValue("monetization", forAttribute: "flow_type")

        tracesLock.lock()
        activeTraces[traceId] = trace
        tracesLock.unlock()

        return traceId
    }

    func completePaywallTrace(_ traceId: String, converted: Bool, plan: String?) {
        tracesLock.lock()
        guard let trace = activeTraces[traceId] else {
            tracesLock.unlock()
            return
        }
        activeTraces.removeValue(forKey: traceId)
        tracesLock.unlock()

        trace.setValue(converted ? "converted" : "dismissed", forAttribute: "result")
        if let plan = plan {
            trace.setValue(plan, forAttribute: "selected_plan")
        }
        trace.stop()
    }

    // MARK: - Artist Selection

    func startArtistSelectionTrace() -> String {
        let traceId = "artist_selection_\(UUID().uuidString.prefix(8))"
        let trace = LocalTrace(name: "artist_selection")
        trace.setValue("user_preference", forAttribute: "flow_type")

        tracesLock.lock()
        activeTraces[traceId] = trace
        tracesLock.unlock()

        return traceId
    }

    func completeArtistSelectionTrace(_ traceId: String, artistsSelected: Int) {
        tracesLock.lock()
        guard let trace = activeTraces[traceId] else {
            tracesLock.unlock()
            return
        }
        activeTraces.removeValue(forKey: traceId)
        tracesLock.unlock()

        trace.setValue(String(artistsSelected), forAttribute: "artists_selected")
        trace.setValue(artistsSelected > 0 ? "success" : "skipped", forAttribute: "result")
        trace.stop()
    }

    // MARK: - Fan Activity & Budget

    func startAddActivityTrace() -> String {
        let traceId = "add_activity_\(UUID().uuidString.prefix(8))"
        let trace = LocalTrace(name: "add_fan_activity")
        trace.setValue("user_engagement", forAttribute: "flow_type")

        tracesLock.lock()
        activeTraces[traceId] = trace
        tracesLock.unlock()

        return traceId
    }

    func completeAddActivityTrace(_ traceId: String, success: Bool, category: String?) {
        tracesLock.lock()
        guard let trace = activeTraces[traceId] else {
            tracesLock.unlock()
            return
        }
        activeTraces.removeValue(forKey: traceId)
        tracesLock.unlock()

        trace.setValue(success ? "added" : "cancelled", forAttribute: "result")
        if let category = category {
            trace.setValue(category, forAttribute: "activity_category")
        }
        trace.stop()
    }

    // MARK: - App Performance Metrics

    func trackScreenLoad(_ screenName: String, loadTime: TimeInterval) {
        let trace = LocalTrace(name: "screen_load")
        trace.setValue(screenName, forAttribute: "screen_name")
        trace.setValue("ui_performance", forAttribute: "metric_type")

        // Simulate the load time by stopping after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + loadTime) {
            trace.stop()
        }
    }

    func trackNetworkRequest(_ endpoint: String, responseTime: TimeInterval, success: Bool) {
        let trace = LocalTrace(name: "api_request")
        trace.setValue(endpoint, forAttribute: "endpoint")
        trace.setValue(success ? "success" : "failure", forAttribute: "result")
        trace.setValue("network", forAttribute: "metric_type")

        // Simulate the response time
        DispatchQueue.main.asyncAfter(deadline: .now() + responseTime) {
            trace.stop()
        }
    }

    // MARK: - Critical User Actions

    func trackCriticalAction(_ actionName: String, duration: TimeInterval, success: Bool) {
        let trace = LocalTrace(name: actionName)
        trace.setValue(success ? "success" : "failure", forAttribute: "result")
        trace.setValue("critical_action", forAttribute: "metric_type")

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            trace.stop()
        }
    }

    // MARK: - Helper Methods

    func cancelTrace(_ traceId: String) {
        tracesLock.lock()
        guard let trace = activeTraces[traceId] else {
            tracesLock.unlock()
            return
        }
        activeTraces.removeValue(forKey: traceId)
        tracesLock.unlock()

        trace.setValue("cancelled", forAttribute: "result")
        trace.stop()
    }

    func cancelAllTraces() {
        tracesLock.lock()
        let traces = Array(activeTraces.values)
        activeTraces.removeAll()
        tracesLock.unlock()

        for trace in traces {
            trace.setValue("app_terminated", forAttribute: "result")
            trace.stop()
        }
    }
}

// MARK: - Convenience Extensions

extension PerformanceService {
    /// Quick trace for simple actions
    func quickTrace(name: String, attributes: [String: String] = [:]) {
        let trace = LocalTrace(name: name)
        for (key, value) in attributes {
            trace.setValue(value, forAttribute: key)
        }

        // Auto-complete after brief delay for immediate actions
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            trace.stop()
        }
    }
}

// MARK: - Usage Examples
/*

 // Authentication Flow
 let loginTraceId = PerformanceService.shared.startLoginTrace()
 // ... perform login
 PerformanceService.shared.completeAuthTrace(loginTraceId, success: true, method: "apple")

 // Paywall Flow
 let paywallTraceId = PerformanceService.shared.startPaywallTrace()
 // ... show paywall
 PerformanceService.shared.completePaywallTrace(paywallTraceId, converted: true, plan: "monthly")

 // Screen Performance
 PerformanceService.shared.trackScreenLoad("HomeScreen", loadTime: 0.8)

 // Quick Actions
 PerformanceService.shared.quickTrace(name: "button_tap", attributes: ["button": "add_activity"])

 */