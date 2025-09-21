import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    let email: String
    let name: String
    var monthlyBudget: Double
    var currency: String
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        email: String,
        name: String,
        monthlyBudget: Double = 0.0,
        currency: String = "USD",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.monthlyBudget = monthlyBudget
        self.currency = currency
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}