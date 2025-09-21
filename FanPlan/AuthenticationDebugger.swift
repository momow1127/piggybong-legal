import Foundation
import SwiftUI
import AuthenticationServices
import GoogleSignIn

// MARK: - Authentication Debug Utility
/// Comprehensive debugging tool for authentication flows
struct AuthenticationDebugger {

    // MARK: - Configuration Validation
    static func validateConfiguration() {
        print("🔍 === AUTHENTICATION CONFIGURATION AUDIT ===")

        // Check Supabase Configuration
        validateSupabaseConfig()

        // Check Google Configuration
        validateGoogleConfig()

        // Check Apple Configuration
        validateAppleConfig()

        print("🔍 === CONFIGURATION AUDIT COMPLETE ===")
    }

    private static func validateSupabaseConfig() {
        print("\n📊 SUPABASE CONFIGURATION:")

        // Check environment variables
        let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"]
        let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]

        print("   - SUPABASE_URL: \(supabaseURL?.isEmpty == false ? "✅ SET" : "❌ MISSING")")
        print("   - SUPABASE_ANON_KEY: \(supabaseKey?.isEmpty == false ? "✅ SET" : "❌ MISSING")")

        // Check Info.plist
        let plistURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
        let plistKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String

        print("   - Info.plist SUPABASE_URL: \(plistURL?.contains("$(") == false ? "✅ CONFIGURED" : "❌ NOT RESOLVED")")
        print("   - Info.plist SUPABASE_ANON_KEY: \(plistKey?.contains("$(") == false ? "✅ CONFIGURED" : "❌ NOT RESOLVED")")

        // Validate URL format
        if let url = supabaseURL ?? plistURL, !url.contains("$(") {
            if url.hasPrefix("https://") && url.contains(".supabase.co") {
                print("   - URL Format: ✅ VALID")
            } else {
                print("   - URL Format: ❌ INVALID (should be https://xxx.supabase.co)")
            }
        }
    }

    private static func validateGoogleConfig() {
        print("\n📊 GOOGLE SIGN-IN CONFIGURATION:")

        // Check Google Client ID
        let googleClientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String
        print("   - GOOGLE_CLIENT_ID: \(googleClientID?.contains("$(") == false ? "✅ CONFIGURED" : "❌ NOT RESOLVED")")

        // Check URL Schemes
        if let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] {
            let hasGoogleScheme = urlTypes.contains { urlType in
                if let schemes = urlType["CFBundleURLSchemes"] as? [String] {
                    return schemes.contains { $0.contains("com.googleusercontent.apps") }
                }
                return false
            }
            print("   - URL Scheme: \(hasGoogleScheme ? "✅ CONFIGURED" : "❌ MISSING")")
        } else {
            print("   - URL Scheme: ❌ NO URL TYPES FOUND")
        }

        // Validate Client ID format
        if let clientID = googleClientID, !clientID.contains("$(") {
            if clientID.hasSuffix(".apps.googleusercontent.com") {
                print("   - Client ID Format: ✅ VALID")
            } else {
                print("   - Client ID Format: ❌ INVALID (should end with .apps.googleusercontent.com)")
            }
        }
    }

    private static func validateAppleConfig() {
        print("\n📊 APPLE SIGN-IN CONFIGURATION:")

        // Check capabilities (this is best effort - requires entitlements)
        print("   - Apple Sign In Capability: ⚠️ CHECK XCODE PROJECT SETTINGS")
        print("   - Bundle ID: \(Bundle.main.bundleIdentifier ?? "UNKNOWN")")

        // Check if running in simulator
        #if targetEnvironment(simulator)
        print("   - Environment: ⚠️ SIMULATOR (Apple Sign In will not work)")
        #else
        print("   - Environment: ✅ DEVICE (Apple Sign In should work)")
        #endif
    }

    // MARK: - Authentication Flow Testing
    static func testAuthenticationFlow() async {
        print("\n🧪 === AUTHENTICATION FLOW TESTING ===")

        // Test anonymous authentication (simplest)
        await testAnonymousAuth()

        // Test email authentication
        await testEmailAuthComponents()

        print("🧪 === FLOW TESTING COMPLETE ===")
    }

    private static func testAnonymousAuth() async {
        print("\n🔓 TESTING ANONYMOUS AUTHENTICATION:")

        do {
            let authService = SupabaseService.shared.authService
            let user = try await authService.signInAnonymously()
            print("   - Anonymous Auth: ✅ SUCCESS")
            print("   - User ID: \(user.id)")
            print("   - User Email: \(user.email ?? "anonymous")")

            // Sign out to clean up
            try await authService.signOut()
            print("   - Sign Out: ✅ SUCCESS")

        } catch {
            print("   - Anonymous Auth: ❌ FAILED")
            print("   - Error: \(error.localizedDescription)")
        }
    }

    private static func testEmailAuthComponents() async {
        print("\n📧 TESTING EMAIL AUTH COMPONENTS:")

        // Test if we can reach Supabase auth endpoint
        let supabaseService = SupabaseService.shared
        print("   - Supabase Connection: Testing...")

        // Try to get current session (should be nil but shouldn't error)
        do {
            let session = try await supabaseService.client.auth.session
            print("   - Current Session: ✅ FOUND (User: \(session.user.email ?? "unknown"))")
        } catch {
            print("   - Current Session: ✅ NONE (Expected for fresh test)")
        }
    }

    // MARK: - Error Diagnostics
    static func diagnoseAuthError(_ error: Error) {
        print("\n🩺 === ERROR DIAGNOSIS ===")
        print("Error Type: \(type(of: error))")
        print("Description: \(error.localizedDescription)")

        if let nsError = error as NSError? {
            print("Domain: \(nsError.domain)")
            print("Code: \(nsError.code)")
            print("UserInfo: \(nsError.userInfo)")
        }

        // Provide specific guidance based on error content
        let errorMessage = error.localizedDescription.lowercased()

        if errorMessage.contains("network") {
            print("\n💡 NETWORK ERROR SUGGESTIONS:")
            print("   - Check internet connection")
            print("   - Verify Supabase URL is correct")
            print("   - Check firewall/VPN settings")
        }

        if errorMessage.contains("invalid") {
            print("\n💡 INVALID REQUEST SUGGESTIONS:")
            print("   - Check API keys are correctly configured")
            print("   - Verify environment variables are set")
            print("   - Ensure Supabase project is active")
        }

        if errorMessage.contains("unauthorized") {
            print("\n💡 AUTHORIZATION ERROR SUGGESTIONS:")
            print("   - Check Supabase anonymous key")
            print("   - Verify project permissions")
            print("   - Check RLS policies")
        }

        if errorMessage.contains("google") {
            print("\n💡 GOOGLE SIGN-IN SUGGESTIONS:")
            print("   - Check Google Client ID configuration")
            print("   - Verify URL scheme matches client ID")
            print("   - Ensure Google Sign-In is enabled in Google Console")
        }

        if errorMessage.contains("apple") {
            print("\n💡 APPLE SIGN-IN SUGGESTIONS:")
            print("   - Test on physical device (not simulator)")
            print("   - Check Apple Developer Console configuration")
            print("   - Verify Services ID matches bundle ID")
        }

        print("🩺 === DIAGNOSIS COMPLETE ===")
    }

    // MARK: - Quick Health Check
    static func quickHealthCheck() -> HealthReport {
        var report = HealthReport()

        // Supabase configuration
        let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ??
                         Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
        let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ??
                         Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String

        report.supabaseConfigured = supabaseURL?.contains("$(") == false && supabaseKey?.contains("$(") == false

        // Google configuration
        let googleClientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String
        report.googleConfigured = googleClientID?.contains("$(") == false

        // Apple configuration (basic check)
        #if targetEnvironment(simulator)
        report.appleAvailable = false
        #else
        report.appleAvailable = true
        #endif

        return report
    }
}

// MARK: - Health Report Model
struct HealthReport {
    var supabaseConfigured = false
    var googleConfigured = false
    var appleAvailable = false

    var overallHealth: String {
        let configured = [supabaseConfigured, googleConfigured, appleAvailable].filter { $0 }.count

        switch configured {
        case 3: return "✅ EXCELLENT"
        case 2: return "⚠️ GOOD"
        case 1: return "🔧 NEEDS WORK"
        case 0: return "❌ CRITICAL"
        default: return "UNKNOWN"
        }
    }
}

// MARK: - SwiftUI Debug View
struct AuthenticationDebugView: View {
    @State private var healthReport = HealthReport()
    @State private var isRunningTests = false
    @State private var testOutput = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Authentication Debugger")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Health Status
                VStack(alignment: .leading, spacing: 10) {
                    Text("System Health: \(healthReport.overallHealth)")
                        .font(.headline)

                    Text("Supabase: \(healthReport.supabaseConfigured ? "✅" : "❌")")
                    Text("Google: \(healthReport.googleConfigured ? "✅" : "❌")")
                    Text("Apple: \(healthReport.appleAvailable ? "✅" : "❌")")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

                // Test Controls
                Button("Run Configuration Validation") {
                    AuthenticationDebugger.validateConfiguration()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)

                Button("Run Authentication Tests") {
                    isRunningTests = true
                    Task {
                        await AuthenticationDebugger.testAuthenticationFlow()
                        isRunningTests = false
                    }
                }
                .disabled(isRunningTests)
                .padding()
                .background(isRunningTests ? Color.gray : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)

                if isRunningTests {
                    Text("Running tests...")
                        .foregroundColor(.orange)
                }
            }
            .padding()
        }
        .onAppear {
            healthReport = AuthenticationDebugger.quickHealthCheck()
        }
    }
}

#Preview {
    AuthenticationDebugView()
}
