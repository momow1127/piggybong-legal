import Foundation

// MARK: - Fan Activity Insights Service
/// Provides advanced analytics and insights about user fan activity patterns
@MainActor
class FanActivityInsightsService: ObservableObject {
    static let shared = FanActivityInsightsService()
    
    @Published var latestInsights: FanActivityInsights?
    @Published var isAnalyzing = false
    
    private init() {}
    
    // MARK: - Core Analytics
    
    /// Generate comprehensive insights about user's fan activity patterns
    /// - Parameter timeframe: Analysis timeframe (default: 30 days)
    /// - Returns: Detailed insights about fan activity patterns
    func generateInsights(timeframe: TimeInterval = 30 * 24 * 3600) async -> FanActivityInsights {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        let startDate = Date().addingTimeInterval(-timeframe)
        let activities = await getFanActivities(since: startDate)
        
        let insights = FanActivityInsights(
            timeframe: timeframe,
            totalActivities: activities.count,
            totalSpent: activities.reduce(0) { $0 + ($1.amount ?? 0.0) },
            categoryDistribution: calculateCategoryDistribution(activities),
            artistDistribution: calculateArtistDistribution(activities),
            spendingTrends: calculateSpendingTrends(activities),
            behaviorPatterns: analyzeBehaviorPatterns(activities),
            recommendations: generateRecommendations(activities)
        )
        
        latestInsights = insights
        return insights
    }
    
    // MARK: - Category Analysis
    
    /// Calculate how user's spending is distributed across categories
    private func calculateCategoryDistribution(_ activities: [FanActivity]) -> [CategoryInsight] {
        var categoryData: [String: (count: Int, total: Double, activities: [FanActivity])] = [:]
        
        for activity in activities {
            let categoryId = getCategoryId(from: activity)
            let current = categoryData[categoryId] ?? (count: 0, total: 0.0, activities: [])
            categoryData[categoryId] = (
                count: current.count + 1,
                total: current.total + (activity.amount ?? 0.0),
                activities: current.activities + [activity]
            )
        }
        
        let totalSpent = activities.reduce(0) { $0 + ($1.amount ?? 0.0) }
        
        return categoryData.map { (categoryId, data) in
            CategoryInsight(
                categoryId: categoryId,
                categoryName: getCategoryDisplayName(categoryId),
                activityCount: data.count,
                totalSpent: data.total,
                percentageOfTotal: totalSpent > 0 ? (data.total / totalSpent) * 100 : 0,
                averagePerActivity: data.count > 0 ? data.total / Double(data.count) : 0,
                trend: calculateCategoryTrend(data.activities),
                topItems: getTopItems(from: data.activities)
            )
        }.sorted { $0.totalSpent > $1.totalSpent }
    }
    
    /// Calculate artist spending distribution and engagement
    private func calculateArtistDistribution(_ activities: [FanActivity]) -> [ArtistInsight] {
        var artistData: [String: (count: Int, total: Double, categories: Set<String>, activities: [FanActivity])] = [:]
        
        for activity in activities {
            let artistName = activity.artistName ?? ""
            let artist = artistName.isEmpty ? "Unknown" : artistName
            let categoryId = getCategoryId(from: activity)
            let current = artistData[artist] ?? (count: 0, total: 0.0, categories: [], activities: [])
            
            var newCategories = current.categories
            newCategories.insert(categoryId)
            
            artistData[artist] = (
                count: current.count + 1,
                total: current.total + (activity.amount ?? 0.0),
                categories: newCategories,
                activities: current.activities + [activity]
            )
        }
        
        let totalSpent = activities.reduce(0) { $0 + ($1.amount ?? 0.0) }
        
        return artistData.map { (artistName, data) in
            ArtistInsight(
                artistName: artistName,
                activityCount: data.count,
                totalSpent: data.total,
                percentageOfTotal: totalSpent > 0 ? (data.total / totalSpent) * 100 : 0,
                categoriesEngaged: Array(data.categories),
                engagementScore: calculateEngagementScore(data.activities),
                trend: calculateArtistTrend(data.activities),
                favoriteCategories: getFavoriteCategories(data.activities)
            )
        }.sorted { $0.totalSpent > $1.totalSpent }
    }
    
    // MARK: - Trend Analysis
    
    /// Calculate spending trends over time
    private func calculateSpendingTrends(_ activities: [FanActivity]) -> SpendingTrends {
        let calendar = Calendar.current
        let now = Date()
        
        // Weekly trends (last 4 weeks)
        var weeklyTrends: [WeeklySpending] = []
        for weekOffset in 0..<4 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) ?? now
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now
            
            let weekActivities = activities.filter { 
                $0.createdAt >= weekStart && $0.createdAt < weekEnd 
            }
            
            weeklyTrends.append(WeeklySpending(
                weekStart: weekStart,
                activityCount: weekActivities.count,
                totalSpent: weekActivities.reduce(0) { $0 + ($1.amount ?? 0.0) },
                averagePerActivity: weekActivities.count > 0 ? 
                    weekActivities.reduce(0) { $0 + ($1.amount ?? 0.0) } / Double(weekActivities.count) : 0
            ))
        }
        
        // Monthly comparison
        let thisMonth = activities.filter { 
            calendar.isDate($0.createdAt, equalTo: now, toGranularity: .month) 
        }
        let lastMonth = activities.filter {
            let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return calendar.isDate($0.createdAt, equalTo: lastMonthDate, toGranularity: .month)
        }
        
        let thisMonthSpent = thisMonth.reduce(0) { $0 + ($1.amount ?? 0.0) }
        let lastMonthSpent = lastMonth.reduce(0) { $0 + ($1.amount ?? 0.0) }
        let monthlyGrowth = lastMonthSpent > 0 ? ((thisMonthSpent - lastMonthSpent) / lastMonthSpent) * 100 : 0
        
        return SpendingTrends(
            weeklyTrends: weeklyTrends.reversed(), // Most recent first
            monthlyGrowth: monthlyGrowth,
            peakSpendingDay: findPeakSpendingDay(activities),
            spendingVelocity: calculateSpendingVelocity(activities)
        )
    }
    
    // MARK: - Behavior Pattern Analysis
    
    /// Analyze user behavior patterns for personalization
    private func analyzeBehaviorPatterns(_ activities: [FanActivity]) -> BehaviorPatterns {
        let patterns = BehaviorPatterns(
            spendingPersonality: determineSpendingPersonality(activities),
            preferredCategories: getPreferredCategories(activities),
            activityFrequency: calculateActivityFrequency(activities),
            priceRangePreferences: analyzePriceRangePreferences(activities),
            temporalPatterns: analyzeTemporalPatterns(activities),
            loyaltyScores: calculateArtistLoyaltyScores(activities)
        )
        
        return patterns
    }
    
    /// Generate personalized recommendations based on analysis
    private func generateRecommendations(_ activities: [FanActivity]) -> [FanRecommendation] {
        var recommendations: [FanRecommendation] = []
        
        // Budget optimization recommendations
        recommendations.append(contentsOf: generateBudgetRecommendations(activities))
        
        // Category balance recommendations
        recommendations.append(contentsOf: generateCategoryRecommendations(activities))
        
        // Artist diversification recommendations
        recommendations.append(contentsOf: generateArtistRecommendations(activities))
        
        // Timing optimization recommendations
        recommendations.append(contentsOf: generateTimingRecommendations(activities))
        
        return recommendations
    }
    
    // MARK: - Analysis Implementation Methods
    
    private func calculateCategoryTrend(_ activities: [FanActivity]) -> TrendDirection {
        guard activities.count >= 2 else { return .stable }
        
        let sortedActivities = activities.sorted { $0.createdAt < $1.createdAt }
        let midpoint = activities.count / 2
        
        let earlierHalf = Array(sortedActivities.prefix(midpoint))
        let laterHalf = Array(sortedActivities.suffix(midpoint))
        
        let earlierAverage = earlierHalf.reduce(0) { $0 + ($1.amount ?? 0.0) } / Double(earlierHalf.count)
        let laterAverage = laterHalf.reduce(0) { $0 + ($1.amount ?? 0.0) } / Double(laterHalf.count)
        
        let changePercent = (laterAverage - earlierAverage) / earlierAverage * 100
        
        if changePercent > 20 { return .increasing }
        if changePercent < -20 { return .decreasing }
        return .stable
    }
    
    private func getTopItems(from activities: [FanActivity]) -> [String] {
        let topActivities = activities.sorted { ($0.amount ?? 0.0) > ($1.amount ?? 0.0) }.prefix(3)
        return topActivities.map { $0.title }
    }
    
    private func calculateEngagementScore(_ activities: [FanActivity]) -> Double {
        let totalSpent = activities.reduce(0) { $0 + ($1.amount ?? 0.0) }
        let activityCount = Double(activities.count)
        let categoryDiversity = Set(activities.compactMap { $0.fanCategory }).count
        
        let spendingScore = min(totalSpent / 500.0, 10.0) // Cap at 10
        let frequencyScore = min(activityCount / 10.0, 5.0) // Cap at 5
        let diversityScore = min(Double(categoryDiversity), 5.0) // Cap at 5
        
        return spendingScore + frequencyScore + diversityScore
    }
    
    private func calculateArtistTrend(_ activities: [FanActivity]) -> TrendDirection {
        return calculateCategoryTrend(activities) // Same logic
    }
    
    private func getFavoriteCategories(_ activities: [FanActivity]) -> [String] {
        var categoryCounts: [String: Int] = [:]
        
        for activity in activities {
            let categoryId = getCategoryId(from: activity)
            categoryCounts[categoryId, default: 0] += 1
        }
        
        return categoryCounts.sorted { $0.value > $1.value }
            .prefix(3)
            .map { getCategoryDisplayName($0.key) }
    }
    
    private func findPeakSpendingDay(_ activities: [FanActivity]) -> String {
        var daySpending: [String: Double] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        
        for activity in activities {
            let day = formatter.string(from: activity.createdAt)
            daySpending[day, default: 0] += (activity.amount ?? 0.0)
        }
        
        return daySpending.max { $0.value < $1.value }?.key ?? "Unknown"
    }
    
    private func calculateSpendingVelocity(_ activities: [FanActivity]) -> Double {
        guard activities.count > 1 else { return 0 }
        
        let sortedActivities = activities.sorted { $0.createdAt < $1.createdAt }
        let timespan = sortedActivities.last!.createdAt.timeIntervalSince(sortedActivities.first!.createdAt)
        let totalSpent = activities.reduce(0) { $0 + ($1.amount ?? 0.0) }
        
        return timespan > 0 ? totalSpent / (timespan / (24 * 3600)) : 0 // Spending per day
    }
    
    private func determineSpendingPersonality(_ activities: [FanActivity]) -> SpendingPersonality {
        let amounts = activities.map { $0.amount ?? 0.0 }
        let average = amounts.reduce(0, +) / Double(amounts.count)
        let standardDeviation = sqrt(amounts.map { pow($0 - average, 2) }.reduce(0, +) / Double(amounts.count))
        
        let highValuePurchases = activities.filter { ($0.amount ?? 0.0) > 100 }.count
        let totalPurchases = activities.count
        let highValueRatio = Double(highValuePurchases) / Double(totalPurchases)
        
        if standardDeviation > average * 0.8 {
            return .impulsive
        } else if highValueRatio > 0.5 {
            return .premium
        } else if average < 30 {
            return .bargainHunter
        } else if standardDeviation < average * 0.3 {
            return .planned
        } else {
            return .balanced
        }
    }
    
    private func getPreferredCategories(_ activities: [FanActivity]) -> [String] {
        return getFavoriteCategories(activities)
    }
    
    private func calculateActivityFrequency(_ activities: [FanActivity]) -> ActivityFrequency {
        guard !activities.isEmpty else { return .occasional }
        
        let daysSinceOldest = Date().timeIntervalSince(activities.min { $0.createdAt < $1.createdAt }!.createdAt) / (24 * 3600)
        let averageDaysBetween = daysSinceOldest / Double(activities.count)
        
        switch averageDaysBetween {
        case 0...2: return .daily
        case 2...7: return .weekly
        case 7...30: return .monthly
        default: return .occasional
        }
    }
    
    private func analyzePriceRangePreferences(_ activities: [FanActivity]) -> PriceRangePreference {
        let amounts = activities.map { $0.amount ?? 0.0 }.sorted()
        let q25 = amounts[amounts.count / 4]
        let q75 = amounts[amounts.count * 3 / 4]
        let iqr = q75 - q25
        
        return PriceRangePreference(
            preferredMin: q25,
            preferredMax: q75,
            tolerance: iqr
        )
    }
    
    private func analyzeTemporalPatterns(_ activities: [FanActivity]) -> TemporalPattern {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        
        var dayFrequency: [String: Int] = [:]
        for activity in activities {
            let day = formatter.string(from: activity.createdAt)
            dayFrequency[day, default: 0] += 1
        }
        
        let preferredDays = dayFrequency.sorted { $0.value > $1.value }
            .prefix(3).map { $0.key }
        
        return TemporalPattern(
            preferredDays: Array(preferredDays),
            preferredTimes: ["Evening"], // Simplified
            seasonality: "Year-round" // Simplified
        )
    }
    
    private func calculateArtistLoyaltyScores(_ activities: [FanActivity]) -> [ArtistLoyalty] {
        var artistData: [String: (count: Int, totalSpent: Double)] = [:]
        
        for activity in activities {
            let artistName = activity.artistName ?? ""
            let artist = artistName.isEmpty ? "Unknown" : artistName
            let current = artistData[artist] ?? (count: 0, totalSpent: 0.0)
            artistData[artist] = (count: current.count + 1, totalSpent: current.totalSpent + (activity.amount ?? 0.0))
        }
        
        return artistData.map { (artist, data) in
            let loyaltyScore = Double(data.count) * 2 + (data.totalSpent / 100)
            let engagementLevel: String
            switch loyaltyScore {
            case 0...5: engagementLevel = "Casual"
            case 5...15: engagementLevel = "Moderate"
            case 15...30: engagementLevel = "High"
            default: engagementLevel = "Super Fan"
            }
            
            return ArtistLoyalty(
                artistName: artist,
                loyaltyScore: loyaltyScore,
                engagementLevel: engagementLevel
            )
        }.sorted { $0.loyaltyScore > $1.loyaltyScore }
    }
    
    private func generateBudgetRecommendations(_ activities: [FanActivity]) -> [FanRecommendation] {
        let totalSpent = activities.reduce(0) { $0 + ($1.amount ?? 0.0) }
        let monthlyAverage = totalSpent / 4 // Assuming 4 weeks of data
        
        var recommendations: [FanRecommendation] = []
        
        if monthlyAverage > 500 {
            recommendations.append(FanRecommendation(
                type: .budget,
                title: "High Spending Alert",
                description: "You're spending $\(Int(monthlyAverage))/month on K-pop activities. Consider setting a monthly budget.",
                impact: .significant,
                actionRequired: "Set a monthly spending limit"
            ))
        } else if monthlyAverage < 50 {
            recommendations.append(FanRecommendation(
                type: .budget,
                title: "Budget Opportunity",
                description: "You have room to explore more fan activities within a reasonable budget.",
                impact: .moderate,
                actionRequired: nil
            ))
        }
        
        return recommendations
    }
    
    private func generateCategoryRecommendations(_ activities: [FanActivity]) -> [FanRecommendation] {
        var categoryCounts: [String: Int] = [:]
        for activity in activities {
            let categoryId = getCategoryId(from: activity)
            categoryCounts[categoryId, default: 0] += 1
        }
        
        var recommendations: [FanRecommendation] = []
        
        if categoryCounts["concerts"] == 0 && activities.count > 5 {
            recommendations.append(FanRecommendation(
                type: .category,
                title: "Concert Experience Missing",
                description: "You haven't attended any concerts recently. Live performances create unforgettable memories!",
                impact: .significant,
                actionRequired: "Look for upcoming concerts"
            ))
        }
        
        if categoryCounts["albums"] ?? 0 > activities.count / 2 {
            recommendations.append(FanRecommendation(
                type: .category,
                title: "Diversify Your Collection",
                description: "Most of your spending is on albums. Try exploring merchandise or fan events!",
                impact: .moderate,
                actionRequired: "Explore other categories"
            ))
        }
        
        return recommendations
    }
    
    private func generateArtistRecommendations(_ activities: [FanActivity]) -> [FanRecommendation] {
        var artistCounts: [String: Int] = [:]
        for activity in activities {
            let artistName = activity.artistName ?? ""
            let artist = artistName.isEmpty ? "Unknown" : artistName
            artistCounts[artist, default: 0] += 1
        }
        
        var recommendations: [FanRecommendation] = []
        
        if artistCounts.count == 1 {
            recommendations.append(FanRecommendation(
                type: .artist,
                title: "Discover New Artists",
                description: "You're focused on one artist. Exploring other K-pop acts might introduce you to amazing new music!",
                impact: .moderate,
                actionRequired: "Try activities for new artists"
            ))
        }
        
        return recommendations
    }
    
    private func generateTimingRecommendations(_ activities: [FanActivity]) -> [FanRecommendation] {
        let recentActivity = activities.filter { 
            Date().timeIntervalSince($0.createdAt) < 7 * 24 * 3600 
        }
        
        var recommendations: [FanRecommendation] = []
        
        if recentActivity.count > 5 {
            recommendations.append(FanRecommendation(
                type: .timing,
                title: "Pace Your Spending",
                description: "You've been very active this week. Consider spacing out purchases to avoid impulse buying.",
                impact: .moderate,
                actionRequired: "Wait 24 hours before next purchase"
            ))
        } else if recentActivity.isEmpty && activities.count > 0 {
            recommendations.append(FanRecommendation(
                type: .timing,
                title: "Stay Engaged",
                description: "You haven't been active lately. Check for new releases or upcoming events!",
                impact: .minimal,
                actionRequired: "Browse recent K-pop news"
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Helper Methods
    
    private func getFanActivities(since date: Date) async -> [FanActivity] {
        // Try to get from dashboard service first
        if let dashboardData = FanDashboardService.shared.dashboardData {
            return dashboardData.recentActivity.filter { $0.createdAt >= date }
        }
        
        // Trigger dashboard refresh if no data
        await FanDashboardService.shared.loadDashboardData()
        
        // Return data after refresh or fallback to mock
        if let dashboardData = FanDashboardService.shared.dashboardData {
            return dashboardData.recentActivity.filter { $0.createdAt >= date }
        }
        
        return generateMockActivities(since: date)
    }
    
    private func getCategoryId(from activity: FanActivity) -> String {
        if let fanCategory = activity.fanCategory {
            return fanCategory.priorityChartCategoryId
        }
        
        // Fallback categorization logic (since FanActivityManager method is private)
        let title = activity.title.lowercased()
        if title.contains("concert") || title.contains("show") || title.contains("ticket") {
            return "concerts"
        } else if title.contains("album") {
            return "albums"
        } else if title.contains("merch") {
            return "merch"
        } else if title.contains("event") || title.contains("fanmeet") {
            return "events"
        } else if title.contains("digital") || title.contains("streaming") || title.contains("subscription") {
            return "subscriptions"
        }
        
        return "merch" // Default fallback
    }
    
    private func getCategoryDisplayName(_ categoryId: String) -> String {
        switch categoryId {
        case "concerts": return "Concerts & Shows"
        case "albums": return "Albums & Photocards"
        case "merch": return "Official Merch"
        case "events": return "Fan Events"
        case "subscriptions": return "Subscriptions & Apps"
        default: return "Other"
        }
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockActivities(since date: Date) -> [FanActivity] {
        let categories: [FanCategory] = [.concerts, .albums, .merch, .events, .subscriptions]
        let artists = ["BTS", "NewJeans", "TWICE", "Stray Kids", "ITZY", "aespa"]
        var activities: [FanActivity] = []
        
        for _ in 0..<20 {
            guard let randomCategory = categories.randomElement(),
                  let randomArtist = artists.randomElement() else { continue }
            let randomDate = Date().addingTimeInterval(-Double.random(in: 0...2592000))
            
            let activity = FanActivity(
                id: UUID(),
                artistName: randomArtist,
                activityType: .purchase,
                title: generateMockActivityTitle(category: randomCategory, artist: randomArtist),
                description: nil,
                amount: generateMockPrice(category: randomCategory),
                createdAt: randomDate,
                fanCategory: randomCategory
            )
            
            activities.append(activity)
        }
        
        return activities.filter { $0.createdAt >= date }
    }
    
    private func generateMockActivityTitle(category: FanCategory, artist: String) -> String {
        switch category {
        case .concerts:
            return "\(artist) Concert Ticket"
        case .albums:
            return "\(artist) Latest Album"
        case .merch:
            return "\(artist) Official Merchandise"
        case .events:
            return "\(artist) Fan Meeting"
        case .subscriptions:
            return "\(artist) Membership Subscription"
        case .other:
            return "\(artist) Fan Item"
        }
    }
    
    private func generateMockPrice(category: FanCategory) -> Double {
        switch category {
        case .concerts:
            return Double.random(in: 80...300)
        case .albums:
            return Double.random(in: 15...50)
        case .merch:
            return Double.random(in: 20...120)
        case .events:
            return Double.random(in: 50...200)
        case .subscriptions:
            return Double.random(in: 5...30)
        case .other:
            return Double.random(in: 10...80)
        }
    }
}

// MARK: - Insights Data Models

struct FanActivityInsights {
    let timeframe: TimeInterval
    let totalActivities: Int
    let totalSpent: Double
    let categoryDistribution: [CategoryInsight]
    let artistDistribution: [ArtistInsight]
    let spendingTrends: SpendingTrends
    let behaviorPatterns: BehaviorPatterns
    let recommendations: [FanRecommendation]
    
    var averagePerActivity: Double {
        totalActivities > 0 ? totalSpent / Double(totalActivities) : 0
    }
    
    var timeframeDays: Int {
        Int(timeframe / (24 * 3600))
    }
}

struct CategoryInsight {
    let categoryId: String
    let categoryName: String
    let activityCount: Int
    let totalSpent: Double
    let percentageOfTotal: Double
    let averagePerActivity: Double
    let trend: TrendDirection
    let topItems: [String]
}

struct ArtistInsight {
    let artistName: String
    let activityCount: Int
    let totalSpent: Double
    let percentageOfTotal: Double
    let categoriesEngaged: [String]
    let engagementScore: Double
    let trend: TrendDirection
    let favoriteCategories: [String]
}

struct SpendingTrends {
    let weeklyTrends: [WeeklySpending]
    let monthlyGrowth: Double
    let peakSpendingDay: String
    let spendingVelocity: Double
}

struct WeeklySpending {
    let weekStart: Date
    let activityCount: Int
    let totalSpent: Double
    let averagePerActivity: Double
}

struct BehaviorPatterns {
    let spendingPersonality: SpendingPersonality
    let preferredCategories: [String]
    let activityFrequency: ActivityFrequency
    let priceRangePreferences: PriceRangePreference
    let temporalPatterns: TemporalPattern
    let loyaltyScores: [ArtistLoyalty]
}

struct FanRecommendation {
    let type: RecommendationType
    let title: String
    let description: String
    let impact: ImpactLevel
    let actionRequired: String?
}

// MARK: - Supporting Enums

enum TrendDirection {
    case increasing, decreasing, stable
}

enum SpendingPersonality {
    case impulsive, planned, bargainHunter, premium, balanced
    
    var description: String {
        switch self {
        case .impulsive: return "Spontaneous Spender"
        case .planned: return "Strategic Planner"
        case .bargainHunter: return "Value Seeker"
        case .premium: return "Premium Collector"
        case .balanced: return "Balanced Fan"
        }
    }
}

enum ActivityFrequency {
    case daily, weekly, monthly, occasional
}

enum RecommendationType {
    case budget, category, artist, timing, opportunity
}


// Additional supporting structs would be defined here...
struct PriceRangePreference {
    let preferredMin: Double
    let preferredMax: Double
    let tolerance: Double
}

struct TemporalPattern {
    let preferredDays: [String]
    let preferredTimes: [String]
    let seasonality: String
}

struct ArtistLoyalty {
    let artistName: String
    let loyaltyScore: Double
    let engagementLevel: String
}