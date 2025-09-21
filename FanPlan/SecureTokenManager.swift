import Foundation
import Security
import Supabase

// MARK: - Secure Token Manager
/// Handles secure storage and retrieval of Supabase access/refresh tokens
/// Uses iOS Keychain for maximum security
final class SecureTokenManager {

    // MARK: - Keychain Keys
    private static let accessTokenKey = "supabase_access_token"
    private static let refreshTokenKey = "supabase_refresh_token"
    private static let tokenExpiryKey = "supabase_token_expiry"
    private static let serviceIdentifier = "com.piggybong.tokens"

    // MARK: - Token Storage

    /// Store access token securely in Keychain
    static func storeAccessToken(_ token: String, expiresAt: Date) {
        print("🔐 Storing access token in Keychain (expires: \(expiresAt))")

        // Store the access token
        storeInKeychain(key: accessTokenKey, value: token)

        // Store expiry date
        let expiryData = String(expiresAt.timeIntervalSince1970).data(using: .utf8) ?? Data()
        storeInKeychain(key: tokenExpiryKey, data: expiryData)
    }

    /// Store refresh token securely in Keychain
    static func storeRefreshToken(_ token: String) {
        print("🔐 Storing refresh token in Keychain")
        storeInKeychain(key: refreshTokenKey, value: token)
    }

    /// Get current access token if valid (not expired)
    static func getCurrentAccessToken() -> String? {
        // Check if token is expired first
        if isAccessTokenExpired() {
            print("⚠️ Access token is expired")
            return nil
        }

        let token = getFromKeychain(key: accessTokenKey)
        if token != nil {
            print("✅ Retrieved valid access token from Keychain")
        } else {
            print("❌ No access token found in Keychain")
        }
        return token
    }

    /// Get refresh token
    static func getRefreshToken() -> String? {
        let token = getFromKeychain(key: refreshTokenKey)
        if token != nil {
            print("✅ Retrieved refresh token from Keychain")
        } else {
            print("❌ No refresh token found in Keychain")
        }
        return token
    }

    /// Check if access token is expired
    static func isAccessTokenExpired() -> Bool {
        guard let expiryData = getDataFromKeychain(key: tokenExpiryKey),
              let expiryString = String(data: expiryData, encoding: .utf8),
              let expiryTimestamp = Double(expiryString) else {
            print("⚠️ No token expiry found, assuming expired")
            return true
        }

        let expiryDate = Date(timeIntervalSince1970: expiryTimestamp)
        let isExpired = Date() >= expiryDate.addingTimeInterval(-300) // 5 minute buffer

        if isExpired {
            print("⚠️ Token expired at \(expiryDate)")
        }

        return isExpired
    }

    /// Clear all stored tokens
    static func clearAllTokens() {
        print("🗑️ Clearing all stored tokens from Keychain")
        deleteFromKeychain(key: accessTokenKey)
        deleteFromKeychain(key: refreshTokenKey)
        deleteFromKeychain(key: tokenExpiryKey)
    }

    // MARK: - Keychain Operations

    private static func storeInKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        storeInKeychain(key: key, data: data)
    }

    private static func storeInKeychain(key: String, data: Data) {
        // Delete existing item first
        deleteFromKeychain(key: key)

        // Add new item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("❌ Failed to store \(key) in Keychain: \(status)")
        }
    }

    private static func getFromKeychain(key: String) -> String? {
        guard let data = getDataFromKeychain(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func getDataFromKeychain(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            return result as? Data
        } else {
            return nil
        }
    }

    private static func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Supabase Client Extension for Token Management
extension SupabaseService {

    /// Get authenticated Supabase client with current access token
    func getAuthenticatedClient() async throws -> SupabaseClient {
        // Try to get current session first
        do {
            let session = try await client.auth.session

            // Store tokens securely when we have a valid session
            let expiresAt = session.expiresAt
            let expiryDate = Date(timeIntervalSince1970: expiresAt)
            SecureTokenManager.storeAccessToken(session.accessToken, expiresAt: expiryDate)

            let refreshToken = session.refreshToken
            SecureTokenManager.storeRefreshToken(refreshToken)

            return client
        } catch {
            print("⚠️ No valid session, attempting token refresh...")

            // Try to refresh using stored refresh token
            if let refreshToken = SecureTokenManager.getRefreshToken() {
                do {
                    let session = try await client.auth.refreshSession(refreshToken: refreshToken)

                    // Update stored tokens
                    let expiresAt = session.expiresAt
                    let expiryDate = Date(timeIntervalSince1970: expiresAt)
                    SecureTokenManager.storeAccessToken(session.accessToken, expiresAt: expiryDate)

                    return client
                } catch {
                    print("❌ Token refresh failed: \(error)")
                    // Clear invalid tokens
                    SecureTokenManager.clearAllTokens()
                    throw AuthenticationError.authenticationRequired
                }
            } else {
                print("❌ No refresh token available")
                throw AuthenticationError.authenticationRequired
            }
        }
    }

    /// Make authenticated request with automatic token refresh
    func makeAuthenticatedRequest<T>(_ request: @escaping (SupabaseClient) async throws -> T) async throws -> T {
        do {
            let authenticatedClient = try await getAuthenticatedClient()
            return try await request(authenticatedClient)
        } catch {
            if case AuthenticationError.authenticationRequired = error {
                // Authentication failed - user needs to sign in again
                await MainActor.run {
                    AuthenticationService.shared.isAuthenticated = false
                    AuthenticationService.shared.currentUser = nil
                }
            }
            throw error
        }
    }
}

// MARK: - Note: AuthenticationError is defined in AuthenticationService.swift