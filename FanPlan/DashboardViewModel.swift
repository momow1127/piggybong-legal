import SwiftUI
import Combine
import Foundation

@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var dashboardData: FanDashboardData?
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Services
    private let supabaseService = SupabaseService.shared
    private let userSession = UserSession.shared
    
    private var currentUserId: UUID {
        return userSession.currentUserId
    }
    
    // MARK: - Computed Properties
    var activeGoalsCount: Int {
        0 // Goal functionality removed
    }
    
    // primaryGoal removed - goal functionality no longer supported
    
    // secondaryGoals removed - goal functionality no longer supported
    
    var totalSaved: Double {
        dashboardData?.user.totalSaved ?? 0
    }
    
    var totalGoals: Int {
        0 // Goal functionality removed
    }
    
    var hasActiveGoals: Bool {
        false // Goal functionality removed
    }
    
    var hasRecentTransactions: Bool {
        !(dashboardData?.recentTransactions.isEmpty ?? true)
    }
    
    var highPriorityInsights: [Insight] {
        dashboardData?.insights.filter { $0.priority == .high } ?? []
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        loadDashboardData()
    }
    
    // MARK: - Public Methods
    func loadDashboardData() {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        showError = false
        
        Task {
            do {
                // Load real data from Supabase
                let dashboardData = try await loadRealDashboardData()
                self.dashboardData = dashboardData
                self.isLoading = false
                
            } catch {
                self.handleError(error)
            }
        }
    }
    
    func refreshData() {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        
        Task {
            do {
                // Load fresh data from Supabase
                let dashboardData = try await loadRealDashboardData()
                self.dashboardData = dashboardData
                self.isRefreshing = false
                
            } catch {
                self.handleError(error)
            }
        }
    }
    
    // addMoneyToGoal method removed - goal functionality no longer supported
    /*
    func addMoneyToGoal(_ goal: Goal, amount: Double) {
        Task {
            do {
                // Update goal progress in Supabase
                try await supabaseService.updateGoalProgress(goalId: goal.id, additionalAmount: amount)
                
                // Refresh dashboard data to reflect changes
                refreshData()
                
                // Trigger celebration if goal will be completed
                let newAmount = goal.currentAmount + amount
                if newAmount >= goal.targetAmount {
                    triggerGoalCompletionCelebration(goal: goal)
                }
                
            } catch {
                self.handleError(error)
            }
        }
    }
    */
    
    func logExpense(title: String, amount: Double, category: TransactionCategory, artistName: String? = nil) {
        Task {
            do {
                // Find artist ID if artistName is provided
                var artistId: UUID? = nil
                if let artistName = artistName {
                    let artists = try await supabaseService.searchArtists(query: artistName)
                    artistId = artists.first?.id
                }
                
                // Convert category to database category
                let dbCategory = convertToDatabaseCategory(category)
                
                // Create purchase in Supabase
                if let artistId = artistId {
                    _ = try await supabaseService.createPurchase(
                        userId: currentUserId,
                        artistId: artistId,
                        amount: amount,
                        category: dbCategory,
                        description: title
                    )
                }
                
                // Update budget spent for current month
                let currentDate = Date()
                let month = Calendar.current.component(.month, from: currentDate)
                let year = Calendar.current.component(.year, from: currentDate)
                try await supabaseService.updateBudgetSpent(
                    userId: currentUserId,
                    month: month,
                    year: year,
                    additionalAmount: amount
                )
                
                // Refresh dashboard data
                refreshData()
                
            } catch {
                self.handleError(error)
            }
        }
    }
    
    func addSavings(amount: Double) {
        Task {
            // For now, we'll just refresh the data
            // In a full implementation, you might want to track savings separately
            refreshData()
        }
    }
    
    func dismissInsight(_ insight: Insight) {
        guard var currentData = dashboardData else { return }
        currentData.insights.removeAll { $0.id == insight.id }
        self.dashboardData = currentData
    }
    
    func retryLoadData() {
        isLoading = false
        isRefreshing = false
        loadDashboardData()
    }
    
    /// Setup for competition demo - creates user with sample data
    func setupCompetitionDemo() {
        Task {
            do {
                // Create demo user for competition judges
                _ = try await userSession.createDemoUser(
                    name: "Competition Judge",
                    monthlyBudget: 500.0
                )
                
                // Goal creation removed - goal functionality no longer supported
                // Just load the dashboard data for demo
                loadDashboardData()
                
                print("✅ Competition demo setup complete")
            } catch {
                print("❌ Competition demo setup failed: \(error)")
                // Still load dashboard, will fallback to mock data
                loadDashboardData()
            }
        }
    }
    
    // MARK: - Private Methods
    private func handleError(_ error: Error) {
        isLoading = false
        isRefreshing = false
        
        // Convert Supabase errors to user-friendly messages
        if let supabaseError = error as? SupabaseService.SupabaseError {
            switch supabaseError {
            case .networkError:
                errorMessage = "Network connection failed. Please check your internet connection."
            case .unauthorized:
                errorMessage = "Authentication required. Please log in again."
            case .notFound:
                errorMessage = "Data not found. Please try refreshing."
            case .dataParsingError:
                errorMessage = "Failed to load data. Please try again."
            case .serverError(let message):
                errorMessage = "Server error: \(message)"
            default:
                errorMessage = "Something went wrong. Please try again."
            }
        } else if let dashboardError = error as? DashboardError {
            errorMessage = dashboardError.localizedDescription
        } else {
            errorMessage = "Something went wrong. Please try again."
        }
        
        showError = true
    }
    
    /// Load real dashboard data from Supabase
    private func loadRealDashboardData() async throws -> FanDashboardData {
        // Test connection first
        let isConnected = try await supabaseService.checkSupabaseConnectivity()
        if !isConnected {
            // Throw error if no connection - force real data only
            throw DashboardError.networkError
        }
        
        // Load data concurrently - real data only
        async let userTask = loadUserWithFallback()
        async let transactionsTask = loadTransactionsWithFallback()
        async let budgetTask = loadBudgetWithFallback()
        async let insightsTask = loadInsightsWithFallback()
        
        // Execute all requests concurrently
        let (user, transactions, budget, insights) = try await (
            userTask,
            transactionsTask,
            budgetTask,
            insightsTask
        )
        
        // Create month summary from budget data
        let monthSummary = createMonthSummary(from: budget, user: user)
        
        return FanDashboardData(
            user: user,
            fanArtists: [], // Will be enhanced in future versions
            aiTip: nil, // Will be enhanced in future versions
            recentActivity: [], // Will be enhanced in future versions
            totalMonthlyBudget: user.monthlyBudget,
            totalMonthSpent: budget?.spent ?? 0.0,
            upcomingEvents: [], // Will be enhanced in future versions
            recentTransactions: transactions,
            insights: insights,
            monthSummary: monthSummary
        )
    }
    
    
    // MARK: - Fallback Loading Methods
    
    private func loadUserWithFallback() async throws -> DashboardUser {
        let databaseUser = try await supabaseService.getUser(id: currentUserId)
        return databaseUser.toDashboardUser()
    }
    
    // loadGoalsWithFallback method removed - goal functionality no longer supported
    
    private func loadTransactionsWithFallback() async throws -> [DashboardTransaction] {
        let transactions = try await supabaseService.getPurchases(for: currentUserId, limit: 10)
        return transactions
    }
    
    private func loadBudgetWithFallback() async throws -> DatabaseBudget? {
        let currentDate = Date()
        let month = Calendar.current.component(.month, from: currentDate)
        let year = Calendar.current.component(.year, from: currentDate)
        
        return try await supabaseService.getBudget(userId: currentUserId, month: month, year: year)
    }
    
    private func loadInsightsWithFallback() async throws -> [Insight] {
        let insights = try await supabaseService.getInsights(for: currentUserId)
        return insights
    }
    
    private func createMonthSummary(from budget: DatabaseBudget?, user: DashboardUser) -> MonthSummary {
        let currentDate = Date()
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"
        let monthName = monthFormatter.string(from: currentDate)
        
        let totalBudget = budget?.totalBudget ?? user.monthlyBudget
        let spent = budget?.spent ?? 0.0
        let spentPercentage = totalBudget > 0 ? spent / totalBudget : 0.0
        
        return MonthSummary(
            month: monthName,
            budget: totalBudget,
            spent: spent,
            saved: 0.0, // TODO: Calculate actual savings
            remainingBudget: totalBudget - spent,
            spentPercentage: spentPercentage,
            isOverBudget: spent > totalBudget
        )
    }
    
    private func convertToDatabaseCategory(_ category: TransactionCategory) -> String {
        switch category {
        case .concert: return "concert"
        case .album: return "album"
        case .merchandise: return "merchandise"
        case .subscription: return "digital"
        case .food: return "food"
        case .transport: return "transport"
        case .saving: return "saving"
        case .other: return "other"
        }
    }
    
    /// Get connection status for debugging
    func getConnectionStatus() async -> String {
        do {
            let isConnected = try await supabaseService.checkSupabaseConnectivity()
            if isConnected {
                return "✅ Connected to Supabase - Real data loading"
            } else {
                return "⚠️ Supabase unavailable - Using enhanced mock data"
            }
        } catch {
            return "❌ Supabase connection failed: \(error.localizedDescription)"
        }
    }
    
    /// Force refresh with connection test
    func forceRefreshWithStatus() {
        Task {
            let status = await getConnectionStatus()
            print("🔄 Force refresh - \(status)")
            refreshData()
        }
    }
    
    // triggerGoalCompletionCelebration method removed - goal functionality no longer supported
    /*
    private func triggerGoalCompletionCelebration(goal: Goal) {
        // Add celebration insight for immediate UI feedback
        guard var currentData = dashboardData else { return }
        
        let celebrationInsight = Insight(
            type: .achievement,
            title: "🎉 Goal Completed!",
            message: "Congratulations! You've reached your \(goal.name) goal! Time to celebrate!",
            actionTitle: "Share Achievement", 
            priority: .high,
            expiresAt: Calendar.current.date(byAdding: .day, value: 1, to: Date())
        )
        
        currentData.insights.insert(celebrationInsight, at: 0)
        self.dashboardData = currentData
        
        // TODO: Add haptic feedback and celebration animation
        print("🎊 Goal celebration triggered for: \(goal.name)")
    }
    */
}

// MARK: - Dashboard Error
enum DashboardError: LocalizedError {
    case networkError
    case dataParsingError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection failed. Please check your internet connection."
        case .dataParsingError:
            return "Failed to load dashboard data. Please try again."
        case .unknownError:
            return "An unexpected error occurred. Please try again."
        }
    }
}