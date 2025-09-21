import Foundation
import SwiftUI
import Combine

/// Main DatabaseService that connects to real Supabase backend
/// This replaces the mock DatabaseService with real data
@MainActor
class DatabaseService: ObservableObject {
    @Published var artists: [Artist] = []
    @Published var purchases: [Purchase] = []
    @Published var userArtists: [Artist] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: User?
    
    internal let supabase = SupabaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    static let shared = DatabaseService()
    
    private init() {
        setupObservers()
    }
    
    func initialize() {
        print("🚀 DatabaseService initialized with real Supabase connection")
        Task {
            await loadInitialData()
        }
    }
    
    // Use this for production/high-traffic scenarios
    func initializeForHighTraffic() {
        print("🚀 DatabaseService initialized for high-traffic scenarios")
        Task {
            // Use optimized loading methods (same as regular fetch for now)
            await fetchArtists()

            // If user is authenticated, load their data with optimizations
            do {
                if let authUser = try await supabase.getCurrentUser() {
                    await loadUserData(userId: authUser.id)
                }
            } catch {
                print("❌ Error loading user data: \(error)")
            }
        }
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe authentication state changes
        NotificationCenter.default.publisher(for: Notification.Name("AuthStateChanged"))
            .sink { [weak self] _ in
                Task {
                    await self?.handleAuthStateChange()
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleAuthStateChange() async {
        do {
            if let authUser = try await supabase.getCurrentUser() {
                await loadUserData(userId: authUser.id)
                // Migrate priorities from UserDefaults to database if needed
                await PriorityMigrationService.shared.migratePrioritiesIfNeeded()
            } else {
                // Clear user-specific data when logged out
                clearUserData()
            }
        } catch {
            print("❌ Error checking auth state: \(error)")
            clearUserData()
        }
    }
    
    private func clearUserData() {
        purchases = []
        userArtists = []
        currentUser = nil
    }
    
    // MARK: - Initial Data Loading
    
    private func loadInitialData() async {
        do {
            // Load all artists (public data)
            await fetchArtists()
            
            // If user is authenticated, load their data
            if let authUser = try await supabase.getCurrentUser() {
                await loadUserData(userId: authUser.id)
            }
        } catch {
            print("❌ Error loading initial data: \(error)")
            errorMessage = "Failed to load data. Please try again."
        }
    }
    
    private func loadUserData(userId: UUID) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchUserArtists(userId: userId) }
            group.addTask { await self.fetchPurchases(for: userId) }
            group.addTask { await self.fetchUserProfile(userId: userId) }
        }
    }
    
    // MARK: - Artist Operations
    
    func fetchArtists() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let fetchedArtists = try await supabase.getArtists()
            await MainActor.run {
                self.artists = fetchedArtists
                self.isLoading = false
            }
            print("✅ Fetched \(fetchedArtists.count) artists from Supabase")
        } catch {
            print("❌ Error fetching artists: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to load artists"
                self.isLoading = false
                // Fallback to cached/offline data if available
                self.loadCachedArtists()
            }
        }
    }
    
    func fetchUserArtists(userId: UUID) async {
        do {
            let userArtistData = try await supabase.getUserArtists(userId: userId)
            let userArtistIds = userArtistData.map { $0.artistId }
            
            await MainActor.run {
                self.userArtists = artists.filter { artist in
                    userArtistIds.contains(artist.id)
                }
                // Notify real-time monitoring service about artist data being loaded
                NotificationCenter.default.post(name: .userArtistsUpdated, object: nil)
            }
            print("✅ User has \(userArtists.count) selected artists")
        } catch {
            print("❌ Error fetching user artists: \(error)")

            // Provide better error feedback for timeouts
            if error.localizedDescription.contains("timeout") || error.localizedDescription.contains("timed out") {
                await MainActor.run {
                    self.errorMessage = "Unable to connect to server. Please check your internet connection and try again."
                }
                print("🔄 Network timeout detected - user may need to retry")
            } else {
                await MainActor.run {
                    self.errorMessage = "Unable to load your artists. Please try again."
                }
            }

            // Don't update UI state on error to avoid clearing existing data
        }
    }
    
    func addUserArtist(_ artist: Artist) async {
        do {
            guard try await supabase.getCurrentUser() != nil else {
                await MainActor.run {
                    errorMessage = "Please sign in to add artists"
                }
                return
            }

            // Check artist limit before adding
            let currentCount = userArtists.count
            let maxArtists = RevenueCatManager.shared.artistTrackingLimit

            if currentCount >= maxArtists {
                await MainActor.run {
                    let limitType = RevenueCatManager.shared.canTrackUnlimitedArtists ? "premium" : "free"
                    errorMessage = "You've reached your \(limitType) limit of \(maxArtists) artists. Remove an artist to add another one."
                }
                print("🚫 Artist limit reached: \(currentCount)/\(maxArtists)")
                return
            }

            // Use the Edge Function to add fan idol
            let message = try await supabase.addFanIdol(
                artistId: artist.id,
                priorityRank: userArtists.count + 1
            )

            if !userArtists.contains(where: { $0.id == artist.id }) {
                userArtists.append(artist)
                // Notify real-time monitoring service about artist changes
                NotificationCenter.default.post(name: .userArtistsUpdated, object: nil)

                // Track artist added event
                AIInsightAnalyticsService.shared.logArtistAdded(
                    artistName: artist.name,
                    artistId: artist.id.uuidString,
                    source: "manual"
                )
            }
            print("✅ \(message)")
        } catch {
            print("❌ Error adding user artist: \(error)")
            errorMessage = "Failed to add artist: \(error.localizedDescription)"
        }
    }
    
    func removeUserArtist(_ artist: Artist) async {
        // Use FanDashboardService to remove artist from backend with delete-fan-idol Edge Function
        let success = await FanDashboardService.shared.removeArtist(artist.id)

        if success {
            // Remove from local array only if backend removal succeeded
            let wasRemoved = !userArtists.isEmpty && userArtists.contains { $0.id == artist.id }
            userArtists.removeAll { $0.id == artist.id }

            // Notify real-time monitoring service about artist changes
            if wasRemoved {
                NotificationCenter.default.post(name: .userArtistsUpdated, object: nil)

                // Track artist removed event
                AIInsightAnalyticsService.shared.logArtistRemoved(
                    artistName: artist.name,
                    artistId: artist.id.uuidString,
                    reason: "manual"
                )
            }

            print("✅ Removed artist from user's collection via delete-fan-idol Edge Function")
        } else {
            print("❌ Failed to remove artist from backend - keeping local data intact")
        }
    }
    
    // MARK: - Purchase Operations
    
    func fetchPurchases(for userId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get dashboard transactions and convert to Purchase objects
            let dashboardTransactions = try await supabase.getPurchases(for: userId, limit: 50)
            
            // Convert DashboardTransaction to Purchase
            self.purchases = dashboardTransactions.map { transaction in
                Purchase(
                    id: transaction.id,
                    userId: userId,
                    artistId: UUID(), // TODO: Map from artistName to artistId
                    amount: transaction.amount,
                    category: mapTransactionToPurchaseCategory(transaction.category),
                    description: transaction.title,
                    createdAt: transaction.date
                )
            }
            print("✅ Fetched \(purchases.count) purchases")
        } catch {
            print("❌ Error fetching purchases: \(error)")
            errorMessage = "Failed to load purchases"
        }
        
        isLoading = false
    }
    
    func addPurchase(_ purchase: Purchase) async {
        do {
            _ = try await supabase.createPurchase(
                userId: purchase.userId,
                artistId: purchase.artistId,
                amount: purchase.amount,
                category: purchase.category.rawValue,
                description: purchase.description,
                notes: nil
            )
            
            purchases.append(purchase)
            print("✅ Added new purchase")
            
            // Update priority spending
            let categoryString = mapPurchaseCategoryToString(purchase.category)
            await updatePrioritySpent(
                userId: purchase.userId,
                category: categoryString,
                additionalAmount: purchase.amount
            )
            
        } catch {
            print("❌ Error adding purchase: \(error)")
            errorMessage = "Failed to add purchase"
        }
    }
    
    /// Maps Purchase category to priority category string
    private func mapPurchaseCategoryToString(_ category: PurchaseCategory) -> String {
        switch category {
        case .concert:
            return "concerts"
        case .album:
            return "albums"
        case .merchandise:
            return "merch"
        case .digital:
            return "subs"
        case .photocard:
            return "photocards"
        case .other:
            return "other"
        }
    }
    
    func deletePurchase(_ purchase: Purchase) async {
        do {
            try await supabase.deletePurchase(id: purchase.id)
            purchases.removeAll { $0.id == purchase.id }
            print("✅ Deleted purchase")
        } catch {
            print("❌ Error deleting purchase: \(error)")
            errorMessage = "Failed to delete purchase"
        }
    }
    
    // MARK: - User Profile
    
    func fetchUserProfile(userId: UUID) async {
        do {
            let dbUser = try await supabase.getUser(id: userId)
            self.currentUser = User(
                id: dbUser.id,
                email: dbUser.email,
                name: dbUser.name,
                monthlyBudget: dbUser.monthlyBudget,
                createdAt: Date() // TODO: Parse date from string if needed
            )
            print("✅ Loaded user profile")
        } catch {
            print("❌ Error fetching user profile: \(error)")
        }
    }
    
    // MARK: - Search
    
    func searchArtists(query: String) async -> [Artist] {
        if query.isEmpty {
            return artists
        }
        
        return artists.filter { artist in
            artist.name.localizedCaseInsensitiveContains(query) ||
            artist.group?.localizedCaseInsensitiveContains(query) == true
        }
    }
    
    // MARK: - Offline Support
    
    private func loadCachedArtists() {
        // Load embedded artists with proper UUIDs from Supabase CSV export
        if artists.isEmpty {
            artists = [
                Artist(id: UUID(uuidString: "18dd2150-6cea-4209-b1cf-cd752d80750f")!, name: "Jungkook", group: "BTS"),
                Artist(id: UUID(uuidString: "193e711b-b10d-4314-b73a-98fbe554699a")!, name: "V", group: "BTS"),
                Artist(id: UUID(uuidString: "1c0cbb1d-8259-475d-83f6-b0dd68b307f9")!, name: "LE SSERAFIM", group: "LE SSERAFIM"),
                Artist(id: UUID(uuidString: "1c12fbdc-5a41-4e99-a14b-01cd8d66160c")!, name: "BABYMONSTER", group: "BABYMONSTER"),
                Artist(id: UUID(uuidString: "1f4d8003-1af5-4913-845e-a779246c425b")!, name: "Taeyeon", group: "Girls' Generation"),
                Artist(id: UUID(uuidString: "2cf2abb0-5cdf-4886-a3ac-a1ffb5033556")!, name: "i-dle", group: "i-dle"),
                Artist(id: UUID(uuidString: "30097cb9-174f-43d6-8804-06fc90aefc92")!, name: "RIIZE", group: "RIIZE"),
                Artist(id: UUID(uuidString: "358a2151-6c14-4517-8da6-7ce5db4d3758")!, name: "Jennie", group: "BLACKPINK"),
                Artist(id: UUID(uuidString: "3c95c84e-19fb-478a-9cdc-59e234bdba88")!, name: "Rosé", group: "BLACKPINK"),
                Artist(id: UUID(uuidString: "48126d6f-9cf0-45aa-a040-12b7cfa05c1f")!, name: "J-Hope", group: "BTS"),
                Artist(id: UUID(uuidString: "4cab2b65-94fa-4247-8714-2d1c6353b561")!, name: "BTS", group: "BTS"),
                Artist(id: UUID(uuidString: "5558d691-03dc-471b-85e7-775c2cded74d")!, name: "ATEEZ", group: "ATEEZ"),
                Artist(id: UUID(uuidString: "5840f8ce-42a5-4ccf-ac63-f67fe422bf9e")!, name: "SEVENTEEN", group: "SEVENTEEN"),
                Artist(id: UUID(uuidString: "5b1cd5d6-c34c-4857-9999-f0b88f194214")!, name: "2NE1", group: "2NE1"),
                Artist(id: UUID(uuidString: "61417fa5-fa2e-46d7-a3ba-958e5c58f527")!, name: "ENHYPEN", group: "ENHYPEN"),
                Artist(id: UUID(uuidString: "65f54088-7a67-4d25-b707-d1fc23bb7a0f")!, name: "BOYNEXTDOOR", group: "BOYNEXTDOOR"),
                Artist(id: UUID(uuidString: "69b41ce2-5eb4-4766-adb6-2ba6124dfb2e")!, name: "CL", group: "2NE1"),
                Artist(id: UUID(uuidString: "7bdd0c21-4f53-46fe-86df-5d40362a4f1e")!, name: "Jimin", group: "BTS"),
                Artist(id: UUID(uuidString: "8866b088-a8f3-4092-9c0c-620ec13e5b23")!, name: "PSY", group: "PSY"),
                Artist(id: UUID(uuidString: "8a2d1528-4be5-4c56-9a31-af687a1d0dde")!, name: "RM", group: "BTS"),
                Artist(id: UUID(uuidString: "8ea6563b-3b52-4d39-a407-c3b407e1f21b")!, name: "aespa", group: "aespa"),
                Artist(id: UUID(uuidString: "8fc2ae57-e562-479a-bd74-e0881cbc72bd")!, name: "ITZY", group: "ITZY"),
                Artist(id: UUID(uuidString: "ae6bd741-920c-452e-b651-f15ddd20e6bf")!, name: "BLACKPINK", group: "BLACKPINK"),
                Artist(id: UUID(uuidString: "bbb6a9f0-34f6-43f1-ae36-a8606334f626")!, name: "ALLDAY PROJECT", group: "ALLDAY PROJECT"),
                Artist(id: UUID(uuidString: "bf86bf36-18bd-43c2-9046-ffc737942a7e")!, name: "ZEROBASEONE", group: "ZEROBASEONE"),
                Artist(id: UUID(uuidString: "c163e508-3c74-47b1-ac56-2486d734425d")!, name: "IVE", group: "IVE"),
                Artist(id: UUID(uuidString: "c90ef5c8-6a37-4b62-95d8-658d422d5383")!, name: "Jisoo", group: "BLACKPINK"),
                Artist(id: UUID(uuidString: "c9ac5c3f-59ae-43d0-85d7-67c74c975e10")!, name: "ILLIT", group: "ILLIT"),
                Artist(id: UUID(uuidString: "ce8142e3-07df-46e1-8176-b77080faab10")!, name: "JEON SOMI", group: "JEON SOMI"),
                Artist(id: UUID(uuidString: "cfb1c685-7751-498d-be90-5b8ff6859a87")!, name: "BIGBANG", group: "BIGBANG"),
                Artist(id: UUID(uuidString: "d0700f24-a962-472f-b185-cf5a6cc8fdd5")!, name: "TWICE", group: "TWICE"),
                Artist(id: UUID(uuidString: "d209847b-d314-4485-90da-810200eb50df")!, name: "Jin", group: "BTS"),
                Artist(id: UUID(uuidString: "d25d2dec-da17-483b-9aac-dcd2e8fa2e6f")!, name: "TOMORROW X TOGETHER", group: "TOMORROW X TOGETHER"),
                Artist(id: UUID(uuidString: "d8c0a943-63dd-4292-a9b8-c1c9e09daa82")!, name: "NewJeans", group: "NewJeans"),
                Artist(id: UUID(uuidString: "de1301f1-dfc3-458d-9852-c349c402ad79")!, name: "Taemin", group: "SHINee"),
                Artist(id: UUID(uuidString: "e8aa1fbe-24ec-4c72-bcee-3fd534a884e9")!, name: "Lisa", group: "BLACKPINK"),
                Artist(id: UUID(uuidString: "ef0ce331-1605-457f-bf30-e3b4ea4f27df")!, name: "IU", group: "IU"),
                Artist(id: UUID(uuidString: "f12b5fb2-dcc2-4b99-91fb-c5190b91b288")!, name: "Stray Kids", group: "Stray Kids"),
                Artist(id: UUID(uuidString: "f1fe4987-da75-44dc-afa1-e3483f00bdb5")!, name: "Suga", group: "BTS"),
                Artist(id: UUID(uuidString: "f4d7de69-728c-4c44-b47f-5e838f92e458")!, name: "G-Dragon", group: "BIGBANG"),
                Artist(id: UUID(uuidString: "fa6d9eea-0ddd-4095-be2d-d662321d8de2")!, name: "KATSEYE", group: "KATSEYE"),
                // Duplicate entries from CSV (different UUIDs for same groups)
                Artist(id: UUID(uuidString: "8372511b-182f-4cdb-b548-031ed7d66a0f")!, name: "BABYMONSTER", group: "BABYMONSTER"),
                Artist(id: UUID(uuidString: "ecf51bab-bc08-4147-a4d4-fff03ae9597a")!, name: "BOYNEXTDOOR", group: "BOYNEXTDOOR")
            ]
            print("⚠️ Using embedded artists with UUIDs from Supabase (offline mode) - 42 artists loaded")
        }
    }
    
    // MARK: - Error Recovery
    
    func retry() async {
        errorMessage = nil
        await loadInitialData()
    }
    
    // MARK: - Statistics
    
    func getTotalSpending(for period: DateInterval? = nil) -> Double {
        let relevantPurchases = period != nil ? 
            purchases.filter { period!.contains($0.createdAt) } : 
            purchases
        
        return relevantPurchases.reduce(0) { $0 + $1.amount }
    }
    
    func getSpendingByCategory() -> [PurchaseCategory: Double] {
        var categoryTotals: [PurchaseCategory: Double] = [:]
        
        for purchase in purchases {
            categoryTotals[purchase.category, default: 0] += purchase.amount
        }
        
        return categoryTotals
    }
    
    func getSpendingByArtist() -> [(Artist, Double)] {
        var artistTotals: [UUID: Double] = [:]
        
        for purchase in purchases {
            artistTotals[purchase.artistId, default: 0] += purchase.amount
        }
        
        return artists.compactMap { artist in
            if let total = artistTotals[artist.id], total > 0 {
                return (artist, total)
            }
            return nil
        }.sorted { $0.1 > $1.1 }
    }
    
    // MARK: - User Priorities Management
    
    func getUserPriorities(userId: UUID) async -> [UserPriority] {
        do {
            let databasePriorities = try await supabase.getUserPriorities(userId: userId)
            return databasePriorities.map { $0.toUserPriority() }
        } catch {
            print("❌ Error fetching user priorities from database: \(error)")
            // Return empty array instead of fallback for now
            return []
        }
    }
    
    func saveOnboardingPriorities(
        userId: UUID,
        categoryPriorities: [String: PriorityLevel]
    ) async {
        do {
            try await supabase.saveOnboardingPriorities(
                userId: userId,
                categoryPriorities: categoryPriorities
            )
            print("✅ Saved onboarding priorities to database")
        } catch {
            print("❌ Failed to save onboarding priorities: \(error)")
            errorMessage = "Failed to save priorities"
        }
    }
    
    func updatePrioritySpent(
        userId: UUID,
        category: String,
        additionalAmount: Double
    ) async {
        do {
            try await supabase.updatePrioritySpent(
                userId: userId,
                categoryId: category,
                amount: additionalAmount
            )
            print("✅ Updated priority spending")
        } catch {
            print("❌ Failed to update priority spending: \(error)")
        }
    }
    
    /// Gets user priorities and converts to UserPriority array for AI insights
    func getCurrentUserPriorities() async -> [UserPriority] {
        guard let authUser = try? await supabase.getCurrentUser() else {
            print("⚠️ No authenticated user for priorities, using UserDefaults fallback")
            return loadPrioritiesFromUserDefaults()
        }
        
        let priorities = await getUserPriorities(userId: authUser.id)
        
        if priorities.isEmpty {
            print("⚠️ No database priorities found, using UserDefaults fallback")
            return loadPrioritiesFromUserDefaults()
        }
        
        return priorities
    }
    
    /// Fallback method to load priorities from UserDefaults
    private func loadPrioritiesFromUserDefaults() -> [UserPriority] {
        guard let data = UserDefaults.standard.data(forKey: "onboarding_category_priorities"),
              let categoryPriorities = try? JSONDecoder().decode([String: PriorityLevel].self, from: data) else {
            print("⚠️ No priorities in UserDefaults, returning empty array")
            return []
        }
        
        var userPriorities: [UserPriority] = []
        
        for (categoryId, priorityLevel) in categoryPriorities {
            let priority: Int
            switch priorityLevel {
            case .high: priority = 1
            case .medium: priority = 2
            case .low: priority = 3
            }
            
            let userPriority = UserPriority(
                id: UUID(),
                artistId: UUID(), // Placeholder for category-level priorities
                category: FanCategory.fromString(categoryId),
                priority: priority,
                monthlyAllocation: 0.0,
                spent: 0.0
            )
            
            userPriorities.append(userPriority)
        }
        
        print("💾 Loaded \(userPriorities.count) priorities from UserDefaults as fallback")
        return userPriorities
    }
    
    // MARK: - Real-time Updates
    
    func subscribeToRealtimeUpdates() {
        // TODO: Implement Supabase realtime subscriptions
        print("📡 Real-time updates will be implemented with Supabase Realtime")
    }
    
    // MARK: - Helper Methods
    
    private func mapTransactionToPurchaseCategory(_ transactionCategory: TransactionCategory) -> PurchaseCategory {
        switch transactionCategory {
        case .concert:
            return .concert
        case .album:
            return .album
        case .merchandise:
            return .merchandise
        case .subscription:
            return .digital
        case .food, .transport, .saving, .other:
            return .other
        }
    }
}

// MARK: - Error Extension

extension DatabaseService {
    enum DatabaseError: LocalizedError {
        case notAuthenticated
        case networkError
        case dataCorrupted
        
        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "Please sign in to continue"
            case .networkError:
                return "Network error. Please check your connection"
            case .dataCorrupted:
                return "Data error. Please try again"
            }
        }
    }
}
