import Foundation
import SwiftUI

// MARK: - Subscription Service
@MainActor
class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    @Published var isVIP: Bool = false
    @Published var subscriptionStatus: SubscriptionStatus = .free
    
    // VIP Limits
    struct Limits {
        static let freeGoals = 1
        static let vipGoals = 3
        static let freeNewsItems = 3 // 1 hero + 2-3 headlines
        static let vipNewsItems = 50 // Unlimited (practical limit)
    }
    
    private init() {}
    
    // MARK: - Subscription Status
    enum SubscriptionStatus {
        case free
        case vip
        case trial
        
        var displayName: String {
            switch self {
            case .free: return "Free"
            case .vip: return "VIP"
            case .trial: return "VIP Trial"
            }
        }
        
        var isVIPTier: Bool {
            return self == .vip || self == .trial
        }
    }
    
    // MARK: - Feature Checks
    func canAddGoal(currentGoalCount: Int) -> Bool {
        let limit = isVIP ? Limits.vipGoals : Limits.freeGoals
        return currentGoalCount < limit
    }
    
    func getGoalLimit() -> Int {
        return isVIP ? Limits.vipGoals : Limits.freeGoals
    }
    
    func canAccessFullNews() -> Bool {
        return isVIP
    }
    
    func getNewsLimit() -> Int {
        return isVIP ? Limits.vipNewsItems : Limits.freeNewsItems
    }
    
    func canAccessAdvancedInsights() -> Bool {
        return isVIP
    }
    
    func canCustomizeNotifications() -> Bool {
        return isVIP
    }
    
    // MARK: - Update Subscription Status
    func updateSubscriptionStatus(from revenueCat: RevenueCatManager) {
        // Sync with RevenueCat - include both subscription AND promo code status
        self.isVIP = revenueCat.isSubscriptionActive || revenueCat.hasValidPromoCode
        
        // Check if this is a trial by examining customer info
        let isTrialActive = revenueCat.customerInfo?.entitlements[RevenueCatManager.premiumEntitlementID]?.periodType == .trial
        
        if isTrialActive {
            self.subscriptionStatus = .trial
        } else if self.isVIP {
            self.subscriptionStatus = .vip
        } else {
            self.subscriptionStatus = .free
        }
    }
    
    // MARK: - VIP Upgrade Prompts
    func getUpgradeMessage(for feature: VIPFeature) -> String {
        switch feature {
        case .multipleGoals:
            return "Track multiple goals simultaneously with VIP"
        case .fullNews:
            return "Get unlimited updates from your artists with VIP"
        case .advancedInsights:
            return "Unlock spending insights and predictions with VIP"
        case .customNotifications:
            return "Customize notifications for each artist with VIP"
        }
    }
    
    func getTrialMessage(for feature: VIPFeature) -> String {
        switch feature {
        case .multipleGoals:
            return "Want to track another goal? Try VIP free for 7 days"
        case .fullNews:
            return "See all updates from your artists — try VIP free for 7 days"
        case .advancedInsights:
            return "Get smart spending insights — try VIP free for 7 days"
        case .customNotifications:
            return "Customize your notifications — try VIP free for 7 days"
        }
    }
}

// MARK: - VIP Features
enum VIPFeature {
    case multipleGoals
    case fullNews
    case advancedInsights
    case customNotifications
}

// MARK: - VIP Upgrade Card Component
struct VIPUpgradeCard: View {
    let feature: VIPFeature
    let action: () -> Void
    @EnvironmentObject private var subscriptionService: SubscriptionService
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.purple)
                            .font(.caption)
                        
                        Text("VIP")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.purple)
                    }
                    
                    Text(subscriptionService.getTrialMessage(for: feature))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            
            Button(action: action) {
                Text("Try 7 Days Free")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

// MARK: - Plan Badge Component
struct PlanBadge: View {
    @EnvironmentObject private var subscriptionService: SubscriptionService
    
    var body: some View {
        HStack(spacing: 4) {
            if subscriptionService.isVIP {
                Image(systemName: "crown.fill")
                    .foregroundColor(.purple)
                    .font(.caption2)
            }
            
            Text(subscriptionService.subscriptionStatus.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(subscriptionService.isVIP ? .purple : .secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            subscriptionService.isVIP 
                ? Color.purple.opacity(0.1)
                : Color.gray.opacity(0.1)
        )
        .cornerRadius(12)
    }
}

// MARK: - Feature Lock Overlay
struct FeatureLockOverlay: View {
    let isLocked: Bool
    
    var body: some View {
        Group {
            if isLocked {
                Color.black.opacity(0.1)
                    .overlay(
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                            .font(.title2)
                    )
            }
        }
    }
}