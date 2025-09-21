import SwiftUI
import Foundation

// MARK: - Local Data Models
enum TimeFrame: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    
    var displayName: String {
        return self.rawValue
    }
}

struct Transaction: Identifiable {
    let id = UUID()
    let title: String
    let amount: Double
    let type: TransactionType
    let category: TransactionCategory
    let date: Date
}

struct BudgetGoal: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let emoji: String
    let currentAmount: Double
    let targetAmount: Double
    let deadline: Date?
}

struct BudgetInsight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let type: InsightType
    let actionTitle: String
}

// MARK: - Budget View Model
class BudgetViewModel: ObservableObject {
    @Published var monthlyBudget: Double = 500
    @Published var monthlySpent: Double = 320
    @Published var totalSaved: Double = 1250
    @Published var goalProgress: Double = 75
    @Published var savingsTrend: Double = 12.5
    @Published var goalsTrend: Double = 8.3
    @Published var recentTransactions: [Transaction] = []
    @Published var budgetGoals: [BudgetGoal] = []
    @Published var insights: [BudgetInsight] = []
    
    init() {
        loadSampleData()
    }
    
    func refreshData() async {
        // Simulate network call
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        loadSampleData()
    }
    
    private func loadSampleData() {
        // Sample transactions
        recentTransactions = [
            Transaction(
                title: "BTS Concert Ticket",
                amount: 150,
                type: .expense,
                category: .concert,
                date: Date().addingTimeInterval(-86400)
            ),
            Transaction(
                title: "TWICE Album",
                amount: 25,
                type: .expense,
                category: .album,
                date: Date().addingTimeInterval(-172800)
            ),
            Transaction(
                title: "Monthly Allowance",
                amount: 200,
                type: .income,
                category: .other,
                date: Date().addingTimeInterval(-259200)
            )
        ]
        
        // Sample budget goals
        budgetGoals = [
            BudgetGoal(
                title: "Korea Trip Fund",
                description: "Save for a trip to Seoul",
                emoji: "✈️",
                currentAmount: 850,
                targetAmount: 2000,
                deadline: Calendar.current.date(byAdding: .month, value: 6, to: Date())
            ),
            BudgetGoal(
                title: "Concert Emergency Fund",
                description: "For surprise concerts",
                emoji: "🎤",
                currentAmount: 400,
                targetAmount: 500,
                deadline: Calendar.current.date(byAdding: .month, value: 2, to: Date())
            )
        ]
        
        // Sample insights
        insights = [
            BudgetInsight(
                title: "Great Progress!",
                description: "You're 15% ahead of your savings goal this month",
                type: .achievement,
                actionTitle: "View"
            ),
            BudgetInsight(
                title: "Concert Alert",
                description: "BLACKPINK tour dates might be announced soon",
                type: .savingTip,
                actionTitle: "Save"
            ),
            BudgetInsight(
                title: "Budget Warning",
                description: "You've used 80% of your monthly budget",
                type: .budgetWarning,
                actionTitle: "Adjust"
            )
        ]
    }
}