import Foundation

/// Simple user session management for PiggyBong
/// This handles basic user identification and persistence
final class UserSession: ObservableObject {
    static let shared = UserSession()
    
    @Published var currentUserId: UUID
    @Published var isLoggedIn: Bool = false
    
    private let userIdKey = "piggy_bong_user_id"
    private let isLoggedInKey = "piggy_bong_is_logged_in"
    
    private init() {
        // Load existing user ID or create a new one
        if let storedUserIdString = UserDefaults.standard.string(forKey: userIdKey),
           let storedUserId = UUID(uuidString: storedUserIdString) {
            self.currentUserId = storedUserId
            self.isLoggedIn = UserDefaults.standard.bool(forKey: isLoggedInKey)
            print("📱 Loaded existing user session: \(storedUserId)")
        } else {
            // Create new user session
            let newUserId = UUID()
            self.currentUserId = newUserId
            self.isLoggedIn = false
            UserDefaults.standard.set(newUserId.uuidString, forKey: userIdKey)
            UserDefaults.standard.set(false, forKey: isLoggedInKey)
            print("🆕 Created new user session: \(newUserId)")
        }
    }
    
    /// Set the current user as logged in
    func setLoggedIn(_ userId: UUID) {
        self.currentUserId = userId
        self.isLoggedIn = true
        UserDefaults.standard.set(userId.uuidString, forKey: userIdKey)
        UserDefaults.standard.set(true, forKey: isLoggedInKey)
        print("✅ User logged in: \(userId)")
    }
    
    /// Log out the current user
    func logout() {
        self.isLoggedIn = false
        UserDefaults.standard.set(false, forKey: isLoggedInKey)
        print("👋 User logged out")
    }
    
    /// Reset the user session (for testing/development)
    func resetSession() {
        let newUserId = UUID()
        self.currentUserId = newUserId
        self.isLoggedIn = false
        UserDefaults.standard.set(newUserId.uuidString, forKey: userIdKey)
        UserDefaults.standard.set(false, forKey: isLoggedInKey)
        print("🔄 User session reset: \(newUserId)")
    }
    
    /// For competition demo purposes - create a demo user
    func createDemoUser(name: String = "Competition Judge", monthlyBudget: Double = 500.0) async throws -> UUID {
        let supabaseService = SupabaseService.shared
        
        do {
            let userId = try await supabaseService.createUser(
                name: name,
                email: "help.piggybong@gmail.com",
                monthlyBudget: monthlyBudget
            )
            
            setLoggedIn(userId)
            return userId
        } catch {
            print("❌ Failed to create demo user: \(error)")
            // For demo purposes, still set as logged in with current ID
            setLoggedIn(currentUserId)
            throw error
        }
    }
}