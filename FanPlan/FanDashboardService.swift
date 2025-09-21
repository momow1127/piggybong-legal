import Foundation
import Combine

class FanDashboardService: ObservableObject {
    static let shared = FanDashboardService()

    @Published var dashboardData: FanDashboardData?
    @Published var isLoading = false
    @Published var error: FanDashboardError?
    @Published var insightMessage: String?
    
    private let supabaseService = SupabaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    
    private init() {}
    
    // MARK: - Dashboard Data Loading
    
    func loadDashboardData() async {
        // UI updates on main thread
        await MainActor.run {
            isLoading = true
            error = nil
        }

        // Check if user is authenticated first
        guard AuthenticationService.shared.isAuthenticated else {
            print("⚠️ User not authenticated, skipping dashboard load")
            await MainActor.run {
                isLoading = false
                // Set empty dashboard data for guest users
                dashboardData = nil
                error = .userNotFound
            }
            return
        }

        do {
            // Heavy network and processing operations on background thread
            let response: DashboardHomeResponse = try await supabaseService.callFunction(
                functionName: "fan-dashboard",
                parameters: [:]
            )

            // Heavy data processing operations
            let fanArtists = await convertToFanArtists(response.biasBudgetStatus)
            let aiTip = response.aiTip?.toAITip()
            let recentActivity = convertToFanActivity(response.recentActivity)

            // Get user data
            guard let user = AuthenticationService.shared.currentUser else {
                throw FanDashboardError.userNotFound
            }

            // Heavy calculations
            let totalMonthlyFanTarget = fanArtists.reduce(0) { $0 + $1.monthlyAllocation }
            let totalMonthSpent = fanArtists.reduce(0) { $0 + $1.monthSpent }

            let dashboardUser = DashboardUser(
                id: user.id,
                name: user.name,
                totalSaved: calculateTotalSaved(from: fanArtists),
                monthlyBudget: user.monthlyBudget,
                totalMonthlyBudget: totalMonthlyFanTarget,
                totalMonthSpent: totalMonthSpent,
                joinedDate: Date()
            )

            // Heavy RSS feed processing
            let upcomingEvents = await fetchRealUpcomingEvents()

            // Heavy data processing
            let insights = generateInsightsFromData(fanArtists: fanArtists)
            let monthSummary = createMonthSummary(fanSpendTarget: totalMonthlyFanTarget, spent: totalMonthSpent)
            let recentTransactions = convertActivityToTransactions(recentActivity)

            let finalDashboardData = FanDashboardData(
                user: dashboardUser,
                fanArtists: fanArtists,
                aiTip: aiTip,
                recentActivity: recentActivity,
                totalMonthlyBudget: totalMonthlyFanTarget,
                totalMonthSpent: totalMonthSpent,
                upcomingEvents: upcomingEvents,
                recentTransactions: recentTransactions,
                insights: insights,
                monthSummary: monthSummary
            )

            // Generate contextual AI tip
            let contextualAITip = generateAITipBasedOnSubscription(for: finalDashboardData)

            // UI update on main thread
            await MainActor.run {
                self.dashboardData = FanDashboardData(
                    user: finalDashboardData.user,
                    fanArtists: finalDashboardData.fanArtists,
                    aiTip: contextualAITip ?? finalDashboardData.aiTip,
                    recentActivity: finalDashboardData.recentActivity,
                    totalMonthlyBudget: finalDashboardData.totalMonthlyBudget,
                    totalMonthSpent: finalDashboardData.totalMonthSpent,
                    upcomingEvents: finalDashboardData.upcomingEvents,
                    recentTransactions: finalDashboardData.recentTransactions,
                    insights: finalDashboardData.insights,
                    monthSummary: finalDashboardData.monthSummary
                )
            }
            
        } catch {
            print("Dashboard loading error: \(error)")
            print("🔄 Falling back to user-customized demo data")

            // Heavy fallback processing on background thread
            let fallbackData = await createUserCustomizedDashboardData()

            // UI updates on main thread
            await MainActor.run {
                self.dashboardData = fallbackData
                self.error = nil // Clear error since we have fallback data
            }
        }

        // Final UI update on main thread
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Fan Activity Management
    
    enum SaveResult {
        case success(insight: String)
        case failure(error: Error)
    }
    
    func saveFanActivity(
        amountMajor: Double,
        categoryId: String,
        categoryTitle: String,
        idolId: UUID?,
        note: String?
    ) async -> SaveResult {
        print("📊 FanDashboardService.saveFanActivity called with:")
        print("   - amountMajor: \(amountMajor)")
        print("   - categoryId: '\(categoryId)'")
        print("   - categoryTitle: '\(categoryTitle)'")
        print("   - idolId: \(idolId?.uuidString ?? "nil")")
        print("   - note: '\(note ?? "nil")'")
        
        // Validation
        guard amountMajor > 0 else {
            print("❌ saveFanActivity failed: amountMajor <= 0")
            return .failure(error: FanDashboardError.invalidInput)
        }
        
        guard !categoryId.isEmpty else {
            print("❌ saveFanActivity failed: categoryId is empty")
            return .failure(error: FanDashboardError.invalidInput)
        }
        
        print("🔐 Checking authentication...")
        print("   - AuthenticationService.shared.currentUser: \(AuthenticationService.shared.currentUser?.email ?? "nil")")
        print("   - isAuthenticated: \(AuthenticationService.shared.isAuthenticated)")
        
        // Get authenticated user or create test user for MVP
        let user: AuthenticationService.AuthUser
        if let authUser = AuthenticationService.shared.currentUser {
            user = authUser
        } else {
            // MVP: Create temporary test user for development
            print("⚠️ No authenticated user found, using test user for MVP")
            user = AuthenticationService.AuthUser(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(),
                email: "test@piggyapp.com",
                name: "MVP Tester",
                monthlyBudget: 500.0,
                createdAt: Date()
            )
        }
        
        print("✅ Authentication passed, user ID: \(user.id)")
        
        // For MVP: Try database save, but fall back to local-only if authentication fails
        let newActivity: DatabaseFanActivity

        do {
            print("🗄️ Attempting to save to database...")
            newActivity = try await supabaseService.databaseService.createFanActivity(
                userId: user.id,
                amountMajor: amountMajor,
                categoryId: categoryId,
                categoryTitle: categoryTitle,
                idolId: idolId,
                note: note
            )
            print("✅ Database save successful, activity ID: \(newActivity.id)")
        } catch {
            print("⚠️ Database save failed, creating local activity for MVP: \(error.localizedDescription)")

            // Create local activity for MVP when database is unavailable
            newActivity = DatabaseFanActivity(
                id: UUID(),
                userId: user.id,
                artistId: idolId,
                activityType: "purchase",
                title: categoryTitle,
                description: note,
                amount: amountMajor,
                metadata: nil,
                createdAt: ISO8601DateFormatter().string(from: Date())
            )
            print("✅ Local activity created for MVP: \(newActivity.id)")
        }

        // Optimistic update - add to current activities
        if let currentData = dashboardData {
            let fanActivity = FanActivity(
                id: newActivity.id,
                artistName: nil, // Will be filled from idol lookup
                activityType: .purchase,
                title: categoryTitle,
                description: note,
                amount: amountMajor,
                createdAt: Date(),
                fanCategory: nil // TODO: Map categoryId to FanCategory
            )

            var updatedData = currentData
            var updatedRecentActivity = updatedData.recentActivity
            updatedRecentActivity.insert(fanActivity, at: 0)
            updatedData = FanDashboardData(
                user: updatedData.user,
                fanArtists: updatedData.fanArtists,
                aiTip: updatedData.aiTip,
                recentActivity: updatedRecentActivity,
                totalMonthlyBudget: updatedData.totalMonthlyBudget,
                totalMonthSpent: updatedData.totalMonthSpent,
                upcomingEvents: updatedData.upcomingEvents,
                recentTransactions: updatedData.recentTransactions,
                insights: updatedData.insights,
                monthSummary: updatedData.monthSummary
            )
            dashboardData = updatedData
        }

        // Track fan activity added event
        AIInsightAnalyticsService.shared.logFanActivityAdded(
            category: categoryTitle,
            costUsd: amountMajor,
            artist: "Unknown", // We don't have artist name here, could be enhanced
            wasAIRecommended: false
        )

        // Refresh data and compute insight
        await loadDashboardData()
        let insight = await computeInsight()

        return .success(insight: insight)
    }
    
    private func computeInsight() async -> String {
        guard let data = dashboardData else {
            let message = "✅ Activity saved successfully!"
            insightMessage = message
            return message
        }
        
        // Get last 30 days activities for calculation
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentActivities = data.recentActivity.filter { $0.createdAt >= thirtyDaysAgo }
        
        guard !recentActivities.isEmpty else {
            let message = "✅ Great start! Keep tracking your fan activities."
            insightMessage = message
            return message
        }
        
        // Calculate total spending
        let totalSpent = recentActivities.compactMap { $0.amount }.reduce(0, +)
        
        // Calculate actual spending by category
        var categoryTotals: [String: Double] = [:]
        for activity in recentActivities {
            let categoryKey = getPriorityChartCategoryKey(from: activity)
            categoryTotals[categoryKey, default: 0] += activity.amount ?? 0
        }
        
        // Calculate actual shares
        var actualShares: [String: Double] = [:]
        for (category, total) in categoryTotals {
            actualShares[category] = total / totalSpent
        }
        
        // Target shares based on priority (High 50%, Medium 30%, Low 20%)
        let targetShares = ["high": 0.50, "medium": 0.30, "low": 0.20]
        
        // Calculate deltas and find insights
        var maxOverCategory: String?
        var maxOverDelta: Double = 0
        let topPriorityCategory: String = "high"
        var topPriorityDelta: Double = 0
        
        for (priority, targetShare) in targetShares {
            let actualShare = actualShares[priority] ?? 0
            let delta = actualShare - targetShare
            
            if delta >= 0.15 && delta > maxOverDelta {
                maxOverDelta = delta
                maxOverCategory = priority
            }
            
            if priority == "high" {
                topPriorityDelta = delta
            }
        }
        
        // Generate insight based on rules
        let message: String
        if let overCategory = maxOverCategory {
            let categoryName = getCategoryDisplayName(overCategory)
            message = "⚠️ You're leaning into \(categoryName) (+15% vs plan). Consider shifting toward \(getCategoryDisplayName(topPriorityCategory))."
        } else if topPriorityDelta <= -0.10 {
            message = "💡 Your \(getCategoryDisplayName(topPriorityCategory)) is under-loved (-10% vs plan). Saving for that concert?"
        } else {
            message = "✅ Nicely aligned with your plan this month."
        }
        
        insightMessage = message
        return message
    }
    
    private func getPriorityChartCategoryKey(from activity: FanActivity) -> String {
        // Use the actual fanCategory if available, otherwise fall back to title parsing
        if let fanCategory = activity.fanCategory {
            return fanCategory.priorityChartCategoryId
        }
        
        // Legacy fallback for activities without fanCategory
        return getCategoryKeyFromTitle(activity.title)
    }
    
    private func getCategoryKeyFromTitle(_ title: String) -> String {
        // Legacy mapping - used for activities that don't have fanCategory set
        let lowerTitle = title.lowercased()
        
        if lowerTitle.contains("concert") || lowerTitle.contains("show") || lowerTitle.contains("ticket") {
            return "concerts"
        } else if lowerTitle.contains("album") || lowerTitle.contains("photocard") {
            return "albums"
        } else if lowerTitle.contains("merch") || lowerTitle.contains("merchandise") {
            return "merch"
        } else if lowerTitle.contains("event") || lowerTitle.contains("fanmeet") {
            return "events"
        } else if lowerTitle.contains("digital") || lowerTitle.contains("streaming") || lowerTitle.contains("subscription") {
            return "subs"
        } else {
            return "merch" // Default to merch category
        }
    }
    
    private func getCategoryDisplayName(_ priority: String) -> String {
        switch priority {
        case "high": return "Concerts"
        case "medium": return "Albums & Merch"
        case "low": return "Other Activities"
        default: return "Activities"
        }
    }
    
    // MARK: - Priority Management
    
    func updatePriorityInsights(artistId: UUID, category: FanCategory, amount: Double) async {
        // Calculate priority adjustments based on spending patterns
        let categoryId = category.priorityChartCategoryId
        
        // Update priority ranking in real-time based on user behavior
        // This will be reflected in the dashboard insights and priority chart
        print("🎯 Priority Update: \(categoryId) +$\(amount) for artist \(artistId)")
        
        // Trigger dashboard refresh to show updated priorities
        await loadDashboardData()
    }
    
    // MARK: - Purchase Management
    
    func addPurchase(_ purchase: QuickAddPurchase) async -> Bool {
        guard let artist = purchase.selectedArtist,
              let amount = Double(purchase.amount) else {
            error = .invalidInput
            return false
        }
        
        do {
            let parameters: [String: Any] = [
                "artist_id": artist.id.uuidString,
                "amount": amount,
                "category": "other", // Legacy field
                "description": purchase.description,
                "context_note": purchase.contextNote,
                "fan_category": purchase.category.rawValue,
                "is_comeback_related": purchase.isComebackRelated,
                "venue_location": purchase.venueLocation,
                "album_version": purchase.albumVersion
            ]
            
            struct AddPurchaseResponse: Codable {
                let success: Bool
                let message: String?
            }
            
            let _: AddPurchaseResponse = try await supabaseService.callFunction(
                functionName: "add-purchase",
                parameters: parameters
            )
            
            // Refresh dashboard data
            await loadDashboardData()
            return true
            
        } catch {
            print("Add purchase error: \(error)")
            self.error = .purchaseCreationFailed
            return false
        }
    }
    
    // MARK: - Goal Progress Management (REMOVED)
    // Goal functionality has been removed from the app
    
    // MARK: - Artist Management
    
    func canAddArtist() -> Bool {
        guard let dashboardData = dashboardData else { return false }
        
        // Check if user has premium subscription
        if RevenueCatManager.shared.isSubscriptionActive {
            return true
        }
        
        // Free users can have up to 3 artists
        return dashboardData.fanArtists.count < 3
    }
    
    func shouldShowPaywallForArtist() -> Bool {
        guard let dashboardData = dashboardData else { return false }
        return dashboardData.fanArtists.count >= 3 && !RevenueCatManager.shared.isSubscriptionActive
    }
    
    func getArtistLimitMessage() -> String {
        guard let dashboardData = dashboardData else { return "" }
        
        if RevenueCatManager.shared.isSubscriptionActive {
            return "Unlimited"
        }
        
        let count = dashboardData.fanArtists.count
        return "\(count)/3"
    }
    
    func shouldShowPremiumAITips() -> Bool {
        return RevenueCatManager.shared.isSubscriptionActive
    }
    
    func generateAITipBasedOnSubscription(for data: FanDashboardData) -> AITip? {
        // Premium users get advanced bias prioritization coaching
        if RevenueCatManager.shared.isSubscriptionActive {
            return generatePremiumBiasTip(for: data)
        } else {
            return generateFreeBiasTip(for: data)
        }
    }
    
    private func generatePremiumBiasTip(for data: FanDashboardData) -> AITip? {
        // Advanced bias prioritization coaching for premium users
        let topArtist = data.topBias
        // urgentGoals removed - no longer using goal functionality
        
        if let artist = topArtist, artist.spentPercentage > 80 {
            let message = "✨ Smart Strategy: You've used \(Int(artist.spentPercentage))% of what you planned to spend on \(artist.name) this month. Consider shifting focus to your #2 bias to maintain balance."
            
            return AITip(
                id: UUID(),
                message: message,
                tipType: .strategy,
                artistName: artist.name,
                isPremium: true,
                expiresAt: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
                createdAt: Date()
            )
        }
        
        return nil
    }
    
    private func generateFreeBiasTip(for data: FanDashboardData) -> AITip? {
        // Basic encouragement for free users
        let topArtist = data.topBias
        
        if let artist = topArtist {
            let messages = [
                "\(artist.name) fans are known for being smart with their money! You're doing great! 💜",
                "Your \(artist.name) dedication is showing! Keep up the smart spending! ✨",
                "\(artist.name) would be proud of how you're managing your fan spending! 🌟"
            ]
            
            let message = messages.randomElement() ?? "Keep up the great work with your fan spending plan! 💪"
            
            return AITip(
                id: UUID(),
                message: message,
                tipType: .cheer,
                artistName: artist.name,
                isPremium: false,
                expiresAt: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                createdAt: Date()
            )
        }
        
        return AITip(
            id: UUID(),
            message: "You're building healthy fan spending habits! Every smart choice counts! 🎯",
            tipType: .cheer,
            artistName: nil,
            isPremium: false,
            expiresAt: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            createdAt: Date()
        )
    }
    
    // MARK: - AI Tips Management
    
    func markAITipAsRead() async {
        guard dashboardData?.aiTip != nil else { return }
        
        // Mark tip as read in backend (would need additional endpoint)
        // For now, just update local state
        if var updatedData = dashboardData {
            updatedData = FanDashboardData(
                user: updatedData.user,
                fanArtists: updatedData.fanArtists,
                aiTip: nil, // Remove tip after reading
                recentActivity: updatedData.recentActivity,
                totalMonthlyBudget: updatedData.totalMonthlyBudget,
                totalMonthSpent: updatedData.totalMonthSpent,
                upcomingEvents: updatedData.upcomingEvents,
                recentTransactions: updatedData.recentTransactions,
                insights: updatedData.insights,
                monthSummary: updatedData.monthSummary
            )
            dashboardData = updatedData
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func convertToFanArtists(_ biasBudgetStatus: [BiasBudgetStatus]) async -> [FanArtist] {
        var fanArtists: [FanArtist] = []
        
        for status in biasBudgetStatus {
            // Get artist image URL (would come from artist data)
            let fanArtist = FanArtist(
                id: UUID(), // This should be the actual artist ID
                name: status.artistName,
                priorityRank: status.priorityRank,
                monthlyAllocation: status.monthlyAllocation,
                monthSpent: status.monthSpent,
                totalSpent: 0, // This would come from the database
                remainingBudget: status.remainingBudget,
                spentPercentage: status.spentPercentage,
                imageURL: nil, // Would fetch from artist data
                timeline: [],
                wishlistItems: [],
                priorities: []
            )
            fanArtists.append(fanArtist)
        }
        
        return fanArtists.sorted { $0.priorityRank < $1.priorityRank }
    }
    
    // convertToFanGoals method removed - no longer using goal functionality
    
    private func convertToFanActivity(_ activityData: [DatabaseFanActivity]) -> [FanActivity] {
        return activityData.compactMap { activity in
            guard let activityType = ActivityType(rawValue: activity.activityType) else {
                return nil
            }
            
            let createdAt = DateDecodingManager.decodeDate(from: activity.createdAt) ?? Date()
            
            return FanActivity(
                id: activity.id,
                artistName: nil, // Would need to join with artist data
                activityType: activityType,
                title: activity.title,
                description: activity.description,
                amount: activity.amount,
                createdAt: createdAt,
                fanCategory: nil // TODO: Load from fan_purchase table with JOIN query
            )
        }
    }
    
    private func convertToUpcomingEvents(_ eventsData: [UpcomingEvent]) -> [UpcomingEvent] {
        // Already in correct format
        return eventsData
    }

    // MARK: - Real RSS Feed Integration

    private func fetchRealUpcomingEvents() async -> [UpcomingEvent] {
        print("🔄 FanDashboardService: Fetching real events from EventService...")

        // Force refresh EventService to get latest RSS data
        await EventService.shared.refreshEvents()

        // Get events from EventService
        let kpopEvents = await EventService.shared.events

        // Convert KPopEvent to UpcomingEvent format
        var upcomingEvents: [UpcomingEvent] = []
        for event in kpopEvents.prefix(5) {
            let upcomingEvent = UpcomingEvent(
                id: UUID(),
                artistName: event.matchedArtists.first ?? "K-Pop Artist",
                eventType: convertEventCategoryToEventType(event.category),
                title: event.title,
                date: event.eventDate ?? event.publishedDate,
                daysUntil: event.eventDate != nil ? Calendar.current.dateComponents([.day], from: Date(), to: event.eventDate!).day : nil,
                isRelatedToUserGoals: true
            )
            upcomingEvents.append(upcomingEvent)
        }

        print("📰 FanDashboardService: Converted \(upcomingEvents.count) RSS events to UpcomingEvent format")
        return upcomingEvents
    }

    private func convertEventCategoryToString(_ category: EventCategory) -> String {
        switch category {
        case .concertsShows, .concerts, .concert:
            return "Concert"
        case .albumsPhotocards, .albums, .album:
            return "Album Release"
        case .comeback:
            return "Comeback"
        case .officialMerch, .merchandise, .merch:
            return "Merch"
        case .fanEvents, .events, .fanmeet:
            return "Fan Event"
        case .subscriptionsApps, .subscriptions:
            return "Subscription"
        case .collaboration:
            return "Collaboration"
        case .award:
            return "Award"
        case .social:
            return "Social Update"
        case .release:
            return "Release"
        case .livestream:
            return "Live Stream"
        case .charity:
            return "Charity Event"
        case .interview:
            return "Interview"
        case .all:
            return "All Events"
        case .concertPrep:
            return "Concert Prep"
        case .albumHunting:
            return "Album Hunting"
        case .fanmeetPrep:
            return "Fanmeet Prep"
        case .digitalContent:
            return "Digital Content"
        case .experience:
            return "Experience"
        case .photocardCollecting:
            return "Photocard Collecting"
        case .other:
            return "News"
        }
    }

    private func convertEventCategoryToEventType(_ category: EventCategory) -> EventType {
        switch category {
        case .concertsShows, .concerts, .concert, .concertPrep:
            return .concert
        case .albumsPhotocards, .albums, .album, .release, .albumHunting:
            return .albumRelease
        case .comeback:
            return .comeback
        case .officialMerch, .merchandise, .merch:
            return .merchandise
        case .fanEvents, .events, .fanmeet, .fanmeetPrep:
            return .fanmeet
        case .subscriptionsApps, .subscriptions, .digitalContent:
            return .merchandise // Map to merchandise for now
        case .collaboration, .award, .social, .livestream, .charity, .interview, .all, .experience, .photocardCollecting, .other:
            return .fanmeet // Default to fanmeet for other categories
        }
    }

    private func calculateTotalSaved(from artists: [FanArtist]) -> Double {
        // Calculate total saved by summing remaining budgets or using another metric
        return artists.reduce(0) { $0 + $1.remainingBudget }
    }
    
    // MARK: - New Helper Methods for DashboardData Properties
    
    // convertFanGoalsToGoals method removed - no longer using goal functionality
    
    
    private func convertActivityToTransactions(_ activities: [FanActivity]) -> [DashboardTransaction] {
        return activities.map { activity in
            DashboardTransaction(
                id: activity.id,
                title: activity.title,
                subtitle: activity.description,
                amount: activity.amount ?? 0.0,
                type: mapActivityTypeToTransactionType(activity.activityType),
                category: .other, // Default category
                date: activity.createdAt,
                artistName: activity.artistName
            )
        }
    }
    
    private func mapActivityTypeToTransactionType(_ activityType: ActivityType) -> TransactionType {
        switch activityType {
        case .purchase: return .expense
        // goalProgress case removed - no longer using goal functionality
        case .artistAdded, .milestoneReached: return .saving
        }
    }
    
    private func generateInsightsFromData(fanArtists: [FanArtist]) -> [Insight] {
        var insights: [Insight] = []
        
        // Check for bias priority warnings
        for artist in fanArtists where artist.spentPercentage > 80 {
            let insight = Insight(
                type: .budgetWarning,
                title: "Bias Priority Alert",
                message: "You've focused \(Int(artist.spentPercentage))% of your \(artist.name) allocation this month - consider rebalancing?",
                actionTitle: "Adjust Priorities",
                priority: artist.spentPercentage > 90 ? .high : .medium
            )
            insights.append(insight)
        }
        
        // Goal deadline checking removed - no longer using goal functionality
        
        return insights.sorted { $0.priority.sortOrder > $1.priority.sortOrder }
    }
    
    private func createMonthSummary(fanSpendTarget: Double, spent: Double) -> MonthSummary {
        // Internal variables use fan-focused terminology
        let saved = max(fanSpendTarget - spent, 0)
        let remainingFanSpend = max(fanSpendTarget - spent, 0)
        let spentPercentage = fanSpendTarget > 0 ? spent / fanSpendTarget : 0
        let isOverSpendTarget = spent > fanSpendTarget
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let month = formatter.string(from: Date())
        
        return MonthSummary(
            month: month,
            budget: fanSpendTarget,  // Legacy field name for UI compatibility
            spent: spent,
            saved: saved,
            remainingBudget: remainingFanSpend,  // Legacy field name for UI compatibility
            spentPercentage: spentPercentage,
            isOverBudget: isOverSpendTarget  // Legacy field name for UI compatibility
        )
    }
    
    // MARK: - User-Customized Dashboard Data
    
    private func createUserCustomizedDashboardData() async -> FanDashboardData {
        // Get real onboarding data from UserDefaults
        let onboardingArtists = loadOnboardingArtists()
        // onboarding goals removed - no longer using goal functionality"
        
        let userBudget = UserDefaults.standard.double(forKey: "monthlyBudget")
        let mockUser = DashboardUser(
            id: UUID(),
            name: UserDefaults.standard.string(forKey: "userName") ?? "Fan",
            totalSaved: 450.0,
            monthlyBudget: userBudget,
            totalMonthlyBudget: userBudget,
            totalMonthSpent: 0.0,
            joinedDate: Date()
        )
        
        // Convert onboarding artists to FanArtists or use mock if none selected
        let fanArtists: [FanArtist]
        if !onboardingArtists.isEmpty {
            // Simplify complex expression to avoid compiler timeout
            var tempFanArtists: [FanArtist] = []
            let allocations = [120.0, 100.0, 80.0]
            let monthSpentValues = [75.0, 60.0, 45.0]
            let totalSpentValues = [450.0, 380.0, 280.0]
            let remainingValues = [45.0, 40.0, 35.0]
            let percentageValues = [62.5, 60.0, 56.3]

            for (index, artist) in onboardingArtists.enumerated() {
                let arrayIndex = min(index, 2)
                let fanArtist = FanArtist(
                    id: artist.id,
                    name: artist.name,
                    priorityRank: index + 1,
                    monthlyAllocation: allocations[arrayIndex],
                    monthSpent: monthSpentValues[arrayIndex],
                    totalSpent: totalSpentValues[arrayIndex],
                    remainingBudget: remainingValues[arrayIndex],
                    spentPercentage: percentageValues[arrayIndex],
                    imageURL: nil,
                    timeline: [],
                    wishlistItems: [],
                    priorities: []
                )
                tempFanArtists.append(fanArtist)
            }
            fanArtists = tempFanArtists
        } else {
            // Fallback to default mock artists if no onboarding data
            fanArtists = [
                FanArtist(
                    id: UUID(),
                    name: "Your Artist",
                    priorityRank: 1,
                    monthlyAllocation: 120.0,
                    monthSpent: 75.0,
                    totalSpent: 450.0,
                    remainingBudget: 45.0,
                    spentPercentage: 62.5,
                    imageURL: nil,
                    timeline: [],
                    wishlistItems: [],
                    priorities: []
                )
            ]
        }
        
        // fanGoals conversion removed - no longer using goal functionality
        
        let totalBudget = fanArtists.reduce(0) { $0 + $1.monthlyAllocation }
        let totalSpent = fanArtists.reduce(0) { $0 + $1.monthSpent }
        
        // Fetch real events from RSS feeds for fallback data
        let upcomingEvents = await fetchRealUpcomingEvents()

        return FanDashboardData(
            user: mockUser,
            fanArtists: fanArtists,
            aiTip: nil, // Remove mock data - will be generated dynamically
            recentActivity: [], // Show empty until real data loads
            totalMonthlyBudget: totalBudget,
            totalMonthSpent: totalSpent,
            upcomingEvents: upcomingEvents,
            recentTransactions: [], // Show empty until real data loads
            insights: generateInsightsFromData(fanArtists: fanArtists),
            monthSummary: createMonthSummary(fanSpendTarget: totalBudget, spent: totalSpent)
        )
    }
    
    // MARK: - Onboarding Data Loading
    
    private func loadOnboardingArtists() -> [Artist] {
        guard let data = UserDefaults.standard.data(forKey: "onboarding_selected_artists"),
              let artists = try? JSONDecoder().decode([Artist].self, from: data) else {
            print("📝 No onboarding artists found in UserDefaults")
            return []
        }
        print("✅ Loaded \(artists.count) artists from onboarding")
        return artists
    }
    
    // loadOnboardingGoals method removed - no longer using goal functionality
    
    // MARK: - Artist Management
    
    func removeArtist(_ artistId: UUID) async -> Bool {
        do {
            struct DeleteResponse: Codable {
                let success: Bool
                let message: String
                let currentCount: Int?
            }

            let response: DeleteResponse = try await self.supabaseService.callFunction(
                functionName: "delete-fan-idol",
                parameters: [
                    "artistId": artistId.uuidString
                ]
            )

            if response.success {
                print("✅ Artist removed: \(response.message)")
                return true
            } else {
                print("❌ Failed to remove artist: \(response.message)")
                self.error = .networkError
                return false
            }
        } catch let apiError {
            print("❌ Failed to remove artist: \(apiError)")
            self.error = .networkError
            return false
        }
    }
    
    // MARK: - New Supabase SDK-based Save Method
    
    /// Save fan activity using Supabase SDK (your requested pattern)
    func saveFanActivityWithSDK(
        amount: Double,
        category: String,
        artist: String,
        note: String?
    ) async -> SaveResult {
        print("📊 FanDashboardService.saveFanActivityWithSDK called with:")
        print("   - amount: \(amount)")
        print("   - category: '\(category)'")
        print("   - artist: '\(artist)'") 
        print("   - note: '\(note ?? "nil")'")
        
        guard amount > 0 else {
            print("❌ saveFanActivityWithSDK failed: amount <= 0")
            return .failure(error: FanDashboardError.invalidInput)
        }
        
        guard !category.isEmpty else {
            print("❌ saveFanActivityWithSDK failed: category is empty")
            return .failure(error: FanDashboardError.invalidInput)
        }
        
        guard !artist.isEmpty else {
            print("❌ saveFanActivityWithSDK failed: artist is empty")
            return .failure(error: FanDashboardError.invalidInput)
        }
        
        do {
            print("🗄️ Calling SupabaseDatabaseService.createFanActivityWithSDK...")
            
            let newActivity = try await supabaseService.databaseService.createFanActivityWithSDK(
                amount: amount,
                category: category,
                artist: artist,
                note: note
            )
            print("✅ SDK-based database call successful, activity ID: \(newActivity.id)")
            
            // TODO: Add optimistic update logic similar to original method
            
            let insight = await computeInsight()
            print("✅ SDK-based save completed with insight: \(insight)")
            return .success(insight: insight)
            
        } catch {
            print("❌ SDK-based save failed: \(error)")
            return .failure(error: error)
        }
    }
    
    // MARK: - Debug Helper Functions
    
    /// Debug authentication status - call this to troubleshoot auth issues
    func debugAuthentication() async {
        print("🔧 === FanDashboardService DEBUG AUTHENTICATION ===")
        await supabaseService.databaseService.debugAuthenticationStatus()
    }
}

// MARK: - Fan Dashboard Error Types

enum FanDashboardError: LocalizedError, Identifiable {
    case loadingFailed
    case userNotFound
    case invalidInput
    case purchaseCreationFailed
    case networkError
    case unauthorized
    
    var id: String {
        switch self {
        case .loadingFailed: return "loading_failed"
        case .userNotFound: return "user_not_found"
        case .invalidInput: return "invalid_input"
        case .purchaseCreationFailed: return "purchase_creation_failed"
        case .networkError: return "network_error"
        case .unauthorized: return "unauthorized"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed:
            return "Failed to load dashboard data"
        case .userNotFound:
            return "User not found"
        case .invalidInput:
            return "Invalid input provided"
        case .purchaseCreationFailed:
            return "Failed to create purchase"
        case .networkError:
            return "Network connection error"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .loadingFailed, .networkError:
            return "Please check your internet connection and try again"
        case .userNotFound, .unauthorized:
            return "Please sign in again"
        case .invalidInput:
            return "Please check your input and try again"
        case .purchaseCreationFailed:
            return "Please try again later"
        }
    }
}

// MARK: - Extension for DatabaseAITip conversion

extension DatabaseAITip {
    func toAITip() -> AITip {
        let tipType = TipType(rawValue: self.tipType) ?? .cheer
        let createdAt = DateDecodingManager.decodeDate(from: self.createdAt) ?? Date()
        let expiresAt = self.expiresAt.flatMap { DateDecodingManager.decodeDate(from: $0) }
        
        return AITip(
            id: self.id,
            message: self.message,
            tipType: tipType,
            artistName: nil, // Would need to join with artist data
            isPremium: self.isPremium,
            expiresAt: expiresAt,
            createdAt: createdAt
        )
    }
}

// MARK: - Category Conversion Helper
private func convertDBGoalCategoryToFanCategory(_ dbCategory: DBGoalCategory) -> FanCategory {
    switch dbCategory {
    case .concert:
        return .concerts
    case .album:
        return .albums
    case .merchandise:
        return .merch
    case .experience:
        return .subscriptions
    case .fanmeet:
        return .events
    case .travel:
        return .other
    case .savings:
        return .other
    case .other:
        return .other
    }
}
