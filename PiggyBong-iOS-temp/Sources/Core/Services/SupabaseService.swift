import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()
    
    private let client: SupabaseClient
    
    private init() {
        // TODO: Replace with your actual Supabase URL and anon key
        let supabaseURL = URL(string: "https://your-project-id.supabase.co")!
        let supabaseKey = "your-anon-key"
        
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }
    
    var auth: AuthClient {
        return client.auth
    }
    
    var database: DatabaseClient {
        return client.database
    }
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String) async throws -> AuthResponse {
        return try await client.auth.signUp(email: email, password: password)
    }
    
    func signIn(email: String, password: String) async throws -> AuthResponse {
        return try await client.auth.signInWithPassword(email: email, password: password)
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    func getCurrentUser() async throws -> User? {
        return try await client.auth.user()
    }
    
    // MARK: - Database Operations
    
    // Users
    func createUser(_ user: User) async throws {
        try await client.database
            .from("users")
            .insert(user)
            .execute()
    }
    
    func updateUser(_ user: User) async throws {
        try await client.database
            .from("users")
            .update(user)
            .eq("id", value: user.id)
            .execute()
    }
    
    func getUser(id: UUID) async throws -> User? {
        let response: [User] = try await client.database
            .from("users")
            .select()
            .eq("id", value: id)
            .limit(1)
            .execute()
            .value
        
        return response.first
    }
    
    // Artists
    func getArtists() async throws -> [Artist] {
        let response: [Artist] = try await client.database
            .from("artists")
            .select()
            .order("name")
            .execute()
            .value
        
        return response
    }
    
    func createArtist(_ artist: Artist) async throws {
        try await client.database
            .from("artists")
            .insert(artist)
            .execute()
    }
    
    func searchArtists(query: String) async throws -> [Artist] {
        let response: [Artist] = try await client.database
            .from("artists")
            .select()
            .or("name.ilike.%\(query)%,group.ilike.%\(query)%")
            .order("name")
            .execute()
            .value
        
        return response
    }
    
    // Purchases
    func getPurchases(for userId: UUID) async throws -> [Purchase] {
        let response: [Purchase] = try await client.database
            .from("purchases")
            .select()
            .eq("user_id", value: userId)
            .order("purchase_date", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    func createPurchase(_ purchase: Purchase) async throws {
        try await client.database
            .from("purchases")
            .insert(purchase)
            .execute()
    }
    
    func updatePurchase(_ purchase: Purchase) async throws {
        try await client.database
            .from("purchases")
            .update(purchase)
            .eq("id", value: purchase.id)
            .execute()
    }
    
    func deletePurchase(id: UUID) async throws {
        try await client.database
            .from("purchases")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // Budgets
    func getBudget(userId: UUID, month: Int, year: Int) async throws -> Budget? {
        let response: [Budget] = try await client.database
            .from("budgets")
            .select()
            .eq("user_id", value: userId)
            .eq("month", value: month)
            .eq("year", value: year)
            .limit(1)
            .execute()
            .value
        
        return response.first
    }
    
    func createBudget(_ budget: Budget) async throws {
        try await client.database
            .from("budgets")
            .insert(budget)
            .execute()
    }
    
    func updateBudget(_ budget: Budget) async throws {
        try await client.database
            .from("budgets")
            .update(budget)
            .eq("id", value: budget.id)
            .execute()
    }
    
    // Artist Budget Allocations
    func getArtistAllocations(for budgetId: UUID) async throws -> [ArtistBudgetAllocation] {
        let response: [ArtistBudgetAllocation] = try await client.database
            .from("artist_budget_allocations")
            .select()
            .eq("budget_id", value: budgetId)
            .execute()
            .value
        
        return response
    }
    
    func createArtistAllocation(_ allocation: ArtistBudgetAllocation) async throws {
        try await client.database
            .from("artist_budget_allocations")
            .insert(allocation)
            .execute()
    }
    
    func updateArtistAllocation(_ allocation: ArtistBudgetAllocation) async throws {
        try await client.database
            .from("artist_budget_allocations")
            .update(allocation)
            .eq("id", value: allocation.id)
            .execute()
    }
}