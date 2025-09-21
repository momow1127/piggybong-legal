import Foundation

// MARK: - Opportunity Detection Service
class OpportunityDetectionService {
    static let shared = OpportunityDetectionService()
    
    private init() {}
    
    // MARK: - Opportunity Detection
    func detectOpportunities() -> [Opportunity] {
        // Sample opportunities
        return [
            Opportunity(
                title: "Concert Ticket Price Drop",
                description: "Tickets for your favorite artist dropped by 20%",
                type: .priceAlert,
                priority: .high,
                potentialSavings: 50.0,
                expiresAt: Date().addingTimeInterval(24 * 60 * 60)
            ),
            Opportunity(
                title: "Early Bird Discount",
                description: "Get 15% off merchandise with early purchase",
                type: .discount,
                priority: .medium,
                potentialSavings: 30.0,
                expiresAt: Date().addingTimeInterval(7 * 24 * 60 * 60)
            )
        ]
    }
    
    func analyzeSpendingPatterns() -> [SpendingInsight] {
        // Sample insights
        return [
            SpendingInsight(
                title: "Peak Spending Pattern",
                description: "You tend to spend more on weekends",
                category: "Timing",
                confidence: 0.85
            )
        ]
    }
    
    // Add missing method that might be called by other services
    func checkForOpportunities() {
        // Stub implementation
        print("Checking for opportunities...")
    }
}

// MARK: - Opportunity Models
struct Opportunity: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let type: OpportunityType
    let priority: OpportunityPriority
    let potentialSavings: Double
    let expiresAt: Date
    
    enum OpportunityType {
        case priceAlert, discount, bundleDeal, earlyBird
    }
    
    enum OpportunityPriority {
        case high, medium, low
    }
}

struct SpendingInsight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: String
    let confidence: Double
}