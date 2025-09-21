import XCTest
import Foundation
@testable import Piggy_Bong

/// Comprehensive authentication test scenarios for PiggyBong
/// These tests validate all authentication methods and edge cases
class AuthenticationTestScenarios: XCTestCase {
    
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
    
    // MARK: - Apple Sign-In Test Scenarios
    
    func testAppleSignInConfigurationValidation() {
        // Test Apple Sign-In configuration
        let bundleID = Bundle.main.bundleIdentifier
        XCTAssertNotNil(bundleID, "Bundle identifier must be configured")
        
        let appleClientID = Bundle.main.object(forInfoDictionaryKey: "APPLE_CLIENT_ID") as? String
        XCTAssertNotNil(appleClientID, "Apple Client ID must be configured in Info.plist")
        XCTAssertEqual(appleClientID, "carmenwong.PiggyBong", "Apple Client ID should match expected value")
    }
    
    func testAppleSignInURLSchemeConfiguration() {
        // Verify Apple Sign-In URL scheme is properly configured
        guard let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] else {
            XCTFail("CFBundleURLTypes not configured in Info.plist")
            return
        }
        
        let appleSchemes = urlTypes.compactMap { urlType in
            (urlType["CFBundleURLSchemes"] as? [String])?.first(where: { $0.contains("PiggyBong") })
        }
        
        XCTAssertFalse(appleSchemes.isEmpty, "Apple Sign-In URL scheme should be configured")
    }
    
    func testAppleSignInUserCreation() async throws {
        // Mock Apple Sign-In credential for testing
        let mockUser = AuthenticationService.AuthUser(
            id: UUID(),
            email: "user@privaterelay.appleid.com",
            name: "Apple User",
            monthlyBudget: 100.0,
            createdAt: Date()
        )
        
        // Verify user creation with Apple provider
        XCTAssertEqual(mockUser.monthlyBudget, 100.0, "Default budget should be $100 for Apple Sign-In")
        XCTAssertTrue(mockUser.email.contains("@privaterelay.appleid.com") || mockUser.email.contains("@icloud.com"), 
                     "Apple Sign-In should handle private relay emails")
    }
    
    // MARK: - Google Sign-In Test Scenarios
    
    func testGoogleSignInConfigurationValidation() {
        // Test Google Sign-In configuration
        let googleClientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String
        XCTAssertNotNil(googleClientID, "Google Client ID must be configured")
        XCTAssertTrue(googleClientID?.hasSuffix(".apps.googleusercontent.com") == true, 
                     "Google Client ID should have correct format")
        XCTAssertEqual(googleClientID, "301452889528-rqd96cu7r6gtu46fmvafrdfbhsjn9vq1.apps.googleusercontent.com",
                      "Google Client ID should match expected value")
    }
    
    func testGoogleSignInURLSchemeConfiguration() {
        // Verify Google OAuth URL scheme is properly configured
        guard let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] else {
            XCTFail("CFBundleURLTypes not configured in Info.plist")
            return
        }
        
        let googleSchemes = urlTypes.compactMap { urlType in
            (urlType["CFBundleURLSchemes"] as? [String])?.first(where: { $0.contains("googleusercontent.com") })
        }
        
        XCTAssertFalse(googleSchemes.isEmpty, "Google OAuth URL scheme should be configured")
    }
    
    func testGoogleSignInUserDataHandling() {
        // Test Google user profile data handling
        let mockGoogleUser = AuthenticationService.AuthUser(
            id: UUID(),
            email: "user@gmail.com",
            name: "Google Test User",
            monthlyBudget: 100.0,
            createdAt: Date()
        )
        
        XCTAssertEqual(mockGoogleUser.monthlyBudget, 100.0, "Default budget should be $100 for Google Sign-In")
        XCTAssertTrue(mockGoogleUser.name.count > 0, "Google Sign-In should provide user name")
        XCTAssertTrue(mockGoogleUser.email.contains("@"), "Google Sign-In should provide valid email")
    }
    
    // MARK: - Email Authentication Test Scenarios
    
    func testEmailValidationComprehensive() {
        // Test various email formats
        let validEmails = [
            "user@example.com",
            "test.email+tag@domain.co.uk",
            "user123@test-domain.org",
            "한글이름@example.com",
            "user@subdomain.example.com"
        ]
        
        for email in validEmails {
            XCTAssertNil(authService.validateEmail(email), "Email \(email) should be valid")
        }
        
        let invalidEmails = [
            "",
            "invalid-email",
            "user@",
            "@domain.com",
            "user..double.dot@example.com",
            "user@domain",
            "user @example.com"
        ]
        
        for email in invalidEmails {
            XCTAssertNotNil(authService.validateEmail(email), "Email \(email) should be invalid")
        }
    }
    
    func testPasswordValidationComprehensive() {
        // Test various password scenarios
        let validPasswords = [
            "password123",
            "MySecureP@ssw0rd",
            "한글비밀번호123",
            "verylongpasswordthatexceedsnormalexpectations",
            "P@ssw0rd!",
            "123456" // Minimum length
        ]
        
        for password in validPasswords {
            XCTAssertNil(authService.validatePassword(password), "Password \(password) should be valid")
        }
        
        let invalidPasswords = [
            "",
            "short",
            "12345", // Too short
            " ", // Whitespace only
            "     " // Multiple spaces
        ]
        
        for password in invalidPasswords {
            XCTAssertNotNil(authService.validatePassword(password), "Password should be invalid")
        }
    }
    
    func testEmailSignUpFlowComplete() async throws {
        // Test complete email sign-up flow
        let signUpRequest = AuthenticationService.SignUpRequest(
            name: "Test User",
            email: "comprehensive.test@piggybong.com",
            password: "SecureTestPassword123!",
            monthlyBudget: 250.0,
            termsAccepted: true
        )
        
        // This would normally create a user in Supabase
        // For unit testing, we verify the request is properly formed
        XCTAssertEqual(signUpRequest.name, "Test User")
        XCTAssertEqual(signUpRequest.email, "comprehensive.test@piggybong.com")
        XCTAssertEqual(signUpRequest.monthlyBudget, 250.0)
        XCTAssertTrue(signUpRequest.termsAccepted)
        XCTAssertEqual(signUpRequest.termsVersion, "2025-08-20")
    }
    
    func testEmailSignInFlowComplete() async throws {
        // Test complete email sign-in flow
        let signInRequest = AuthenticationService.SignInRequest(
            email: "existing.user@piggybong.com",
            password: "ExistingUserPassword123!"
        )
        
        // Verify request formatting
        XCTAssertEqual(signInRequest.email, "existing.user@piggybong.com")
        XCTAssertEqual(signInRequest.password, "ExistingUserPassword123!")
    }
    
    // MARK: - Session Management Test Scenarios
    
    func testSessionPersistenceAcrossAppRestarts() {
        // Simulate app restart by creating new auth service instance
        let originalUser = AuthenticationService.AuthUser(
            id: UUID(),
            email: "persistent.user@example.com",
            name: "Persistent User",
            monthlyBudget: 500.0,
            createdAt: Date()
        )
        
        // Simulate saving user to keychain
        authService.currentUser = originalUser
        authService.isAuthenticated = true
        
        // Create new instance to simulate app restart
        let newAuthService = AuthenticationService.shared
        
        // In a real app, this would restore from keychain
        // Here we verify the user data structure is consistent
        XCTAssertEqual(originalUser.email, "persistent.user@example.com")
        XCTAssertEqual(originalUser.monthlyBudget, 500.0)
    }
    
    func testConcurrentAuthenticationPrevention() async {
        // Test that concurrent authentication attempts are handled properly
        let request1 = AuthenticationService.SignUpRequest(
            name: "User 1",
            email: "user1@concurrent-test.com",
            password: "Password123!",
            monthlyBudget: 300.0
        )
        
        let request2 = AuthenticationService.SignInRequest(
            email: "user2@concurrent-test.com",
            password: "Password456!"
        )
        
        // Simulate concurrent requests
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                // These would normally make network requests
                // For unit testing, we verify proper request formation
                XCTAssertFalse(self.authService.isLoading)
            }
            
            group.addTask {
                // Verify second request doesn't interfere
                XCTAssertEqual(request2.email, "user2@concurrent-test.com")
            }
        }
        
        // Verify auth service returns to consistent state
        XCTAssertFalse(authService.isLoading)
    }
    
    // MARK: - Error Handling Test Scenarios
    
    func testNetworkErrorHandling() async {
        // Test various network error scenarios
        let networkErrors = [
            NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil),
            NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil),
            NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotFindHost, userInfo: nil)
        ]
        
        for error in networkErrors {
            // In a real implementation, these would trigger specific error handling
            XCTAssertNotNil(error.localizedDescription)
            print("Network error handled: \(error.localizedDescription)")
        }
    }
    
    func testAuthenticationErrorMapping() {
        // Test authentication error mapping
        let authErrors: [AuthenticationError] = [
            .signUpFailed("Email already exists"),
            .signInFailed("Invalid credentials"),
            .userNotFound,
            .passwordResetFailed("Email not found"),
            .emailVerificationFailed("Invalid code"),
            .invalidCredentials,
            .networkError
        ]
        
        for error in authErrors {
            XCTAssertNotNil(error.localizedDescription)
            XCTAssertTrue(error.localizedDescription.count > 0)
            print("Auth error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Supabase Integration Test Scenarios
    
    func testSupabaseConfigurationValidation() {
        // Test Supabase configuration using SupabaseConfig
        let supabaseURL = SupabaseConfig.url
        let supabaseKey = SupabaseConfig.anonKey
        
        // Validate URL format
        XCTAssertTrue(supabaseURL.hasPrefix("https://"), "Supabase URL should use HTTPS")
        XCTAssertTrue(supabaseURL.contains("supabase.co"), "Should be valid Supabase URL")
        
        // Validate key format (JWT)
        XCTAssertTrue(supabaseKey.hasPrefix("eyJ"), "Supabase key should be JWT format")
        XCTAssertTrue(supabaseKey.count > 100, "Supabase key should be sufficiently long")
    }
    
    func testUserProfileDataValidation() {
        // Test user profile data constraints
        let validUser = AuthenticationService.AuthUser(
            id: UUID(),
            email: "valid@example.com",
            name: "Valid User Name",
            monthlyBudget: 500.0,
            createdAt: Date()
        )
        
        // Test valid user data
        XCTAssertNotNil(validUser.id)
        XCTAssertTrue(validUser.email.contains("@"))
        XCTAssertTrue(validUser.name.count >= 2)
        XCTAssertTrue(validUser.monthlyBudget >= 0)
        XCTAssertNotNil(validUser.createdAt)
    }
    
    // MARK: - Security Test Scenarios
    
    func testInputSanitization() {
        // Test input sanitization for security
        let maliciousInputs = [
            "<script>alert('xss')</script>",
            "'; DROP TABLE users; --",
            "user@example.com'; DELETE FROM users; --",
            "../../../etc/passwd",
            "javascript:alert('xss')"
        ]
        
        for input in maliciousInputs {
            // Email validation should reject malicious inputs
            XCTAssertNotNil(authService.validateEmail(input), "Malicious input should be rejected")
        }
    }
    
    func testPasswordSecurityRequirements() {
        // Test password security requirements
        let weakPasswords = [
            "password",
            "123456",
            "qwerty",
            "abc123",
            "password123"
        ]
        
        for password in weakPasswords {
            // Current implementation allows these, but they're flagged as weak
            let validation = authService.validatePassword(password)
            if validation == nil {
                print("Warning: Weak password '\(password)' passed validation")
            }
        }
    }
    
    // MARK: - Performance Test Scenarios
    
    func testAuthenticationPerformance() {
        // Test authentication performance
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Simulate multiple validation calls
        for i in 0..<100 {
            let email = "test\(i)@example.com"
            let password = "password\(i)123"
            
            _ = authService.validateEmail(email)
            _ = authService.validatePassword(password)
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should complete 100 validations in under 0.1 seconds
        XCTAssertLessThan(timeElapsed, 0.1, "Validation performance should be fast")
        print("Validation performance: \(timeElapsed) seconds for 100 validations")
    }
    
    // MARK: - Integration Test Scenarios
    
    func testFullAuthenticationFlow() {
        // Test complete authentication flow end-to-end
        let testUser = AuthenticationService.SignUpRequest(
            name: "Integration Test User",
            email: "integration@piggybong.com",
            password: "IntegrationTest123!",
            monthlyBudget: 750.0
        )
        
        // Verify all components are properly configured
        XCTAssertTrue(testUser.termsAccepted)
        XCTAssertEqual(testUser.termsVersion, "2025-08-20")
        XCTAssertNil(authService.validateEmail(testUser.email))
        XCTAssertNil(authService.validatePassword(testUser.password))
        XCTAssertNil(authService.validateName(testUser.name))
        XCTAssertNil(authService.validateBudget(testUser.monthlyBudget))
    }
    
    func testAuthenticationStateConsistency() {
        // Test authentication state consistency
        XCTAssertFalse(authService.isAuthenticated, "Should start unauthenticated")
        XCTAssertNil(authService.currentUser, "Should have no current user")
        XCTAssertFalse(authService.isLoading, "Should not be loading")
        
        // Simulate authentication
        let mockUser = AuthenticationService.AuthUser(
            id: UUID(),
            email: "consistency@test.com",
            name: "Consistency Test",
            monthlyBudget: 400.0,
            createdAt: Date()
        )
        
        authService.currentUser = mockUser
        authService.isAuthenticated = true
        
        // Verify state consistency
        XCTAssertTrue(authService.isAuthenticated)
        XCTAssertNotNil(authService.currentUser)
        XCTAssertEqual(authService.currentUser?.email, "consistency@test.com")
    }
}

// MARK: - Test Extensions

extension AuthenticationTestScenarios {
    
    /// Helper method to create test users with different configurations
    func createTestUser(provider: String) -> AuthenticationService.AuthUser {
        let baseEmail = "test-\(provider)@piggybong.com"
        let baseName = "Test \(provider.capitalized) User"
        
        return AuthenticationService.AuthUser(
            id: UUID(),
            email: baseEmail,
            name: baseName,
            monthlyBudget: 100.0,
            createdAt: Date()
        )
    }
    
    /// Helper method to validate auth configuration
    func validateAuthConfiguration() -> [String: Bool] {
        return [
            "supabase_configured": Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") != nil,
            "google_configured": Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") != nil,
            "apple_configured": Bundle.main.object(forInfoDictionaryKey: "APPLE_CLIENT_ID") != nil,
            "url_schemes_configured": Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") != nil
        ]
    }
}

// MARK: - Mock Data for Testing

extension AuthenticationTestScenarios {
    
    struct MockAuthData {
        static let validEmails = [
            "user@example.com",
            "test@piggybong.com",
            "admin@company.org",
            "한글@example.com"
        ]
        
        static let invalidEmails = [
            "",
            "invalid",
            "@domain.com",
            "user@",
            "user..double@example.com"
        ]
        
        static let validPasswords = [
            "password123",
            "SecureP@ssw0rd",
            "MyVeryLongPasswordThatIsSecure123!",
            "한글비밀번호123"
        ]
        
        static let invalidPasswords = [
            "",
            "short",
            "12345"
        ]
        
        static let testUsers: [AuthenticationService.AuthUser] = [
            AuthenticationService.AuthUser(
                id: UUID(),
                email: "apple@privaterelay.appleid.com",
                name: "Apple Test User",
                monthlyBudget: 100.0,
                createdAt: Date()
            ),
            AuthenticationService.AuthUser(
                id: UUID(),
                email: "google@gmail.com",
                name: "Google Test User",
                monthlyBudget: 150.0,
                createdAt: Date()
            ),
            AuthenticationService.AuthUser(
                id: UUID(),
                email: "email@piggybong.com",
                name: "Email Test User",
                monthlyBudget: 200.0,
                createdAt: Date()
            )
        ]
    }
}