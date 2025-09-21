import Foundation
import RevenueCat

/// Comprehensive RevenueCat Fix for API Issues
/// This addresses the "Invalid API Key" and timeout issues

// MARK: - Updated RevenueCat Configuration in FanPlanApp.swift

/// Replace the RevenueCat configuration in FanPlanApp.swift init() with this:
func configureRevenueCatWithErrorHandling() {
    print("🚀 Starting RevenueCat configuration...")
    
    let apiKey = RevenueCatConfig.apiKey
    print("🔑 Using API key: \(apiKey.prefix(10))...")
    
    // Enhanced API key validation
    guard isValidAPIKey(apiKey) else {
        print("❌ CRITICAL: Invalid RevenueCat API key format!")
        handleInvalidAPIKey()
        return
    }
    
    // Configure with proper error handling
    Purchases.logLevel = .debug
    Purchases.configure(withAPIKey: apiKey, appUserID: nil)
    
    // IMPORTANT: Remove network timeout setting (not available in all versions)
    // Purchases.shared.networkTimeout = NetworkManager.revenueCatTimeout
    
    print("✅ RevenueCat configured successfully")
    
    // Test configuration with timeout wrapper
    Task {
        await testRevenueCatConnectionSafely()
    }
}

private func isValidAPIKey(_ key: String) -> Bool {
    // RevenueCat iOS keys start with "appl_"
    return key.hasPrefix("appl_") && key.count > 20 && !key.contains("XXXXX")
}

private func handleInvalidAPIKey() {
    print("🔧 RevenueCat API Key Setup Required:")
    print("1. Visit https://app.revenuecat.com")
    print("2. Go to your app settings")
    print("3. Copy the iOS API key (starts with 'appl_')")
    print("4. Set environment variable: REVENUECAT_API_KEY=your_key_here")
    print("5. Or update Secrets.swift with your key")
    
    #if DEBUG
    print("ℹ️ App will continue in development mode without RevenueCat features")
    #else
    fatalError("RevenueCat API key required for production build")
    #endif
}

@MainActor
private func testRevenueCatConnectionSafely() async {
    do {
        // Test with timeout wrapper
        let customerInfo = try await withTimeout(NetworkManager.revenueCatTimeout) {
            try await Purchases.shared.customerInfo()
        }
        print("✅ RevenueCat connection test successful")
        print("📊 Customer info loaded: \(customerInfo.entitlements.active.count) active entitlements")
    } catch {
        print("⚠️ RevenueCat connection test failed: \(error)")
        if error.localizedDescription.contains("Invalid API key") {
            print("🚨 SOLUTION: Check your RevenueCat API key in dashboard")
            print("🔗 https://app.revenuecat.com")
        }
    }
}

// MARK: - Timeout Wrapper for RevenueCat Operations

func withTimeout<T>(_ timeout: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    return try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            throw TimeoutError()
        }
        
        guard let result = try await group.next() else {
            throw TimeoutError()
        }
        
        group.cancelAll()
        return result
    }
}

struct TimeoutError: Error {
    var localizedDescription: String {
        return "Operation timed out"
    }
}

// MARK: - Enhanced RevenueCat Manager Updates

extension RevenueCatManager {
    
    /// Safe method to load offerings with timeout
    @MainActor
    func loadOfferingsWithTimeout() async {
        isLoading = true
        lastError = nil
        
        do {
            let offerings = try await withTimeout(NetworkManager.revenueCatTimeout) {
                try await Purchases.shared.offerings()
            }
            
            currentOffering = offerings.current
            print("✅ Offerings loaded successfully")
            
        } catch let error as TimeoutError {
            lastError = "Connection timeout. Check your internet connection."
            print("⏰ RevenueCat offerings load timed out")
        } catch {
            lastError = handleRevenueCatError(error)
            print("❌ Failed to load offerings: \(error)")
        }
        
        isLoading = false
    }
    
    /// Enhanced error handling for RevenueCat errors
    private func handleRevenueCatError(_ error: Error) -> String {
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("invalid api key") || errorDescription.contains("credentials") {
            return "Configuration issue. Please check app settings."
        } else if errorDescription.contains("network") || errorDescription.contains("timeout") {
            return "Network connection issue. Please try again."
        } else if errorDescription.contains("store") {
            return "App Store connection issue. Please try again later."
        } else {
            return "Unable to load subscription options. Please try again."
        }
    }
    
    /// Safe subscription check with timeout
    @MainActor
    func checkSubscriptionStatusWithTimeout() async {
        do {
            let customerInfo = try await withTimeout(NetworkManager.revenueCatTimeout) {
                try await Purchases.shared.customerInfo()
            }
            
            updateSubscriptionStatus(customerInfo)
            print("✅ Subscription status updated")
            
        } catch let error as TimeoutError {
            print("⏰ Subscription status check timed out")
        } catch {
            print("❌ Failed to check subscription status: \(error)")
        }
    }
    
    private func updateSubscriptionStatus(_ customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        self.isSubscriptionActive = !customerInfo.entitlements.active.isEmpty
        
        // Update subscription tier
        if customerInfo.entitlements.active[RevenueCatManager.premiumEntitlementID] != nil {
            subscriptionTier = .premium
        } else {
            subscriptionTier = .free
        }
        
        // Calculate trial days remaining
        if let entitlement = customerInfo.entitlements.active[RevenueCatManager.premiumEntitlementID] {
            trialDaysRemaining = calculateTrialDaysRemaining(entitlement)
        }
    }
    
    private func calculateTrialDaysRemaining(_ entitlement: EntitlementInfo) -> Int {
        guard entitlement.periodType == .trial,
              let expirationDate = entitlement.expirationDate else {
            return 0
        }
        
        let calendar = Calendar.current
        let now = Date()
        let days = calendar.dateComponents([.day], from: now, to: expirationDate).day ?? 0
        return max(0, days)
    }
}

// MARK: - Subscription Tier Enum

enum SubscriptionTier {
    case free
    case premium
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Premium"
        }
    }
}

/// SETUP INSTRUCTIONS:
/// 1. Replace FanPlanApp.swift RevenueCat configuration with configureRevenueCatWithErrorHandling()
/// 2. Update RevenueCatManager with the new timeout methods
/// 3. Set environment variable: REVENUECAT_API_KEY=your_actual_key
/// 4. Test in Xcode with proper API key from RevenueCat dashboard