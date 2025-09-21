import Foundation

// MARK: - Fan Activity Manager
@MainActor
class FanActivityManager: ObservableObject {
    static let shared = FanActivityManager()
    
    private init() {}
    
    // MARK: - Auto-Priority Update Logic
    
    /// Updates category priorities based on user activity frequency in the last 30 days
    /// - Parameter onboardingData: The onboarding data to update
    func updateCategoryPrioritiesFromActivity(onboardingData: OnboardingData) {
        let activityCounts = getActivityCountsLast30Days()
        let updatedPriorities = calculatePrioritiesFromCounts(activityCounts)
        
        // Update the onboarding data
        onboardingData.categoryPriorities = updatedPriorities
        
        // Save to UserDefaults for Home tab persistence
        saveToUserDefaults(priorities: updatedPriorities)
        
        print("🎯 Auto-updated category priorities from activity: \(updatedPriorities)")
    }
    
    // MARK: - Activity Counting Logic
    
    /// Counts fan activities by category in the last 30 days
    /// - Returns: Dictionary mapping category IDs to activity count
    private func getActivityCountsLast30Days() -> [String: Int] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        var activityCounts: [String: Int] = [:]
        
        // Get recent activities (this would normally come from your data source)
        let recentActivities = getRecentFanActivities(since: thirtyDaysAgo)
        
        // Count by category
        for activity in recentActivities {
            let categoryId = getCategoryId(from: activity)
            activityCounts[categoryId, default: 0] += 1
        }
        
        print("📊 Activity counts (last 30 days): \(activityCounts)")
        return activityCounts
    }
    
    /// Enhanced priority calculation with weighted scoring and intelligent thresholds
    /// - Parameter counts: Activity counts by category
    /// - Returns: Priority levels by category ID
    private func calculatePrioritiesFromCounts(_ counts: [String: Int]) -> [String: PriorityLevel] {
        var priorities: [String: PriorityLevel] = [:]
        
        // Calculate weighted scores with recency bias
        let scoredCategories = calculateWeightedScores(counts)
        let totalActivity = scoredCategories.values.reduce(0, +)
        
        // Dynamic threshold calculation based on total activity
        let highThreshold = max(totalActivity * 0.35, 3.0) // At least 35% of activity or 3 activities
        let mediumThreshold = max(totalActivity * 0.15, 1.0) // At least 15% of activity or 1 activity
        
        // Apply dynamic priority logic based on weighted scores
        for (categoryId, score) in scoredCategories {
            if score >= highThreshold {
                priorities[categoryId] = .high
            } else if score >= mediumThreshold {
                priorities[categoryId] = .medium
            } else {
                priorities[categoryId] = .low
            }
        }
        
        // Ensure all main categories have a priority (even if no activity)
        let mainCategories = ["concerts", "albums", "merch", "events", "subscriptions"]
        for categoryId in mainCategories {
            if priorities[categoryId] == nil {
                priorities[categoryId] = .low
            }
        }
        
        // Apply business logic adjustments
        priorities = applyBusinessLogicAdjustments(priorities, scores: scoredCategories)
        
        return priorities
    }
    
    /// Calculate weighted scores for categories with recency bias and activity importance
    /// - Parameter counts: Raw activity counts
    /// - Returns: Weighted scores by category
    private func calculateWeightedScores(_ counts: [String: Int]) -> [String: Double] {
        var weightedScores: [String: Double] = [:]
        
        // Get recent activities for temporal weighting
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentActivities = getRecentFanActivities(since: thirtyDaysAgo)
        
        // Calculate base scores with temporal weighting
        for (categoryId, count) in counts {
            let baseScore = Double(count)
            
            // Apply recency weighting: more recent = higher weight
            let activitiesInCategory = recentActivities.filter { getCategoryId(from: $0) == categoryId }
            let recencyWeight = calculateRecencyWeight(activities: activitiesInCategory)
            
            // Apply category importance multiplier
            let categoryMultiplier = getCategoryImportanceMultiplier(categoryId)
            
            weightedScores[categoryId] = baseScore * recencyWeight * categoryMultiplier
        }
        
        return weightedScores
    }
    
    /// Calculate recency weight for activities (more recent = higher weight)
    /// - Parameter activities: Activities in the category
    /// - Returns: Recency weight multiplier (1.0 - 2.0)
    private func calculateRecencyWeight(activities: [FanActivity]) -> Double {
        guard !activities.isEmpty else { return 1.0 }
        
        let now = Date()
        let daysSinceEpoch = now.timeIntervalSince1970 / (24 * 3600)
        
        var totalWeight = 0.0
        for activity in activities {
            let activityDays = activity.createdAt.timeIntervalSince1970 / (24 * 3600)
            let daysSinceActivity = daysSinceEpoch - activityDays
            
            // Exponential decay: weight = 2^(-days/10), clamped between 0.5 and 2.0
            let weight = max(0.5, min(2.0, pow(2.0, -daysSinceActivity / 10.0)))
            totalWeight += weight
        }
        
        return totalWeight / Double(activities.count)
    }
    
    /// Get category importance multiplier based on fan behavior patterns
    /// - Parameter categoryId: Category identifier
    /// - Returns: Importance multiplier (0.8 - 1.5)
    private func getCategoryImportanceMultiplier(_ categoryId: String) -> Double {
        switch categoryId {
        case "concerts":
            return 1.3 // Concerts are high-impact, infrequent events
        case "albums":
            return 1.2 // Albums are core fan activities
        case "events":
            return 1.1 // Fan events are important for engagement
        case "merch":
            return 1.0 // Merchandise is baseline
        case "subscriptions":
            return 0.9 // Subscriptions are ongoing, less priority-defining
        default:
            return 0.8 // Other categories get lower weight
        }
    }
    
    /// Apply business logic adjustments to priorities
    /// - Parameters:
    ///   - priorities: Initial priority levels
    ///   - scores: Weighted scores by category
    /// - Returns: Adjusted priority levels
    private func applyBusinessLogicAdjustments(_ priorities: [String: PriorityLevel], scores: [String: Double]) -> [String: PriorityLevel] {
        var adjustedPriorities = priorities
        
        // Rule 1: If concerts have any activity, bump to at least medium
        if let concertScore = scores["concerts"], concertScore > 0, adjustedPriorities["concerts"] == .low {
            adjustedPriorities["concerts"] = .medium
            print("🎤 Business Rule: Boosted concerts from low to medium (any concert activity is significant)")
        }
        
        // Rule 2: Balance high priorities - don't have more than 3 high priorities
        let highPriorities = adjustedPriorities.filter { $0.value == .high }
        if highPriorities.count > 3 {
            // Downgrade the lowest-scoring high priority to medium
            let sortedHigh = highPriorities.sorted { 
                scores[$0.key] ?? 0 < scores[$1.key] ?? 0 
            }
            if let lowestHigh = sortedHigh.first {
                adjustedPriorities[lowestHigh.key] = .medium
                print("🎯 Business Rule: Downgraded \(lowestHigh.key) from high to medium to maintain focus")
            }
        }
        
        // Rule 3: Ensure at least one high priority exists for engaged users
        let totalScore = scores.values.reduce(0, +)
        if totalScore > 5 && !adjustedPriorities.values.contains(.high) {
            // Promote the highest-scoring medium priority to high
            let mediumPriorities = adjustedPriorities.filter { $0.value == .medium }
            if let topMedium = mediumPriorities.max(by: { 
                (scores[$0.key] ?? 0) < (scores[$1.key] ?? 0) 
            }) {
                adjustedPriorities[topMedium.key] = .high
                print("📈 Business Rule: Promoted \(topMedium.key) to high priority (engaged user pattern)")
            }
        }
        
        return adjustedPriorities
    }
    
    // MARK: - Data Integration
    
    /// Gets recent fan activities from Supabase database
    /// - Parameter since: Start date for activity query
    /// - Returns: Array of recent fan activities
    private func getRecentFanActivities(since: Date) -> [FanActivity] {
        // Check if user is authenticated
        guard let userId = getCurrentUserId() else {
            print("⚠️ No authenticated user, using mock data for testing")
            return getMockRecentActivities(since: since)
        }
        
        print("📊 Looking for real activities for user: \(userId) since: \(since)")
        
        // Try to get data from FanDashboardService cache first
        if let dashboardData = FanDashboardService.shared.dashboardData {
            let recentActivities = dashboardData.recentActivity.filter { activity in
                activity.createdAt >= since
            }
            
            if !recentActivities.isEmpty {
                print("✅ Found \(recentActivities.count) cached activities since \(since)")
                return recentActivities
            } else {
                print("ℹ️ No cached activities found since \(since)")
            }
        }
        
        // If no cached data, trigger a dashboard data refresh (async)
        print("🔄 No recent cached data, will trigger dashboard refresh...")
        Task {
            await FanDashboardService.shared.loadDashboardData()
            print("🔄 Dashboard refresh completed")
        }
        
        // For now, fall back to mock data since this is a synchronous method
        // The next time this is called (after refresh), real data should be available
        print("⚠️ Using mock data while dashboard refreshes")
        return getMockRecentActivities(since: since)
    }
    
    /// Gets current user ID from authentication service
    /// - Returns: User ID if available
    private func getCurrentUserId() -> UUID? {
        return AuthenticationService.shared.currentUser?.id
    }
    
    /// Enhanced activity categorization with intelligent keyword matching and context analysis
    /// - Parameter activity: Fan activity to categorize
    /// - Returns: Category ID string
    private func getCategoryId(from activity: FanActivity) -> String {
        // Primary: Use explicit fanCategory if available
        if let fanCategory = activity.fanCategory {
            return fanCategory.priorityChartCategoryId
        }
        
        // Enhanced fallback categorization with comprehensive keyword analysis
        return categorizeActivityByContent(activity)
    }
    
    /// Sophisticated content-based categorization using weighted keyword matching
    /// - Parameter activity: Fan activity to categorize
    /// - Returns: Category ID string
    private func categorizeActivityByContent(_ activity: FanActivity) -> String {
        let title = activity.title.lowercased()
        let description = (activity.description ?? "").lowercased()
        let combinedText = "\(title) \(description)"
        
        // Define comprehensive keyword sets with weights
        let categoryKeywords: [String: [(keyword: String, weight: Double)]] = [
            "concerts": [
                ("concert", 3.0), ("tour", 3.0), ("show", 2.5), ("live", 2.0),
                ("ticket", 2.5), ("venue", 2.0), ("performance", 2.0), ("stage", 1.5),
                ("presale", 2.0), ("vip", 1.5), ("soundcheck", 2.0), ("meet & greet", 2.5),
                ("world tour", 3.5), ("fanmeet", 2.0), ("showcase", 2.0)
            ],
            "albums": [
                ("album", 3.0), ("cd", 2.5), ("vinyl", 2.5), ("photocard", 3.0),
                ("comeback", 2.5), ("release", 2.0), ("pre-order", 2.0), ("preorder", 2.0),
                ("single", 2.0), ("ep", 2.0), ("mini album", 3.0), ("full album", 3.0),
                ("track", 1.5), ("song", 1.0), ("music", 1.0), ("pc", 2.0)
            ],
            "merch": [
                ("merchandise", 3.0), ("merch", 3.0), ("lightstick", 3.0), ("hoodie", 2.5),
                ("shirt", 2.0), ("poster", 2.0), ("keychain", 2.0), ("bag", 2.0),
                ("official", 1.5), ("limited edition", 2.5), ("exclusive", 2.0),
                ("collection", 2.0), ("drop", 2.0), ("store", 1.5)
            ],
            "events": [
                ("fanmeet", 3.0), ("fansign", 3.0), ("kcon", 3.0), ("convention", 2.5),
                ("hi-touch", 3.0), ("meet and greet", 3.0), ("fan event", 3.0),
                ("birthday", 2.0), ("anniversary", 2.0), ("debut", 2.0),
                ("vlive", 2.0), ("live stream", 2.0), ("instagram live", 2.0)
            ],
            "subscriptions": [
                ("subscription", 3.0), ("membership", 3.0), ("weverse", 2.5), ("bubble", 2.5),
                ("lysn", 2.5), ("app", 2.0), ("platform", 2.0), ("streaming", 2.0),
                ("digital", 2.0), ("premium", 2.0), ("exclusive content", 2.5),
                ("monthly", 1.5), ("yearly", 1.5)
            ]
        ]
        
        // Calculate weighted scores for each category
        var categoryScores: [String: Double] = [:]
        
        for (categoryId, keywords) in categoryKeywords {
            var score = 0.0
            for (keyword, weight) in keywords {
                if combinedText.contains(keyword) {
                    score += weight
                    
                    // Bonus for exact title match
                    if title.contains(keyword) {
                        score += weight * 0.5
                    }
                    
                    // Bonus for multiple keyword matches in same category
                    let keywordCount = keywords.filter { combinedText.contains($0.keyword) }.count
                    if keywordCount > 1 {
                        score += 0.5 * Double(keywordCount - 1)
                    }
                }
            }
            categoryScores[categoryId] = score
        }
        
        // Context-based adjustments
        categoryScores = applyContextualAdjustments(categoryScores, activity: activity, text: combinedText)
        
        // Return the highest-scoring category, or default fallback
        let bestMatch = categoryScores.max { $0.value < $1.value }
        
        if let category = bestMatch, category.value > 0.5 {
            print("🤖 Smart categorization: '\(activity.title)' → \(category.key) (score: \(String(format: "%.1f", category.value)))")
            return category.key
        } else {
            print("⚠️ Categorization fallback for: '\(activity.title)'")
            return "merch" // Safe default fallback
        }
    }
    
    /// Apply contextual adjustments to category scores based on additional signals
    /// - Parameters:
    ///   - scores: Initial category scores
    ///   - activity: The fan activity being categorized
    ///   - text: Combined text content
    /// - Returns: Adjusted category scores
    private func applyContextualAdjustments(_ scores: [String: Double], activity: FanActivity, text: String) -> [String: Double] {
        var adjustedScores = scores
        
        // Price-based adjustments
        let price = activity.amount ?? 0.0
        if price > 100 {
            // High-price items are more likely to be concerts or limited merch
            adjustedScores["concerts"] = (adjustedScores["concerts"] ?? 0) + 1.0
            adjustedScores["merch"] = (adjustedScores["merch"] ?? 0) + 0.5
        } else if price < 30 {
            // Low-price items are more likely to be subscriptions or digital content
            adjustedScores["subscriptions"] = (adjustedScores["subscriptions"] ?? 0) + 1.0
        }
        
        // Artist name context (if available)
        let artistName = activity.artistName ?? ""
        if !artistName.isEmpty {
            let artistLower = artistName.lowercased()
            
            // Some artists are known for specific types of content
            if artistLower.contains("bts") || artistLower.contains("blackpink") {
                // Popular groups often have high-value concerts and merch
                adjustedScores["concerts"] = (adjustedScores["concerts"] ?? 0) + 0.5
                adjustedScores["merch"] = (adjustedScores["merch"] ?? 0) + 0.3
            }
        }
        
        // Time-based context
        let daysSinceActivity = Date().timeIntervalSince(activity.createdAt) / (24 * 3600)
        if daysSinceActivity < 7 {
            // Recent activities might be trending events or new releases
            adjustedScores["events"] = (adjustedScores["events"] ?? 0) + 0.3
            adjustedScores["albums"] = (adjustedScores["albums"] ?? 0) + 0.3
        }
        
        return adjustedScores
    }
    
    /// Saves priority data to UserDefaults for Home tab access
    /// - Parameter priorities: Priority levels to save
    private func saveToUserDefaults(priorities: [String: PriorityLevel]) {
        if let encoded = try? JSONEncoder().encode(priorities) {
            UserDefaults.standard.set(encoded, forKey: "onboarding_category_priorities")
            print("💾 Saved auto-updated priorities to UserDefaults")
        }
    }
    
    // MARK: - Mock Data (for testing)
    
    /// Generates mock activity data for testing the auto-priority system
    /// - Parameter since: Start date for mock data
    /// - Returns: Array of mock fan activities
    private func getMockRecentActivities(since: Date) -> [FanActivity] {
        // Generate realistic mock data for testing
        var mockActivities: [FanActivity] = []
        
        let categories: [FanCategory] = [.concerts, .albums, .merch, .events, .subscriptions]
        let artists = ["BTS", "NewJeans", "TWICE", "Stray Kids", "ITZY"]
        
        // Generate activities with different frequencies to test priority calculation
        for _ in 0..<15 { // 15 activities in last 30 days
            guard let randomCategory = categories.randomElement(),
                  let randomArtist = artists.randomElement() else { continue }
            let randomDate = Date().addingTimeInterval(-Double.random(in: 0...2592000)) // Random date within 30 days
            
            let activity = FanActivity(
                id: UUID(),
                artistName: randomArtist,
                activityType: .purchase, // Default activity type
                title: "\(randomArtist) \(randomCategory.rawValue)",
                description: nil,
                amount: Double.random(in: 10...200),
                createdAt: randomDate,
                fanCategory: randomCategory
            )
            
            mockActivities.append(activity)
        }
        
        // Add extra concert activities to make "concerts" high priority in mock data
        for _ in 0..<8 {
            let activity = FanActivity(
                id: UUID(),
                artistName: "BTS",
                activityType: .purchase,
                title: "Concert Ticket Purchase",
                description: nil,
                amount: Double.random(in: 100...300),
                createdAt: Date().addingTimeInterval(-Double.random(in: 0...2592000)),
                fanCategory: .concerts
            )
            mockActivities.append(activity)
        }
        
        return mockActivities.filter { $0.createdAt >= since }
    }
}

// MARK: - Integration Hook for QuickAddView
extension FanActivityManager {
    
    /// Call this after a user adds a new fan activity
    /// - Parameters:
    ///   - activity: The newly added activity
    ///   - onboardingData: Onboarding data to potentially update
    func didAddActivity(_ activity: FanActivity, onboardingData: OnboardingData? = nil) {
        // Update priorities after new activity is added
        if let onboardingData = onboardingData {
            updateCategoryPrioritiesFromActivity(onboardingData: onboardingData)
        } else {
            // If no onboarding data provided, create a temporary one to update UserDefaults
            let tempOnboardingData = OnboardingData()
            updateCategoryPrioritiesFromActivity(onboardingData: tempOnboardingData)
        }
        
        print("🆕 Activity added: \(activity.title) - priorities updated!")
    }
}