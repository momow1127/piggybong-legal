import Foundation

struct Budget: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let month: Int
    let year: Int
    let totalBudget: Double
    var spent: Double
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        month: Int,
        year: Int,
        totalBudget: Double,
        spent: Double = 0.0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.month = month
        self.year = year
        self.totalBudget = totalBudget
        self.spent = spent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var remaining: Double {
        return totalBudget - spent
    }
    
    var progress: Double {
        guard totalBudget > 0 else { return 0 }
        return min(spent / totalBudget, 1.0)
    }
    
    var isOverBudget: Bool {
        return spent > totalBudget
    }
    
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let date = Calendar.current.date(from: DateComponents(year: year, month: month)) ?? Date()
        return formatter.string(from: date)
    }
}

struct ArtistBudgetAllocation: Identifiable, Codable {
    let id: UUID
    let budgetId: UUID
    let artistId: UUID
    let allocatedAmount: Double
    var spentAmount: Double
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        budgetId: UUID,
        artistId: UUID,
        allocatedAmount: Double,
        spentAmount: Double = 0.0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.budgetId = budgetId
        self.artistId = artistId
        self.allocatedAmount = allocatedAmount
        self.spentAmount = spentAmount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var remaining: Double {
        return allocatedAmount - spentAmount
    }
    
    var progress: Double {
        guard allocatedAmount > 0 else { return 0 }
        return min(spentAmount / allocatedAmount, 1.0)
    }
}