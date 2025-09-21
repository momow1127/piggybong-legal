import Foundation

// MARK: - Trade-Off Analysis Engine
class TradeOffAnalysisEngine {
    static let shared = TradeOffAnalysisEngine()
    
    private init() {}
    
    // MARK: - Trade-off Analysis
    func analyzeTradeOffs(budget: Double, priorities: [FanPriority]) -> [TradeOffOption] {
        // Sample trade-off analysis
        return [
            TradeOffOption(
                title: "Skip Coffee for Concert",
                description: "Reduce daily coffee spending to save for concert tickets",
                impactDescription: "Save $100/month by making coffee at home",
                tradeOffType: .reduction,
                potentialSavings: 100.0,
                difficulty: .easy,
                timeToGoal: 30 // days
            ),
            TradeOffOption(
                title: "Choose General Admission",
                description: "Select general admission instead of VIP tickets",
                impactDescription: "Save $200 while still attending the concert",
                tradeOffType: .substitution,
                potentialSavings: 200.0,
                difficulty: .medium,
                timeToGoal: 0
            )
        ]
    }
    
    func calculateImpact(_ option: TradeOffOption) -> TradeOffImpact {
        return TradeOffImpact(
            monthlySavings: option.potentialSavings,
            timeToReachGoal: option.timeToGoal,
            satisfactionScore: calculateSatisfaction(for: option),
            feasibilityScore: calculateFeasibility(for: option)
        )
    }
    
    private func calculateSatisfaction(for option: TradeOffOption) -> Double {
        switch option.difficulty {
        case .easy: return 0.9
        case .medium: return 0.7
        case .hard: return 0.5
        }
    }
    
    private func calculateFeasibility(for option: TradeOffOption) -> Double {
        switch option.tradeOffType {
        case .reduction: return 0.8
        case .substitution: return 0.9
        case .elimination: return 0.6
        case .delay: return 0.7
        }
    }
}

// MARK: - Trade-off Models
struct TradeOffOption: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let impactDescription: String
    let tradeOffType: TradeOffType
    let potentialSavings: Double
    let difficulty: Difficulty
    let timeToGoal: Int // days
    
    enum TradeOffType {
        case reduction, substitution, elimination, delay
    }
    
    enum Difficulty {
        case easy, medium, hard
    }
}

struct TradeOffImpact {
    let monthlySavings: Double
    let timeToReachGoal: Int
    let satisfactionScore: Double // 0.0 - 1.0
    let feasibilityScore: Double // 0.0 - 1.0
}