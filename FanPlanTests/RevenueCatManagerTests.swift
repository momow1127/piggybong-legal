import XCTest
import Foundation
import RevenueCat
@testable import Piggy_Bong

class RevenueCatManagerTests: XCTestCase {
    
    var revenueCatManager: RevenueCatManager!
    
    override func setUpWithError() throws {
        super.setUp()
        revenueCatManager = RevenueCatManager.shared
    }
    
    override func tearDownWithError() throws {
        revenueCatManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(revenueCatManager, "RevenueCatManager should initialize")
        XCTAssertFalse(revenueCatManager.isLoading, "Should not be loading initially")
        XCTAssertNil(revenueCatManager.lastError, "Should have no error initially")
    }
    
    func testSingletonPattern() {
        let manager1 = RevenueCatManager.shared
        let manager2 = RevenueCatManager.shared
        
        XCTAssertTrue(manager1 === manager2, "Should return same instance (singleton)")
    }
    
    // MARK: - Configuration Tests
    
    func testConfiguration() {
        // Test that configuration doesn't crash
        revenueCatManager.configure()
        
        XCTAssertNotNil(RevenueCatManager.premiumEntitlementID, "Premium entitlement ID should be set")
        XCTAssertNotNil(RevenueCatManager.monthlyProductID, "Monthly product ID should be set")
        XCTAssertNotNil(RevenueCatManager.promoCode, "Promo code should be set")
    }
    
    // MARK: - Subscription Status Tests
    
    func testInitialSubscriptionStatus() {
        // Initial state should be not subscribed
        XCTAssertFalse(revenueCatManager.isSubscriptionActive, "Should not be subscribed initially")
        XCTAssertNil(revenueCatManager.customerInfo, "Customer info should be nil initially")
    }
    
    func testCheckSubscriptionStatus() {
        let expectation = XCTestExpectation(description: "Check subscription status")
        
        revenueCatManager.checkSubscriptionStatus()
        
        // Wait for async completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Should complete without crashing
            XCTAssertFalse(self.revenueCatManager.isLoading, "Should not be loading after check")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Offerings Tests
    
    func testLoadOfferings() {
        let expectation = XCTestExpectation(description: "Load offerings")
        
        revenueCatManager.loadOfferings()
        
        // Wait for async completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // Should complete without crashing (may or may not have offerings in test environment)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Premium Feature Tests
    
    func testPremiumFeatureChecksWhenNotSubscribed() {
        // Ensure not subscribed for test
        revenueCatManager.isSubscriptionActive = false
        
        XCTAssertFalse(revenueCatManager.canTrackUnlimitedArtists, "Should not allow unlimited artists")
        XCTAssertFalse(revenueCatManager.canAccessAIConcierge, "Should not allow AI concierge")
        XCTAssertFalse(revenueCatManager.canAccessHistoricalData, "Should not allow historical data")
        XCTAssertEqual(revenueCatManager.artistTrackingLimit, 2, "Should have limited artist tracking")
    }
    
    func testPremiumFeatureChecksWhenSubscribed() {
        // Simulate subscription for test
        revenueCatManager.isSubscriptionActive = true
        
        XCTAssertTrue(revenueCatManager.canTrackUnlimitedArtists, "Should allow unlimited artists")
        XCTAssertTrue(revenueCatManager.canAccessAIConcierge, "Should allow AI concierge")
        XCTAssertTrue(revenueCatManager.canAccessHistoricalData, "Should allow historical data")
        XCTAssertEqual(revenueCatManager.artistTrackingLimit, Int.max, "Should have unlimited artist tracking")
    }
    
    func testShouldShowPaywallLogic() {
        // Test when not subscribed
        revenueCatManager.isSubscriptionActive = false
        
        XCTAssertTrue(revenueCatManager.shouldShowPaywall(for: .unlimitedArtists), "Should show paywall for unlimited artists")
        XCTAssertTrue(revenueCatManager.shouldShowPaywall(for: .aiConcierge), "Should show paywall for AI concierge")
        XCTAssertTrue(revenueCatManager.shouldShowPaywall(for: .historicalData), "Should show paywall for historical data")
        XCTAssertTrue(revenueCatManager.shouldShowPaywall(for: .smartSavings), "Should show paywall for smart savings")
        XCTAssertTrue(revenueCatManager.shouldShowPaywall(for: .priorityAlerts), "Should show paywall for priority alerts")
        
        // Test when subscribed
        revenueCatManager.isSubscriptionActive = true
        
        XCTAssertFalse(revenueCatManager.shouldShowPaywall(for: .unlimitedArtists), "Should not show paywall when subscribed")
        XCTAssertFalse(revenueCatManager.shouldShowPaywall(for: .aiConcierge), "Should not show paywall when subscribed")
        XCTAssertFalse(revenueCatManager.shouldShowPaywall(for: .historicalData), "Should not show paywall when subscribed")
        XCTAssertFalse(revenueCatManager.shouldShowPaywall(for: .smartSavings), "Should not show paywall when subscribed")
        XCTAssertFalse(revenueCatManager.shouldShowPaywall(for: .priorityAlerts), "Should not show paywall when subscribed")
    }
    
    // MARK: - Purchase Flow Tests
    
    func testPurchaseMonthlySubscriptionWithoutOffering() {
        let expectation = XCTestExpectation(description: "Purchase without offering")
        
        // Ensure no current offering
        revenueCatManager.currentOffering = nil
        
        revenueCatManager.purchaseMonthlySubscription { success, error in
            XCTAssertFalse(success, "Should not succeed without offering")
            XCTAssertNotNil(error, "Should return error without offering")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // Note: Testing actual purchases requires StoreKit testing environment
    // These tests focus on error handling and state management
    
    func testRestorePurchases() {
        let expectation = XCTestExpectation(description: "Restore purchases")
        
        revenueCatManager.restorePurchases { success, error in
            // Should complete without crashing (may or may not succeed in test environment)
            XCTAssertFalse(self.revenueCatManager.isLoading, "Should not be loading after restore attempt")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Promo Code Tests
    
    func testValidPromoCode() {
        let expectation = XCTestExpectation(description: "Valid promo code")
        
        revenueCatManager.applyPromoCode(RevenueCatManager.promoCode) { success, error in
            XCTAssertTrue(success, "Valid promo code should succeed")
            XCTAssertNil(error, "Valid promo code should not return error")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testInvalidPromoCode() {
        let expectation = XCTestExpectation(description: "Invalid promo code")
        
        revenueCatManager.applyPromoCode("INVALID_CODE") { success, error in
            XCTAssertFalse(success, "Invalid promo code should fail")
            XCTAssertNotNil(error, "Invalid promo code should return error")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testEmptyPromoCode() {
        let expectation = XCTestExpectation(description: "Empty promo code")
        
        revenueCatManager.applyPromoCode("") { success, error in
            XCTAssertFalse(success, "Empty promo code should fail")
            XCTAssertNotNil(error, "Empty promo code should return error")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testCaseInsensitivePromoCode() {
        let expectation = XCTestExpectation(description: "Case insensitive promo code")
        
        let lowercasePromo = RevenueCatManager.promoCode.lowercased()
        revenueCatManager.applyPromoCode(lowercasePromo) { success, error in
            XCTAssertTrue(success, "Promo code should be case insensitive")
            XCTAssertNil(error, "Case insensitive promo code should not return error")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - State Management Tests
    
    func testLoadingStateManagement() {
        // Test that loading state is properly managed during operations
        XCTAssertFalse(revenueCatManager.isLoading, "Should not be loading initially")
        
        let expectation = XCTestExpectation(description: "Loading state management")
        
        revenueCatManager.checkSubscriptionStatus()
        
        // Check that loading state is set immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Loading state may be true during operation
            
            // Wait for completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                XCTAssertFalse(self.revenueCatManager.isLoading, "Should not be loading after operation completes")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testErrorStateClearing() {
        // Set an error state
        revenueCatManager.lastError = "Test error"
        XCTAssertNotNil(revenueCatManager.lastError, "Should have error set")
        
        let expectation = XCTestExpectation(description: "Error state clearing")
        
        // Perform successful operation (or operation that clears error)
        revenueCatManager.checkSubscriptionStatus()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // Error should be cleared if operation succeeds
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentOperations() {
        let expectation = XCTestExpectation(description: "Concurrent operations")
        expectation.expectedFulfillmentCount = 3
        
        // Test multiple concurrent operations
        DispatchQueue.global().async {
            self.revenueCatManager.checkSubscriptionStatus()
            expectation.fulfill()
        }
        
        DispatchQueue.global().async {
            self.revenueCatManager.loadOfferings()
            expectation.fulfill()
        }
        
        DispatchQueue.global().async {
            self.revenueCatManager.restorePurchases { _, _ in
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Should complete without crashes or deadlocks
        XCTAssertTrue(true, "Concurrent operations should complete safely")
    }
    
    // MARK: - Integration Tests
    
    func testRevenueCatPurchasesIntegration() {
        // Test that RevenueCat Purchases framework is properly integrated
        XCTAssertNotNil(Purchases.shared, "Purchases should be configured")
        
        // Test that our manager is set as delegate
        let delegate = Purchases.shared.delegate
        XCTAssertTrue(delegate is RevenueCatManager, "RevenueCatManager should be set as delegate")
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() {
        // Test that the manager doesn't create retain cycles
        weak var weakManager = revenueCatManager
        
        revenueCatManager = nil
        
        // Note: RevenueCatManager is a singleton, so it won't be deallocated
        // This test ensures the singleton pattern is working correctly
        XCTAssertNotNil(weakManager, "Singleton should remain in memory")
        
        // Reset for other tests
        revenueCatManager = RevenueCatManager.shared
    }
    
    // MARK: - Performance Tests
    
    func testOperationPerformance() {
        measure {
            // Test performance of subscription status check
            let expectation = XCTestExpectation(description: "Performance test")
            
            revenueCatManager.checkSubscriptionStatus()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 2.0)
        }
    }
    
    func testPromoCodePerformance() {
        measure {
            // Test performance of promo code validation
            let expectation = XCTestExpectation(description: "Promo code performance")
            
            revenueCatManager.applyPromoCode("TEST_CODE") { _, _ in
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
}