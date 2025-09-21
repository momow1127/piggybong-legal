import Foundation
import FirebaseAnalytics

/// Firebase Analytics service specifically for AI insights and purchase decision tracking
class AIInsightAnalyticsService {
    static let shared = AIInsightAnalyticsService()

    private init() {}

    // MARK: - AI Insight Events

    /// Track when an AI insight is successfully generated
    func logAIInsightGenerated(
        insightType: String,
        artistId: String?,
        artistName: String?,
        generationTimeMs: Int,
        fallbackUsed: Bool = false
    ) {
        var parameters: [String: Any] = [
            "insight_type": insightType,
            "generation_time_ms": generationTimeMs,
            "fallback_used": fallbackUsed
        ]

        if let artistId = artistId {
            parameters["artist_id"] = artistId
        }

        if let artistName = artistName {
            parameters["artist_name"] = artistName
        }

        Analytics.logEvent("ai_insight_generated", parameters: parameters)

        print("📊 Analytics: AI insight generated - \(insightType) for \(artistName ?? "unknown artist")")
    }

    /// Track user feedback on AI insights (thumbs up/down)
    func logAIInsightFeedback(
        insightType: String,
        artistId: String?,
        artistName: String?,
        feedback: String, // "positive" or "negative"
        responseTimeMs: Int? = nil
    ) {
        var parameters: [String: Any] = [
            "insight_type": insightType,
            "feedback": feedback
        ]

        if let artistId = artistId {
            parameters["artist_id"] = artistId
        }

        if let artistName = artistName {
            parameters["artist_name"] = artistName
        }

        if let responseTime = responseTimeMs {
            parameters["response_time_ms"] = responseTime
        }

        Analytics.logEvent("ai_insight_feedback", parameters: parameters)

        print("📊 Analytics: AI feedback - \(feedback) for \(insightType)")
    }

    /// Track when user views an AI insight
    func logAIInsightViewed(
        insightType: String,
        artistId: String?,
        artistName: String?,
        timeSpentSeconds: Int
    ) {
        var parameters: [String: Any] = [
            "insight_type": insightType,
            "time_spent_seconds": timeSpentSeconds
        ]

        if let artistId = artistId {
            parameters["artist_id"] = artistId
        }

        if let artistName = artistName {
            parameters["artist_name"] = artistName
        }

        Analytics.logEvent("ai_insight_viewed", parameters: parameters)

        print("📊 Analytics: AI insight viewed - \(insightType) for \(timeSpentSeconds)s")
    }

    // MARK: - Purchase Decision Events

    /// Track when user starts the purchase decision flow
    func logPurchaseDecisionStarted(
        artist: String,
        category: String,
        amountUsd: Double
    ) {
        let parameters: [String: Any] = [
            "artist": artist,
            "category": category,
            "amount_usd": amountUsd
        ]

        Analytics.logEvent("purchase_decision_started", parameters: parameters)

        print("📊 Analytics: Purchase decision started - \(artist) \(category) $\(amountUsd)")
    }

    /// Track when user completes the purchase decision flow
    func logPurchaseDecisionCompleted(
        artist: String,
        category: String,
        amountUsd: Double,
        aiRecommendation: String?, // "buy", "save", "reconsider"
        userDecision: String, // "purchased", "saved", "cancelled"
        followedAIAdvice: Bool
    ) {
        var parameters: [String: Any] = [
            "artist": artist,
            "category": category,
            "amount_usd": amountUsd,
            "user_decision": userDecision,
            "followed_ai_advice": followedAIAdvice
        ]

        if let recommendation = aiRecommendation {
            parameters["ai_recommendation"] = recommendation
        }

        Analytics.logEvent("purchase_decision_completed", parameters: parameters)

        print("📊 Analytics: Purchase decision completed - \(userDecision), followed AI: \(followedAIAdvice)")
    }

    // MARK: - Artist & AI Intelligence Events

    /// Track when AI insight is requested for a specific artist
    func logArtistAIInsightRequested(
        artistId: String,
        artistName: String,
        userSpendingHistory: Double,
        isPopularArtist: Bool
    ) {
        let parameters: [String: Any] = [
            "artist_id": artistId,
            "artist_name": artistName,
            "user_spending_history": userSpendingHistory,
            "is_popular_artist": isPopularArtist
        ]

        Analytics.logEvent("artist_ai_insight_requested", parameters: parameters)

        print("📊 Analytics: AI insight requested for \(artistName)")
    }

    /// Track AI recommendation accuracy
    func logAIRecommendationAccuracy(
        recommendationType: String,
        artist: String,
        predictedOutcome: String,
        actualOutcome: String,
        accuracyScore: Double
    ) {
        let parameters: [String: Any] = [
            "recommendation_type": recommendationType,
            "artist": artist,
            "predicted_outcome": predictedOutcome,
            "actual_outcome": actualOutcome,
            "accuracy_score": accuracyScore
        ]

        Analytics.logEvent("ai_recommendation_accuracy", parameters: parameters)

        print("📊 Analytics: AI accuracy - \(accuracyScore) for \(recommendationType)")
    }

    // MARK: - Enhanced Core Events (Updated from your original list)

    /// Enhanced artist added event with AI context
    func logArtistAdded(artistName: String, artistId: String, source: String = "manual") {
        let parameters: [String: Any] = [
            "artist_name": artistName,
            "artist_id": artistId,
            "source": source // "manual", "ai_recommendation", "onboarding"
        ]

        Analytics.logEvent(AnalyticsEventSelectContent, parameters: parameters)
        Analytics.logEvent("artist_added", parameters: parameters)

        print("📊 Analytics: Artist added - \(artistName) from \(source)")
    }

    /// Track when artist is removed from user's list
    func logArtistRemoved(artistName: String, artistId: String, reason: String = "manual") {
        let parameters: [String: Any] = [
            "artist_name": artistName,
            "artist_id": artistId,
            "reason": reason // "manual", "limit_reached", "subscription_downgrade"
        ]

        Analytics.logEvent("artist_removed", parameters: parameters)

        print("📊 Analytics: Artist removed - \(artistName) for \(reason)")
    }

    /// Track when user sets or changes their fandom name
    func logFandomNamed(fandomName: String, isFirstTime: Bool = false) {
        let parameters: [String: Any] = [
            "fandom_name": fandomName,
            "is_first_time": isFirstTime,
            "name_length": fandomName.count
        ]

        Analytics.logEvent("fandom_named", parameters: parameters)

        print("📊 Analytics: Fandom named - \(fandomName)")
    }

    /// Track when fan activity is deleted
    func logFanActivityDeleted(
        category: String,
        costUsd: Double,
        artist: String,
        deleteReason: String = "user_action"
    ) {
        let parameters: [String: Any] = [
            "category": category,
            "cost_usd": costUsd,
            "artist": artist,
            "delete_reason": deleteReason // "user_action", "bulk_delete", "account_cleanup"
        ]

        Analytics.logEvent("fan_activity_deleted", parameters: parameters)

        print("📊 Analytics: Fan activity deleted - \(category) $\(costUsd) for \(artist)")
    }

    /// Enhanced fan activity added with AI intelligence
    func logFanActivityAdded(
        category: String,
        costUsd: Double,
        artist: String,
        wasAIRecommended: Bool = false,
        followedAIAdvice: Bool? = nil
    ) {
        var parameters: [String: Any] = [
            "category": category,
            "cost_usd": costUsd,
            "artist": artist,
            "was_ai_recommended": wasAIRecommended
        ]

        if let followedAdvice = followedAIAdvice {
            parameters["followed_ai_advice"] = followedAdvice
        }

        Analytics.logEvent("fan_activity_added", parameters: parameters)

        print("📊 Analytics: Fan activity added - \(category) $\(costUsd) for \(artist)")
    }

    // MARK: - Subscription & Monetization Events

    /// Track when user starts a trial
    func logTrialStarted(plan: String, trialDurationDays: Int = 7) {
        let parameters: [String: Any] = [
            "plan": plan, // "monthly", "yearly", "lifetime"
            "trial_duration_days": trialDurationDays,
            "has_used_ai": true // Since trial is likely triggered by AI features
        ]

        Analytics.logEvent("trial_started", parameters: parameters)

        print("📊 Analytics: Trial started - \(plan) for \(trialDurationDays) days")
    }

    /// Track when user starts a subscription
    func logSubscriptionStarted(plan: String, price: Double, currency: String = "USD", source: String = "paywall") {
        let parameters: [String: Any] = [
            "plan": plan, // "monthly", "yearly", "lifetime"
            "price": price,
            "currency": currency,
            "source": source, // "paywall", "trial_conversion", "ai_feature_gate"
            "has_used_ai": true
        ]

        Analytics.logEvent(AnalyticsEventPurchase, parameters: parameters)
        Analytics.logEvent("subscription_started", parameters: parameters)

        print("📊 Analytics: Subscription started - \(plan) $\(price) from \(source)")
    }

    /// Track subscription cancellation
    func logSubscriptionCancelled(plan: String, reason: String?, daysSinceStart: Int) {
        var parameters: [String: Any] = [
            "plan": plan,
            "days_since_start": daysSinceStart,
            "was_trial": daysSinceStart <= 7
        ]

        if let reason = reason {
            parameters["cancellation_reason"] = reason
        }

        Analytics.logEvent("subscription_cancelled", parameters: parameters)

        print("📊 Analytics: Subscription cancelled - \(plan) after \(daysSinceStart) days")
    }

    // MARK: - User Journey Events

    /// Track onboarding completion with AI readiness
    func logOnboardingCompleted(artistsSelected: Int, budgetSet: Double, aiEnabled: Bool = true) {
        let parameters: [String: Any] = [
            "artists_selected": artistsSelected,
            "budget_set": budgetSet,
            "ai_enabled": aiEnabled
        ]

        Analytics.logEvent("onboarding_completed", parameters: parameters)

        print("📊 Analytics: Onboarding completed - \(artistsSelected) artists, $\(budgetSet) budget")
    }

    /// Track paywall interaction with AI context
    func logPaywallViewed(source: String, variant: String, hasUsedAI: Bool = false) {
        let parameters: [String: Any] = [
            "source": source,
            "variant": variant,
            "has_used_ai": hasUsedAI
        ]

        Analytics.logEvent("paywall_viewed", parameters: parameters)

        print("📊 Analytics: Paywall viewed - \(variant) from \(source)")
    }

    // MARK: - Utility Methods

    /// Set user properties for AI analytics
    func setUserAIProperties(
        totalAIInteractions: Int,
        averageFeedbackScore: Double?, // 0.0 to 1.0 (positive feedback ratio)
        preferredInsightTypes: [String]
    ) {
        Analytics.setUserProperty("\(totalAIInteractions)", forName: "ai_interactions_total")

        if let score = averageFeedbackScore {
            Analytics.setUserProperty(String(format: "%.2f", score), forName: "ai_feedback_score")
        }

        if !preferredInsightTypes.isEmpty {
            Analytics.setUserProperty(preferredInsightTypes.joined(separator: ","), forName: "preferred_insights")
        }

        print("📊 Analytics: User AI properties updated")
    }

    /// Track app session with AI usage context
    func logSessionStart(hasAIFeatures: Bool = true) {
        let parameters: [String: Any] = [
            "has_ai_features": hasAIFeatures,
            "session_start_time": Date().timeIntervalSince1970
        ]

        Analytics.logEvent(AnalyticsEventAppOpen, parameters: parameters)

        print("📊 Analytics: Session started with AI features: \(hasAIFeatures)")
    }

    // MARK: - Advanced Engagement Tracking

    /// Track time spent viewing AI insights (call when insight is dismissed)
    func logAIInsightViewingSession(
        insightType: String,
        artistName: String?,
        viewingStartTime: Date,
        userEngaged: Bool = false // Did they scroll, tap, or interact?
    ) {
        let viewingDuration = Int(Date().timeIntervalSince(viewingStartTime))

        logAIInsightViewed(
            insightType: insightType,
            artistId: nil,
            artistName: artistName,
            timeSpentSeconds: viewingDuration
        )

        // Additional engagement tracking
        var parameters: [String: Any] = [
            "insight_type": insightType,
            "viewing_duration_seconds": viewingDuration,
            "user_engaged": userEngaged,
            "engagement_quality": viewingDuration > 10 ? "high" : viewingDuration > 3 ? "medium" : "low"
        ]

        if let artistName = artistName {
            parameters["artist_name"] = artistName
        }

        Analytics.logEvent("ai_insight_engagement", parameters: parameters)

        print("📊 Analytics: AI insight viewing session - \(viewingDuration)s, engaged: \(userEngaged)")
    }

    /// Track complete purchase decision journey
    func logPurchaseDecisionJourney(
        startTime: Date,
        artist: String,
        category: String,
        amountUsd: Double,
        aiRecommendation: String?,
        finalDecision: String, // "purchased", "saved_for_later", "cancelled", "reconsidering"
        decisionFactors: [String] = [] // ["price", "ai_advice", "budget", "priority"]
    ) {
        let journeyDuration = Int(Date().timeIntervalSince(startTime))
        let followedAI = aiRecommendation != nil &&
                        ((aiRecommendation == "buy" && finalDecision == "purchased") ||
                         (aiRecommendation == "save" && finalDecision == "saved_for_later") ||
                         (aiRecommendation == "reconsider" && finalDecision == "reconsidering"))

        // Log the completion event
        logPurchaseDecisionCompleted(
            artist: artist,
            category: category,
            amountUsd: amountUsd,
            aiRecommendation: aiRecommendation,
            userDecision: finalDecision,
            followedAIAdvice: followedAI
        )

        // Log additional journey analytics
        var parameters: [String: Any] = [
            "artist": artist,
            "category": category,
            "amount_usd": amountUsd,
            "journey_duration_seconds": journeyDuration,
            "final_decision": finalDecision,
            "followed_ai_advice": followedAI,
            "decision_factors": decisionFactors.joined(separator: ","),
            "had_ai_recommendation": aiRecommendation != nil
        ]

        if let recommendation = aiRecommendation {
            parameters["ai_recommendation"] = recommendation
        }

        Analytics.logEvent("purchase_decision_journey", parameters: parameters)

        print("📊 Analytics: Purchase decision journey - \(finalDecision) in \(journeyDuration)s, followed AI: \(followedAI)")
    }
}

// MARK: - Convenience Extensions

extension AIInsightAnalyticsService {
    /// Quick method to track AI insight feedback from PurchaseDecisionCalculatorView
    func trackInsightFeedback(
        feedback: String, // "positive" or "negative"
        artistName: String?,
        insightType: String = "purchase_decision"
    ) {
        logAIInsightFeedback(
            insightType: insightType,
            artistId: nil, // Can be enhanced later if artist IDs are available
            artistName: artistName,
            feedback: feedback
        )
    }

    /// Quick method to track when AI insight generation starts
    func trackInsightGenerationStart(for artistName: String?) {
        // This will be completed when generation finishes
        print("📊 Analytics: Starting AI insight generation for \(artistName ?? "unknown artist")")
    }

    /// Start tracking a purchase decision session - returns start time for later completion
    func startPurchaseDecisionTracking(artist: String, category: String, amountUsd: Double) -> Date {
        let startTime = Date()

        logPurchaseDecisionStarted(
            artist: artist,
            category: category,
            amountUsd: amountUsd
        )

        return startTime
    }

    /// Start tracking AI insight viewing session - returns start time for later completion
    func startAIInsightViewing(insightType: String, artistName: String?) -> Date {
        let startTime = Date()
        print("📊 Analytics: Started viewing AI insight - \(insightType)")
        return startTime
    }

    /// Log performance metrics from PerformanceService
    func logPerformanceMetric(
        traceName: String,
        durationMs: Int,
        attributes: [String: String]
    ) {
        var parameters: [String: Any] = [
            "trace_name": traceName,
            "duration_ms": durationMs,
            "performance_category": getPerformanceCategory(traceName)
        ]

        // Add custom attributes
        for (key, value) in attributes {
            parameters["perf_\(key)"] = value
        }

        Analytics.logEvent("app_performance_metric", parameters: parameters)

        print("📊 Analytics: Performance metric - \(traceName) took \(durationMs)ms")
    }

    private func getPerformanceCategory(_ traceName: String) -> String {
        switch traceName {
        case let name where name.contains("login") || name.contains("signup") || name.contains("auth"):
            return "authentication"
        case let name where name.contains("onboarding"):
            return "onboarding"
        case let name where name.contains("paywall"):
            return "monetization"
        case let name where name.contains("artist"):
            return "user_preference"
        case let name where name.contains("activity"):
            return "user_engagement"
        case let name where name.contains("screen"):
            return "ui_performance"
        case let name where name.contains("api") || name.contains("network"):
            return "network"
        default:
            return "general"
        }
    }
}

// MARK: - AI Insight Types Enum for Consistency

enum AIInsightType: String, CaseIterable {
    case spendingPattern = "spending_pattern"
    case eventPreference = "event_preference"
    case artistAffinity = "artist_affinity"
    case growthOpportunity = "growth_opportunity"
    case purchaseDecision = "purchase_decision"
    case budgetRecommendation = "budget_recommendation"

    var displayName: String {
        switch self {
        case .spendingPattern: return "Spending Pattern"
        case .eventPreference: return "Event Preference"
        case .artistAffinity: return "Artist Affinity"
        case .growthOpportunity: return "Growth Opportunity"
        case .purchaseDecision: return "Purchase Decision"
        case .budgetRecommendation: return "Budget Recommendation"
        }
    }
}