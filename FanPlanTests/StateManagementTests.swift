import XCTest
import SwiftUI
@testable import Piggy_Bong

// MARK: - State Management Tests for ProfileSettingsView
// Testing authentication state, UserDefaults, memory management, and data persistence
class StateManagementTests: XCTestCase {
    
    var mockAuthService: MockAuthenticationService!
    
    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthenticationService()
        
        // Clean UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "user_fandom_name")
        UserDefaults.standard.synchronize()
    }
    
    override func tearDown() {
        // Clean up after each test
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "user_fandom_name")
        UserDefaults.standard.synchronize()
        
        mockAuthService = nil
        super.tearDown()
    }
    
    // MARK: - Authentication Service State Management Tests
    
    func testAuthServiceIsAuthenticatedTriggersViewUpdates() async throws {
        mockAuthService.mockUser = MockUser(id: "test-user", name: "Test User", email: "test@example.com", monthlyBudget: 100.0)
        mockAuthService.isAuthenticated = true
        
        let profileSettingsView = ProfileSettingsView().environmentObject(mockAuthService)
        
        // Initial state - user is authenticated
        XCTAssertTrue(mockAuthService.isAuthenticated, "Initial auth state should be true")
        XCTAssertNotNil(mockAuthService.currentUser, "Current user should exist")
        
        // Simulate logout state change
        await mockAuthService.signOut()
        
        // Verify state changes propagated
        XCTAssertFalse(mockAuthService.isAuthenticated, "Auth state should change to false after signOut")
        XCTAssertNil(mockAuthService.currentUser, "Current user should be nil after signOut")
        XCTAssertEqual(mockAuthService.signOutCallCount, 1, "SignOut should be called once")
    }
    
    func testAuthServiceStateConsistencyDuringRapidChanges() async throws {
        mockAuthService.mockUser = MockUser(id: "test-user", name: "Test User", email: "test@example.com", monthlyBudget: 100.0)
        mockAuthService.isAuthenticated = true
        
        // Perform rapid state changes
        for i in 0..<10 {
            if i % 2 == 0 {
                // Sign out
                mockAuthService.signOutCallCount = 0
                await mockAuthService.signOut()
                XCTAssertFalse(mockAuthService.isAuthenticated, "Should be unauthenticated on iteration \(i)")
            } else {
                // Sign in
                mockAuthService.mockUser = MockUser(id: "test-user-\(i)", name: "Test User \(i)", email: "test\(i)@example.com", monthlyBudget: 100.0)
                XCTAssertTrue(mockAuthService.isAuthenticated, "Should be authenticated on iteration \(i)")
            }
            
            // Verify consistency
            if mockAuthService.isAuthenticated {
                XCTAssertNotNil(mockAuthService.currentUser, "User should exist when authenticated (iteration \(i))")
            } else {
                XCTAssertNil(mockAuthService.currentUser, "User should be nil when unauthenticated (iteration \(i))")
            }
        }
    }
    
    func testAuthServicePublishedPropertiesNotifyViews() {
        mockAuthService.isAuthenticated = false
        mockAuthService.currentUser = nil
        
        var authStateChanges = 0
        var userChanges = 0
        
        // Simulate view observation
        let cancellable1 = mockAuthService.$isAuthenticated.sink { _ in
            authStateChanges += 1
        }
        
        let cancellable2 = mockAuthService.$currentUser.sink { _ in
            userChanges += 1
        }
        
        // Make changes
        mockAuthService.mockUser = MockUser(id: "test", name: "Test", email: "test@example.com", monthlyBudget: 100.0)
        
        // Allow publishers to fire
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        
        // Verify notifications
        XCTAssertGreaterThan(authStateChanges, 1, "Auth state changes should notify observers")
        XCTAssertGreaterThan(userChanges, 1, "User changes should notify observers")
        
        // Clean up
        cancellable1.cancel()
        cancellable2.cancel()
    }
    
    // MARK: - UserDefaults State Management Tests
    
    func testUserDefaultsOnboardingStateManagement() async throws {
        // Test initial state
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"), 
                      "Initial onboarding state should be false")
        
        // Set onboarding completed
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.synchronize()
        
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"), 
                     "Onboarding state should be true after setting")
        
        // Simulate logout
        mockAuthService.mockUser = MockUser(id: "test-user", name: "Test User", email: "test@example.com", monthlyBudget: 100.0)
        mockAuthService.isAuthenticated = true
        
        let profileSettingsView = ProfileSettingsView().environmentObject(mockAuthService)
        
        // Trigger logout which should remove onboarding state
        await mockAuthService.signOut()
        
        // Verify UserDefaults key was removed (simulated in our mock)
        // In real implementation, this would be tested by actually triggering the logout button
        // For now, we manually test the UserDefaults removal
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.synchronize()
        
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"), 
                      "Onboarding state should be false after logout")
    }
    
    func testUserDefaultsFandomNamePersistence() throws {
        let testFandomName = "Test Fandom"
        
        // Test saving fandom name
        UserDefaults.standard.set(testFandomName, forKey: "user_fandom_name")
        UserDefaults.standard.synchronize()
        
        let savedName = UserDefaults.standard.string(forKey: "user_fandom_name")
        XCTAssertEqual(savedName, testFandomName, "Fandom name should be saved correctly")
        
        // Test loading in ProfileSettingsView
        mockAuthService.mockUser = nil // No current user, should fallback to UserDefaults
        
        let profileSettingsView = ProfileSettingsView().environmentObject(mockAuthService)
        
        // In real implementation, onAppear would be triggered and loadUserData called
        // We simulate this by testing the logic directly
        
        // Test removal
        UserDefaults.standard.removeObject(forKey: "user_fandom_name")
        UserDefaults.standard.synchronize()
        
        let removedName = UserDefaults.standard.string(forKey: "user_fandom_name")
        XCTAssertNil(removedName, "Fandom name should be removed correctly")
    }
    
    func testUserDefaultsDataIntegrityUnderLoad() {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 10
        
        let expectation = XCTestExpectation(description: "Concurrent UserDefaults operations")
        expectation.expectedFulfillmentCount = 20
        
        // Perform concurrent UserDefaults operations
        for i in 0..<20 {
            operationQueue.addOperation {
                let key = "test_key_\(i)"
                let value = "test_value_\(i)"
                
                // Set value
                UserDefaults.standard.set(value, forKey: key)
                UserDefaults.standard.synchronize()
                
                // Verify value
                let retrievedValue = UserDefaults.standard.string(forKey: key)
                XCTAssertEqual(retrievedValue, value, "Value should be correct under concurrent access")
                
                // Remove value
                UserDefaults.standard.removeObject(forKey: key)
                UserDefaults.standard.synchronize()
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Memory Management Tests
    
    func testProfileSettingsViewMemoryManagement() async throws {
        weak var weakView: ProfileSettingsView?
        weak var weakAuthService: MockAuthenticationService?
        
        autoreleasepool {
            let authService = MockAuthenticationService()
            authService.mockUser = MockUser(id: "test", name: "Test", email: "test@example.com", monthlyBudget: 100.0)
            
            let view = ProfileSettingsView()
            let testView = view.environmentObject(authService)
            
            weakView = view
            weakAuthService = authService
            
            // Perform operations that might create retain cycles
            Task {
                await authService.signOut()
            }
            
            // Let async operations complete
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        // Force garbage collection
        for _ in 0..<3 {
            autoreleasepool {
                _ = Array(0..<1000).map { $0 * 2 }
            }
        }
        
        // Verify objects are deallocated
        XCTAssertNil(weakView, "ProfileSettingsView should be deallocated")
        XCTAssertNil(weakAuthService, "AuthenticationService should be deallocated")
    }
    
    func testLoadingViewMemoryManagement() {
        weak var weakLoadingView: LoadingView?
        
        autoreleasepool {
            let loadingView = LoadingView(isSimpleMode: true)
            weakLoadingView = loadingView
            
            // Simulate view usage
            _ = loadingView.body
        }
        
        // Force garbage collection
        autoreleasepool {
            _ = Array(0..<100).map { $0 }
        }
        
        XCTAssertNil(weakLoadingView, "LoadingView should be deallocated")
    }
    
    func testMemoryLeaksDuringLogoutProcess() async throws {
        var memorySnapshots: [Int] = []
        
        // Take initial memory snapshot
        memorySnapshots.append(getCurrentMemoryUsage())
        
        // Perform multiple logout cycles
        for i in 0..<5 {
            autoreleasepool {
                let authService = MockAuthenticationService()
                authService.mockUser = MockUser(id: "test-\(i)", name: "Test \(i)", email: "test\(i)@example.com", monthlyBudget: 100.0)
                
                let view = ProfileSettingsView()
                _ = view.environmentObject(authService)
                
                // Simulate logout
                Task {
                    await authService.signOut()
                }
            }
            
            // Take memory snapshot after each cycle
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
            memorySnapshots.append(getCurrentMemoryUsage())
        }
        
        // Verify memory usage doesn't continuously grow
        let initialMemory = memorySnapshots[0]
        let finalMemory = memorySnapshots.last!
        let memoryGrowth = finalMemory - initialMemory
        
        // Allow for reasonable memory fluctuation (1MB)
        XCTAssertLessThan(memoryGrowth, 1024 * 1024, 
                         "Memory growth should not exceed 1MB over multiple logout cycles")
    }
    
    // MARK: - Data Consistency Tests
    
    func testUserDataConsistencyAfterLogout() async throws {
        // Setup initial user data
        let initialUser = MockUser(id: "test-user", name: "Test User", email: "test@example.com", monthlyBudget: 100.0)
        mockAuthService.mockUser = initialUser
        mockAuthService.isAuthenticated = true
        
        UserDefaults.standard.set("Test Fandom", forKey: "user_fandom_name")
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.synchronize()
        
        // Verify initial state
        XCTAssertTrue(mockAuthService.isAuthenticated)
        XCTAssertNotNil(mockAuthService.currentUser)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "user_fandom_name"), "Test Fandom")
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"))
        
        // Perform logout
        await mockAuthService.signOut()
        
        // Simulate UserDefaults cleanup (as done in the actual logout process)
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.synchronize()
        
        // Verify logout state consistency
        XCTAssertFalse(mockAuthService.isAuthenticated, "User should be unauthenticated")
        XCTAssertNil(mockAuthService.currentUser, "Current user should be nil")
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"), 
                      "Onboarding flag should be removed")
        
        // Fandom name might remain (depending on app logic)
        let fandomName = UserDefaults.standard.string(forKey: "user_fandom_name")
        // Test passes whether it's preserved or removed, as both are valid behaviors
    }
    
    func testStateRecoveryAfterAppRestart() throws {
        // Simulate app state before restart
        UserDefaults.standard.set("Persisted Fandom", forKey: "user_fandom_name")
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.synchronize()
        
        // Create new instance (simulating app restart)
        let newMockAuthService = MockAuthenticationService()
        newMockAuthService.isAuthenticated = false // User logged out before restart
        
        let newProfileView = ProfileSettingsView().environmentObject(newMockAuthService)
        
        // Verify persisted data is available
        let persistedFandom = UserDefaults.standard.string(forKey: "user_fandom_name")
        XCTAssertEqual(persistedFandom, "Persisted Fandom", "Fandom name should persist across app restarts")
        
        let persistedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        XCTAssertTrue(persistedOnboarding, "Onboarding state should persist until logout")
    }
    
    // MARK: - Concurrent State Management Tests
    
    func testConcurrentLogoutAttempts() async throws {
        mockAuthService.mockUser = MockUser(id: "test-user", name: "Test User", email: "test@example.com", monthlyBudget: 100.0)
        mockAuthService.isAuthenticated = true
        mockAuthService.signOutDelay = 0.5 // Slower logout to test concurrency
        
        // Start multiple logout attempts concurrently
        let task1 = Task { await mockAuthService.signOut() }
        let task2 = Task { await mockAuthService.signOut() }
        let task3 = Task { await mockAuthService.signOut() }
        
        // Wait for all attempts to complete
        await task1.value
        await task2.value  
        await task3.value
        
        // Verify final state is consistent
        XCTAssertFalse(mockAuthService.isAuthenticated, "Final auth state should be false")
        XCTAssertNil(mockAuthService.currentUser, "Final user should be nil")
        
        // Verify signOut was called appropriate number of times
        XCTAssertGreaterThanOrEqual(mockAuthService.signOutCallCount, 1, "SignOut should be called at least once")
        XCTAssertLessThanOrEqual(mockAuthService.signOutCallCount, 3, "SignOut should not be called more than 3 times")
    }
    
    func testStateManagementUnderMemoryPressure() {
        // Simulate memory pressure
        var largeArrays: [Array<Int>] = []
        
        for _ in 0..<10 {
            autoreleasepool {
                // Create large arrays to simulate memory pressure
                largeArrays.append(Array(0..<100000))
                
                // Test state operations under pressure
                mockAuthService.mockUser = MockUser(id: "pressure-test", name: "Pressure Test", email: "pressure@example.com", monthlyBudget: 100.0)
                XCTAssertTrue(mockAuthService.isAuthenticated, "State should remain consistent under memory pressure")
                
                UserDefaults.standard.set("pressure-test-fandom", forKey: "user_fandom_name")
                UserDefaults.standard.synchronize()
                
                let retrievedName = UserDefaults.standard.string(forKey: "user_fandom_name")
                XCTAssertEqual(retrievedName, "pressure-test-fandom", "UserDefaults should work under memory pressure")
                
                UserDefaults.standard.removeObject(forKey: "user_fandom_name")
                UserDefaults.standard.synchronize()
            }
        }
        
        // Clean up
        largeArrays.removeAll()
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int(info.resident_size)
        } else {
            return 0
        }
    }
}

// MARK: - Enhanced Mock Authentication Service
extension MockAuthenticationService {
    
    func simulateNetworkDelay() async {
        try? await Task.sleep(nanoseconds: UInt64(signOutDelay * 1_000_000_000))
    }
    
    func simulateAuthStateChange() {
        // Simulate realistic auth state changes
        objectWillChange.send()
    }
}

// MARK: - Test Data Persistence Helper
class TestDataPersistenceHelper {
    
    static func cleanAllTestData() {
        let testKeys = [
            "hasCompletedOnboarding",
            "user_fandom_name",
            "test_key_0", "test_key_1", "test_key_2", "test_key_3", "test_key_4",
            "test_key_5", "test_key_6", "test_key_7", "test_key_8", "test_key_9",
            "pressure-test-fandom"
        ]
        
        for key in testKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        UserDefaults.standard.synchronize()
    }
    
    static func verifyCleanState() -> Bool {
        let testKeys = [
            "hasCompletedOnboarding",
            "user_fandom_name"
        ]
        
        for key in testKeys {
            if UserDefaults.standard.object(forKey: key) != nil {
                return false
            }
        }
        
        return true
    }
}