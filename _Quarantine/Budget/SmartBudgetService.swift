import Foundation
import SwiftUI

// MARK: - Smart Fan Pick Service
@MainActor
class SmartBudgetPickService: ObservableObject {
    static let shared = SmartBudgetPickService()
    
    @Published var recommendations: [SmartPickRecommendation] = []
    @Published var isAnalyzing = false
    @Published var lastAnalysis: Date?
    
    private let supabaseService = SupabaseService.shared
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Smart Fan Pick Engine
    func generateRecommendations(for user: DashboardUser, artists: [FanArtist], goals: [FanGoal], purchases: [FanPurchase]) async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        // Validate input data to prevent crashes
        guard !artists.isEmpty else {
            print("⚠️ No artists selected, skipping recommendations")
            return
        }
        
        var newRecommendations: [SmartPickRecommendation] = []
        
        // 1. Priority Alignment Analysis
        let priorityPatterns = analyzePriorityPatterns(purchases: purchases, goals: goals)
        newRecommendations.append(contentsOf: generatePriorityRecommendations(patterns: priorityPatterns))
        
        // 2. Artist Priority Optimization
        let artistAlignment = analyzeArtistPriorityAlignment(artists: artists, purchases: purchases)
        newRecommendations.append(contentsOf: generateArtistAlignmentRecommendations(analysis: artistAlignment))
        
        // 3. Goal Priority Matching
        let goalMatching = analyzeGoalPriorityAlignment(goals: goals, currentDecisions: purchases)
        newRecommendations.append(contentsOf: generateGoalAlignmentRecommendations(analysis: goalMatching))
        
        // 4. Seasonal and Comeback Priority Alerts
        let seasonalPriorities = analyzeSeasonalPriorityTrends(purchases: purchases)
        newRecommendations.append(contentsOf: generateSeasonalPriorityRecommendations(trends: seasonalPriorities))
        
        // 5. Smart Priority Decision Suggestions
        let smartPicks = analyzeSmartPickOpportunities(artists: artists, goals: goals)
        newRecommendations.append(contentsOf: smartPicks)
        
        // Sort by confidence score and priority
        self.recommendations = newRecommendations
            .sorted { $0.confidenceScore > $1.confidenceScore }
            .prefix(5)
            .map { $0 }
        
        self.lastAnalysis = Date()
        
        // Cache recommendations
        await cacheRecommendations()
        
        print("✅ Generated \(self.recommendations.count) smart fan pick recommendations")
    }
    
    // MARK: - Priority Pattern Analysis
    private func analyzePriorityPatterns(purchases: [FanPurchase], goals: [FanGoal]) -> PriorityPatternAnalysis {
        let last30Days = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentPurchases = purchases.filter { $0.purchaseDate >= last30Days }
        
        // Categorize priority-aligned decisions
        let categoryPriorities = Dictionary(grouping: recentPurchases) { $0.category }
            .mapValues { purchases in
                // For now, score based on goal alignment - higher score = better priority alignment
                let alignedGoals = goals.filter { goal in
                    purchases.contains { $0.category.rawValue == goal.category.rawValue }
                }
                return alignedGoals.isEmpty ? 1.0 : Double(alignedGoals.count) / Double(purchases.count) * 3.0
            }
        
        // Artist priority alignment
        let artistPriorityAlignment = Dictionary(grouping: recentPurchases) { $0.artistName }
            .mapValues { purchases in
                // Score based on whether user has goals for this artist
                let hasGoalsForArtist = goals.contains { goal in
                    purchases.contains { $0.artistName == goal.artistName }
                }
                return hasGoalsForArtist ? 3.0 : 1.0 // High alignment if user has goals for this artist
            }
        
        // Day of week smart decision patterns
        let dayOfWeekDecisions = Dictionary(grouping: recentPurchases) {
            Calendar.current.component(.weekday, from: $0.purchaseDate)
        }.mapValues { $0.count } // Count of decisions made per day
        
        // Average decision confidence (based on goal alignment)
        let averageDecisionConfidence = recentPurchases.isEmpty ? 0 : recentPurchases.map { purchase in
            // Score higher if purchase aligns with user goals
            goals.contains { $0.category.rawValue == purchase.category.rawValue || $0.artistName == purchase.artistName } ? 1.0 : 0.3
        }.reduce(0.0, +) / Double(recentPurchases.count)
        
        // Comeback-related priority alignment
        let comebackDecisions = recentPurchases.filter { $0.isComebackRelated }
        let comebackPriorityAlignment = comebackDecisions.isEmpty ? 0 : comebackDecisions.map { purchase in
            goals.contains { $0.category.rawValue == purchase.category.rawValue || $0.artistName == purchase.artistName } ? 1.0 : 0.5
        }.reduce(0.0, +) / Double(comebackDecisions.count)
        
        return PriorityPatternAnalysis(
            categoryPriorityAlignment: categoryPriorities,
            artistPriorityAlignment: artistPriorityAlignment,
            dayOfWeekDecisionPattern: dayOfWeekDecisions,
            averageDecisionConfidence: averageDecisionConfidence,
            comebackPriorityAlignment: comebackPriorityAlignment,
            totalRecentDecisions: recentPurchases.count
        )
    }
    
    private func generatePriorityRecommendations(patterns: PriorityPatternAnalysis) -> [SmartPickRecommendation] {
        var recommendations: [SmartPickRecommendation] = []
        
        // High-priority category recommendation
        if let topCategory = patterns.categoryPriorityAlignment.max(by: { $0.value < $1.value }) {
            if topCategory.value > 2.5 { // High priority alignment score
                recommendations.append(SmartPickRecommendation(
                    type: .priorityAlignment,
                    title: "Perfect \(topCategory.key.displayName) Alignment",
                    description: "Your \(topCategory.key.displayName) decisions match your priorities perfectly!",
                    suggestedAction: "Keep making smart \(topCategory.key.displayName) choices",
                    confidenceScore: 0.9,
                    priorityAlignment: topCategory.value / 3.0,
                    category: topCategory.key
                ))
            } else if topCategory.value < 1.5 { // Low priority alignment
                recommendations.append(SmartPickRecommendation(
                    type: .priorityRebalance,
                    title: "Realign \(topCategory.key.displayName) Decisions",
                    description: "Your \(topCategory.key.displayName) choices could better match your stated priorities.",
                    suggestedAction: "Consider your priorities before next \(topCategory.key.displayName) decision",
                    confidenceScore: 0.8,
                    priorityAlignment: topCategory.value / 3.0,
                    category: topCategory.key
                ))
            }
        }
        
        // Weekend decision pattern
        let weekendDecisions = (patterns.dayOfWeekDecisionPattern[1] ?? 0) + (patterns.dayOfWeekDecisionPattern[7] ?? 0) // Sunday + Saturday
        let weekdayDecisions = patterns.totalRecentDecisions - weekendDecisions
        
        if weekendDecisions > weekdayDecisions * 2 {
            recommendations.append(SmartPickRecommendation(
                type: .smartTiming,
                title: "Weekend Decision Pattern",
                description: "You make most fan decisions on weekends. This can be great for thoughtful choices!",
                suggestedAction: "Use weekend time to research and make smart priority-aligned decisions",
                confidenceScore: 0.7,
                priorityAlignment: 0.6
            ))
        } else if patterns.averageDecisionConfidence > 0.8 {
            recommendations.append(SmartPickRecommendation(
                type: .priorityAlignment,
                title: "Excellent Decision Making",
                description: "Your recent fan decisions align well with your priorities!",
                suggestedAction: "Keep up the smart decision-making pattern",
                confidenceScore: 0.9,
                priorityAlignment: patterns.averageDecisionConfidence
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Artist Priority Analysis
    private func analyzeArtistPriorityAlignment(artists: [FanArtist], purchases: [FanPurchase]) -> PriorityAlignment {
        // Analyze how well user's decisions align with their stated artist priorities
        var alignmentScores: [String: Double] = [:]
        
        for artist in artists {
            let artistPurchases = purchases.filter { $0.artistName == artist.name }
            let alignmentScore = artistPurchases.isEmpty ? 0.5 : min(3.0, Double(artistPurchases.count) * 0.3 + 1.0)
            alignmentScores[artist.name] = alignmentScore
        }
        
        return PriorityAlignment(artistAlignmentScores: alignmentScores)
    }
    
    private func generateArtistAlignmentRecommendations(analysis: PriorityAlignment) -> [SmartPickRecommendation] {
        return analysis.artistAlignmentScores.compactMap { (artistName, score) in
            if score > 2.5 {
                return SmartPickRecommendation(
                    type: .artistFocus,
                    title: "Great \(artistName) Focus",
                    description: "Your \(artistName) decisions show strong priority alignment!",
                    suggestedAction: "Continue prioritizing \(artistName) content that matters to you",
                    confidenceScore: 0.8,
                    priorityAlignment: score / 3.0,
                    artistName: artistName
                )
            } else if score < 1.0 {
                return SmartPickRecommendation(
                    type: .priorityRebalance,
                    title: "Consider \(artistName) Priorities",
                    description: "You might be missing out on \(artistName) content that matches your interests.",
                    suggestedAction: "Check for new \(artistName) releases or content",
                    confidenceScore: 0.7,
                    priorityAlignment: score / 3.0,
                    artistName: artistName
                )
            }
            return nil
        }
    }
    
    // Legacy method for backward compatibility
    private func analyzeArtistPrioritySpending(artists: [FanArtist], purchases: [FanPurchase]) -> PrioritySpendingAnalysis {
        var artistPriorityMismatch: [(artist: FanArtist, expectedRatio: Double, actualRatio: Double)] = []
        
        let totalSpending = purchases.reduce(0) { $0 + $1.amount }
        let totalAllocation = artists.reduce(0) { $0 + $1.monthlyAllocation }
        
        for artist in artists {
            let artistSpending = purchases.filter { $0.artistName == artist.name }.reduce(0) { $0 + $1.amount }
            let actualRatio = totalSpending > 0 ? artistSpending / totalSpending : 0
            let expectedRatio = totalAllocation > 0 ? artist.monthlyAllocation / totalAllocation : 0
            
            if abs(actualRatio - expectedRatio) > 0.1 {
                artistPriorityMismatch.append((artist, expectedRatio, actualRatio))
            }
        }
        
        return PrioritySpendingAnalysis(priorityMismatches: artistPriorityMismatch)
    }
    
    // Add placeholder implementations for new methods
    private func analyzeGoalPriorityAlignment(goals: [FanGoal], currentDecisions: [FanPurchase]) -> GoalAlignment {
        let alignmentScore = goals.isEmpty ? 0.5 : min(1.0, Double(currentDecisions.count) / Double(goals.count))
        return GoalAlignment(overallAlignment: alignmentScore)
    }
    
    private func generateGoalAlignmentRecommendations(analysis: GoalAlignment) -> [SmartPickRecommendation] {
        if analysis.overallAlignment > 0.8 {
            return [SmartPickRecommendation(
                type: .goalAlignment,
                title: "Excellent Goal Alignment",
                description: "Your decisions align well with your fan goals!",
                suggestedAction: "Keep making priority-focused choices",
                confidenceScore: 0.9,
                priorityAlignment: analysis.overallAlignment
            )]
        }
        return []
    }
    
    private func analyzeSeasonalPriorityTrends(purchases: [FanPurchase]) -> SeasonalTrends {
        return SeasonalTrends(hasSeasonalPattern: !purchases.isEmpty)
    }
    
    private func generateSeasonalPriorityRecommendations(trends: SeasonalTrends) -> [SmartPickRecommendation] {
        return trends.hasSeasonalPattern ? [SmartPickRecommendation(
            type: .seasonalSmart,
            title: "Smart Seasonal Timing",
            description: "You make thoughtful decisions during comeback seasons!",
            suggestedAction: "Continue timing your decisions with major releases",
            confidenceScore: 0.7,
            priorityAlignment: 0.7
        )] : []
    }
    
    private func analyzeSmartPickOpportunities(artists: [FanArtist], goals: [FanGoal]) -> [SmartPickRecommendation] {
        return [SmartPickRecommendation(
            type: .priorityAlignment,
            title: "Smart Fan Decision Helper",
            description: "Your priority-focused approach is working well!",
            suggestedAction: "Continue using your priorities to guide fan decisions",
            confidenceScore: 0.8,
            priorityAlignment: 0.8
        )]
    }
    
    // Legacy method for backward compatibility
    private func generatePriorityRecommendations(analysis: PrioritySpendingAnalysis) -> [BudgetRecommendation] {
        return analysis.priorityMismatches.compactMap { mismatch in
            let artist = mismatch.artist
            let difference = mismatch.actualRatio - mismatch.expectedRatio
            
            if difference < -0.15 { // Underspending on high priority
                return BudgetRecommendation(
                    type: .artistReallocation,
                    title: "Increase \(artist.name) Budget",
                    description: "You're underspending on your #\(artist.priorityRank) bias by \(Int(abs(difference) * 100))%",
                    suggestedAction: "Consider increasing monthly allocation by $\(Int(artist.monthlyAllocation * 0.2))",
                    confidenceScore: 0.85,
                    estimatedImpact: "Better alignment with your priorities",
                    artistName: artist.name
                )
            } else if difference > 0.15 { // Overspending
                return BudgetRecommendation(
                    type: .artistReallocation,
                    title: "Optimize \(artist.name) Spending",
                    description: "You're overspending on \(artist.name) compared to their priority rank",
                    suggestedAction: "Consider reducing allocation by $\(Int(artist.monthlyAllocation * 0.15))",
                    confidenceScore: 0.8,
                    estimatedSavings: artist.monthlyAllocation * 0.15,
                    artistName: artist.name
                )
            }
            return nil
        }
    }
    
    // MARK: - Goal Achievement Analysis
    private func analyzeGoalAchievability(goals: [FanGoal], currentSpending: Double, budget: Double) -> [GoalPrediction] {
        return goals.map { goal in
            let monthsRemaining = Calendar.current.dateComponents([.month], from: Date(), to: goal.deadline).month ?? 1
            let monthlyRequired = goal.remainingAmount / max(Double(monthsRemaining), 1)
            let availableBudget = budget - currentSpending
            
            let achievabilityScore = availableBudget > 0 ? min(availableBudget / monthlyRequired, 1.0) : 0
            
            return GoalPrediction(
                goal: goal,
                achievabilityScore: achievabilityScore,
                monthlyRequirement: monthlyRequired,
                riskLevel: achievabilityScore < 0.7 ? .high : achievabilityScore < 0.9 ? .medium : .low
            )
        }
    }
    
    private func generateGoalRecommendations(predictions: [GoalPrediction]) -> [BudgetRecommendation] {
        return predictions.compactMap { prediction in
            let goal = prediction.goal
            
            switch prediction.riskLevel {
            case .high:
                return BudgetRecommendation(
                    type: .goalOptimization,
                    title: "\(goal.name) at Risk",
                    description: "Your current spending pace makes this goal challenging to achieve",
                    suggestedAction: "Save $\(Int(prediction.monthlyRequirement)) monthly or extend deadline",
                    confidenceScore: 0.9,
                    goalId: goal.id
                )
            case .medium:
                return BudgetRecommendation(
                    type: .goalOptimization,
                    title: "Optimize \(goal.name) Strategy",
                    description: "Small adjustments can help you achieve this goal more comfortably",
                    suggestedAction: "Increase monthly savings by $\(Int(prediction.monthlyRequirement * 0.2))",
                    confidenceScore: 0.75,
                    goalId: goal.id
                )
            case .low:
                return nil // Goal is on track
            }
        }
    }
    
    // MARK: - Seasonal Trend Analysis
    private func analyzeSeasonalTrends(purchases: [FanPurchase]) -> SeasonalTrendAnalysis {
        let monthlySpending = Dictionary(grouping: purchases) {
            Calendar.current.component(.month, from: $0.purchaseDate)
        }.mapValues { $0.reduce(0) { $0 + $1.amount } }
        
        // Identify comeback seasons (higher spending months)
        let averageMonthlySpending = monthlySpending.values.reduce(0, +) / Double(monthlySpending.count)
        let highSpendingMonths = monthlySpending.filter { $0.value > averageMonthlySpending * 1.3 }
        
        return SeasonalTrendAnalysis(
            monthlySpending: monthlySpending,
            averageSpending: averageMonthlySpending,
            highSpendingSeasons: Array(highSpendingMonths.keys)
        )
    }
    
    private func generateSeasonalRecommendations(trends: SeasonalTrendAnalysis) -> [BudgetRecommendation] {
        var recommendations: [BudgetRecommendation] = []
        
        let currentMonth = Calendar.current.component(.month, from: Date())
        if trends.highSpendingSeasons.contains(currentMonth) {
            recommendations.append(BudgetRecommendation(
                type: .seasonalOptimization,
                title: "High Spending Season Alert",
                description: "This is typically a high spending month for you (\(Int(trends.monthlySpending[currentMonth] ?? 0))% above average)",
                suggestedAction: "Consider setting aside extra budget or prioritizing essential purchases",
                confidenceScore: 0.8
            ))
        }
        
        // Predict next high spending month
        let nextMonth = (currentMonth % 12) + 1
        if trends.highSpendingSeasons.contains(nextMonth) {
            recommendations.append(BudgetRecommendation(
                type: .seasonalOptimization,
                title: "Prepare for Next Month",
                description: "Next month is typically a high spending period. Start saving now!",
                suggestedAction: "Save an extra $\(Int(trends.averageSpending * 0.3)) this month",
                confidenceScore: 0.7
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Budget Efficiency Analysis
    private func analyzeBudgetEfficiency(artists: [FanArtist], goals: [FanGoal]) -> [BudgetRecommendation] {
        var recommendations: [BudgetRecommendation] = []
        
        // Find underutilized artists
        let underutilizedArtists = artists.filter { $0.spentPercentage < 30 && $0.monthlyAllocation > 20 }
        for artist in underutilizedArtists {
            recommendations.append(BudgetRecommendation(
                type: .budgetReallocation,
                title: "Reallocate \(artist.name) Budget",
                description: "Only using \(Int(artist.spentPercentage))% of allocation",
                suggestedAction: "Move $\(Int(artist.monthlyAllocation * 0.3)) to other goals",
                confidenceScore: 0.7,
                estimatedSavings: artist.monthlyAllocation * 0.3,
                artistName: artist.name
            ))
        }
        
        // Find goals that need more funding
        let urgentGoals = goals.filter { goal in
            let daysUntil = goal.daysUntilEvent ?? Int.max
            return daysUntil < 60 && goal.progressPercentage < 80
        }
        
        for goal in urgentGoals {
            recommendations.append(BudgetRecommendation(
                type: .goalOptimization,
                title: "Urgent: \(goal.name)",
                description: "Only \(Int(goal.progressPercentage))% complete with \(goal.daysUntilEvent ?? 0) days left",
                suggestedAction: "Increase weekly savings by $\(Int(goal.remainingAmount / 4))",
                confidenceScore: 0.9,
                goalId: goal.id
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Caching
    private func cacheRecommendations() async {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(recommendations) {
            userDefaults.set(data, forKey: "cached_recommendations")
        }
    }
    
    func loadCachedRecommendations() {
        let decoder = JSONDecoder()
        if let data = userDefaults.data(forKey: "cached_recommendations"),
           let _ = try? decoder.decode([BudgetRecommendation].self, from: data) {
            // Convert cached BudgetRecommendation to SmartPickRecommendation if needed
            self.recommendations = [] // For now, start fresh with priority-based recommendations
        }
    }
}

// MARK: - Supporting Models
struct BudgetRecommendation: Identifiable, Codable {
    let id: UUID
    let type: BudgetRecommendationType
    let title: String
    let description: String
    let suggestedAction: String
    let confidenceScore: Double
    let estimatedSavings: Double?
    let estimatedImpact: String?
    let artistName: String?
    let goalId: UUID?
    let category: FanCategory?
    
    init(type: BudgetRecommendationType, title: String, description: String, suggestedAction: String, confidenceScore: Double, estimatedSavings: Double? = nil, estimatedImpact: String? = nil, artistName: String? = nil, goalId: UUID? = nil, category: FanCategory? = nil) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.description = description
        self.suggestedAction = suggestedAction
        self.confidenceScore = confidenceScore
        self.estimatedSavings = estimatedSavings
        self.estimatedImpact = estimatedImpact
        self.artistName = artistName
        self.goalId = goalId
        self.category = category
    }
    
    var confidenceText: String {
        switch confidenceScore {
        case 0.9...1.0: return "Very Confident"
        case 0.8..<0.9: return "Confident"
        case 0.7..<0.8: return "Moderately Confident"
        default: return "Low Confidence"
        }
    }
    
    var typeIcon: String {
        switch type {
        case .categoryOptimization: return "chart.pie.fill"
        case .artistReallocation: return "person.2.circle.fill"
        case .goalOptimization: return "target"
        case .seasonalOptimization: return "calendar.badge.clock"
        case .budgetReallocation: return "arrow.triangle.swap"
        case .behaviorOptimization: return "brain.head.profile"
        }
    }
    
    var typeColor: Color {
        switch type {
        case .categoryOptimization: return .blue
        case .artistReallocation: return .purple
        case .goalOptimization: return .green
        case .seasonalOptimization: return .orange
        case .budgetReallocation: return .red
        case .behaviorOptimization: return .pink
        }
    }
}

// Legacy - keeping for backward compatibility
enum BudgetRecommendationType: String, Codable {
    case categoryOptimization = "category_optimization"
    case artistReallocation = "artist_reallocation"
    case goalOptimization = "goal_optimization"
    case seasonalOptimization = "seasonal_optimization"
    case budgetReallocation = "budget_reallocation"
    case behaviorOptimization = "behavior_optimization"
}

// MARK: - Smart Fan Pick Data Structures

struct SmartPickRecommendation: Identifiable, Codable {
    let id: UUID
    let type: SmartPickType
    let title: String
    let description: String
    let suggestedAction: String
    let confidenceScore: Double
    let priorityAlignment: Double // How well this aligns with user priorities
    let artistName: String?
    let category: FanCategory?
    let emoji: String
    
    init(type: SmartPickType, title: String, description: String, suggestedAction: String, 
         confidenceScore: Double, priorityAlignment: Double = 0.8, artistName: String? = nil, 
         category: FanCategory? = nil) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.description = description
        self.suggestedAction = suggestedAction
        self.confidenceScore = confidenceScore
        self.priorityAlignment = priorityAlignment
        self.artistName = artistName
        self.category = category
        self.emoji = type.emoji
    }
    
    var typeColor: Color {
        switch type {
        case .priorityAlignment: return .green
        case .artistFocus: return .purple
        case .smartTiming: return .blue
        case .priorityRebalance: return .orange
        case .goalAlignment: return .pink
        case .seasonalSmart: return .cyan
        }
    }
}

enum SmartPickType: String, Codable {
    case priorityAlignment = "priority_alignment"
    case artistFocus = "artist_focus"
    case smartTiming = "smart_timing"
    case priorityRebalance = "priority_rebalance"
    case goalAlignment = "goal_alignment"
    case seasonalSmart = "seasonal_smart"
    
    var emoji: String {
        switch self {
        case .priorityAlignment: return "🎯"
        case .artistFocus: return "⭐"
        case .smartTiming: return "⏰"
        case .priorityRebalance: return "⚖️"
        case .goalAlignment: return "✨"
        case .seasonalSmart: return "🌟"
        }
    }
}

struct PriorityPatternAnalysis {
    let categoryPriorityAlignment: [FanCategory: Double]
    let artistPriorityAlignment: [String: Double]
    let dayOfWeekDecisionPattern: [Int: Int]
    let averageDecisionConfidence: Double
    let comebackPriorityAlignment: Double
    let totalRecentDecisions: Int
}

// Legacy - keeping for backward compatibility
struct SpendingPatternAnalysis {
    let categoryDistribution: [FanCategory: Double]
    let artistDistribution: [String: Double]
    let dayOfWeekPattern: [Int: Double]
    let averagePurchaseAmount: Double
    let comebackSpendingRatio: Double
    let totalRecentSpending: Double
}

struct PrioritySpendingAnalysis {
    let priorityMismatches: [(artist: FanArtist, expectedRatio: Double, actualRatio: Double)]
}

struct GoalPrediction {
    let goal: FanGoal
    let achievabilityScore: Double
    let monthlyRequirement: Double
    let riskLevel: RiskLevel
}

enum RiskLevel {
    case low, medium, high
}

struct SeasonalTrendAnalysis {
    let monthlySpending: [Int: Double]
    let averageSpending: Double
    let highSpendingSeasons: [Int]
}

// MARK: - New Priority-Based Structures

struct PriorityAlignment {
    let artistAlignmentScores: [String: Double]
}

struct GoalAlignment {
    let overallAlignment: Double
}

struct SeasonalTrends {
    let hasSeasonalPattern: Bool
}
