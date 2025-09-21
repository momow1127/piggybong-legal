import SwiftUI

// MARK: - Supabase Debug View
/// Comprehensive debugging interface for Supabase authentication and insert issues
struct SupabaseDebugView: View {
    // Use direct Supabase service access instead of FanDashboardService
    private let supabaseService = SupabaseService.shared
    @State private var testResult = ""
    @State private var isRunningTest = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("🔧 Supabase Debug Console")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Authentication Debug Section
                        debugSection(
                            title: "1. Authentication Status",
                            description: "Check if user is logged in and has valid token",
                            buttonText: "🔐 Debug Authentication",
                            action: {
                                await runAuthenticationDebug()
                            }
                        )
                        
                        // Connection Test Section
                        debugSection(
                            title: "2. Basic Connectivity",
                            description: "Test connection to Supabase without authentication",
                            buttonText: "🔗 Test Connection",
                            action: {
                                await runConnectionTest()
                            }
                        )
                        
                        // Table Access Test
                        debugSection(
                            title: "3. Table Access Test",
                            description: "Test reading from fan_activities table (checks RLS)",
                            buttonText: "🗄️ Test Table Access",
                            action: {
                                await runTableAccessTest()
                            }
                        )
                        
                        // Sample Insert Test
                        debugSection(
                            title: "4. Sample Insert Test",
                            description: "Try actual insert with debug logging",
                            buttonText: "📝 Test Insert",
                            action: {
                                await runInsertTest()
                            }
                        )
                        
                        // User ID Validation
                        debugSection(
                            title: "5. User ID Validation",
                            description: "Validate UUID format and user existence",
                            buttonText: "🆔 Validate User ID",
                            action: {
                                await runUserIdValidation()
                            }
                        )
                    }
                    .padding()
                }
                
                // Results Section
                if !testResult.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📋 Console Output:")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ScrollView {
                            Text(testResult)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .overlay(
            Group {
                if isRunningTest {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            
                            Text("Running Diagnostic...")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .padding(24)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 10)
                    }
                }
            }
        )
    }
    
    // MARK: - Debug Section Component
    private func debugSection(
        title: String,
        description: String,
        buttonText: String,
        action: @escaping () async -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button(action: {
                Task {
                    isRunningTest = true
                    await action()
                    isRunningTest = false
                }
            }) {
                Text(buttonText)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .disabled(isRunningTest)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Debug Actions
    
    private func runAuthenticationDebug() async {
        testResult = "🔐 Running authentication debug...\n\n"
        
        // Capture console output
        await supabaseService.databaseService.debugAuthenticationStatus()
        
        // Add additional validation
        let authStatus = await getAuthenticationStatus()
        testResult += authStatus
    }
    
    private func runConnectionTest() async {
        testResult = "🔗 Testing Supabase connection...\n\n"
        
        let connected = await supabaseService.databaseService.checkSupabaseConnectivity()
        testResult += "Connection Status: \(connected ? "✅ Success" : "❌ Failed")\n"
        testResult += "Base URL: \(SupabaseConfig.isValid ? "✅ Configured" : "❌ Not configured")\n"
    }
    
    private func runTableAccessTest() async {
        testResult = "🗄️ Testing table access...\n\n"
        
        do {
            let count = try await SupabaseService.shared.client
                .from("fan_activities")
                .select("*", head: true, count: .exact)
                .execute()
                .count
            
            testResult += "✅ Table Access Successful\n"
            testResult += "Records in table: \(count ?? 0)\n"
            testResult += "This indicates basic auth and RLS SELECT policies work\n"
            
        } catch {
            testResult += "❌ Table Access Failed\n"
            testResult += "Error: \(error.localizedDescription)\n"
            testResult += "This could indicate RLS issues or table doesn't exist\n"
        }
    }
    
    private func runInsertTest() async {
        testResult = "📝 Testing sample insert...\n\n"
        
        do {
            let result = try await supabaseService.databaseService.createFanActivityWithSDK(
                amount: 25.0,
                category: "test",
                artist: "Debug Test",
                note: "Diagnostic insert test"
            )
            
            testResult += "✅ Insert Successful!\n"
            testResult += "Activity ID: \(result.id)\n"
            testResult += "Check console for detailed debugging output\n"
            
        } catch {
            testResult += "❌ Insert Failed\n"
            testResult += "Error: \(error.localizedDescription)\n"
            testResult += "\nCheck console for detailed debugging output\n"
        }
    }
    
    private func runUserIdValidation() async {
        testResult = "🆔 Validating user ID...\n\n"
        
        // Check current user
        let currentUser = supabaseService.client.auth.currentUser
        
        if let user = currentUser {
            let userId = user.id.uuidString
            testResult += "✅ User Found\n"
            testResult += "User ID: \(userId)\n"
            testResult += "Email: \(user.email ?? "N/A")\n"
            testResult += "UUID Format Valid: \(UUID(uuidString: userId) != nil ? "✅" : "❌")\n"
            testResult += "Email Confirmed: \(user.emailConfirmedAt != nil ? "✅" : "❌")\n"
            
            // Test session
            do {
                let session = try await supabaseService.client.auth.session
                testResult += "Session Access Token: ✅ Available\n"
                testResult += "Token Expires: \(session.expiresAt)\n"
                testResult += "Token Valid: \(session.expiresAt > Date().timeIntervalSince1970 ? "✅" : "❌ EXPIRED")\n"
            } catch {
                testResult += "❌ Session Error: \(error.localizedDescription)\n"
            }
            
        } else {
            testResult += "❌ No Authenticated User\n"
            testResult += "Solution: User needs to log in with Google\n"
        }
    }
    
    private func getAuthenticationStatus() async -> String {
        var status = ""
        
        let authClient = supabaseService.client.auth
        if let currentUser = authClient.currentUser {
            status += "👤 Current User Status:\n"
            status += "   - ID: \(currentUser.id.uuidString)\n"
            status += "   - Email: \(currentUser.email ?? "N/A")\n"
            
            do {
                let session = try await authClient.session
                status += "   - Session: ✅ Active\n"
                status += "   - Token Valid: \(session.expiresAt > Date().timeIntervalSince1970 ? "✅" : "❌")\n"
            } catch {
                status += "   - Session: ❌ Error - \(error.localizedDescription)\n"
            }
        } else {
            status += "👤 Authentication Status: ❌ NOT LOGGED IN\n"
        }
        
        return status
    }
}

// MARK: - Preview
#Preview {
    SupabaseDebugView()
}