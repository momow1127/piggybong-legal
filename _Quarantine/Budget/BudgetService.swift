import Foundation
import SwiftUI

@MainActor
class BudgetService: ObservableObject {
    @Published var currentBudget: Budget?
    @Published var artistAllocations: [ArtistBudgetAllocation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let databaseService: DatabaseService
    
    init(databaseService: DatabaseService = DatabaseService()) {
        self.databaseService = databaseService
    }
    
    // MARK: - Budget Operations
    
    func fetchCurrentBudget(for userId: UUID) async {
        isLoading = true
        
        do {
            // TODO: Implement Supabase query for current month budget
            await Task.sleep(nanoseconds: 500_000_000)
            
            let now = Date()
            let calendar = Calendar.current
            let month = calendar.component(.month, from: now)
            let year = calendar.component(.year, from: now)
            
            // Mock current budget
            self.currentBudget = Budget(
                userId: userId,
                month: month,
                year: year,
                totalBudget: 300.0,
                spent: 145.99
            )
            
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    func updateBudget(totalBudget: Double, for userId: UUID) async {
        guard var budget = currentBudget else { return }
        
        budget.totalBudget = totalBudget
        budget.updatedAt = Date()
        
        // TODO: Implement Supabase update
        self.currentBudget = budget
    }
    
    func addPurchaseToBudget(_ purchase: Purchase) async {
        guard var budget = currentBudget else { return }
        
        budget.spent += purchase.amount
        budget.updatedAt = Date()
        
        // TODO: Implement Supabase update
        self.currentBudget = budget
        
        // Update artist allocation if exists
        if let allocationIndex = artistAllocations.firstIndex(where: { $0.artistId == purchase.artistId }) {
            artistAllocations[allocationIndex].spentAmount += purchase.amount
            artistAllocations[allocationIndex].updatedAt = Date()
        }
    }
    
    // MARK: - Artist Allocation Operations
    
    func fetchArtistAllocations(for budgetId: UUID) async {
        // TODO: Implement Supabase query
        // Mock data for now
        if let budget = currentBudget, !databaseService.artists.isEmpty {
            let totalArtists = databaseService.artists.count
            let allocationPerArtist = budget.totalBudget / Double(totalArtists)
            
            self.artistAllocations = databaseService.artists.map { artist in
                ArtistBudgetAllocation(
                    budgetId: budgetId,
                    artistId: artist.id,
                    allocatedAmount: allocationPerArtist,
                    spentAmount: Double.random(in: 0...(allocationPerArtist * 0.8))
                )
            }
        }
    }
    
    func updateArtistAllocation(artistId: UUID, amount: Double) async {
        if let index = artistAllocations.firstIndex(where: { $0.artistId == artistId }) {
            artistAllocations[index].allocatedAmount = amount
            artistAllocations[index].updatedAt = Date()
            
            // TODO: Implement Supabase update
        }
    }
    
    // MARK: - Analytics
    
    func getSpendingByCategory() -> [PurchaseCategory: Double] {
        var categorySpending: [PurchaseCategory: Double] = [:]
        
        for purchase in databaseService.purchases {
            categorySpending[purchase.category, default: 0] += purchase.amount
        }
        
        return categorySpending
    }
    
    func getTopArtists(limit: Int = 5) -> [(Artist, Double)] {
        let artistSpending = Dictionary(grouping: databaseService.purchases) { $0.artistId }
            .mapValues { purchases in
                purchases.reduce(0) { $0 + $1.amount }
            }
        
        let sortedArtists = artistSpending.sorted { $0.value > $1.value }
        
        return Array(sortedArtists.prefix(limit).compactMap { (artistId, amount) in
            guard let artist = databaseService.artists.first(where: { $0.id == artistId }) else { return nil }
            return (artist, amount)
        })
    }
}