import Foundation
import SwiftUI

// MARK: - Purchase Decision Models

enum PurchaseDecision: String, CaseIterable {
    case buyNow = "Buy Now!"
    case saveForLater = "Save for Later"
    case skipThis = "Skip This"
    
    // Legacy aliases for backward compatibility
    static let buyIt = buyNow
    static let waitAndSave = saveForLater
    static let skipIt = skipThis
    static let buyLater = saveForLater
}

// MARK: - VIP Tip Models (Simplified MVP)

struct VIPTip {
    let icon: String
    let message: String
    let decision: PurchaseDecision
    
    // Hardcoded tips based on decision type and price band
    static func getTip(for decision: PurchaseDecision, price: Double, remainingBudget: Double) -> VIPTip {
        let priceBand = getPriceBand(price: price)
        let daysLeft = getDaysLeftInMonth()
        
        switch decision {
        case .buyNow:
            return getBuyTip(priceBand: priceBand, daysLeft: daysLeft)
        case .saveForLater:
            return getSaveTip(price: price, remainingBudget: remainingBudget)
        case .skipThis:
            return getSkipTip()
        }
    }
    
    private static func getPriceBand(price: Double) -> PriceBand {
        if price < 40 { return .small }
        if price < 120 { return .medium }
        return .large
    }
    
    private static func getDaysLeftInMonth() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let range = calendar.range(of: .day, in: .month, for: now)!
        let currentDay = calendar.component(.day, from: now)
        return range.count - currentDay
    }
    
    private static func getBuyTip(priceBand: PriceBand, daysLeft: Int) -> VIPTip {
        let tips = [
            "You'll stay on track! Consider setting aside $5 next week 🎯",
            "Great choice! This fits your fan wallet perfectly 💜",
            "Smart timing! You've got this covered 🎉"
        ]
        return VIPTip(icon: "✨", message: tips.randomElement() ?? "Smart choice!", decision: .buyNow)
    }
    
    private static func getSaveTip(price: Double, remainingBudget: Double) -> VIPTip {
        let weeksNeeded = Int(ceil((price - remainingBudget) / 10))
        let tips = [
            "Close! Add $10/week and you'll have it in ~\(weeksNeeded) weeks 📅",
            "Almost there! Save a bit more for maximum joy 💫",
            "Perfect patience! This will feel even better when you get it 🎁"
        ]
        return VIPTip(icon: "⏳", message: tips.randomElement() ?? "Save up for this!", decision: .saveForLater)
    }
    
    private static func getSkipTip() -> VIPTip {
        let tips = [
            "Smart move! Your comeback fund stays strong 💪",
            "Discipline pays off! Keep eyes on your priority 🎯",
            "Wise choice! Your future self will thank you 💜"
        ]
        return VIPTip(icon: "🛡️", message: tips.randomElement() ?? "Focus on your priorities!", decision: .skipThis)
    }
    
    enum PriceBand {
        case small, medium, large
    }
}

// MARK: - Feature Flags

struct FeatureFlags {
    static let showVIPTips = true          // Show lightweight VIP tips
    static let advancedAI = false          // Future AI features (disabled)
    static let freeChecksLimit = 3         // Monthly limit for free users
}

// MARK: - Monthly Check Tracking

struct MonthlyCheckTracker {
    private static let checksKey = "monthly_checks_"
    private static let lastResetKey = "last_reset_month"
    
    static func getRemainingChecks() -> Int {
        resetIfNewMonth()
        let key = getCurrentMonthKey()
        let used = UserDefaults.standard.integer(forKey: key)
        return max(0, FeatureFlags.freeChecksLimit - used)
    }
    
    static func incrementCheckCount() {
        resetIfNewMonth()
        let key = getCurrentMonthKey()
        let current = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(current + 1, forKey: key)
    }
    
    static func canPerformCheck(isVIP: Bool) -> Bool {
        if isVIP { return true }
        return getRemainingChecks() > 0
    }
    
    private static func resetIfNewMonth() {
        let currentMonth = getCurrentMonthString()
        let lastReset = UserDefaults.standard.string(forKey: lastResetKey) ?? ""
        
        if currentMonth != lastReset {
            // New month, reset counter
            UserDefaults.standard.set(0, forKey: getCurrentMonthKey())
            UserDefaults.standard.set(currentMonth, forKey: lastResetKey)
        }
    }
    
    private static func getCurrentMonthKey() -> String {
        return checksKey + getCurrentMonthString()
    }
    
    private static func getCurrentMonthString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM"
        return formatter.string(from: Date())
    }
}

// MARK: - Purchase Recommendation Model
struct PurchaseRecommendation {
    let decision: PurchaseDecision
    let reasoning: String
    let emoji: String
    let color: Color
    let category: String?
    let priorityLevel: String?
    
    init(decision: PurchaseDecision, reasoning: String, emoji: String, color: Color, category: String? = nil, priorityLevel: String? = nil) {
        self.decision = decision
        self.reasoning = reasoning
        self.emoji = emoji
        self.color = color
        self.category = category
        self.priorityLevel = priorityLevel
    }
}

// MARK: - Analytics Events

struct VIPAnalytics {
    static func logTipShown(decision: PurchaseDecision, price: Double) {
        // Log to existing analytics service
        print("📊 VIP Tip Shown: \(decision.rawValue) for $\(price)")
    }
    
    static func logTeaserTapped() {
        // Log teaser interaction
        print("📊 VIP Teaser Tapped")
    }
    
    static func logDecisionSaved(outcome: String) {
        // Log final decision
        print("📊 Decision Saved: \(outcome)")
    }
}
