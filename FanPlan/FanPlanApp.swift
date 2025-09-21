import SwiftUI
import UserNotifications

@main
struct FanPlanApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var authService = AuthenticationService.shared
    @ObservedObject var pushService = PushNotificationService.shared
    @StateObject var globalLoading = GlobalLoadingManager.shared
    @State private var showDashboard = false

    // Lazy initialization to ensure AppDelegate configures RevenueCat first
    @StateObject private var revenueCatManager: RevenueCatManager = {
        // Defer initialization until after Bundle.main is ready
        print("🔧 DEBUG: Initializing RevenueCatManager after Bundle.main is ready")
        return RevenueCatManager.shared
    }()

    init() {
        // Run diagnostics first to debug Info.plist reading
        DiagnosticHelper.runDiagnostics()

        validateConfiguration()
        setupPushNotifications()

        #if DEBUG
        // Reset onboarding for testing - uncomment when needed
        // UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        print("🧪 DEBUG: Onboarding completion status: \(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"))")
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentCoordinator(authService: authService, showDashboard: $showDashboard)
                    .environmentObject(authService)
                    .environmentObject(pushService)
                    .environmentObject(revenueCatManager)
                    .environmentObject(SubscriptionService.shared)
                    .environmentObject(globalLoading)
                    .onAppear {
                        print("🔧 DEBUG: FanPlanApp main view appeared")
                        print("🔧 DEBUG: Services initialized")
                    }

                // Global loading overlay
                GlobalLoadingOverlay()
                    .environmentObject(globalLoading)

            }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // App became active - no longer requesting notifications here
                    // Notifications will be requested after artist selection in onboarding
                }
                .onOpenURL { url in
                    // Handle magic link deep links
                    Task {
                        await handleMagicLinkURL(url)
                    }
                }
        }
    }

    // MARK: - Configuration Validation
    private func validateConfiguration() {
        print("🔧 ===== FANPLAN APP STARTUP VALIDATION =====")
        print("🔧 App launched at: \(Date())")

        // 1. Validate Supabase Configuration
        print("🔧 Supabase Config Check:")
        print("  📋 URL: \(SupabaseConfig.url)")
        print("  🔑 Anon Key: \(SupabaseConfig.anonKey.prefix(20))...")
        print("  ✅ Config Valid: \(SupabaseConfig.isValid)")

        if !SupabaseConfig.isValid {
            print("❌ CRITICAL: Supabase configuration is invalid!")
            print("   Check your environment variables or Info.plist")
        }

        // 2. Check Google Client ID
        if let googleClientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String {
            print("🔐 Google Client ID: \(googleClientID.prefix(20))...")
        } else {
            print("⚠️  Google Client ID not found in Info.plist")
        }

        // 3. Check Bundle ID for Apple Sign In
        if let bundleID = Bundle.main.bundleIdentifier {
            print("🍎 Bundle ID: \(bundleID)")
        } else {
            print("❌ Bundle ID not found!")
        }

        // 4. Check Build Configuration
        #if DEBUG
        print("🔧 Build Configuration: DEBUG")

        // Check environment variables availability in debug builds
        let env = ProcessInfo.processInfo.environment
        if let envSupabaseURL = env["SUPABASE_URL"] {
            print("🌍 Environment SUPABASE_URL: \(envSupabaseURL.prefix(30))...")
        } else {
            print("⚠️  Environment SUPABASE_URL not available")
        }
        #else
        print("🔧 Build Configuration: RELEASE")
        #endif

        print("🔧 ============================================")
    }

    // MARK: - Magic Link Handling
    private func handleMagicLinkURL(_ url: URL) async {
        print("🔗 Received URL: \(url)")

        // Check if this is our magic link callback
        guard url.scheme == "piggybong" else {
            print("⚠️ Unknown URL scheme: \(url.scheme ?? "nil")")
            return
        }

        do {
            print("🔐 Processing magic link authentication...")

            // Use Supabase to handle the magic link session
            let session = try await SupabaseService.shared.client.auth.session(from: url)

            print("✅ Magic link session created successfully!")
            print("👤 User ID: \(session.user.id)")
            print("📧 Email: \(session.user.email ?? "N/A")")

            // The auth state listener will automatically handle the successful sign-in
            // No need to manually update authService here

            // FORCE: Set onboarding as completed for magic link users
            await MainActor.run {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                print("🔧 DEBUG: Forced onboarding completion for magic link user")
            }

        } catch {
            print("❌ Magic link authentication failed: \(error)")
            print("❌ Error description: \(error.localizedDescription)")

            // You could show an alert to the user here if needed
        }
    }

    // MARK: - Push Notifications Setup

    private func setupPushNotifications() {
        print("📱 Setting up push notifications...")

        // Set the notification center delegate
        UNUserNotificationCenter.current().delegate = pushService

        // Handle device token registration callbacks
        NotificationCenter.default.addObserver(
            forName: UIApplication.didRegisterForRemoteNotificationsWithDeviceTokenNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let deviceToken = notification.userInfo?["deviceToken"] as? Data {
                Task { @MainActor in
                    pushService.didReceiveDeviceToken(deviceToken)
                }
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didFailToRegisterForRemoteNotificationsErrorNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let error = notification.userInfo?["error"] as? Error {
                Task { @MainActor in
                    pushService.didFailToReceiveDeviceToken(error: error)
                }
            }
        }
    }

    private func requestPushNotificationPermissionIfNeeded() async {
        guard pushService.authorizationStatus == .notDetermined else { return }

        print("📱 Requesting push notification permission...")
        let granted = await pushService.requestPushNotificationPermission()
        print(granted ? "✅ Push notifications authorized" : "❌ Push notifications denied")
    }
}

struct ContentCoordinator: View {
    @ObservedObject var authService: AuthenticationService
    @Binding var showDashboard: Bool
    @State private var navigationKey = UUID()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        contentView
            .onChange(of: authService.isAuthenticated) { _, newValue in
                print("🔄 Authentication state changed to: \(newValue)")
                withAnimation(.easeInOut(duration: 0.3)) {
                    navigationKey = UUID()
                }
            }
            .onChange(of: authService.currentUser) { _, newUser in
                if let user = newUser {
                    print("🔄 Current user changed, user is now: \(user.email)")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        navigationKey = UUID()
                    }
                }
            }
    }

    @ViewBuilder
    private var contentView: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView()
                    .id("authenticated-\(navigationKey)")
                    .onAppear { print("🔧 DEBUG: Showing MainTabView") }
            } else {
                // Always show welcome screen for non-authenticated users
                WelcomeScreenCoordinator(showDashboard: $showDashboard)
                    .id("welcome-\(navigationKey)")
                    .onAppear { print("🔧 DEBUG: Showing WelcomeScreenCoordinator") }
            }
        }
        .onAppear {
            print("🔧 DEBUG: ContentCoordinator appeared")
            print("🔧 DEBUG: authService.isAuthenticated = \(authService.isAuthenticated)")
        }
    }
}
