import Foundation
import SwiftUI

/// Debug utility to diagnose authentication configuration issues
struct AuthDebugUtility {
    static func performComprehensiveAuthCheck() {
        print("\n🔍 AUTHENTICATION DEBUG REPORT")
        print(String(repeating: "=", count: 50))
        
        checkSupabaseConfiguration()
        checkGoogleSignInConfiguration()
        checkAppleSignInConfiguration()
        checkNetworkConnectivity()
        checkEnvironmentVariables()
        
        print(String(repeating: "=", count: 50))
        print("✅ Authentication debug check complete\n")
    }
    
    private static func checkSupabaseConfiguration() {
        print("\n📡 SUPABASE CONFIGURATION")
        print(String(repeating: "-", count: 30))
        
        // Check SupabaseConfig
        let configValid = SupabaseConfig.isValid
        let configURL = SupabaseConfig.url
        let configKey = String(SupabaseConfig.anonKey.prefix(20)) + "..."
        
        print("Config Valid: \(configValid ? "✅" : "❌")")
        print("URL: \(configURL)")
        print("Key: \(configKey)")
        
        // Check Info.plist values
        if let plistURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String {
            print("Info.plist URL: ✅ \(plistURL)")
        } else {
            print("Info.plist URL: ❌ Not found")
        }
        
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String {
            print("Info.plist Key: ✅ \(String(plistKey.prefix(20)))...")
        } else {
            print("Info.plist Key: ❌ Not found")
        }
        
        // Test URL validity
        if let url = URL(string: configURL), url.scheme == "https" {
            print("URL Format: ✅ Valid HTTPS URL")
        } else {
            print("URL Format: ❌ Invalid URL")
        }
        
        // Check key format
        if configKey.hasPrefix("eyJ") {
            print("Key Format: ✅ Valid JWT format")
        } else {
            print("Key Format: ❌ Invalid JWT format")
        }
    }
    
    private static func checkGoogleSignInConfiguration() {
        print("\n🔐 GOOGLE SIGN-IN CONFIGURATION")
        print(String(repeating: "-", count: 30))
        
        if let clientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String {
            print("Client ID: ✅ \(String(clientID.prefix(30)))...")
            
            // Check format
            if clientID.hasSuffix(".apps.googleusercontent.com") {
                print("Format: ✅ Valid Google Client ID format")
            } else {
                print("Format: ❌ Invalid format (should end with .apps.googleusercontent.com)")
            }
        } else {
            print("Client ID: ❌ Not found in Info.plist")
            print("💡 Add GOOGLE_CLIENT_ID key to Info.plist")
        }
        
        // Check URL schemes
        if let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] {
            let googleSchemes = urlTypes.compactMap { dict in
                (dict["CFBundleURLSchemes"] as? [String])?.first
            }.filter { $0.contains("googleusercontent.com") }
            
            if !googleSchemes.isEmpty {
                print("URL Schemes: ✅ Google OAuth scheme configured")
            } else {
                print("URL Schemes: ❌ Google OAuth scheme missing")
                print("💡 Add your Google Client ID as a URL scheme")
            }
        } else {
            print("URL Schemes: ❌ No URL schemes configured")
        }
    }
    
    private static func checkAppleSignInConfiguration() {
        print("\n🍎 APPLE SIGN-IN CONFIGURATION")
        print(String(repeating: "-", count: 30))
        
        if let clientID = Bundle.main.object(forInfoDictionaryKey: "APPLE_CLIENT_ID") as? String {
            print("Client ID: ✅ \(clientID)")
        } else {
            print("Client ID: ❌ Not found in Info.plist")
        }
        
        // Check bundle identifier format for Apple Sign-In
        if let bundleID = Bundle.main.bundleIdentifier {
            print("Bundle ID: ✅ \(bundleID)")
            
            // Apple Sign-In works with any valid bundle identifier
            if bundleID.contains(".") {
                print("Format: ✅ Valid bundle identifier format")
            } else {
                print("Format: ❌ Invalid bundle identifier")
            }
        } else {
            print("Bundle ID: ❌ Not found")
        }
    }
    
    private static func checkNetworkConnectivity() {
        print("\n🌐 NETWORK CONNECTIVITY")
        print(String(repeating: "-", count: 30))
        
        let networkManager = NetworkManager.shared
        print("Current Connection: \(networkManager.isConnected ? "✅ Connected" : "❌ Disconnected")")
        
        if let connectionType = networkManager.connectionType {
            print("Connection Type: \(connectionType.description)")
        }
        
        // Test Supabase URL reachability
        Task {
            let url = SupabaseConfig.url
            await testURLReachability(url: url, service: "Supabase")
            await testURLReachability(url: "https://accounts.google.com", service: "Google")
            await testURLReachability(url: "https://appleid.apple.com", service: "Apple")
        }
    }
    
    private static func checkEnvironmentVariables() {
        print("\n🔧 ENVIRONMENT VARIABLES")
        print(String(repeating: "-", count: 30))
        
        let envVars = [
            "SUPABASE_URL",
            "SUPABASE_ANON_KEY",
            "GOOGLE_CLIENT_ID",
            "APPLE_CLIENT_ID",
            "REVENUECAT_API_KEY"
        ]
        
        for variable in envVars {
            // Check environment variables first
            if let envValue = ProcessInfo.processInfo.environment[variable], !envValue.isEmpty {
                let preview = String(envValue.prefix(20)) + (envValue.count > 20 ? "..." : "")
                print("\(variable): ✅ \(preview) (from environment)")
            }
            // Check Info.plist as fallback
            else if let plistValue = Bundle.main.object(forInfoDictionaryKey: variable) as? String, !plistValue.isEmpty {
                let preview = String(plistValue.prefix(20)) + (plistValue.count > 20 ? "..." : "")
                print("\(variable): ✅ \(preview) (from Info.plist)")
            } else {
                print("\(variable): ❌ Not set")
            }
        }
    }
    
    @MainActor
    private static func testURLReachability(url: String, service: String) async {
        guard let testURL = URL(string: url) else {
            print("\(service) URL Test: ❌ Invalid URL")
            return
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: testURL)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode < 400 {
                    print("\(service) Reachability: ✅ Reachable (HTTP \(httpResponse.statusCode))")
                } else {
                    print("\(service) Reachability: ⚠️ HTTP \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("\(service) Reachability: ❌ \(error.localizedDescription)")
        }
    }
    
    /// Generate a report that can be shared with developers
    static func generateDebugReport() -> String {
        var report = "\n🐛 PIGGYBONG AUTHENTICATION DEBUG REPORT\n"
        report += "Generated: \(Date())\n"
        report += "App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")\n"
        report += "iOS Version: \(UIDevice.current.systemVersion)\n"
        report += "Device: \(UIDevice.current.model)\n\n"
        
        // Supabase Config
        report += "SUPABASE:\n"
        report += "- Config Valid: \(SupabaseConfig.isValid)\n"
        report += "- URL: \(SupabaseConfig.url)\n"
        report += "- Key Length: \(SupabaseConfig.anonKey.count)\n\n"
        
        // Google Config
        if let googleID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String {
            report += "GOOGLE SIGN-IN:\n"
            report += "- Client ID Length: \(googleID.count)\n"
            report += "- Valid Format: \(googleID.hasSuffix(".apps.googleusercontent.com"))\n\n"
        } else {
            report += "GOOGLE SIGN-IN: Not configured\n\n"
        }
        
        // Network
        report += "NETWORK:\n"
        report += "- Connected: \(NetworkManager.shared.isConnected)\n"
        report += "- Type: \(NetworkManager.shared.connectionType?.description ?? "Unknown")\n\n"
        
        report += "This report helps diagnose authentication issues.\n"
        report += "Share this with the development team for support.\n"
        
        return report
    }
}

// MARK: - Debug View for Testing
struct AuthDebugView: View {
    @State private var debugReport = ""
    @State private var showingReport = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Authentication Debug") {
                    Button("Run Diagnostic Check") {
                        AuthDebugUtility.performComprehensiveAuthCheck()
                    }
                    
                    Button("Generate Debug Report") {
                        debugReport = AuthDebugUtility.generateDebugReport()
                        showingReport = true
                    }
                }
                
                Section("Quick Tests") {
                    Button("Test Supabase Config") {
                        testSupabaseConfig()
                    }
                    
                    Button("Test Google Config") {
                        testGoogleConfig()
                    }
                    
                    Button("Test Network") {
                        testNetwork()
                    }
                }
            }
            .navigationTitle("Auth Debug")
        }
        .sheet(isPresented: $showingReport) {
            NavigationView {
                ScrollView {
                    Text(debugReport)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                }
                .navigationTitle("Debug Report")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingReport = false
                        }
                    }
                }
            }
        }
    }
    
    private func testSupabaseConfig() {
        print("\n🧪 Testing Supabase Configuration...")
        
        if SupabaseConfig.isValid {
            print("✅ Supabase config is valid")
            
            Task {
                let testResult = try await SupabaseService.shared.checkSupabaseConnectivity()
                print("Database connection test: \(testResult ? "✅" : "❌")")
            }
        } else {
            print("❌ Supabase config is invalid")
            print("Debug: \(SupabaseConfig.debugDescription)")
        }
    }
    
    private func testGoogleConfig() {
        print("\n🧪 Testing Google Configuration...")
        
        if let clientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String {
            print("✅ Google Client ID found")
            print("Format valid: \(clientID.hasSuffix(".apps.googleusercontent.com"))")
        } else {
            print("❌ Google Client ID not found")
        }
    }
    
    private func testNetwork() {
        print("\n🧪 Testing Network...")
        
        Task {
            let connected = await NetworkManager.shared.checkConnectivity()
            print("Network connectivity: \(connected ? "✅" : "❌")")
        }
    }
}

#Preview {
    AuthDebugView()
}