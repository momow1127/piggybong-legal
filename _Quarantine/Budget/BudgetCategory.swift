import Foundation

struct BudgetCategory: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let emoji: String
    let averagePrice: Double
    
    static let defaultCategories: [BudgetCategory] = [
        BudgetCategory(title: "Albums", emoji: "💿", averagePrice: 25),
        BudgetCategory(title: "Concert Tickets", emoji: "🎟️", averagePrice: 150),
        BudgetCategory(title: "Merchandise", emoji: "👕", averagePrice: 35),
        BudgetCategory(title: "Fan Meetings", emoji: "🤝", averagePrice: 80),
        BudgetCategory(title: "Subscriptions", emoji: "📱", averagePrice: 15),
        BudgetCategory(title: "Collectibles", emoji: "💎", averagePrice: 45)
    ]
}