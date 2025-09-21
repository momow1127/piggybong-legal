import Foundation
import RevenueCat

final class RevenueCatManager: NSObject, ObservableObject, @unchecked Sendable {
    private static var _shared: RevenueCatManager?
    private static let initQueue = DispatchQueue(label: "revenuecat.manager.init", qos: .userInitiated)

    static var shared: RevenueCatManager {
        return initQueue.sync {
            if _shared == nil {
                _shared = RevenueCatManager()
            }
            return _shared!
        }
    }
    
    @Published var isSubscriptionActive = false
    @Published var customerInfo: CustomerInfo?
    @Published var currentOffering: Offering?
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var hasValidPromoCode = false
    @Published var subscriptionTier: SubscriptionTier = .free
    @Published var trialDaysRemaining: Int = 0
    
    // Product and entitlement identifiers
    static let premiumEntitlementID = RevenueCatConfig.Entitlements.premium
    static let monthlyProductID = RevenueCatConfig.Products.stanPlusMonthly
    static let promoCode = RevenueCatConfig.PromoCodes.hackathonJudges
    
    // Premium feature limits
    private let freeArtistLimit = 3
    private let premiumArtistLimit = 6
    private let freeBudgetHistoryMonths = 1
    
    public override init() {
        super.init()

        // Safe initialization that won't crash
        // Check if Bundle.main is ready before configuring
        if Bundle.main.bundleIdentifier != nil {
            configureWithErrorHandling()
        } else {
            print("⚠️ RevenueCatManager: Bundle.main not ready, deferring configuration")
            // Defer configuration until Bundle.main is ready
            DispatchQueue.main.async {
                self.configureWithErrorHandling()
            }
        }
    }
    
    private func configureWithErrorHandling() {
        // Note: RevenueCat should be configured in AppDelegate first
        // This function now only sets up the manager-specific configuration

        // Guard against Purchases not being configured yet
        guard RevenueCatManager.isPurchasesConfigured() else {
            print("⚠️ RevenueCat not configured yet - will try again later")
            // Don't throw immediately, try to defer initialization
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.configureDeferred()
            }
            return
        }

        configurePurchases()
    }

    private func configureDeferred() {
        guard RevenueCatManager.isPurchasesConfigured() else {
            print("⚠️ RevenueCat still not configured after delay")
            return
        }
        configurePurchases()
    }

    private func configurePurchases() {

        // Set up customer info listener
        Purchases.shared.delegate = self
        
        // Configure for hackathon/competition
        #if DEBUG
        print("🎯 RevenueCat configured for competition demo")
        print("📝 Available promo codes: \(RevenueCatConfig.PromoCodes.hackathonJudges)")
        #endif
        
        // For testing in simulator - force StoreKit testing
        #if targetEnvironment(simulator)
        print("🧪 TESTING: Enabling StoreKit Testing mode for simulator")
        #endif
        
        // Check initial subscription status
        checkSubscriptionStatus()
        // Temporarily disable offerings loading to prevent startup errors
        // loadOfferings()
        setupTrialTracking()
    }
    
    // MARK: - Temporary VIP Access
    func activateTemporaryVIP(minutes: Int) {
        // Store the temporary VIP expiration time
        let expirationDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
        UserDefaults.standard.set(expirationDate, forKey: "temporaryVIPExpiration")
        
        // Activate VIP immediately
        isSubscriptionActive = true
        subscriptionTier = .premium
        hasValidPromoCode = true
        
        // IMMEDIATELY sync SubscriptionService with new VIP status
        DispatchQueue.main.async {
            SubscriptionService.shared.updateSubscriptionStatus(from: self)
        }
        
        print("⏰ Temporary VIP activated for \(minutes) minutes until \(expirationDate)")
        
        // Schedule deactivation
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(minutes * 60)) { [weak self] in
            self?.deactivateTemporaryVIP()
        }
    }
    
    private func deactivateTemporaryVIP() {
        // Check if temporary VIP has expired
        if let expirationDate = UserDefaults.standard.object(forKey: "temporaryVIPExpiration") as? Date,
           Date() >= expirationDate {
            UserDefaults.standard.removeObject(forKey: "temporaryVIPExpiration")
            
            // Reset to free tier unless they have a real subscription
            if customerInfo?.entitlements[Self.premiumEntitlementID]?.isActive != true {
                isSubscriptionActive = false
                subscriptionTier = .free
                hasValidPromoCode = false
                print("⏰ Temporary VIP access expired")
            }
        }
    }
    
    func checkSubscriptionStatus() {
        Task {
            await checkSubscriptionStatusWithTimeout()
        }
    }
    
    func checkSubscriptionStatusWithTimeout() async {
        DispatchQueue.main.async { self.isLoading = true }

        // Guard against RevenueCat not being configured
        guard RevenueCatManager.isPurchasesConfigured() else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.lastError = "Service temporarily unavailable"
                print("⚠️ Cannot check subscription - RevenueCat not configured")
            }
            return
        }

        do {
            let customerInfo = try await withTimeout(NetworkManager.revenueCatTimeout) {
                try await Purchases.shared.customerInfo()
            }

            DispatchQueue.main.async {
                self.updateSubscriptionStatus(customerInfo)
            }
            print("✅ Subscription status updated")

        } catch _ as TimeoutError {
            print("⏰ Subscription status check timed out")
            DispatchQueue.main.async {
                self.lastError = "Connection timeout. Premium features may be limited."
                // Graceful degradation - assume free tier
                self.subscriptionTier = .free
                self.isSubscriptionActive = false
            }
        } catch {
            print("❌ Failed to check subscription status: \(error)")
            DispatchQueue.main.async {
                self.lastError = error.localizedDescription
                // Graceful degradation - assume free tier
                self.subscriptionTier = .free
                self.isSubscriptionActive = false
            }
        }

        DispatchQueue.main.async { self.isLoading = false }
    }
    
    private func updateSubscriptionStatus(_ customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        self.isSubscriptionActive = !customerInfo.entitlements.active.isEmpty
        self.lastError = nil
        
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
    
    func loadOfferings() {
        Task {
            await loadOfferingsWithTimeout()
        }
    }
    
    func loadOfferingsWithTimeout() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.lastError = nil
        }

        // Guard against RevenueCat not being configured
        guard RevenueCatManager.isPurchasesConfigured() else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.lastError = "Service temporarily unavailable"
                print("⚠️ Cannot load offerings - RevenueCat not configured")
            }
            return
        }

        do {
            let offerings = try await withTimeout(NetworkManager.revenueCatTimeout) {
                try await Purchases.shared.offerings()
            }

            DispatchQueue.main.async {
                self.currentOffering = offerings.current
            }
            print("✅ Offerings loaded successfully")

        } catch _ as TimeoutError {
            DispatchQueue.main.async {
                self.lastError = "Connection timeout. Check your internet connection."
            }
            print("⏰ RevenueCat offerings load timed out")
        } catch {
            DispatchQueue.main.async {
                self.lastError = self.handleRevenueCatError(error)
            }
            print("❌ Failed to load offerings: \(error)")
        }

        DispatchQueue.main.async { self.isLoading = false }
    }
    
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
    
    func purchaseMonthlySubscription(completion: @escaping @Sendable (Bool, Error?) -> Void) {
        guard let offering = currentOffering,
              let monthlyPackage = offering.monthly else {
            completion(false, NSError(domain: "RevenueCat", code: -1, userInfo: [NSLocalizedDescriptionKey: "No monthly package available"]))
            return
        }
        
        isLoading = true
        
        // Add timeout wrapper for purchase operation
        let _ = DispatchQueue.main.asyncAfter(deadline: .now() + NetworkManager.revenueCatTimeout) { [weak self] in
            guard let self = self else { return }
            if self.isLoading {
                self.isLoading = false
                self.lastError = "Purchase request timed out. Please try again."
                completion(false, TimeoutError())
            }
        }
        
        Purchases.shared.purchase(package: monthlyPackage) { @Sendable [weak self] transaction, customerInfo, error, userCancelled in
            // Note: Cannot cancel DispatchQueue.main.asyncAfter in Swift 5 - will rely on isLoading check
            
            DispatchQueue.main.async {
                self?.isLoading = false

                // Assume monthlyPackage.storeProduct is non-optional
                let amount = NSDecimalNumber(decimal: monthlyPackage.storeProduct.price).doubleValue

                if userCancelled {
                    print("🚫 Purchase cancelled by user")
                    completion(false, nil)
                } else if let error = error {
                    let errorMessage = self?.handleRevenueCatError(error) ?? error.localizedDescription
                    self?.lastError = errorMessage
                    print("❌ Purchase failed: \(errorMessage)")

                    // Report payment error to Crashlytics
                    CrashlyticsService.shared.recordPaymentError(
                        error,
                        plan: "monthly",
                        amount: amount
                    )

                    completion(false, error)
                } else {
                    self?.customerInfo = customerInfo
                    self?.isSubscriptionActive = customerInfo?.entitlements[Self.premiumEntitlementID]?.isActive == true
                    self?.lastError = nil
                    print("✅ Purchase completed successfully")

                    // Track successful subscription purchase
                    AIInsightAnalyticsService.shared.logSubscriptionStarted(
                        plan: "monthly",
                        price: amount,
                        source: "paywall"
                    )

                    // Track successful purchase in Crashlytics for context
                    CrashlyticsService.shared.trackPurchase(
                        amount: amount,
                        currency: "USD",
                        itemCount: 1
                    )

                    // Set subscription status for crash context
                    CrashlyticsService.shared.setSubscriptionStatus(isActive: true, plan: "monthly")

                    completion(true, nil)
                }
            }
        }
    }
    
    func restorePurchases(completion: @escaping @Sendable (Bool, Error?) -> Void) {
        isLoading = true
        
        // Add timeout wrapper for restore operation
        let _ = DispatchQueue.main.asyncAfter(deadline: .now() + NetworkManager.revenueCatTimeout) { [weak self] in
            guard let self = self else { return }
            if self.isLoading {
                self.isLoading = false
                self.lastError = "Restore request timed out. Please try again."
                completion(false, TimeoutError())
            }
        }
        
        Purchases.shared.restorePurchases { @Sendable [weak self] customerInfo, error in
            // Note: Cannot cancel DispatchQueue.main.asyncAfter in Swift 5 - will rely on isLoading check
            
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    let errorMessage = self?.handleRevenueCatError(error) ?? error.localizedDescription
                    self?.lastError = errorMessage
                    print("❌ Restore failed: \(errorMessage)")
                    completion(false, error)
                } else {
                    self?.customerInfo = customerInfo
                    self?.isSubscriptionActive = customerInfo?.entitlements[Self.premiumEntitlementID]?.isActive == true
                    self?.lastError = nil
                    let isActive = self?.isSubscriptionActive ?? false
                    print("\(isActive ? "✅" : "⚠️") Restore completed - Premium: \(isActive)")
                    completion(isActive, nil)
                }
            }
        }
    }
    
    func setUserID(_ userID: String) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Purchases.shared.logIn(userID) { @Sendable customerInfo, created, error in
                if let error = error {
                    print("❌ RevenueCat login failed: \(error.localizedDescription)")
                } else {
                    print("✅ RevenueCat user ID set: \(userID), created: \(created)")
                    if let customerInfo = customerInfo {
                        DispatchQueue.main.async { [weak self] in
                            self?.customerInfo = customerInfo
                            self?.updateSubscriptionState(customerInfo)
                        }
                    }
                }
                continuation.resume()
            }
        }
    }
    
    func applyPromoCode(_ code: String, completion: @escaping (Bool, Error?) -> Void) {
        let upperCode = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if it's a valid hackathon promo code
        let validCodes = [
            RevenueCatConfig.PromoCodes.hackathonJudges,
            RevenueCatConfig.PromoCodes.shippathon,
            RevenueCatConfig.PromoCodes.betaTesters,
            "PIGGYVIP25" // Judge demo code
        ]
        
        if validCodes.contains(upperCode) {
            // Grant premium access for judges/testers
            hasValidPromoCode = true
            subscriptionTier = .premium
            isSubscriptionActive = true
            
            // Special handling for PIGGYVIP25 - 3 minute demo
            if upperCode == "PIGGYVIP25" {
                trialDaysRemaining = 0 // No trial days, just temporary access
                activateTemporaryVIP(minutes: 3)
            } else {
                trialDaysRemaining = 30 // Special extended trial for other codes
            }
            
            print("✅ Valid promo code applied: \(upperCode)")
            
            // IMMEDIATELY sync SubscriptionService with new VIP status
            DispatchQueue.main.async {
                SubscriptionService.shared.updateSubscriptionStatus(from: self)
            }
            
            completion(true, nil)
        } else {
            let error = NSError(domain: "PromoCode", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid promo code. Try: \(RevenueCatConfig.PromoCodes.hackathonJudges)"
            ])
            completion(false, error)
        }
    }
    
    // MARK: - Premium Feature Checks
    
    var canTrackUnlimitedArtists: Bool {
        return isPremiumActive
    }
    
    var canAccessAIConcierge: Bool {
        return isPremiumActive
    }
    
    var canAccessHistoricalData: Bool {
        return isPremiumActive
    }
    
    var canAccessAIFanPlanner: Bool {
        return isPremiumActive
    }
    
    var canAccessSmartSavings: Bool {
        return isPremiumActive
    }
    
    var canAccessPriorityAlerts: Bool {
        return isPremiumActive
    }
    
    var artistTrackingLimit: Int {
        return isPremiumActive ? premiumArtistLimit : freeArtistLimit
    }
    
    var budgetHistoryLimit: Int {
        return isPremiumActive ? Int.max : freeBudgetHistoryMonths
    }
    
    private var isPremiumActive: Bool {
        return isSubscriptionActive || hasValidPromoCode
    }
    
    func shouldShowPaywall(for feature: PremiumFeature) -> Bool {
        if isPremiumActive { return false }
        
        switch feature {
        case .unlimitedArtists:
            return true
        case .aiConcierge:
            return true
        case .aiFanPlanner:
            return true
        case .historicalData:
            return true
        case .smartSavings:
            return true
        case .priorityAlerts:
            return true
        case .advancedInsights:
            return true
        }
    }
    
    func getFeatureDescription(for feature: PremiumFeature) -> String {
        switch feature {
        case .unlimitedArtists:
            return "Track all your favorite K-pop artists without limits"
        case .aiConcierge:
            return "Get personalized K-pop recommendations"
        case .aiFanPlanner:
            return "AI-powered comeback planning and budget optimization"
        case .historicalData:
            return "Access your complete spending history and trends"
        case .smartSavings:
            return "Automated savings goals for upcoming releases"
        case .priorityAlerts:
            return "First to know about concerts, drops, and sales"
        case .advancedInsights:
            return "Deep analytics on your K-pop spending patterns"
        }
    }
    
    // MARK: - Helper Methods

    /// Check if Purchases has been configured to prevent crashes
    private static func isPurchasesConfigured() -> Bool {
        // Use a static flag that AppDelegate will set after configuration
        return RevenueCatManager.isConfiguredByAppDelegate
    }

    /// Static flag set by AppDelegate after Purchases.configure() is called
    static var isConfiguredByAppDelegate = false

    /// Called by AppDelegate after configuring RevenueCat
    static func notifyConfigurationComplete() {
        print("✅ [RevenueCatManager] Notified that RevenueCat is configured")
        isConfiguredByAppDelegate = true
        // If the shared instance already exists, configure it now
        if _shared != nil {
            shared.configureWithErrorHandling()
        }
    }

    private func updateSubscriptionState(_ customerInfo: CustomerInfo) {
        let wasActive = isSubscriptionActive
        isSubscriptionActive = customerInfo.entitlements[Self.premiumEntitlementID]?.isActive == true
        
        // Update subscription tier
        if isSubscriptionActive {
            subscriptionTier = .premium
        } else if hasValidPromoCode {
            subscriptionTier = .premium
        } else {
            subscriptionTier = .free
        }
        
        // Calculate trial days remaining
        if let entitlement = customerInfo.entitlements[Self.premiumEntitlementID],
           entitlement.periodType == .trial {
            trialDaysRemaining = calculateTrialDaysRemaining(entitlement)
        }
        
        // Notify about subscription changes
        if wasActive != isSubscriptionActive {
            NotificationCenter.default.post(
                name: .subscriptionStatusChanged,
                object: nil,
                userInfo: ["isActive": isSubscriptionActive]
            )
        }
    }
    
    private func calculateTrialDaysRemaining(_ entitlement: EntitlementInfo) -> Int {
        guard let expirationDate = entitlement.expirationDate else { return 0 }
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: expirationDate)
        return max(0, components.day ?? 0)
    }
    
    private func setupTrialTracking() {
        // Track trial usage for analytics
        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in
            if self.subscriptionTier == .premium && self.trialDaysRemaining > 0 {
                print("📅 Trial days remaining: \(self.trialDaysRemaining)")
            }
        }
    }
}

// MARK: - Subscription Tier Enum

enum SubscriptionTier {
    case free
    case premium
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Stan Plus Premium"
        }
    }
}

// MARK: - Premium Features Enum

enum PremiumFeature {
    case unlimitedArtists
    case aiConcierge
    case aiFanPlanner
    case historicalData
    case smartSavings
    case priorityAlerts
    case advancedInsights
    
    var title: String {
        switch self {
        case .unlimitedArtists: return "Unlimited Artists"
        case .aiConcierge: return "AI Concierge"
        case .aiFanPlanner: return "AI Fan Planner"
        case .historicalData: return "Historical Data"
        case .smartSavings: return "Smart Savings"
        case .priorityAlerts: return "Priority Alerts"
        case .advancedInsights: return "Advanced Insights"
        }
    }
    
    var icon: String {
        switch self {
        case .unlimitedArtists: return "person.3.fill"
        case .aiConcierge: return "brain.head.profile"
        case .aiFanPlanner: return "calendar.badge.clock"
        case .historicalData: return "chart.line.uptrend.xyaxis"
        case .smartSavings: return "banknote.fill"
        case .priorityAlerts: return "bell.badge.fill"
        case .advancedInsights: return "chart.pie.fill"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let subscriptionStatusChanged = Notification.Name("SubscriptionStatusChanged")
}

// MARK: - Timeout Wrapper

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

// MARK: - PurchasesDelegate
extension RevenueCatManager: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        DispatchQueue.main.async { @Sendable [weak self] in
            self?.customerInfo = customerInfo
            self?.updateSubscriptionState(customerInfo)
            
            // Log subscription status for debugging
            if let entitlement = customerInfo.entitlements[Self.premiumEntitlementID] {
                print("💳 Premium entitlement - Active: \(entitlement.isActive), Will Renew: \(entitlement.willRenew)")
                print("📅 Period Type: \(entitlement.periodType), Store: \(entitlement.store)")
            } else {
                print("❌ No premium entitlement found")
            }
        }
    }
    
    func purchases(_ purchases: Purchases, readyForPromotedProduct product: StoreProduct, purchase startPurchase: @escaping StartPurchaseBlock) {
        // Handle promoted purchases from App Store
        _ = product // Silence unused parameter warning
        startPurchase { @Sendable [weak self] transaction, customerInfo, error, userCancelled in
            DispatchQueue.main.async { @Sendable [weak self] in
                if let error = error {
                    print("❌ Promoted purchase failed: \(error.localizedDescription)")
                    self?.lastError = self?.handleRevenueCatError(error)
                } else if userCancelled {
                    print("🚫 Promoted purchase cancelled")
                } else if let customerInfo = customerInfo {
                    print("✅ Promoted purchase completed")
                    self?.customerInfo = customerInfo
                    self?.isSubscriptionActive = customerInfo.entitlements[RevenueCatManager.premiumEntitlementID]?.isActive == true
                    self?.updateSubscriptionState(customerInfo)
                }
            }
        }
    }
}
