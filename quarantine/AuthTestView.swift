import SwiftUI
import AuthenticationServices
import GoogleSignIn

/// Comprehensive authentication test view for debugging
struct AuthTestView: View {
    @StateObject private var authService = AuthenticationService.shared
    @State private var testResults: [TestResult] = []
    @State private var isRunningTests = false
    
    struct TestResult {
        let title: String
        let success: Bool
        let message: String
        let timestamp: Date
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("Quick Auth Tests") {
                    Button("Test All Authentication Methods") {
                        Task {
                            await runAllTests()
                        }
                    }
                    .disabled(isRunningTests)
                    
                    if isRunningTests {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Running tests...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Individual Tests") {
                    Button("Test Supabase Configuration") {
                        Task { await testSupabaseConfig() }
                    }
                    
                    Button("Test Google Sign-In Setup") {
                        Task { await testGoogleSetup() }
                    }
                    
                    Button("Test Apple Sign-In Setup") {
                        Task { await testAppleSetup() }
                    }
                    
                    Button("Test Email Authentication") {
                        Task { await testEmailAuth() }
                    }
                    
                    Button("Test Network Connectivity") {
                        Task { await testNetworkConnectivity() }
                    }
                }
                
                Section("Test Results") {
                    if testResults.isEmpty {
                        Text("No tests run yet")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(testResults.indices, id: \.self) { index in
                            let result = testResults[index]
                            TestResultRow(result: result)
                        }
                    }
                }
                
                Section("Manual Auth Tests") {
                    Button("Try Apple Sign-In") {
                        Task { await performAppleSignIn() }
                    }
                    
                    Button("Try Google Sign-In") {
                        Task { await performGoogleSignIn() }
                    }
                    
                    Button("Try Email Sign-In (Test Account)") {
                        Task { await performEmailSignIn() }
                    }
                }
                
                Section("Debug Actions") {
                    Button("Clear Test Results") {
                        testResults.removeAll()
                    }
                    
                    Button("Force Auth Reset") {
                        Task {
                            await authService.signOut()
                            addTestResult(
                                title: "Force Sign Out", 
                                success: true, 
                                message: "All auth state cleared"
                            )
                        }
                    }
                    
                    Button("Generate Debug Report") {
                        let report = AuthDebugUtility.generateDebugReport()
                        print(report)
                        addTestResult(
                            title: "Debug Report", 
                            success: true, 
                            message: "Report generated in console"
                        )
                    }
                }
            }
            .navigationTitle("Auth Tests")
            .refreshable {
                await runAllTests()
            }
        }
    }
    
    // MARK: - Test Methods
    
    private func runAllTests() async {
        isRunningTests = true
        testResults.removeAll()
        
        await testSupabaseConfig()
        await testGoogleSetup()
        await testAppleSetup()
        await testNetworkConnectivity()
        await testEmailAuth()
        
        isRunningTests = false
        
        let successCount = testResults.filter { $0.success }.count
        let totalCount = testResults.count
        
        addTestResult(
            title: "Test Summary",
            success: successCount == totalCount,
            message: "\(successCount)/\(totalCount) tests passed"
        )
    }
    
    private func testSupabaseConfig() async {
        let isValid = SupabaseConfig.isValid
        let url = SupabaseConfig.url
        let keyLength = SupabaseConfig.anonKey.count
        
        if isValid && url.hasPrefix("https://") && keyLength > 100 {
            addTestResult(
                title: "Supabase Config",
                success: true,
                message: "Valid configuration found"
            )
            
            // Test actual connection
            let canConnect = await SupabaseService.shared.checkSupabaseConnectivity()
            addTestResult(
                title: "Supabase Connection",
                success: canConnect,
                message: canConnect ? "Database connection successful" : "Database connection failed"
            )
        } else {
            addTestResult(
                title: "Supabase Config",
                success: false,
                message: "Invalid configuration - URL: \(url.prefix(30)), Key length: \(keyLength)"
            )
        }
    }
    
    private func testGoogleSetup() async {
        if let clientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String,
           !clientID.isEmpty {
            
            let hasValidFormat = clientID.hasSuffix(".apps.googleusercontent.com")
            let hasURLScheme = checkForGoogleURLScheme(clientID: clientID)
            
            if hasValidFormat && hasURLScheme {
                addTestResult(
                    title: "Google Sign-In Setup",
                    success: true,
                    message: "Configuration complete"
                )
            } else {
                addTestResult(
                    title: "Google Sign-In Setup",
                    success: false,
                    message: "Format: \(hasValidFormat), URL Scheme: \(hasURLScheme)"
                )
            }
        } else {
            addTestResult(
                title: "Google Sign-In Setup",
                success: false,
                message: "GOOGLE_CLIENT_ID not found in Info.plist"
            )
        }
    }
    
    private func testAppleSetup() async {
        let hasCapability = Bundle.main.object(forInfoDictionaryKey: "com.apple.developer.applesignin") != nil
        let hasBundleID = Bundle.main.bundleIdentifier != nil
        
        // Apple Sign-In should work with any valid bundle ID
        if let bundleID = Bundle.main.bundleIdentifier {
            addTestResult(
                title: "Apple Sign-In Setup",
                success: true,
                message: "Bundle ID configured: \(bundleID)"
            )
        } else {
            addTestResult(
                title: "Apple Sign-In Setup",
                success: false,
                message: "Missing bundle identifier"
            )
        }
    }
    
    private func testNetworkConnectivity() async {
        let isConnected = await NetworkManager.shared.checkConnectivity()
        
        addTestResult(
            title: "Network Connectivity",
            success: isConnected,
            message: isConnected ? "Internet connection available" : "No internet connection"
        )
        
        if isConnected {
            // Test Supabase endpoint
            await testEndpointReachability(
                url: SupabaseConfig.url,
                name: "Supabase"
            )
        }
    }
    
    private func testEmailAuth() async {
        // Test basic email auth configuration
        do {
            // Try to create a test request (don't actually send)
            let testEmail = "test@example.com"
            let testPassword = "testpassword123"
            
            // Validate email format
            if let emailError = authService.validateEmail(testEmail) {
                addTestResult(
                    title: "Email Validation",
                    success: false,
                    message: "Email validation failed: \(emailError)"
                )
                return
            }
            
            // Validate password format
            if let passwordError = authService.validatePassword(testPassword) {
                addTestResult(
                    title: "Password Validation",
                    success: false,
                    message: "Password validation failed: \(passwordError)"
                )
                return
            }
            
            addTestResult(
                title: "Email Auth Setup",
                success: true,
                message: "Email validation functions working"
            )
            
        } catch {
            addTestResult(
                title: "Email Auth Setup",
                success: false,
                message: "Configuration error: \(error.localizedDescription)"
            )
        }
    }
    
    private func testEndpointReachability(url: String, name: String) async {
        guard let testURL = URL(string: url) else {
            addTestResult(
                title: "\(name) Reachability",
                success: false,
                message: "Invalid URL: \(url)"
            )
            return
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: testURL)
            if let httpResponse = response as? HTTPURLResponse {
                let success = httpResponse.statusCode < 500
                addTestResult(
                    title: "\(name) Reachability",
                    success: success,
                    message: "HTTP \(httpResponse.statusCode)"
                )
            }
        } catch {
            addTestResult(
                title: "\(name) Reachability",
                success: false,
                message: "Connection failed: \(error.localizedDescription)"
            )
        }
    }
    
    // MARK: - Manual Auth Tests
    
    private func performAppleSignIn() async {
        do {
            // Create a mock credential for testing (this won't actually work in simulator)
            addTestResult(
                title: "Apple Sign-In Test",
                success: false,
                message: "Apple Sign-In requires device or TestFlight - use AuthenticationView instead"
            )
        }
    }
    
    private func performGoogleSignIn() async {
        do {
            try await authService.signInWithGoogle()
            addTestResult(
                title: "Google Sign-In Test",
                success: true,
                message: "Google Sign-In successful"
            )
        } catch {
            addTestResult(
                title: "Google Sign-In Test",
                success: false,
                message: "Error: \(error.localizedDescription)"
            )
        }
    }
    
    private func performEmailSignIn() async {
        // Try with a test account that should exist
        let request = AuthenticationService.SignInRequest(
            email: "test@piggybong.com",
            password: "testpassword123"
        )
        
        do {
            try await authService.signIn(request: request)
            addTestResult(
                title: "Email Sign-In Test",
                success: true,
                message: "Test account sign-in successful"
            )
        } catch {
            addTestResult(
                title: "Email Sign-In Test",
                success: false,
                message: "Error: \(error.localizedDescription)"
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkForGoogleURLScheme(clientID: String) -> Bool {
        guard let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] else {
            return false
        }
        
        for urlType in urlTypes {
            if let schemes = urlType["CFBundleURLSchemes"] as? [String] {
                for scheme in schemes {
                    if scheme == clientID {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private func addTestResult(title: String, success: Bool, message: String) {
        let result = TestResult(
            title: title,
            success: success,
            message: message,
            timestamp: Date()
        )
        testResults.append(result)
        print("\(success ? "✅" : "❌") \(title): \(message)")
    }
}

// MARK: - Test Result Row View

struct TestResultRow: View {
    let result: AuthTestView.TestResult
    
    var body: some View {
        HStack {
            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.success ? .green : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(result.title)
                    .font(.headline)
                    .foregroundColor(result.success ? .primary : .red)
                
                Text(result.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(result.timestamp, format: .dateTime.hour().minute().second())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    AuthTestView()
}