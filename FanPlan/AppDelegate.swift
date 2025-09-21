import UIKit
import UserNotifications
import RevenueCat
import FirebaseCore
import FirebaseAppCheck
import FirebaseAnalytics
import FirebasePerformance

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        print("AppDelegate: didFinishLaunchingWithOptions")

        // Configure App Check BEFORE Firebase for debug tokens to work
        #if DEBUG
        print("🔒 Setting up App Check Debug Provider...")
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        AppCheck.setAppCheckProviderFactory(DeviceCheckProviderFactory())
        #endif

        // Configure Firebase (includes Crashlytics) - Must be synchronous
        FirebaseApp.configure()
        CrashlyticsService.shared.configure()

        // Enable Firebase Analytics
        Analytics.setAnalyticsCollectionEnabled(true)

        // Enable Firebase Performance Monitoring
        Performance.sharedInstance().isDataCollectionEnabled = true
        Performance.sharedInstance().isInstrumentationEnabled = true

        #if DEBUG
        // Enable debug mode for immediate data in Firebase console
        Performance.sharedInstance().isDataCollectionEnabled = true
        print("🚀 Firebase Performance: Debug mode enabled for immediate data visibility")

        // Disable network instrumentation to prevent URLProtocol conflicts in debug builds
        Performance.sharedInstance().isInstrumentationEnabled = false
        print("⚠️ Firebase Performance: Network instrumentation disabled to prevent URLProtocol conflicts in debug")
        #endif

        print("🔥 Firebase: Configured successfully!")

        // CRITICAL: Configure RevenueCat SYNCHRONOUSLY before any other code can access it
        configureRevenueCatSynchronously()

        // Do async work in Task
        Task { @MainActor in
            // Log app launch event to test Analytics
            Analytics.logEvent(AnalyticsEventAppOpen, parameters: [
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                "platform": "ios"
            ])

            print("📊 Firebase Analytics: Enabled and test event logged")
            print("🚀 Firebase Performance: Enabled and ready to track app performance")
            print("🔒 Firebase App Check: Ready for secure requests")

            // Get App Check debug token (in DEBUG builds)
            #if DEBUG
            do {
                let token = try await AppCheck.appCheck().token(forcingRefresh: false)
                print("🔒 App Check Debug Token: \(token.token)")
                print("📝 Add this token to Firebase Console > App Check > Apps > Debug tokens")
            } catch {
                print("❌ App Check token error: \(error)")
            }
            #endif

            // Check device security
            if !(await SecurityService.shared.checkDeviceSecurity()) {
                print("⚠️ Security warning: Device security compromised")
                // You can show a warning to user or limit functionality
            }
        }

        return true
    }

    // Synchronous version for immediate configuration
    private func configureRevenueCatSynchronously() {
        print("🔄 [AppDelegate] Configuring RevenueCat SYNCHRONOUSLY...")

        let apiKey = RevenueCatConfig.apiKey

        if !apiKey.isEmpty && apiKey != "REPLACE_WITH_YOUR_REVENUECAT_API_KEY" {
            Purchases.logLevel = .debug
            Purchases.configure(withAPIKey: apiKey)
            print("✅ RevenueCat configured synchronously with API key: \(apiKey.prefix(10))...")

            // Notify RevenueCatManager that configuration is complete
            RevenueCatManager.notifyConfigurationComplete()

            // Set app user ID if we have one
            if let userId = UserDefaults.standard.string(forKey: "userId") {
                Task { @MainActor in
                    Purchases.shared.logIn(userId) { _, _, _ in
                        print("RevenueCat user ID set: \(userId)")
                    }
                }
            }
        } else {
            print("⚠️ RevenueCat API key not configured")
            #if DEBUG
            // In debug mode, configure with the development key to prevent crashes
            print("🚧 Using development key to prevent crashes in debug mode")
            let developmentKey = "appl_LTzZxrqzQBpTTIkBOJXnsmQJyzG"
            Purchases.logLevel = .debug
            Purchases.configure(withAPIKey: developmentKey)
            print("✅ RevenueCat configured with development key for debug builds")

            // Notify even with development key
            RevenueCatManager.notifyConfigurationComplete()
            #else
            // Production should use a fallback key to prevent crashes
            print("⚠️ Production build using fallback RevenueCat key")
            let fallbackKey = "appl_aXABVpZnhojTFHMskeYPUsIzXuX"
            Purchases.configure(withAPIKey: fallbackKey)

            // Notify even with fallback key
            RevenueCatManager.notifyConfigurationComplete()
            #endif
        }
    }

    @MainActor
    private func configureRevenueCat() {
        let apiKey = RevenueCatConfig.apiKey

        if !apiKey.isEmpty && apiKey != "REPLACE_WITH_YOUR_REVENUECAT_API_KEY" {
            Purchases.logLevel = .debug
            Purchases.configure(withAPIKey: apiKey)
            print("✅ RevenueCat configured with API key: \(apiKey.prefix(10))...")

            // Set app user ID if we have one
            if let userId = UserDefaults.standard.string(forKey: "userId") {
                Purchases.shared.logIn(userId) { _, _, _ in
                    print("RevenueCat user ID set: \(userId)")
                }
            }
        } else {
            print("⚠️ RevenueCat API key not configured")
            #if DEBUG
            // In debug mode, configure with the development key to prevent crashes
            print("🚧 Using development key to prevent crashes in debug mode")
            let developmentKey = "appl_LTzZxrqzQBpTTIkBOJXnsmQJyzG"  // Development key from documentation
            Purchases.logLevel = .debug
            Purchases.configure(withAPIKey: developmentKey)
            print("✅ RevenueCat configured with development key for debug builds")
            #else
            // Production should fail fast if no key is available
            print("❌ Production build requires valid RevenueCat API key")
            // Don't configure RevenueCat - app will handle gracefully
            #endif
        }
    }

    // MARK: - Push Notification Registration

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("AppDelegate: didRegisterForRemoteNotificationsWithDeviceToken")

        // Send the device token to our PushNotificationService
        NotificationCenter.default.post(
            name: UIApplication.didRegisterForRemoteNotificationsWithDeviceTokenNotification,
            object: nil,
            userInfo: ["deviceToken": deviceToken]
        )

        // Also send directly to PushNotificationService
        PushNotificationService.shared.didReceiveDeviceToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("AppDelegate: didFailToRegisterForRemoteNotificationsWithError: \(error)")

        // Send the error to our PushNotificationService
        NotificationCenter.default.post(
            name: UIApplication.didFailToRegisterForRemoteNotificationsErrorNotification,
            object: nil,
            userInfo: ["error": error]
        )

        // Also send directly to PushNotificationService
        PushNotificationService.shared.didFailToReceiveDeviceToken(error: error)
    }
}

// MARK: - Notification Names

extension UIApplication {
    static let didRegisterForRemoteNotificationsWithDeviceTokenNotification = Notification.Name("didRegisterForRemoteNotificationsWithDeviceToken")
    static let didFailToRegisterForRemoteNotificationsErrorNotification = Notification.Name("didFailToRegisterForRemoteNotificationsError")
}
