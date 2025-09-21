import Foundation
import Combine
import Supabase

// MARK: - Supabase Authentication Service
/// Handles all authentication-related operations with Supabase
class SupabaseAuthService: ObservableObject {
    private let baseURL: String
    private let apiKey: String
    internal var accessToken: String?
    
    // MARK: - Auth State Management
    @Published var currentUser: AuthUser?
    @Published var isAuthenticated: Bool = false
    
    init(baseURL: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        
        // Load persisted access token on init
        self.accessToken = loadAccessTokenFromKeychain()
        
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        // This would typically use Supabase's auth state change listener
        // For now, we'll implement basic session management
        print("🔐 Auth state listener configured")
    }
    
    // MARK: - Authentication Models
    struct AuthResponse {
        let user: AuthUser
        let session: AuthSession?
    }
    
    struct AuthUser {
        let id: UUID
        let email: String?
        let emailConfirmedAt: Date?
        let createdAt: Date
    }
    
    struct AuthSession {
        let accessToken: String
        let refreshToken: String
        let expiresAt: Date
    }
    
    // MARK: - Error Types
    enum AuthError: LocalizedError {
        case invalidURL
        case invalidResponse
        case unauthorized
        case notFound
        case dataParsingError
        case serverError(String)
        case networkError(Error)
        case authenticationFailed(String)
        case emailAlreadyExists
        case weakPassword
        case emailNotConfirmed
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .invalidResponse:
                return "Invalid response from server"
            case .unauthorized:
                return "Authentication required"
            case .notFound:
                return "Resource not found"
            case .dataParsingError:
                return "Failed to parse data from server"
            case .serverError(let message):
                return message
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .authenticationFailed(let message):
                return "Authentication failed: \(message)"
            case .emailAlreadyExists:
                return "An account with this email already exists"
            case .weakPassword:
                return "Password should be at least 6 characters"
            case .emailNotConfirmed:
                return "Please verify your email address before signing in"
            }
        }
    }
    
    // MARK: - Public API
    
    /// Sign up a new user with email and password
    func signUp(email: String, password: String) async throws -> AuthUser {
        let signUpData = [
            "email": email,
            "password": password
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: signUpData)
        
        do {
            let responseData = try await makeAuthRequest(
                path: "/auth/v1/signup",
                method: "POST",
                body: jsonData
            )
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let authResponse = try decoder.decode(AuthResponseDTO.self, from: responseData)
            
            // Store the session
            self.accessToken = authResponse.access_token
            self.saveAccessTokenToKeychain(authResponse.access_token)
            
            let authUser = AuthUser(
                id: UUID(uuidString: authResponse.user.id) ?? UUID(),
                email: authResponse.user.email,
                emailConfirmedAt: authResponse.user.email_confirmed_at,
                createdAt: authResponse.user.created_at ?? Date()
            )
            
            // Update state
            await MainActor.run {
                self.currentUser = authUser
                self.isAuthenticated = true
            }
            
            print("✅ User signed up successfully: \(email)")
            return authUser
            
        } catch {
            print("❌ Sign up failed: \(error)")
            throw AuthError.authenticationFailed(error.localizedDescription)
        }
    }
    
    /// Sign in an existing user
    func signIn(email: String, password: String) async throws -> AuthUser {
        let signInData = [
            "email": email,
            "password": password
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: signInData)
        
        do {
            let responseData = try await makeAuthRequest(
                path: "/auth/v1/token?grant_type=password",
                method: "POST",
                body: jsonData
            )
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let authResponse = try decoder.decode(AuthResponseDTO.self, from: responseData)
            
            // Store the session
            self.accessToken = authResponse.access_token
            self.saveAccessTokenToKeychain(authResponse.access_token)
            
            let authUser = AuthUser(
                id: UUID(uuidString: authResponse.user.id) ?? UUID(),
                email: authResponse.user.email,
                emailConfirmedAt: authResponse.user.email_confirmed_at,
                createdAt: authResponse.user.created_at ?? Date()
            )
            
            // Update state
            await MainActor.run {
                self.currentUser = authUser
                self.isAuthenticated = true
            }
            
            print("✅ User signed in successfully: \(email)")
            return authUser
            
        } catch {
            print("❌ Sign in failed: \(error)")
            throw AuthError.authenticationFailed(error.localizedDescription)
        }
    }

    /// Sign in anonymously for testing/demo purposes
    func signInAnonymously() async throws -> AuthUser {
        print("🔓 Attempting anonymous sign in...")

        do {
            let session = try await SupabaseService.shared.client.auth.signInAnonymously()
            let user = session.user

            let authUser = AuthUser(
                id: user.id,
                email: user.email ?? "anonymous@piggy-bong.com",
                emailConfirmedAt: user.emailConfirmedAt,
                createdAt: user.createdAt
            )

            await MainActor.run {
                self.currentUser = authUser
                self.isAuthenticated = true
            }

            self.accessToken = session.accessToken
            self.saveAccessTokenToKeychain(session.accessToken)

            print("✅ Anonymous sign in successful")
            return authUser

        } catch {
            print("❌ Anonymous sign in failed: \(error)")
            throw AuthError.authenticationFailed(error.localizedDescription)
        }
    }

    /// Sign out the current user
    func signOut() async throws {
        print("🔓 Starting sign out process...")
        
        // Try to sign out from Supabase server (best effort)
        do {
            _ = try await makeAuthRequest(
                path: "/auth/v1/logout",
                method: "POST"
            )
            print("✅ Server sign out successful")
        } catch {
            print("⚠️ Server sign out failed (continuing with local cleanup): \(error.localizedDescription)")
            // Don't throw - continue with local cleanup
        }
        
        // Always clear local session regardless of server response
        self.accessToken = nil
        self.removeAccessTokenFromKeychain()
        
        // Update state
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
        }
        
        print("✅ Local session cleared - user signed out successfully")
    }
    
    /// Get current authenticated user
    func getCurrentUser() async throws -> AuthUser? {
        guard let _ = accessToken else {
            return nil // No active session
        }
        
        do {
            let responseData = try await makeAuthRequest(
                path: "/auth/v1/user",
                method: "GET"
            )
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let userResponse = try decoder.decode(AuthUserDTO.self, from: responseData)
            
            let authUser = AuthUser(
                id: UUID(uuidString: userResponse.id) ?? UUID(),
                email: userResponse.email,
                emailConfirmedAt: userResponse.email_confirmed_at,
                createdAt: userResponse.created_at ?? Date()
            )
            
            // Update state
            await MainActor.run {
                self.currentUser = authUser
                self.isAuthenticated = true
            }
            
            return authUser
        } catch {
            print("❌ Get current user failed: \(error)")
            self.accessToken = nil // Clear invalid session
            self.removeAccessTokenFromKeychain()
            
            // Update state
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
            }
            
            return nil
        }
    }
    
    /// Reset user password
    func resetPassword(email: String) async throws {
        let resetData = ["email": email]
        let jsonData = try JSONSerialization.data(withJSONObject: resetData)
        
        do {
            _ = try await makeAuthRequest(
                path: "/auth/v1/recover",
                method: "POST",
                body: jsonData
            )
            
            print("✅ Password reset email sent to: \(email)")
        } catch {
            print("❌ Password reset failed: \(error)")
            throw AuthError.authenticationFailed(error.localizedDescription)
        }
    }
    
    /// Resend verification email
    func resendVerificationEmail(email: String) async throws {
        let emailData = ["email": email]
        let jsonData = try JSONSerialization.data(withJSONObject: emailData)
        
        do {
            _ = try await makeAuthRequest(
                path: "/auth/v1/resend",
                method: "POST",
                body: jsonData
            )
            
            print("✅ Verification email resent to: \(email)")
        } catch {
            print("❌ Resend verification failed: \(error)")
            throw AuthError.authenticationFailed(error.localizedDescription)
        }
    }
    
    /// Sign in with Google using Supabase Swift SDK (PROPER METHOD)
    func signInWithGoogle(idToken: String, accessToken: String, nonce: String? = nil) async throws -> AuthUser {
        print("🔐 Starting Supabase Google Sign In with Swift SDK...")
        print("📝 ID Token (first 50 chars): \(String(idToken.prefix(50)))...")
        print("📝 Access Token available: \(!accessToken.isEmpty)")
        print("📝 Nonce: \(nonce?.prefix(20) ?? "nil")...")

        do {
            // FIXED: Use Supabase Swift SDK's native signInWithIdToken method with nonce
            let session = try await SupabaseService.shared.client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .google,
                    idToken: idToken,
                    accessToken: accessToken,
                    nonce: nonce
                )
            )
            
            print("✅ Supabase SDK authentication successful!")
            print("   - Session expires at: \(session.expiresAt)")
            print("   - User ID: \(session.user.id)")
            print("   - User email: \(session.user.email ?? "N/A")")
            
            // Store the session using the SDK's built-in session management
            self.accessToken = session.accessToken
            self.saveAccessTokenToKeychain(session.accessToken)
            
            let authUser = AuthUser(
                id: session.user.id,
                email: session.user.email,
                emailConfirmedAt: session.user.emailConfirmedAt,
                createdAt: session.user.createdAt
            )
            
            // Update state
            await MainActor.run {
                self.currentUser = authUser
                self.isAuthenticated = true
            }
            
            print("✅ Google OAuth successful: \(authUser.email ?? "unknown")")
            return authUser
            
        } catch {
            print("❌ Supabase SDK Google OAuth failed: \(error)")
            print("🔍 Error details: \(error.localizedDescription)")
            
            // Fallback to manual REST API approach if SDK fails
            print("🔄 Attempting fallback to REST API approach...")
            return try await signInWithGoogleFallback(idToken: idToken, accessToken: accessToken)
        }
    }
    
    /// Fallback method using REST API for Google Sign-In
    private func signInWithGoogleFallback(idToken: String, accessToken: String) async throws -> AuthUser {
        let endpoint = "/auth/v1/token?grant_type=id_token"
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw AuthError.invalidURL
        }
        
        let payload = [
            "id_token": idToken,
            "access_token": accessToken,
            "provider": "google"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        
        let jsonData = try JSONSerialization.data(withJSONObject: payload)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if httpResponse.statusCode >= 400 {
            let responseString = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Google OAuth REST fallback failed: HTTP \(httpResponse.statusCode)")
            print("❌ Response: \(responseString)")
            throw AuthError.authenticationFailed("Google OAuth failed: HTTP \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let authResponse = try decoder.decode(AuthResponseDTO.self, from: data)
        
        // Store the session
        self.accessToken = authResponse.access_token
        self.saveAccessTokenToKeychain(authResponse.access_token)
        
        let authUser = AuthUser(
            id: UUID(uuidString: authResponse.user.id) ?? UUID(),
            email: authResponse.user.email,
            emailConfirmedAt: authResponse.user.email_confirmed_at,
            createdAt: authResponse.user.created_at ?? Date()
        )
        
        // Update state
        await MainActor.run {
            self.currentUser = authUser
            self.isAuthenticated = true
        }
        
        print("✅ Google OAuth REST fallback successful: \(authUser.email ?? "unknown")")
        return authUser
    }
    
    /// Sign in with Apple using Supabase Swift SDK (FIXED)
    func signInWithApple(idToken: String, nonce: String? = nil) async throws -> AuthUser {
        print("🍎 Starting Apple Sign In with Supabase Swift SDK...")
        print("🔧 Token (first 20 chars): \(idToken.prefix(20))...")

        do {
            // FIXED: Use Supabase Swift SDK's native signInWithIdToken method
            let session = try await SupabaseService.shared.client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )

            print("✅ Supabase SDK Apple authentication successful!")
            print("   - Session expires at: \(session.expiresAt)")
            print("   - User ID: \(session.user.id)")
            print("   - User email: \(session.user.email ?? "N/A")")

            // Store the session using the SDK's built-in session management
            self.accessToken = session.accessToken
            self.saveAccessTokenToKeychain(session.accessToken)

            let authUser = AuthUser(
                id: session.user.id,
                email: session.user.email,
                emailConfirmedAt: session.user.emailConfirmedAt,
                createdAt: session.user.createdAt
            )

            // Update state
            await MainActor.run {
                self.currentUser = authUser
                self.isAuthenticated = true
            }

            print("✅ Apple OAuth successful: \(authUser.email ?? "unknown")")
            return authUser

        } catch {
            print("❌ Supabase SDK Apple OAuth failed: \(error)")
            print("🔍 Error details: \(error.localizedDescription)")

            // Provide helpful debugging information
            if error.localizedDescription.contains("invalid") {
                print("🔍 DEBUGGING HINTS for Apple Sign In:")
                print("🔍   1. Check Apple Developer Console - Services ID configuration")
                print("🔍   2. Verify audience (aud) claim matches your app's bundle ID")
                print("🔍   3. Ensure Apple Sign In capability is enabled in Xcode")
                print("🔍   4. Apple Sign In doesn't work in iOS Simulator - test on device")
            }

            throw AuthError.authenticationFailed("Apple Sign In: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Internal Properties
    
    /// Get the current access token (for internal use by other services)
    var currentAccessToken: String? {
        return accessToken
    }
    
    /// Check if user is currently authenticated
    var hasValidSession: Bool {
        return accessToken != nil && isAuthenticated
    }
    
    // MARK: - Private Helpers
    
    private func makeAuthRequest(
        path: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> Data {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw AuthError.invalidURL
        }
        
        return try await NetworkManager.performRequest(
            timeout: NetworkManager.authTimeout,
            maxRetries: 1 // Auth requests shouldn't retry much
        ) {
            let session = NetworkManager.createURLSession(timeout: NetworkManager.authTimeout)
            
            var request = URLRequest(url: url)
            request.httpMethod = method
            
            // Set auth-specific headers
            request.setValue(self.apiKey, forHTTPHeaderField: "apikey")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            // Add authorization header if we have a token
            if let token = self.accessToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            if let body = body {
                request.httpBody = body
            }
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                return data
            case 400:
                // Bad request - parse error for specific auth errors
                throw AuthError.authenticationFailed("Invalid request")
            case 401:
                throw AuthError.unauthorized
            case 404:
                throw AuthError.notFound
            case 408: // Request Timeout
                throw NetworkError.timeout
            case 422:
                // Unprocessable entity - common for validation errors
                if let errorData = try? JSONDecoder().decode(AuthErrorDTO.self, from: data) {
                    throw self.mapAuthError(errorData)
                }
                throw AuthError.authenticationFailed("Validation error")
            case 503, 504: // Service/Gateway Unavailable
                throw NetworkError.hostUnreachable
            default:
                throw AuthError.serverError("HTTP \(httpResponse.statusCode)")
            }
        }
    }
    
    private func mapAuthError(_ error: AuthErrorDTO) -> AuthError {
        switch error.message?.lowercased() {
        case let msg where msg?.contains("already registered") == true:
            return .emailAlreadyExists
        case let msg where msg?.contains("weak password") == true:
            return .weakPassword
        case let msg where msg?.contains("email not confirmed") == true:
            return .emailNotConfirmed
        default:
            return .authenticationFailed(error.message ?? "Unknown auth error")
        }
    }
    
    // MARK: - Token Persistence
    
    private func saveAccessTokenToKeychain(_ token: String) {
        guard let tokenData = token.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "supabase_access_token",
            kSecValueData as String: tokenData
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        SecItemAdd(query as CFDictionary, nil)
        print("🔐 Access token saved to keychain")
    }
    
    private func loadAccessTokenFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "supabase_access_token",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8) else {
            print("🔍 No access token found in keychain")
            return nil
        }
        
        print("🔐 Access token loaded from keychain")
        return token
    }
    
    private func removeAccessTokenFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "supabase_access_token"
        ]
        
        SecItemDelete(query as CFDictionary)
        print("🔐 Access token removed from keychain")
    }
}

// MARK: - Authentication DTOs

/// Response from Supabase auth endpoints
struct AuthResponseDTO: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let refresh_token: String?
    let user: AuthUserDTO
}

/// User data from Supabase auth
struct AuthUserDTO: Codable {
    let id: String
    let aud: String?
    let email: String?
    let phone: String?
    let created_at: Date?
    let email_confirmed_at: Date?
    let phone_confirmed_at: Date?
    let last_sign_in_at: Date?
    let updated_at: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, aud, email, phone
        case created_at, updated_at
        case email_confirmed_at
        case phone_confirmed_at
        case last_sign_in_at
    }
}

/// Error response from Supabase auth
struct AuthErrorDTO: Codable {
    let message: String?
    let error: String?
    let error_description: String?
}