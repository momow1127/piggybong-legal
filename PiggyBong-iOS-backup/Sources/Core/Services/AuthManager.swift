import Foundation
import SwiftUI

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let databaseService: DatabaseService
    
    init(databaseService: DatabaseService = DatabaseService()) {
        self.databaseService = databaseService
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        // TODO: Implement Supabase auth check
        // For now, simulate auth check
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
            // Simulate no user for onboarding flow
            self.isAuthenticated = false
        }
    }
    
    func signUp(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // TODO: Implement Supabase sign up
            // For now, create a mock user
            let user = User(
                email: email,
                name: name,
                monthlyBudget: 0,
                currency: "USD"
            )
            
            self.currentUser = user
            self.isAuthenticated = true
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // TODO: Implement Supabase sign in
            await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network call
            
            // Mock successful sign in
            let user = User(
                email: email,
                name: "K-pop Fan",
                monthlyBudget: 200,
                currency: "USD"
            )
            
            self.currentUser = user
            self.isAuthenticated = true
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
    }
}