import XCTest
import Foundation
@testable import Piggy_Bong

class AuthenticationServiceTests: XCTestCase {
    
    var authService: AuthenticationService!
    
    override func setUpWithError() throws {
        super.setUp()
        authService = AuthenticationService.shared
        // Clear any existing authentication state
        Task {
            await authService.signOut()
        }
    }
    
    override func tearDownWithError() throws {
        Task {
            await authService.signOut()
        }
        authService = nil
        super.tearDown()
    }
    
    // MARK: - Authentication Tests
    
    func testInitialAuthenticationState() {
        XCTAssertFalse(authService.isAuthenticated, "User should not be authenticated initially")
        XCTAssertNil(authService.currentUser, "Current user should be nil initially")
        XCTAssertFalse(authService.isLoading, "Should not be loading initially")
    }
    
    func testSignUpWithValidData() async throws {
        let signUpRequest = AuthenticationService.SignUpRequest(
            name: "Test User",
            email: "test@example.com",
            password: "SecurePassword123!",
            monthlyBudget: 500.0
        )
        
        try await authService.signUp(request: signUpRequest)
        
        XCTAssertTrue(authService.isAuthenticated, "User should be authenticated after sign up")
        XCTAssertNotNil(authService.currentUser, "Current user should be set after sign up")
        XCTAssertEqual(authService.currentUser?.name, "Test User", "User name should match")
        XCTAssertEqual(authService.currentUser?.email, "test@example.com", "User email should match")
        XCTAssertEqual(authService.currentUser?.monthlyBudget, 500.0, "Monthly budget should match")
    }
    
    func testSignInFlow() async throws {
        let signInRequest = AuthenticationService.SignInRequest(
            email: "test@example.com",
            password: "password123"
        )
        
        try await authService.signIn(request: signInRequest)
        
        XCTAssertTrue(authService.isAuthenticated, "User should be authenticated after sign in")
        XCTAssertNotNil(authService.currentUser, "Current user should be set after sign in")
    }
    
    func testSignOutFlow() {
        // First simulate authentication
        let mockUser = AuthenticationService.AuthUser(
            id: UUID(),
            email: "test@example.com",
            name: "Test User",
            monthlyBudget: 500.0,
            createdAt: Date()
        )
        
        authService.currentUser = mockUser
        authService.isAuthenticated = true
        
        // Then sign out
        Task {
            await authService.signOut()
        }
        
        XCTAssertFalse(authService.isAuthenticated, "User should not be authenticated after sign out")
        XCTAssertNil(authService.currentUser, "Current user should be nil after sign out")
    }
    
    // MARK: - Validation Tests
    
    func testEmailValidation() {
        // Valid emails
        XCTAssertNil(authService.validateEmail("test@example.com"), "Valid email should pass validation")
        XCTAssertNil(authService.validateEmail("user.name+tag@domain.co.uk"), "Complex valid email should pass")
        
        // Invalid emails
        XCTAssertNotNil(authService.validateEmail(""), "Empty email should fail validation")
        XCTAssertNotNil(authService.validateEmail("invalid"), "Email without @ should fail")
        XCTAssertNotNil(authService.validateEmail("invalid@"), "Email without domain should fail")
        XCTAssertNotNil(authService.validateEmail("@domain.com"), "Email without local part should fail")
    }
    
    func testPasswordValidation() {
        // Valid passwords
        XCTAssertNil(authService.validatePassword("SecurePass123!"), "Strong password should pass")
        
        // Invalid passwords
        XCTAssertNotNil(authService.validatePassword(""), "Empty password should fail")
        XCTAssertNotNil(authService.validatePassword("weak"), "Weak password should fail")
        XCTAssertNotNil(authService.validatePassword("12345"), "Numeric only password should fail")
    }
    
    func testNameValidation() {
        // Valid names
        XCTAssertNil(authService.validateName("John Doe"), "Normal name should pass validation")
        XCTAssertNil(authService.validateName("김민정"), "Korean name should pass validation")
        XCTAssertNil(authService.validateName("Marie-Claire"), "Hyphenated name should pass validation")
        
        // Invalid names
        XCTAssertNotNil(authService.validateName(""), "Empty name should fail validation")
        XCTAssertNotNil(authService.validateName("J"), "Too short name should fail validation")
        XCTAssertNotNil(authService.validateName("123"), "Numeric name should fail validation")
    }
    
    func testBudgetValidation() {
        // Valid budgets
        XCTAssertNil(authService.validateBudget(100.0), "Normal budget should pass validation")
        XCTAssertNil(authService.validateBudget(5000.0), "High budget should pass validation")
        XCTAssertNil(authService.validateBudget(0.01), "Very low budget should pass validation")
        
        // Invalid budgets
        XCTAssertNotNil(authService.validateBudget(0.0), "Zero budget should fail validation")
        XCTAssertNotNil(authService.validateBudget(-100.0), "Negative budget should fail validation")
        XCTAssertNotNil(authService.validateBudget(200000.0), "Extremely high budget should fail validation")
    }
    
    // MARK: - Keychain Persistence Tests
    
    func testKeychainPersistence() async throws {
        let signUpRequest = AuthenticationService.SignUpRequest(
            name: "Persistent User",
            email: "persistent@example.com",
            password: "SecurePassword123!",
            monthlyBudget: 750.0
        )
        
        try await authService.signUp(request: signUpRequest)
        let originalUserId = authService.currentUser?.id
        
        // Simulate app restart by creating new instance
        let newAuthService = AuthenticationService.shared
        
        // Check if user data is restored
        XCTAssertEqual(newAuthService.currentUser?.id, originalUserId, "User ID should be restored from keychain")
        XCTAssertTrue(newAuthService.isAuthenticated, "Authentication state should be restored")
    }
    
    // MARK: - Error Handling Tests
    
    func testSignUpWithInvalidData() async {
        let invalidRequest = AuthenticationService.SignUpRequest(
            name: "",
            email: "invalid-email",
            password: "weak",
            monthlyBudget: -100.0
        )
        
        do {
            try await authService.signUp(request: invalidRequest)
            XCTFail("Sign up should fail with invalid data")
        } catch {
            XCTAssertFalse(authService.isAuthenticated, "User should not be authenticated after failed sign up")
            XCTAssertNil(authService.currentUser, "Current user should remain nil after failed sign up")
        }
    }
    
    func testConcurrentAuthenticationRequests() async {
        let request1 = AuthenticationService.SignUpRequest(
            name: "User 1",
            email: "user1@example.com",
            password: "Password123!",
            monthlyBudget: 500.0
        )
        
        let request2 = AuthenticationService.SignInRequest(
            email: "user2@example.com",
            password: "password123"
        )
        
        // Test concurrent requests don't cause race conditions
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    try await self.authService.signUp(request: request1)
                } catch {
                    // Expected to handle gracefully
                }
            }
            
            group.addTask {
                do {
                    try await self.authService.signIn(request: request2)
                } catch {
                    // Expected to handle gracefully
                }
            }
        }
        
        // Should end up in a consistent state
        XCTAssertFalse(authService.isLoading, "Should not be loading after concurrent operations complete")
    }
}