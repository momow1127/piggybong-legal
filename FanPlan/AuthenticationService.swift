import Foundation
import SwiftUI
import AuthenticationServices
import GoogleSignIn
import Supabase

// MARK: - Authentication Service
class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: AuthUser?
    @Published var isLoading = false

    private let supabaseService = SupabaseService.shared

    // MARK: - Access Token for API Requests
    var currentAccessToken: String? {
        get async {
            return try? await supabaseService.client.auth.session.accessToken
        }
    }
    
    private init() {
        print("🔧 AuthenticationService initializing...")
        setupAuthStateListener()
        checkAuthStatus()
    }

    // MARK: - Auth State Listener
    private func setupAuthStateListener() {
        print("🔧 Setting up Supabase auth state listener...")

        // Use Supabase Swift SDK auth state listener
        Task {
            // Listen for auth state changes
            for await (event, session) in supabaseService.client.auth.authStateChanges {
                print("🔄 Auth state change detected - Event: \(event)")
                print("🔄 Session exists: \(session != nil)")

                await MainActor.run {
                    switch event {
                    case .signedIn, .tokenRefreshed:
                        print("✅ User signed in or token refreshed")
                        if session != nil {
                            // Session exists, update auth state and fetch user profile
                            Task {
                                await self.handleSuccessfulAuth(from: session)
                            }
                        }

                    case .signedOut:
                        print("🔓 User signed out")
                        self.isAuthenticated = false
                        self.currentUser = nil
                        self.removeUserFromKeychain()

                    case .passwordRecovery:
                        print("🔄 Password recovery initiated")

                    case .userUpdated:
                        print("🔄 User profile updated")
                        // Optionally refresh user data

                    default:
                        print("🔄 Other auth event: \(event)")
                    }
                }
            }
        }
    }

    // Helper method to handle successful authentication
    private func handleSuccessfulAuth(from session: Session?) async {
        do {
            print("🔍 Fetching user profile after successful auth...")

            // CRITICAL: Store Supabase tokens securely after successful auth
            if let session = session {
                print("🔐 Storing Supabase tokens securely...")

                let expiresAt = session.expiresAt
                let expiryDate = Date(timeIntervalSince1970: expiresAt)
                SecureTokenManager.storeAccessToken(session.accessToken, expiresAt: expiryDate)
                print("✅ Access token stored (expires: \(expiryDate))")

                SecureTokenManager.storeRefreshToken(session.refreshToken)
                print("✅ Refresh token stored")
            }

            if let authUser = try await supabaseService.getCurrentUser() {
                print("✅ Found auth user: \(authUser.email ?? "unknown")")

                // Get user profile from database
                if let userProfile = try await supabaseService.getUserByEmail(email: authUser.email ?? "") {
                    let user = AuthUser(
                        id: userProfile.id,
                        email: userProfile.email,
                        name: userProfile.name,
                        monthlyBudget: userProfile.monthlyBudget,
                        createdAt: userProfile.createdAtDate ?? Date()
                    )

                    await MainActor.run {
                        self.currentUser = user
                        self.isAuthenticated = true
                        self.saveUserToKeychain(user)
                    }

                    await syncRevenueCatUser(user)
                    print("✅ User profile loaded and synced: \(user.email)")
                } else {
                    print("⚠️ Auth user found but no database profile - creating one for magic link user")

                    // Create minimal profile for magic link users
                    do {
                        let email = authUser.email ?? ""
                        let name = email.components(separatedBy: "@").first ?? "User"

                        print("📝 Creating profile for magic link user: \(email)")
                        _ = try await supabaseService.createUser(
                            name: name,
                            email: email,
                            monthlyBudget: 100.0, // Default budget
                            termsAccepted: true,
                            termsVersion: "2025-08-20"
                        )

                        // Fetch the newly created profile
                        if let newProfile = try await supabaseService.getUserByEmail(email: email) {
                            let user = AuthUser(
                                id: newProfile.id,
                                email: newProfile.email,
                                name: newProfile.name,
                                monthlyBudget: newProfile.monthlyBudget,
                                createdAt: newProfile.createdAtDate ?? Date()
                            )

                            await MainActor.run {
                                self.currentUser = user
                                self.isAuthenticated = true
                                self.saveUserToKeychain(user)
                            }

                            await syncRevenueCatUser(user)
                            print("✅ Created and loaded profile for magic link user: \(user.email)")
                        } else {
                            print("❌ Failed to fetch newly created profile")
                            await MainActor.run {
                                self.isAuthenticated = false
                                self.currentUser = nil
                            }
                        }
                    } catch {
                        print("❌ Failed to create profile for magic link user: \(error)")
                        await MainActor.run {
                            self.isAuthenticated = false
                            self.currentUser = nil
                        }
                    }
                }
            }
        } catch {
            print("❌ Error handling successful auth: \(error)")
            await MainActor.run {
                self.isAuthenticated = false
                self.currentUser = nil
            }
        }
    }

    // MARK: - Auth Models
    struct AuthUser: Codable, Equatable {
        let id: UUID
        let email: String
        let name: String
        let monthlyBudget: Double
        let createdAt: Date

        // Equatable conformance to fix .onChange() compile error
        static func == (lhs: AuthUser, rhs: AuthUser) -> Bool {
            return lhs.id == rhs.id && lhs.email == rhs.email
        }
    }
    
    struct SignUpRequest {
        let name: String
        let email: String
        let password: String
        let monthlyBudget: Double
        let termsAccepted: Bool
        let termsVersion: String
        
        init(name: String, email: String, password: String, monthlyBudget: Double, termsAccepted: Bool = false) {
            self.name = name
            self.email = email
            self.password = password
            self.monthlyBudget = monthlyBudget
            self.termsAccepted = termsAccepted
            self.termsVersion = "2025-08-20" // Current terms version
        }
    }
    
    struct SignInRequest {
        let email: String
        let password: String
    }
    
    // MARK: - Authentication Methods
    func signUp(request: SignUpRequest) async throws {
        let traceId = PerformanceService.shared.startSignUpTrace()
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        do {
            print("📧 Starting email sign-up process...")
            print("📧 Email: \(request.email)")
            print("📧 Name: \(request.name)")
            print("📧 Monthly Budget: $\(request.monthlyBudget)")
            print("📧 Terms Accepted: \(request.termsAccepted)")

            // Step 1: Create Supabase Auth user
            print("📧 Step 1: Creating Supabase auth user...")
            let authUser = try await supabaseService.signUp(
                email: request.email,
                password: request.password
            )
            print("📧 Step 1 Complete: Auth user created with ID \(authUser.id)")
            
            // Step 2: Create user profile in database
            print("📧 Step 2: Creating user profile in database...")
            let userId = try await supabaseService.createUser(
                name: request.name,
                email: request.email,
                monthlyBudget: request.monthlyBudget,
                termsAccepted: request.termsAccepted,
                termsVersion: request.termsVersion
            )
            print("📧 Step 2 Complete: User profile created with ID \(userId)")

            // Step 3: Update user record with auth ID for linking
            print("📧 Step 3: Linking auth user with database user...")
            try await supabaseService.linkAuthUser(userId: userId, authId: authUser.id)
            print("📧 Step 3 Complete: Auth user linked successfully")
            
            let user = AuthUser(
                id: userId,
                email: request.email,
                name: request.name,
                monthlyBudget: request.monthlyBudget,
                createdAt: Date()
            )
            
            // Step 4: Set up RevenueCat user ID sync
            print("📧 Step 4: Setting up RevenueCat sync...")
            await syncRevenueCatUser(user)
            print("📧 Step 4 Complete: RevenueCat synced")

            print("📧 Step 5: Updating local authentication state...")
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.saveUserToKeychain(user)
            }
            print("📧 Step 5 Complete: Local state updated")

            print("✅ User signed up successfully with ID: \(userId)")

            // Automatically send verification code after successful signup
            print("📧 Step 6: Sending verification code...")
            try await supabaseService.sendVerificationCode(email: request.email, type: "signup")
            print("📧 Step 6 Complete: Verification code sent to: \(request.email)")
            print("✅ Email sign-up process completed successfully!")
            PerformanceService.shared.completeAuthTrace(traceId, success: true, method: "email")

        } catch {
            PerformanceService.shared.completeAuthTrace(traceId, success: false, method: "email")
            print("❌ Email sign-up failed with error: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Localized description: \(error.localizedDescription)")

            // Enhanced error reporting for debugging
            if let nsError = error as NSError? {
                print("❌ Error domain: \(nsError.domain)")
                print("❌ Error code: \(nsError.code)")
                print("❌ Error userInfo: \(nsError.userInfo)")
            }

            // Check for specific error types
            if let authError = error as? SupabaseService.SupabaseError {
                switch authError {
                case .emailAlreadyExists:
                    throw AuthenticationError.signUpFailed("An account with this email already exists. Try signing in instead.")
                case .weakPassword:
                    throw AuthenticationError.signUpFailed("Password is too weak. Please use at least 6 characters.")
                case .emailNotConfirmed:
                    throw AuthenticationError.signUpFailed("Please check your email and verify your account.")
                case .networkError(let netError):
                    throw AuthenticationError.signUpFailed("Network error: \(netError.localizedDescription)")
                case .authenticationFailed(let message):
                    throw AuthenticationError.signUpFailed("Authentication failed: \(message)")
                default:
                    throw AuthenticationError.signUpFailed("Signup failed: \(authError.localizedDescription)")
                }
            } else {
                throw AuthenticationError.signUpFailed(error.localizedDescription)
            }
        }
    }

    // MARK: - Magic Link Authentication
    func sendMagicLink(email: String) async throws {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        do {
            print("📧 Sending magic link to: \(email)")

            // Send magic link using Supabase (handles both signup and signin)
            try await supabaseService.sendMagicLink(
                email: email,
                redirectTo: "piggybong://login-callback"
            )

            print("✅ Magic link sent successfully to: \(email)")

        } catch {
            print("❌ Magic link failed: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Localized description: \(error.localizedDescription)")

            if let authError = error as? SupabaseService.SupabaseError {
                switch authError {
                case .networkError(let netError):
                    throw AuthenticationError.signInFailed("Network error: \(netError.localizedDescription)")
                case .authenticationFailed(let message):
                    throw AuthenticationError.signInFailed("Authentication failed: \(message)")
                default:
                    throw AuthenticationError.signInFailed("Failed to send login link: \(authError.localizedDescription)")
                }
            } else {
                throw AuthenticationError.signInFailed("Failed to send login link: \(error.localizedDescription)")
            }
        }
    }

    func signIn(request: SignInRequest) async throws {
        let traceId = PerformanceService.shared.startLoginTrace()
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        do {
            print("📧 Starting email sign-in process...")
            print("📧 Email: \(request.email)")

            // Step 1: Authenticate with Supabase Auth
            print("📧 Step 1: Authenticating with Supabase Auth...")
            _ = try await supabaseService.signIn(
                email: request.email,
                password: request.password
            )
            print("📧 Step 1 Complete: Supabase authentication successful")

            // Step 2: Fetch user profile from database
            print("📧 Step 2: Fetching user profile from database...")
            guard let userProfile = try await supabaseService.getUserByEmail(email: request.email) else {
                print("❌ Step 2 Failed: No user profile found for email \(request.email)")
                throw AuthenticationError.userNotFound
            }
            print("📧 Step 2 Complete: User profile found - ID: \(userProfile.id)")
            
            let user = AuthUser(
                id: userProfile.id,
                email: userProfile.email,
                name: userProfile.name,
                monthlyBudget: userProfile.monthlyBudget,
                createdAt: userProfile.createdAtDate ?? Date()
            )
            
            // Step 3: Set up RevenueCat user ID sync
            print("📧 Step 3: Setting up RevenueCat sync...")
            await syncRevenueCatUser(user)
            print("📧 Step 3 Complete: RevenueCat synced")

            print("📧 Step 4: Updating local authentication state...")
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.saveUserToKeychain(user)
            }
            print("📧 Step 4 Complete: Local state updated")

            print("✅ User signed in successfully: \(user.email)")
            print("✅ Email sign-in process completed successfully!")
            PerformanceService.shared.completeAuthTrace(traceId, success: true, method: "email")

        } catch {
            PerformanceService.shared.completeAuthTrace(traceId, success: false, method: "email")
            print("❌ Email sign-in failed with error: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Localized description: \(error.localizedDescription)")

            // Enhanced error reporting for debugging
            if let nsError = error as NSError? {
                print("❌ Error domain: \(nsError.domain)")
                print("❌ Error code: \(nsError.code)")
                print("❌ Error userInfo: \(nsError.userInfo)")
            }

            throw AuthenticationError.signInFailed("Email Sign In: \(error.localizedDescription)")
        }
    }
    
    func signOut() async {
        print("🔓 Starting complete sign out process...")
        
        do {
            // Sign out from Supabase Auth
            try await supabaseService.signOut()
            print("✅ Supabase sign out successful")
        } catch {
            print("⚠️ Supabase sign out error (continuing with cleanup): \(error.localizedDescription)")
            // Continue with local cleanup even if server signout fails
        }
        
        // Also sign out from Google Sign-In if applicable
        GIDSignIn.sharedInstance.signOut()
        print("✅ Google Sign-In sign out successful")
        
        // Always clear local state regardless of server responses
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
            self.removeUserFromKeychain()
        }

        // CRITICAL: Clear all stored tokens on sign out
        SecureTokenManager.clearAllTokens()
        print("✅ All tokens cleared from secure storage")
        
        print("✅ Complete sign out successful - all sessions cleared")
    }
    
    // MARK: - Persistence (Secure)
    private func saveUserToKeychain(_ user: AuthUser) {
        guard let userData = try? JSONEncoder().encode(user) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "piggy_bong_user",
            kSecValueData as String: userData
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func loadUserFromKeychain() -> AuthUser? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "piggy_bong_user",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let data = item as? Data,
              let user = try? JSONDecoder().decode(AuthUser.self, from: data) else {
            return nil
        }
        
        return user
    }
    
    private func removeUserFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "piggy_bong_user"
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Quick Auth Recovery
    func forceAuthRestore() async -> Bool {
        print("🔐 Forcing auth restore...")
        
        // Try keychain first (fastest)
        if let user = loadUserFromKeychain() {
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }
            print("✅ User restored from keychain: \(user.email)")
            
            // Also try to restore Supabase session
            if let authUser = try? await supabaseService.getCurrentUser() {
                print("✅ Supabase session also restored for: \(authUser.email ?? "unknown")")
            } else {
                print("⚠️ User restored from keychain but Supabase session may be expired")
            }
            return true
        }
        
        // Try Supabase session restore
        do {
            if let authUser = try await supabaseService.getCurrentUser() {
                if let userProfile = try await supabaseService.getUserByEmail(email: authUser.email ?? "") {
                    let user = AuthUser(
                        id: userProfile.id,
                        email: userProfile.email,
                        name: userProfile.name,
                        monthlyBudget: userProfile.monthlyBudget,
                        createdAt: userProfile.createdAtDate ?? Date()
                    )
                    
                    await MainActor.run {
                        self.currentUser = user
                        self.isAuthenticated = true
                        self.saveUserToKeychain(user)
                    }
                    print("✅ User restored from Supabase: \(user.email)")
                    return true
                }
            }
        } catch {
            print("❌ Auth restore failed: \(error)")
        }
        
        print("❌ No valid auth session found")
        return false
    }
    
    private func checkAuthStatus() {
        Task {
            print("🔍 Checking authentication status...")
            
            // Run debug check if in debug mode
            #if DEBUG
            AuthDebugUtility.performComprehensiveAuthCheck()
            #endif
            
            do {
                // Check if there's a valid Supabase Auth session
                if let authUser = try await supabaseService.getCurrentUser() {
                    print("✅ Found Supabase auth user: \(authUser.email ?? "unknown")")
                    
                    // Try to get user profile from database
                    if let userProfile = try await supabaseService.getUserByEmail(email: authUser.email ?? "") {
                        let user = AuthUser(
                            id: userProfile.id,
                            email: userProfile.email,
                            name: userProfile.name,
                            monthlyBudget: userProfile.monthlyBudget,
                            createdAt: userProfile.createdAtDate ?? Date()
                        )
                        
                        await MainActor.run {
                            self.currentUser = user
                            self.isAuthenticated = true
                            self.saveUserToKeychain(user)
                        }
                        
                        // Sync with RevenueCat
                        await syncRevenueCatUser(user)
                        
                        print("✅ User session restored: \(user.email)")
                        return
                    } else {
                        print("⚠️ Supabase user found but no database profile - user may need to complete signup")
                    }
                } else {
                    print("ℹ️ No active Supabase session found")
                }
                
                // Fallback to keychain for offline access
                if let user = loadUserFromKeychain() {
                    await MainActor.run {
                        self.currentUser = user
                        self.isAuthenticated = true
                    }
                    print("✅ User restored from keychain (offline)")
                } else {
                    print("ℹ️ No cached user found - user needs to authenticate")
                    await MainActor.run {
                        self.isAuthenticated = false
                        self.currentUser = nil
                    }
                }
            } catch {
                print("⚠️ Auth check failed: \(error.localizedDescription)")
                print("🔍 Error details: \(error)")
                
                // Fallback to keychain
                if let user = loadUserFromKeychain() {
                    await MainActor.run {
                        self.currentUser = user
                        self.isAuthenticated = true
                    }
                    print("✅ User restored from keychain (fallback)")
                } else {
                    await MainActor.run {
                        self.isAuthenticated = false
                        self.currentUser = nil
                    }
                    print("ℹ️ No fallback available - user needs fresh authentication")
                }
            }
        }
    }
}

// MARK: - Input Validation
extension AuthenticationService {
    func validateEmail(_ email: String) -> String? {
        return ValidationService.shared.validateEmail(email)
    }
    
    func validatePassword(_ password: String) -> String? {
        return ValidationService.shared.validatePassword(password)
    }
    
    func validateName(_ name: String) -> String? {
        return ValidationService.shared.validateName(name)
    }
    
    func validateBudget(_ budget: Double) -> String? {
        if budget <= 0 {
            return "Budget must be greater than $0"
        } else if budget > 100000 {
            return "Budget cannot exceed $100,000"
        }
        return nil
    }
    
    // MARK: - RevenueCat Integration
    private func syncRevenueCatUser(_ user: AuthUser) async {
        do {
            // Configure RevenueCat with the user ID
            await RevenueCatManager.shared.setUserID(user.id.uuidString)
            print("✅ RevenueCat user ID synced: \(user.id.uuidString)")
        }
    }
    
    // MARK: - Social Authentication Methods
    func signInWithApple(credential: ASAuthorizationAppleIDCredential, nonce: String? = nil) async throws {
        let traceId = PerformanceService.shared.startLoginTrace()
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        do {
            // Extract ID token from Apple credential
            guard let idTokenData = credential.identityToken,
                  let idToken = String(data: idTokenData, encoding: .utf8) else {
                print("❌ Apple Sign In: Failed to extract ID token from credential")
                throw AuthenticationError.signInFailed("Failed to extract Apple ID token")
            }

            print("🍎 Starting Apple Sign In with direct Supabase SDK...")
            print("🍎 ID Token present: \(idToken.prefix(20))...")
            print("🍎 User identifier: \(credential.user)")

            // SIMPLIFIED: Only use direct Supabase SDK approach
            // Use provided nonce from coordinator, or generate one if not provided
            let authNonce = nonce ?? generateNonce()
            print("🍎 Using nonce: \(authNonce.prefix(10))...")

            // Direct Supabase OAuth for Apple Sign In - no fallbacks
            let authUser = try await supabaseService.authService.signInWithApple(
                idToken: idToken,
                nonce: authNonce
            )
            print("✅ Direct Supabase Apple OAuth successful for: \(authUser.email ?? "unknown")")

            // Extract display information from Apple credential
            let displayName = credential.fullName?.givenName ?? "Fan"
            let email = authUser.email ?? credential.email ?? "\(credential.user)@appleid.private"
            let username = generateUsername(from: displayName)
            
            // Check if user profile exists in database with fallback handling
            var userProfile: DatabaseUser

            do {
                if let existingUser = try await supabaseService.getUserByEmail(email: email) {
                    userProfile = existingUser
                    print("✅ Found existing user profile: \(userProfile.email)")
                } else {
                    // Create new user profile in database
                    print("📝 Creating new user profile...")
                    let userId = try await supabaseService.createUser(
                        name: username,
                        email: email,
                        monthlyBudget: 100.0, // Default budget for Apple Sign In users
                        termsAccepted: true,
                        termsVersion: "2025-08-20"
                    )

                    // Link auth user with database user
                    try await supabaseService.linkAuthUser(userId: userId, authId: authUser.id)

                    // Fetch the created user with error handling
                    do {
                        userProfile = try await supabaseService.getUser(id: userId)
                        print("✅ Created new user profile: \(userProfile.email)")
                    } catch {
                        print("⚠️ Failed to fetch created user, creating fallback profile")
                        // Create a fallback user profile
                        userProfile = DatabaseUser(
                            id: userId,
                            authUserId: authUser.id,
                            email: email,
                            name: username,
                            monthlyBudget: 100.0,
                            currency: "USD",
                            termsAcceptedAt: nil,
                            privacyAcceptedAt: nil,
                            termsVersion: "2025-08-20",
                            createdAt: nil,
                            updatedAt: nil
                        )
                        print("✅ Created fallback user profile")
                    }
                }
            } catch {
                print("⚠️ Database user operations failed, creating minimal profile: \(error)")
                // Create a minimal user profile for authentication continuity
                userProfile = DatabaseUser(
                    id: UUID(),
                    authUserId: authUser.id,
                    email: email,
                    name: username,
                    monthlyBudget: 100.0,
                    currency: "USD",
                    termsAcceptedAt: nil,
                    privacyAcceptedAt: nil,
                    termsVersion: "2025-08-20",
                    createdAt: nil,
                    updatedAt: nil
                )
                print("✅ Created minimal fallback profile for user continuity")
            }
            
            let user = AuthUser(
                id: userProfile.id,
                email: userProfile.email,
                name: userProfile.name,
                monthlyBudget: userProfile.monthlyBudget,
                createdAt: userProfile.createdAtDate ?? Date()
            )
            
            // Sync with RevenueCat
            await syncRevenueCatUser(user)
            
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.saveUserToKeychain(user)
                
                // Save username for profile settings
                let username = generateUsernameFromAuth(displayName, email)
                UserDefaults.standard.set(username, forKey: "user_fandom_name")
            }
            
            print("✅ Apple Sign In complete: \(user.email)")
            PerformanceService.shared.completeAuthTrace(traceId, success: true, method: "apple")

        } catch {
            PerformanceService.shared.completeAuthTrace(traceId, success: false, method: "apple")
            print("❌ Apple Sign In failed with error: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Localized description: \(error.localizedDescription)")

            // Enhanced error reporting for debugging
            if let nsError = error as NSError? {
                print("❌ Error domain: \(nsError.domain)")
                print("❌ Error code: \(nsError.code)")
                print("❌ Error userInfo: \(nsError.userInfo)")
            }

            throw AuthenticationError.signInFailed("Apple Sign In: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func signInWithGoogle() async throws {
        let traceId = PerformanceService.shared.startLoginTrace()

        // Ensure we're on main thread for UI operations
        MainThreadManager.assertMainThread()
        isLoading = true

        defer {
            isLoading = false
        }

        do {
            print("🔐 Starting Google Sign In with direct Supabase SDK...")

            // Generate secure nonce BEFORE any UI operations
            let originalNonce = GoogleAuthNonceManager.generateNonce()
            let hashedNonce = GoogleAuthNonceManager.sha256Hash(of: originalNonce)
            print("🔐 Generated secure nonce for Google Sign-In: \(originalNonce.prefix(20))...")
            print("🔐 SHA256 hash for Google config: \(hashedNonce.prefix(20))...")

            // CRITICAL: Get view controller and configure Google Sign-In on main thread
            // We're already @MainActor, so no need for await MainActor.run
            MainThreadManager.assertMainThread()
            print("🔐 Configuring Google Sign-In on main thread...")

            // SAFE: Get presenting view controller on main thread
            let presentingViewController = MainThreadManager.getPresentingViewController()

            // Configure Google Sign In with multiple fallback sources
            var clientID: String?

            // Try Bundle.main first (production)
            if let bundleClientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String,
               !bundleClientID.isEmpty && !bundleClientID.contains("$(") {
                clientID = bundleClientID
                print("🔐 Google Client ID from Bundle: \(bundleClientID.prefix(20))...")
            }
            // Fallback to hardcoded value (development/testing)
            else {
                clientID = "301452889528-moohj3f0kkp4leq8m8fu0mcull3aqi65.apps.googleusercontent.com"
                print("🔐 Google Client ID from fallback: \(clientID!.prefix(20))...")
            }

            guard let finalClientID = clientID else {
                print("❌ Google Sign In: No valid GOOGLE_CLIENT_ID available")
                throw AuthenticationError.signInFailed("Unable to configure Google Sign-In")
            }

            print("🔐 Google Client ID configured: \(finalClientID.prefix(20))...")

            // CRITICAL: Configure Google Sign-In on main thread
            let config = GIDConfiguration(clientID: finalClientID)

            guard let presentingViewController = presentingViewController else {
                print("❌ Google Sign In: Unable to get presenting view controller")
                throw AuthenticationError.signInFailed("Unable to get presenting view controller")
            }

            // CRITICAL: Set configuration and perform sign-in on main thread
            // We're already @MainActor, so UI operations are safe
            MainThreadManager.assertMainThread()
            print("🔐 Setting Google Sign-In configuration on main thread...")

            // Configure Google Sign-In instance
            GIDSignIn.sharedInstance.configuration = config
            print("🔐 Presenting Google Sign In UI on main thread...")

            // CRITICAL: Google Sign-In presentation MUST be on main thread
            let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)

            guard let idToken = signInResult.user.idToken?.tokenString else {
                print("❌ Google Sign In: Failed to extract ID token from result")
                throw AuthenticationError.signInFailed("Failed to get Google ID token")
            }

            let accessToken = signInResult.user.accessToken.tokenString
            let email = signInResult.user.profile?.email ?? ""
            let name = signInResult.user.profile?.name ?? "User"

            print("🔐 Google Sign In successful - ID Token: \(idToken.prefix(20))...")
            print("🔐 Google user info - Email: \(email), Name: \(name)")

            // CRITICAL: Use the original nonce (not hashed) for Supabase authentication
            print("🔐 Authenticating with Supabase using original nonce: \(originalNonce.prefix(20))...")
            let authUser = try await supabaseService.signInWithGoogle(
                idToken: idToken,
                accessToken: accessToken,
                nonce: originalNonce
            )

            print("✅ Direct Supabase Google OAuth successful for: \(authUser.email ?? "unknown")")
            
            // Check if user profile exists in database with fallback handling
            var userProfile: DatabaseUser

            do {
                if let existingUser = try await supabaseService.getUserByEmail(email: email) {
                    userProfile = existingUser
                    print("✅ Found existing user profile: \(userProfile.email)")
                } else {
                    // Create new user profile in database
                    print("📝 Creating new user profile for Google user...")
                    let userId = try await supabaseService.createUser(
                        name: name,
                        email: email,
                        monthlyBudget: 100.0, // Default budget for Google Sign In users
                        termsAccepted: true,
                        termsVersion: "2025-08-20"
                    )

                    // Link auth user with database user
                    try await supabaseService.linkAuthUser(userId: userId, authId: authUser.id)

                    // Fetch the created user with error handling
                    do {
                        userProfile = try await supabaseService.getUser(id: userId)
                        print("✅ Created new user profile: \(userProfile.email)")
                    } catch {
                        print("⚠️ Failed to fetch created user, creating fallback profile")
                        // Create a fallback user profile
                        userProfile = DatabaseUser(
                            id: userId,
                            authUserId: authUser.id,
                            email: email,
                            name: name,
                            monthlyBudget: 100.0,
                            currency: "USD",
                            termsAcceptedAt: nil,
                            privacyAcceptedAt: nil,
                            termsVersion: "2025-08-20",
                            createdAt: nil,
                            updatedAt: nil
                        )
                        print("✅ Created fallback user profile")
                    }
                }
            } catch {
                print("⚠️ Database user operations failed, creating minimal profile: \(error)")
                // Create a minimal user profile for authentication continuity
                userProfile = DatabaseUser(
                    id: UUID(),
                    authUserId: authUser.id,
                    email: email,
                    name: name,
                    monthlyBudget: 100.0,
                    currency: "USD",
                    termsAcceptedAt: nil,
                    privacyAcceptedAt: nil,
                    termsVersion: "2025-08-20",
                    createdAt: nil,
                    updatedAt: nil
                )
                print("✅ Created minimal fallback profile for user continuity")
            }
            
            let user = AuthUser(
                id: userProfile.id,
                email: userProfile.email,
                name: userProfile.name,
                monthlyBudget: userProfile.monthlyBudget,
                createdAt: userProfile.createdAtDate ?? Date()
            )
            
            // Sync with RevenueCat
            await syncRevenueCatUser(user)
            
            await MainActor.run {
                MainThreadManager.assertMainThread()
                print("🔐 Updating authentication state on main thread...")

                self.currentUser = user
                self.isAuthenticated = true
                self.saveUserToKeychain(user)

                // Save username for profile settings
                let username = generateUsernameFromAuth(name, email)
                UserDefaults.standard.set(username, forKey: "user_fandom_name")
            }
            
            print("✅ Google Sign In with Supabase complete: \(user.email)")
            PerformanceService.shared.completeAuthTrace(traceId, success: true, method: "google")

        } catch {
            PerformanceService.shared.completeAuthTrace(traceId, success: false, method: "google")
            print("❌ Google Sign In failed with error: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Localized description: \(error.localizedDescription)")

            // Enhanced error reporting for debugging
            if let nsError = error as NSError? {
                print("❌ Error domain: \(nsError.domain)")
                print("❌ Error code: \(nsError.code)")
                print("❌ Error userInfo: \(nsError.userInfo)")
            }

            throw AuthenticationError.signInFailed("Google Sign In: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Username Generation
    private func generateUsernameFromAuth(_ displayName: String, _ email: String) -> String {
        // First try to use display name if it's meaningful
        if !displayName.isEmpty && displayName != "User" && !displayName.contains("@") {
            return displayName
        }
        
        // Otherwise extract from email
        let emailPrefix = email.components(separatedBy: "@").first ?? "Fan"
        
        // Clean up common email patterns
        let cleanedName = emailPrefix
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .components(separatedBy: .decimalDigits.inverted)
            .joined()
        
        // Capitalize properly
        let finalName = cleanedName.isEmpty ? "Fan User" : cleanedName.capitalized
        
        return finalName.isEmpty ? "Fan User" : finalName
    }
    
    private func generateUsername(from displayName: String) -> String {
        let cleanName = displayName.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .filter { $0.isLetter }
        
        if cleanName.isEmpty {
            return "fan_\(String(Int.random(in: 1000...9999)))"
        }
        
        let prefix = String(cleanName.prefix(8))
        let suffix = String(Int.random(in: 100...999))
        return "\(prefix)_\(suffix)"
    }
    
    // MARK: - Nonce Generation for Apple Sign In
    private func generateNonce(length: Int = 32) -> String {
        let charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._"
        return String((0..<length).compactMap { _ in charset.randomElement() })
    }
    
    // MARK: - REMOVED: Edge Function Fallback
    // Simplified auth flow - removed complex fallback logic that was masking real issues
    // Now using only direct Supabase SDK authentication paths
    
    // MARK: - Password Reset
    func resetPassword(email: String) async throws {
        do {
            try await supabaseService.resetPassword(email: email)
            print("✅ Password reset email sent")
        } catch {
            print("❌ Password reset failed: \(error.localizedDescription)")
            throw AuthenticationError.passwordResetFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Email Verification
    func resendVerificationEmail() async throws {
        guard let user = currentUser else {
            throw AuthenticationError.userNotFound
        }
        
        do {
            try await supabaseService.resendVerificationEmail(email: user.email)
            print("✅ Verification email resent")
        } catch {
            print("❌ Failed to resend verification email: \(error.localizedDescription)")
            throw AuthenticationError.emailVerificationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Delete Account
    func deleteAccount() async throws {
        guard let currentUser = currentUser else {
            throw AuthenticationError.userNotFound
        }

        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        do {
            print("🗑️ Starting account deletion for user: \(currentUser.email)")

            // Call Edge Function to delete account (handles cascade deletion)
            let response = try await EdgeFunctionService.shared.deleteUserAccount()

            if response.success {
                print("✅ Account deletion successful on server")

                // Sign out locally
                await signOut()

                print("✅ Local sign out complete after deletion")
            } else {
                print("❌ Account deletion failed: \(response.message ?? "Unknown error")")
                throw AuthenticationError.accountDeletionFailed(response.message ?? "Failed to delete account")
            }

        } catch {
            print("❌ Account deletion error: \(error)")
            throw AuthenticationError.accountDeletionFailed(error.localizedDescription)
        }
    }

    // MARK: - Code Verification
    func verifyEmailCode(email: String, code: String) async throws -> Bool {
        do {
            print("🔍 Verifying code \(code) for email: \(email)")
            
            // Call the Supabase Edge Function
            let result = try await supabaseService.verifyEmailCode(email: email, code: code)
            
            if result {
                print("✅ Email verification successful")
                return true
            } else {
                print("❌ Invalid verification code")
                throw AuthenticationError.emailVerificationFailed("Invalid verification code")
            }
            
        } catch {
            print("❌ Code verification failed: \(error.localizedDescription)")
            throw AuthenticationError.emailVerificationFailed(error.localizedDescription)
        }
    }
    
    func resendVerificationCode(email: String) async throws {
        do {
            print("📧 Sending new verification code to: \(email)")
            
            // Call the Supabase Edge Function to send new code
            try await supabaseService.sendVerificationCode(email: email)
            
            print("✅ New verification code sent")
            
        } catch {
            print("❌ Failed to send verification code: \(error.localizedDescription)")
            throw AuthenticationError.emailVerificationFailed(error.localizedDescription)
        }
    }
}

// MARK: - Authentication Errors
enum AuthenticationError: LocalizedError {
    case signUpFailed(String)
    case signInFailed(String)
    case userNotFound
    case passwordResetFailed(String)
    case emailVerificationFailed(String)
    case invalidCredentials
    case networkError
    case accountDeletionFailed(String)
    case authenticationRequired
    
    var errorDescription: String? {
        switch self {
        case .signUpFailed(let message):
            return "Sign up failed: \(message)"
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        case .userNotFound:
            return "User account not found"
        case .passwordResetFailed(let message):
            return "Password reset failed: \(message)"
        case .emailVerificationFailed(let message):
            return "Email verification failed: \(message)"
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network connection error. Please try again."
        case .accountDeletionFailed(let message):
            return "Account deletion failed: \(message)"
        case .authenticationRequired:
            return "Authentication required. Please sign in again."
        }
    }
}
