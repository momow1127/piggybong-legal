//
//  FanPlanTests.swift
//  FanPlanTests
//
//  Created by Carmen Wong on 7/22/25.
//

import XCTest
@testable import Piggy_Bong

/// Main test suite entry point
/// This file serves as an example and entry point for the comprehensive test suite
/// For specific test implementations, see:
/// - AuthenticationServiceTests.swift (Authentication logic)
/// - SupabaseServiceTests.swift (Database operations)
/// - RevenueCatManagerTests.swift (Subscription management)
/// - SupabaseIntegrationTests.swift (End-to-end workflows)
/// - RevenueCatIntegrationTests.swift (Subscription integration)
/// - PerformanceTests.swift (Performance benchmarks)
class FanPlanTests: BaseTestCase {
    
    // MARK: - App Configuration Tests
    
    func testAppBundle() {
        // Verify basic app configuration
        let bundle = Bundle.main
        XCTAssertNotNil(bundle.bundleIdentifier, "App should have bundle identifier")
        XCTAssertNotNil(bundle.infoDictionary?["CFBundleName"], "App should have display name")
        XCTAssertNotNil(bundle.infoDictionary?["CFBundleVersion"], "App should have version")
    }
    
    func testTestConfiguration() {
        // Verify test environment is properly configured
        let config = TestConfiguration.shared
        
        XCTAssertNotNil(config, "Test configuration should be available")
        XCTAssertGreaterThan(config.defaultTimeout, 0, "Default timeout should be positive")
        XCTAssertGreaterThan(config.networkTimeout, 0, "Network timeout should be positive")
        
        // Log test environment info
        print("Test Environment Info:")
        print("- Running in CI: \(config.isRunningInCI)")
        print("- Using mock data: \(config.shouldUseMockData)")
        print("- Default timeout: \(config.defaultTimeout)s")
    }
    
    func testMockDataGeneration() {
        // Test mock data utilities
        let mockUser = TestUtilities.generateMockUser()
        XCTAssertFalse(mockUser.name.isEmpty, "Mock user should have name")
        XCTAssertTrue(mockUser.email.contains("@"), "Mock user should have valid email format")
        XCTAssertGreaterThan(mockUser.monthlyBudget, 0, "Mock user should have positive budget")
        
        let mockArtist = TestUtilities.generateMockArtist()
        XCTAssertFalse(mockArtist.name.isEmpty, "Mock artist should have name")
        XCTAssertFalse(mockArtist.group?.isEmpty ?? true, "Mock artist should have group")
        XCTAssertNotNil(mockArtist.id, "Mock artist should have ID")
        
        let mockGoal = TestUtilities.generateMockGoal()
        XCTAssertFalse(mockGoal.name.isEmpty, "Mock goal should have name")
        XCTAssertGreaterThan(mockGoal.targetAmount, 0, "Mock goal should have positive target")
        XCTAssertGreaterThanOrEqual(mockGoal.currentAmount, 0, "Mock goal current amount should not be negative")
    }
    
    // MARK: - Service Availability Tests
    
    func testServicesAvailability() {
        // Test that all core services can be instantiated
        let supabaseService = SupabaseService.shared
        XCTAssertNotNil(supabaseService, "SupabaseService should be available")
        
        let authService = AuthenticationService.shared
        XCTAssertNotNil(authService, "AuthenticationService should be available")
        
        let revenueCatManager = RevenueCatManager.shared
        XCTAssertNotNil(revenueCatManager, "RevenueCatManager should be available")
        
        // Verify initial states
        XCTAssertFalse(authService.isAuthenticated, "User should not be authenticated initially")
        XCTAssertNil(authService.currentUser, "Current user should be nil initially")
        XCTAssertFalse(authService.isLoading, "Authentication should not be loading initially")
    }
    
    // MARK: - Test Utilities Tests
    
    func testAsyncUtilities() async {
        // Test async testing utilities
        let condition = await TestUtilities.waitForCondition(timeout: 1.0) {
            return true
        }
        XCTAssertTrue(condition, "Wait for condition should succeed for true condition")
        
        let falseCondition = await TestUtilities.waitForCondition(timeout: 0.5) {
            return false
        }
        XCTAssertFalse(falseCondition, "Wait for condition should timeout for false condition")
        
        // Test async operation wrapper
        let result = await TestUtilities.waitForAsyncOperation {
            return "test result"
        }
        
        switch result {
        case .success(let value):
            XCTAssertEqual(value, "test result", "Async operation should return expected value")
        case .failure(let error):
            XCTFail("Async operation should not fail: \(error)")
        }
    }
    
    func testPerformanceMeasurement() {
        // Test performance measurement utilities
        let averageTime = TestUtilities.measureAverageTime(iterations: 5) {
            // Simulate some work
            Thread.sleep(forTimeInterval: 0.01)
        }
        
        XCTAssertGreaterThan(averageTime, 0, "Average time should be positive")
        XCTAssertLessThan(averageTime, 1.0, "Average time should be reasonable")
    }
    
    // MARK: - Basic Model Tests
    
    func testArtistModel() {
        let artist = Artist(
            name: "Test Artist",
            group: "Test Group",
            imageURL: "https://test.com/image.jpg",
            spotifyID: "test_spotify_id",
            isFollowing: true
        )
        
        XCTAssertEqual(artist.name, "Test Artist")
        XCTAssertEqual(artist.group, "Test Group")
        XCTAssertEqual(artist.imageURL, "https://test.com/image.jpg")
        XCTAssertEqual(artist.spotifyID, "test_spotify_id")
        XCTAssertTrue(artist.isFollowing)
    }
    
    func testGoalModel() {
        let deadline = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        let goal = Goal(
            name: "Concert Tickets",
            targetAmount: 200.0,
            currentAmount: 50.0,
            deadline: deadline,
            category: .concert,
            imageURL: "https://test.com/goal.jpg",
            artistName: "Test Artist",
            priority: .high
        )
        
        XCTAssertEqual(goal.name, "Concert Tickets")
        XCTAssertEqual(goal.targetAmount, 200.0)
        XCTAssertEqual(goal.currentAmount, 50.0)
        XCTAssertEqual(goal.category, .concert)
        XCTAssertEqual(goal.priority, .high)
        XCTAssertEqual(goal.progressPercentage, 25.0) // 50/200 * 100
    }
    
    // MARK: - Environment-Specific Tests
    
    func testCIEnvironment() {
        if TestConfiguration.shared.isRunningInCI {
            // Tests specific to CI environment
            print("Running in CI environment")
            XCTAssertTrue(TestConfiguration.shared.shouldUseMockData, "CI should use mock data")
            XCTAssertGreaterThan(TestConfiguration.shared.defaultTimeout, 10.0, "CI should have longer timeouts")
        } else {
            // Tests for local development
            print("Running in local development environment")
        }
    }
    
    func testLocalTestConfiguration() throws {
        if !TestConfiguration.shared.isRunningInCI {
            // Skip if in CI to avoid local-specific assumptions
            try skipTestIfInCI("Local configuration test")
            
            // Test local development setup
            XCTAssertLessThan(TestConfiguration.shared.defaultTimeout, 20.0, "Local tests should have reasonable timeouts")
        }
    }
    
    // MARK: - Integration Test Connectivity
    
    func testDatabaseConnectivity() async {
        // Test basic connectivity (should work with mock or real database)
        let supabaseService = SupabaseService.shared
        let isConnected = await supabaseService.checkSupabaseConnectivity()
        
        if TestConfiguration.shared.shouldUseMockData {
            // In mock mode, connection status may vary
            print("Database connection status (mock mode): \(isConnected)")
        } else {
            // With real database, should connect
            XCTAssertTrue(isConnected, "Should connect to test database")
        }
    }
    
    // MARK: - Test Suite Health Checks
    
    func testTestSuiteIntegrity() {
        // Verify all test classes are properly configured
        let testBundle = Bundle(for: type(of: self))
        XCTAssertNotNil(testBundle, "Test bundle should be available")
        
        // Check for required test files
        let requiredTestClasses = [
            "AuthenticationServiceTests",
            "SupabaseServiceTests", 
            "RevenueCatManagerTests",
            "PerformanceTests"
        ]
        
        for className in requiredTestClasses {
            let testClass = NSClassFromString("FanPlanTests.\(className)")
            XCTAssertNotNil(testClass, "\(className) should be available in test bundle")
        }
    }
}
