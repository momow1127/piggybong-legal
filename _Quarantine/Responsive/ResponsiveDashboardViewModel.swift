import SwiftUI
import Combine
import Foundation

// MARK: - Responsive Dashboard ViewModel
@MainActor
class ResponsiveDashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var monthlySpent: Double = 0
    @Published var monthlyBudget: Double = 300
    @Published var totalSaved: Double = 0
    @Published var savingsGrowth: Double = 0
    @Published var spendingProgress: Double = 0
    @Published var activeGoalsCount: Int = 0
    @Published var completedGoalsCount: Int = 0
    
    // Chart data
    @Published var spendingData: [ChartDataPoint] = []
    @Published var savingsData: [ChartDataPoint] = []
    @Published var goalsProgressData: [ChartDataPoint] = []
    @Published var categoryData: [ChartDataPoint] = []
    @Published var goalsData: [ChartDataPoint] = []
    
    // Dashboard items
    @Published var topGoals: [DashboardGoal] = []
    @Published var recentActivities: [DashboardActivity] = []
    @Published var insights: [DashboardInsight] = []
    
    // Loading states
    @Published var isLoading: Bool = false
    @Published var lastUpdated: Date?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let databaseService = DatabaseService()
    
    // MARK: - Initialization
    init() {
        setupReactiveUpdates()
    }
    
    // MARK: - Public Methods
    func loadDashboardData() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            async let spendingTask = loadSpendingData()
            async let savingsTask = loadSavingsData()
            async let goalsTask = loadGoalsData()
            async let categoryTask = loadCategoryData()
            async let activitiesTask = loadRecentActivities()
            async let insightsTask = generateInsights()
            
            // Wait for all tasks to complete
            _ = await (spendingTask, savingsTask, goalsTask, categoryTask, activitiesTask, insightsTask)
            
            lastUpdated = Date()
            calculateDerivedMetrics()
        }
    }
    
    func updateTimeRange(_ timeRange: TimeRange) {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            // Reload data for new time range
            await loadSpendingData(for: timeRange)
            await loadSavingsData(for: timeRange)
            await loadGoalsProgressData(for: timeRange)
            
            calculateDerivedMetrics()
        }
    }
    
    func refreshData() {
        loadDashboardData()
    }
    
    // MARK: - Private Methods - Data Loading
    
    private func loadSpendingData(for timeRange: TimeRange = .month) async {
        do {
            // Generate mock data based on time range
            let dataPoints = generateMockSpendingData(for: timeRange)
            spendingData = dataPoints
            monthlySpent = dataPoints.reduce(0) { $0 + $1.value }
            spendingProgress = monthlySpent / monthlyBudget
        } catch {
            print("Error loading spending data: \\(error)")
            // Use fallback data
            spendingData = generateFallbackSpendingData()
        }
    }
    
    private func loadSavingsData(for timeRange: TimeRange = .month) async {
        do {
            let dataPoints = generateMockSavingsData(for: timeRange)
            savingsData = dataPoints
            totalSaved = dataPoints.last?.value ?? 0
            
            // Calculate growth percentage
            if let first = dataPoints.first, let last = dataPoints.last, first.value > 0 {
                savingsGrowth = ((last.value - first.value) / first.value) * 100
            }
        } catch {
            print("Error loading savings data: \\(error)")
            savingsData = generateFallbackSavingsData()
        }
    }
    
    private func loadGoalsData() async {
        do {
            let goals = generateMockGoalsData()
            topGoals = goals
            activeGoalsCount = goals.filter { $0.progress < 100 }.count
            completedGoalsCount = goals.filter { $0.progress >= 100 }.count
            
            // Convert to chart data
            goalsData = goals.map { goal in
                ChartDataPoint(
                    date: Date(),
                    value: goal.progress,
                    label: goal.title
                )
            }
        } catch {
            print("Error loading goals data: \\(error)")
            topGoals = generateFallbackGoalsData()
        }
    }
    
    private func loadGoalsProgressData(for timeRange: TimeRange) async {
        // Generate mock progress over time data
        goalsProgressData = generateMockGoalsProgressData(for: timeRange)
    }
    
    private func loadCategoryData() async {
        do {
            let categories = [
                ("Concert Tickets", 45.0, Color.purple),
                ("Albums", 25.0, Color.blue),
                ("Merchandise", 20.0, Color.pink),
                ("Digital Content", 10.0, Color.orange)
            ]
            
            categoryData = categories.map { name, percentage, color in
                ChartDataPoint(
                    date: Date(),
                    value: percentage,
                    label: name
                )
            }
        } catch {
            print("Error loading category data")
            categoryData = generateFallbackCategoryData()
        }
    }
    
    private func loadRecentActivities() async {
        recentActivities = [
            DashboardActivity(
                title: "Album Pre-order",
                subtitle: "NewJeans - Get Up",
                amount: -28.0,
                relativeTime: "2 hours ago",
                color: .blue,
                icon: "opticaldisc"
            ),
            DashboardActivity(
                title: "Concert Savings",
                subtitle: "Added to BTS fund",
                amount: 50.0,
                relativeTime: "1 day ago",
                color: .green,
                icon: "arrow.up.circle"
            ),
            DashboardActivity(
                title: "Goal Completed",
                subtitle: "TWICE Merch Collection",
                amount: nil,
                relativeTime: "3 days ago",
                color: .purple,
                icon: "checkmark.circle"
            ),
            DashboardActivity(
                title: "Streaming Subscription",
                subtitle: "Monthly Spotify Premium",
                amount: -9.99,
                relativeTime: "1 week ago",
                color: .orange,
                icon: "music.note"
            )
        ]
    }
    
    private func generateInsights() async {
        insights = [
            DashboardInsight(
                title: "Spending Alert",
                message: "You're 80% through your monthly budget with 10 days left",
                actionTitle: "Adjust Budget",
                color: .orange,
                icon: "exclamationmark.triangle"
            ),
            DashboardInsight(
                title: "Goal Progress",
                message: "You're ahead of schedule on your BTS concert goal!",
                actionTitle: "Add More",
                color: .green,
                icon: "target"
            ),
            DashboardInsight(
                title: "Smart Tip",
                message: "Skip coffee twice this week to save $12 for your album fund",
                actionTitle: "Set Reminder",
                color: .blue,
                icon: "lightbulb"
            )
        ]
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockSpendingData(for timeRange: TimeRange) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var dataPoints: [ChartDataPoint] = []
        
        let (startDate, interval, count) = timeRangeParameters(for: timeRange)
        
        for i in 0..<count {
            let date = calendar.date(byAdding: interval, value: i, to: startDate) ?? now
            let baseAmount = Double.random(in: 20...100)
            let weekdayMultiplier = calendar.isDateInWeekend(date) ? 1.5 : 1.0
            let amount = baseAmount * weekdayMultiplier
            
            dataPoints.append(ChartDataPoint(
                date: date,
                value: amount,
                label: "\\(Int(amount))"
            ))\n        }
        
        return dataPoints.sorted { $0.date < $1.date }
    }
    
    private func generateMockSavingsData(for timeRange: TimeRange) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var dataPoints: [ChartDataPoint] = []
        var cumulativeAmount = 250.0
        
        let (startDate, interval, count) = timeRangeParameters(for: timeRange)
        
        for i in 0..<count {
            let date = calendar.date(byAdding: interval, value: i, to: startDate) ?? now
            let growth = Double.random(in: 10...50)
            cumulativeAmount += growth
            
            dataPoints.append(ChartDataPoint(
                date: date,
                value: cumulativeAmount,
                label: "\\(Int(cumulativeAmount))"
            ))
        }
        
        return dataPoints.sorted { $0.date < $1.date }
    }
    
    private func generateMockGoalsProgressData(for timeRange: TimeRange) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var dataPoints: [ChartDataPoint] = []
        var progress = 25.0
        
        let (startDate, interval, count) = timeRangeParameters(for: timeRange)
        
        for i in 0..<count {
            let date = calendar.date(byAdding: interval, value: i, to: startDate) ?? now
            progress += Double.random(in: 2...8)
            progress = min(progress, 100)
            
            dataPoints.append(ChartDataPoint(
                date: date,
                value: progress,
                label: "\\(Int(progress))%"
            ))
        }
        
        return dataPoints.sorted { $0.date < $1.date }
    }
    
    private func generateMockGoalsData() -> [DashboardGoal] {
        return [
            DashboardGoal(
                title: "BTS World Tour",
                currentAmount: 420,
                targetAmount: 500,
                progress: 84,
                color: .purple,
                icon: "music.note"
            ),
            DashboardGoal(
                title: "BLACKPINK Merch",
                currentAmount: 85,
                targetAmount: 150,
                progress: 57,
                color: .pink,
                icon: "tshirt"
            ),
            DashboardGoal(
                title: "Album Collection",
                currentAmount: 120,
                targetAmount: 200,
                progress: 60,
                color: .blue,
                icon: "opticaldisc"
            ),
            DashboardGoal(
                title: "Fan Meeting",
                currentAmount: 200,
                targetAmount: 200,
                progress: 100,
                color: .green,
                icon: "heart"
            )
        ]
    }
    
    // MARK: - Fallback Data
    
    private func generateFallbackSpendingData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<7).map { i in
            let date = calendar.date(byAdding: .day, value: i - 6, to: now) ?? now
            return ChartDataPoint(
                date: date,
                value: Double.random(in: 20...80),
                label: "Fallback"
            )
        }
    }
    
    private func generateFallbackSavingsData() -> [ChartDataPoint] {
        return [
            ChartDataPoint(date: Date(), value: 250, label: "Fallback")
        ]
    }
    
    private func generateFallbackGoalsData() -> [DashboardGoal] {
        return [
            DashboardGoal(
                title: "Sample Goal",
                currentAmount: 50,
                targetAmount: 100,
                progress: 50,
                color: .blue,
                icon: "target"
            )
        ]
    }
    
    private func generateFallbackCategoryData() -> [ChartDataPoint] {
        return [
            ChartDataPoint(date: Date(), value: 50, label: "Other"),
            ChartDataPoint(date: Date(), value: 50, label: "Misc")
        ]
    }
    
    // MARK: - Helper Methods
    
    private func timeRangeParameters(for timeRange: TimeRange) -> (startDate: Date, interval: Calendar.Component, count: Int) {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeRange {
        case .week:
            let startDate = calendar.date(byAdding: .day, value: -6, to: now) ?? now
            return (startDate, .day, 7)
        case .month:
            let startDate = calendar.date(byAdding: .day, value: -29, to: now) ?? now
            return (startDate, .day, 30)
        case .threeMonths:
            let startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            return (startDate, .weekOfYear, 12)
        case .year:
            let startDate = calendar.date(byAdding: .month, value: -11, to: now) ?? now
            return (startDate, .month, 12)
        }
    }
    
    private func calculateDerivedMetrics() {
        // Update computed metrics based on loaded data
        spendingProgress = monthlySpent / monthlyBudget
    }
    
    private func setupReactiveUpdates() {
        // Set up real-time updates if needed
        Timer.publish(every: 300, on: .main, in: .common) // Update every 5 minutes
            .autoconnect()
            .sink { [weak self] _ in
                // Could trigger a refresh here if needed
            }
            .store(in: &cancellables)
    }
}

// MARK: - Extensions

extension ResponsiveDashboardViewModel {
    // Convenience methods for accessing data
    var isOverBudget: Bool {
        spendingProgress > 1.0
    }
    
    var budgetRemaining: Double {
        max(monthlyBudget - monthlySpent, 0)
    }
    
    var topSpendingCategory: String {
        categoryData.max(by: { $0.value < $1.value })?.label ?? "N/A"
    }
    
    var averageDailySpending: Double {
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
        return monthlySpent / Double(daysInMonth)
    }
}