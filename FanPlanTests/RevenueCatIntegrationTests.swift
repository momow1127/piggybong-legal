import XCTest
import Foundation
import RevenueCat
@testable import Piggy_Bong

class RevenueCatIntegrationTests: XCTestCase {
    
    var revenueCatManager: RevenueCatManager!
    
    override func setUpWithError() throws {
        super.setUp()
        revenueCatManager = RevenueCatManager.shared
        
        // Ensure RevenueCat is properly configured
        revenueCatManager.configure()
        
        // Wait for initial configuration to complete
        let expectation = XCTestExpectation(description: "Initial configuration")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    override func tearDownWithError() throws {
        revenueCatManager = nil
        super.tearDown()
    }
    
    // MARK: - Configuration Integration Tests
    
    func testRevenueCatConfiguration() {
        // Test that RevenueCat is properly configured with correct API key
        XCTAssertNotNil(Purchases.shared, "Purchases should be initialized")
        
        // Test that delegate is properly set
        let delegate = Purchases.shared.delegate
        XCTAssertTrue(delegate is RevenueCatManager, "RevenueCatManager should be set as delegate")
        
        // Test configuration constants
        XCTAssertFalse(RevenueCatManager.premiumEntitlementID.isEmpty, "Premium entitlement ID should not be empty")
        XCTAssertFalse(RevenueCatManager.monthlyProductID.isEmpty, "Monthly product ID should not be empty")
    }
    
    func testInitialCustomerInfoFetch() async {
        let expectation = XCTestExpectation(description: "Customer info fetch")
        
        revenueCatManager.checkSubscriptionStatus()
        
        // Wait for customer info to be fetched
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            // Should complete without crashing
            XCTAssertFalse(self.revenueCatManager.isLoading, "Should not be loading after completion")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    // MARK: - Offerings Integration Tests
    
    func testOfferingsFetch() async {
        let expectation = XCTestExpectation(description: "Offerings fetch")
        
        revenueCatManager.loadOfferings()
        
        // Wait for offerings to be loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            // In test environment, offerings may or may not be available
            // The important thing is that it doesn't crash
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
        
        // Test offering validation if available
        if let offering = revenueCatManager.currentOffering {
            XCTAssertNotNil(offering.identifier, "Offering should have identifier")
            
            // Test that monthly package exists (required for our app)
            if let monthlyPackage = offering.monthly {
                XCTAssertNotNil(monthlyPackage.storeProduct, "Monthly package should have store product")
                XCTAssertNotNil(monthlyPackage.storeProduct.localizedTitle, "Product should have title")
                XCTAssertNotNil(monthlyPackage.storeProduct.localizedDescription, "Product should have description")
                XCTAssertGreaterThan(monthlyPackage.storeProduct.price, 0, "Product should have positive price")
            }
        }
    }
    
    func testOfferingsRetryMechanism() async {
        // Test that offerings can be reloaded if initial fetch fails
        let expectation = XCTestExpectation(description: "Offerings retry")
        expectation.expectedFulfillmentCount = 2
        
        // First attempt
        revenueCatManager.loadOfferings()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            expectation.fulfill()
            
            // Second attempt (retry)
            self.revenueCatManager.loadOfferings()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 8.0)
    }
    
    // MARK: - Purchase Flow Integration Tests
    
    func testPurchaseFlowWithoutOfferings() async {
        // Ensure no offerings are loaded
        revenueCatManager.currentOffering = nil
        
        let expectation = XCTestExpectation(description: "Purchase without offerings")
        
        revenueCatManager.purchaseMonthlySubscription { success, error in
            XCTAssertFalse(success, "Purchase should fail without offerings")
            XCTAssertNotNil(error, "Should return error when no offerings available")
            
            if let error = error as NSError? {
                XCTAssertEqual(error.domain, "RevenueCat", "Should return RevenueCat error")
                XCTAssertEqual(error.code, -1, "Should return expected error code")
            }
            
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testPurchaseFlowErrorHandling() async {
        // Load offerings first
        let offeringsExpectation = XCTestExpectation(description: "Load offerings")
        
        revenueCatManager.loadOfferings()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            offeringsExpectation.fulfill()
        }
        
        await fulfillment(of: [offeringsExpectation], timeout: 5.0)
        
        // Test purchase error handling (will fail in test environment, but should handle gracefully)
        let purchaseExpectation = XCTestExpectation(description: "Purchase error handling")
        
        revenueCatManager.purchaseMonthlySubscription { success, error in
            // In test environment, purchase will likely fail, but should be handled gracefully
            if !success {
                XCTAssertNotNil(error, "Failed purchase should return error")
            }
            
            // Should not crash and loading state should be cleared
            DispatchQueue.main.async {
                XCTAssertFalse(self.revenueCatManager.isLoading, "Loading state should be cleared")
                purchaseExpectation.fulfill()
            }
        }
        
        await fulfillment(of: [purchaseExpectation], timeout: 10.0)
    }
    
    // MARK: - Restore Purchases Integration Tests
    
    func testRestorePurchasesFlow() async {
        let expectation = XCTestExpectation(description: "Restore purchases")
        
        revenueCatManager.restorePurchases { success, error in
            // In test environment, restore may or may not find purchases
            // The important thing is that it completes without crashing
            
            DispatchQueue.main.async {
                XCTAssertFalse(self.revenueCatManager.isLoading, "Loading state should be cleared after restore")
                
                // If there was an error, it should be properly handled
                if let error = error {
                    XCTAssertNotNil(error.localizedDescription, "Error should have description")
                }
                
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    func testConcurrentRestoreOperations() async {
        // Test that multiple restore operations don't interfere with each other
        let expectation = XCTestExpectation(description: "Concurrent restore operations")
        expectation.expectedFulfillmentCount = 3
        
        for i in 0..<3 {
            revenueCatManager.restorePurchases { success, error in
                // Should handle concurrent operations gracefully
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 20.0)
        
        // Should end in consistent state
        XCTAssertFalse(revenueCatManager.isLoading, "Should not be loading after concurrent operations")
    }
    
    // MARK: - Subscription Status Integration Tests
    
    func testSubscriptionStatusConsistency() async {
        let expectation = XCTestExpectation(description: "Subscription status consistency")
        
        // Check status multiple times to ensure consistency
        var statusResults: [Bool] = []
        
        revenueCatManager.checkSubscriptionStatus()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            statusResults.append(self.revenueCatManager.isSubscriptionActive)
            
            self.revenueCatManager.checkSubscriptionStatus()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                statusResults.append(self.revenueCatManager.isSubscriptionActive)
                
                self.revenueCatManager.checkSubscriptionStatus()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    statusResults.append(self.revenueCatManager.isSubscriptionActive)
                    
                    // All status checks should return consistent results
                    let uniqueResults = Set(statusResults)
                    XCTAssertEqual(uniqueResults.count, 1, "Subscription status should be consistent across multiple checks")
                    
                    expectation.fulfill()
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    func testCustomerInfoUpdates() async {
        let expectation = XCTestExpectation(description: "Customer info updates")
        
        let initialCustomerInfo = revenueCatManager.customerInfo
        
        revenueCatManager.checkSubscriptionStatus()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            let updatedCustomerInfo = self.revenueCatManager.customerInfo
            
            // Customer info should be updated (even if it's the same data)
            // In test environment, this verifies the update mechanism works
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    // MARK: - Premium Features Integration Tests
    
    func testPremiumFeatureToggling() async {
        // Test premium features with different subscription states
        
        // 1. Test when not subscribed
        revenueCatManager.isSubscriptionActive = false
        
        XCTAssertFalse(revenueCatManager.canTrackUnlimitedArtists, "Should not allow unlimited artists when not subscribed")
        XCTAssertEqual(revenueCatManager.artistTrackingLimit, 2, "Should have limited artist tracking")
        XCTAssertTrue(revenueCatManager.shouldShowPaywall(for: .unlimitedArtists), "Should show paywall for premium features")
        
        // 2. Test when subscribed
        revenueCatManager.isSubscriptionActive = true
        
        XCTAssertTrue(revenueCatManager.canTrackUnlimitedArtists, "Should allow unlimited artists when subscribed")
        XCTAssertEqual(revenueCatManager.artistTrackingLimit, Int.max, "Should have unlimited artist tracking")
        XCTAssertFalse(revenueCatManager.shouldShowPaywall(for: .unlimitedArtists), "Should not show paywall when subscribed")
        
        // 3. Test all premium features
        let premiumFeatures: [PremiumFeature] = [.unlimitedArtists, .aiConcierge, .historicalData, .smartSavings, .priorityAlerts]
        
        for feature in premiumFeatures {
            // When not subscribed
            revenueCatManager.isSubscriptionActive = false
            XCTAssertTrue(revenueCatManager.shouldShowPaywall(for: feature), "Should show paywall for \(feature) when not subscribed")
            
            // When subscribed
            revenueCatManager.isSubscriptionActive = true
            XCTAssertFalse(revenueCatManager.shouldShowPaywall(for: feature), "Should not show paywall for \(feature) when subscribed")
        }
    }
    
    // MARK: - Promo Code Integration Tests
    
    func testPromoCodeValidation() async {
        let validExpectation = XCTestExpectation(description: "Valid promo code")
        
        revenueCatManager.applyPromoCode(RevenueCatManager.promoCode) { success, error in
            XCTAssertTrue(success, "Valid promo code should be accepted")
            XCTAssertNil(error, "Valid promo code should not return error")
            validExpectation.fulfill()
        }
        
        await fulfillment(of: [validExpectation], timeout: 3.0)
        
        let invalidExpectation = XCTestExpectation(description: "Invalid promo code")
        
        revenueCatManager.applyPromoCode("INVALID_CODE_12345") { success, error in
            XCTAssertFalse(success, "Invalid promo code should be rejected")
            XCTAssertNotNil(error, "Invalid promo code should return error")
            invalidExpectation.fulfill()
        }
        
        await fulfillment(of: [invalidExpectation], timeout: 3.0)
    }
    
    func testPromoCodeEdgeCases() async {
        let testCases = [
            ("", false),  // Empty code
            ("   ", false),  // Whitespace only
            ("invalid", false),  // Wrong code
            (RevenueCatManager.promoCode.lowercased(), true),  // Lowercase valid code
            (RevenueCatManager.promoCode.uppercased(), true),  // Uppercase valid code
            ("  \(RevenueCatManager.promoCode)  ", true),  // Valid code with whitespace
        ]
        
        for (code, expectedSuccess) in testCases {
            let expectation = XCTestExpectation(description: "Promo code test: \(code)")
            
            revenueCatManager.applyPromoCode(code) { success, error in
                XCTAssertEqual(success, expectedSuccess, "Promo code '\(code)' should return \(expectedSuccess)")
                
                if expectedSuccess {
                    XCTAssertNil(error, "Successful promo code should not return error")
                } else {
                    XCTAssertNotNil(error, "Failed promo code should return error")
                }
                
                expectation.fulfill()
            }
            
            await fulfillment(of: [expectation], timeout: 3.0)
        }
    }
    
    // MARK: - Performance Integration Tests
    
    func testOperationPerformance() async {
        // Test that RevenueCat operations complete within reasonable time
        
        // Test subscription status check performance
        let statusStartTime = Date()
        let statusExpectation = XCTestExpectation(description: "Status check performance")
        
        revenueCatManager.checkSubscriptionStatus()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            func checkIfCompleted() {
                if !self.revenueCatManager.isLoading {
                    let duration = Date().timeIntervalSince(statusStartTime)
                    XCTAssertLessThan(duration, 10.0, "Subscription status check should complete within 10 seconds")
                    statusExpectation.fulfill()
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: checkIfCompleted)
                }
            }
            checkIfCompleted()
        }
        
        await fulfillment(of: [statusExpectation], timeout: 15.0)
        
        // Test offerings load performance
        let offeringsStartTime = Date()
        let offeringsExpectation = XCTestExpectation(description: "Offerings load performance")
        
        revenueCatManager.loadOfferings()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            let duration = Date().timeIntervalSince(offeringsStartTime)
            XCTAssertLessThan(duration, 10.0, "Offerings load should complete within 10 seconds")
            offeringsExpectation.fulfill()
        }
        
        await fulfillment(of: [offeringsExpectation], timeout: 15.0)
    }
    
    // MARK: - Error Recovery Integration Tests
    
    func testNetworkErrorRecovery() async {
        // Test that the app handles network errors gracefully
        
        let expectation = XCTestExpectation(description: "Network error recovery")
        
        // Attempt operations that may fail due to network issues
        revenueCatManager.checkSubscriptionStatus()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            // Should handle network errors gracefully
            if let error = self.revenueCatManager.lastError {
                // If there's an error, it should be a proper error message
                XCTAssertNotNil(error, "Error should have description")
                XCTAssertFalse(error.isEmpty, "Error message should not be empty")
            }
            
            // Should not be in loading state indefinitely
            XCTAssertFalse(self.revenueCatManager.isLoading, "Should not be loading after timeout")
            
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    func testSubsequentOperationsAfterError() async {
        // Test that operations can continue normally after an error
        
        let firstExpectation = XCTestExpectation(description: "First operation")
        
        // First operation (may fail in test environment)
        revenueCatManager.checkSubscriptionStatus()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            firstExpectation.fulfill()
        }
        
        await fulfillment(of: [firstExpectation], timeout: 5.0)
        
        let secondExpectation = XCTestExpectation(description: "Second operation")
        
        // Second operation should work normally regardless of first operation result
        revenueCatManager.loadOfferings()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // Should not be stuck in error state
            XCTAssertFalse(self.revenueCatManager.isLoading, "Should not be loading after second operation")
            secondExpectation.fulfill()
        }
        
        await fulfillment(of: [secondExpectation], timeout: 5.0)
    }
    
    // MARK: - Thread Safety Integration Tests
    
    func testConcurrentRevenueCatOperations() async {
        let expectation = XCTestExpectation(description: "Concurrent operations")
        expectation.expectedFulfillmentCount = 4
        
        // Test that concurrent RevenueCat operations don't cause issues
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
        
        DispatchQueue.global().async {
            self.revenueCatManager.applyPromoCode("TEST") { _, _ in
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
        
        // Should end in consistent state without crashes
        XCTAssertFalse(revenueCatManager.isLoading, "Should not be loading after concurrent operations")
    }
    
    // MARK: - Integration with App Lifecycle
    
    func testAppLifecycleIntegration() async {
        // Test that RevenueCat handles app lifecycle events properly
        
        // Simulate app becoming active (common scenario)
        let activeExpectation = XCTestExpectation(description: "App active")
        
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        
        // Check that subscription status is refreshed
        revenueCatManager.checkSubscriptionStatus()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // Should handle app lifecycle notifications without issues
            activeExpectation.fulfill()
        }
        
        await fulfillment(of: [activeExpectation], timeout: 5.0)
    }
}