import Foundation
import CryptoKit

// MARK: - Google Auth Nonce Manager
/// Handles secure nonce generation and validation for Google Sign-In with Supabase
final class GoogleAuthNonceManager {

    /// Generate a cryptographically secure nonce for Google Sign-In
    /// This nonce will be embedded in the ID token and validated by Supabase
    static func generateNonce() -> String {
        // Generate 32 random bytes for high entropy
        let data = Data((0..<32).map { _ in UInt8.random(in: 0...255) })

        // Convert to base64url encoding (required by OAuth 2.0 spec)
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// Generate SHA256 hash of nonce for Google Sign-In configuration
    /// Google Sign-In requires the hashed version, while Supabase needs the original
    static func sha256Hash(of nonce: String) -> String {
        let inputData = Data(nonce.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }

    /// Validate that a nonce matches expected format
    static func isValidNonce(_ nonce: String) -> Bool {
        // Check that nonce is base64url format and reasonable length
        let validCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")
        return nonce.count >= 32 &&
               nonce.count <= 128 &&
               nonce.rangeOfCharacter(from: validCharacters.inverted) == nil
    }
}