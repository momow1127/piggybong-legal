import Foundation
import AuthenticationServices

// MARK: - Edge Function Service
class EdgeFunctionService {
    static let shared = EdgeFunctionService()
    
    private let baseURL: String
    private let headers: [String: String]
    
    private init() {
        // Use same configuration method as SupabaseService for consistency
        let anonKey: String
        if SupabaseConfig.isValid {
            self.baseURL = SupabaseConfig.url
            anonKey = SupabaseConfig.anonKey
        } else if let envURL = ProcessInfo.processInfo.environment["SUPABASE_URL"],
                  let envKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"],
                  !envURL.isEmpty, !envKey.isEmpty {
            self.baseURL = envURL
            anonKey = envKey
        } else {
            // Fallback to Info.plist (legacy)
            self.baseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
            anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""
        }

        // Debug logging
        print("🔧 EdgeFunctionService initialized:")
        print("  📋 Base URL: \(baseURL)")
        print("  🔑 Anon Key: \(anonKey.prefix(20))...")

        self.headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(anonKey)",
            "apikey": anonKey
        ]
    }
    
    // MARK: - Apple Sign In Validation
    func validateAppleSignIn(credential: ASAuthorizationAppleIDCredential) async throws -> EdgeFunctionUser {
        guard let identityTokenData = credential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            throw EdgeFunctionError.invalidCredential
        }
        
        guard let authCodeData = credential.authorizationCode,
              let authCode = String(data: authCodeData, encoding: .utf8) else {
            throw EdgeFunctionError.invalidCredential
        }
        
        let requestBody: [String: Any] = [
            "idToken": identityToken,
            "authorizationCode": authCode,
            "fullName": [
                "givenName": credential.fullName?.givenName ?? "",
                "familyName": credential.fullName?.familyName ?? ""
            ].compactMapValues { $0.isEmpty ? nil : $0 },
            "user": [
                "email": credential.email ?? ""
            ].compactMapValues { $0.isEmpty ? nil : $0 }
        ]
        
        return try await callEdgeFunction(endpoint: "/functions/v1/auth-apple", body: requestBody)
    }
    
    // MARK: - Google Sign In Validation  
    func validateGoogleSignIn(idToken: String, accessToken: String?) async throws -> EdgeFunctionUser {
        var requestBody: [String: Any] = [
            "idToken": idToken
        ]
        if let accessToken = accessToken, !accessToken.isEmpty {
            requestBody["accessToken"] = accessToken
        }
        
        return try await callEdgeFunction(endpoint: "/functions/v1/auth-google", body: requestBody)
    }
    
    // MARK: - User Management
    func createUser(email: String, name: String, monthlyBudget: Double = 0, authProvider: String, emailVerified: Bool = false) async throws -> EdgeFunctionUser {
        let requestBody: [String: Any] = [
            "email": email,
            "name": name,
            "monthlyBudget": monthlyBudget,
            "authProvider": authProvider,
            "emailVerified": emailVerified
        ]
        
        return try await callEdgeFunction(endpoint: "/functions/v1/user-management?action=create", body: requestBody)
    }
    
    func getUser(userId: String? = nil, email: String? = nil) async throws -> EdgeFunctionUser {
        var endpoint = "/functions/v1/user-management?action=get"
        
        if let userId = userId {
            endpoint += "&userId=\(userId)"
        } else if let email = email {
            endpoint += "&email=\(email)"
        } else {
            throw EdgeFunctionError.missingParameter
        }
        
        return try await callEdgeFunction(endpoint: endpoint, method: "GET")
    }
    
    func updateUser(userId: String, name: String? = nil, monthlyBudget: Double? = nil, emailVerified: Bool? = nil) async throws -> EdgeFunctionUser {
        var requestBody: [String: Any] = ["userId": userId]
        
        if let name = name { requestBody["name"] = name }
        if let monthlyBudget = monthlyBudget { requestBody["monthlyBudget"] = monthlyBudget }
        if let emailVerified = emailVerified { requestBody["emailVerified"] = emailVerified }
        
        return try await callEdgeFunction(endpoint: "/functions/v1/user-management?action=update", body: requestBody)
    }
    
    func deleteUser(userId: String) async throws {
        let requestBody = ["userId": userId]
        let _: EdgeFunctionResponse = try await callEdgeFunction(endpoint: "/functions/v1/user-management?action=delete", body: requestBody)
    }
    
    func verifyEmail(email: String) async throws {
        let requestBody = ["email": email]
        let _: EdgeFunctionResponse = try await callEdgeFunction(endpoint: "/functions/v1/user-management?action=verify-email", body: requestBody)
    }
    
    // MARK: - Private Helper Methods
    private func callAuthenticatedEdgeFunction<T: Codable>(
        endpoint: String,
        method: String = "POST",
        body: [String: Any]? = nil,
        userToken: String
    ) async throws -> T {

        guard let url = URL(string: baseURL + endpoint) else {
            throw EdgeFunctionError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        // Use authenticated headers with user token
        let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""
        let authenticatedHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(userToken)",  // Use user's JWT token
            "apikey": anonKey
        ]

        // Add headers
        for (key, value) in authenticatedHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Add body if provided
        if let body = body {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            } catch {
                throw EdgeFunctionError.serializationError
            }
        }

        // Make request
        do {
            let customSession = NetworkManager.createURLSession(timeout: NetworkManager.standardTimeout)
            let (data, response) = try await customSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw EdgeFunctionError.invalidResponse
            }

            // Check status code
            guard 200...299 ~= httpResponse.statusCode else {
                // Try to parse error message
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorData["error"] as? String {
                    throw EdgeFunctionError.serverError(errorMessage)
                } else {
                    throw EdgeFunctionError.httpError(httpResponse.statusCode)
                }
            }

            // Parse response
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return try decoder.decode(T.self, from: data)
            } catch {
                print("❌ EdgeFunction decode error: \(error)")
                print("❌ Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                throw EdgeFunctionError.decodingError
            }
        } catch {
            if error is EdgeFunctionError {
                throw error
            } else {
                throw EdgeFunctionError.networkError(error.localizedDescription)
            }
        }
    }

    private func callEdgeFunction<T: Codable>(
        endpoint: String,
        method: String = "POST",
        body: [String: Any]? = nil
    ) async throws -> T {
        
        guard let url = URL(string: baseURL + endpoint) else {
            throw EdgeFunctionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add body if provided
        if let body = body {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            } catch {
                throw EdgeFunctionError.serializationError
            }
        }
        
        // Make request
        do {
            let customSession = NetworkManager.createURLSession(timeout: NetworkManager.standardTimeout)
            let (data, response) = try await customSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw EdgeFunctionError.invalidResponse
            }
            
            // Check status code
            guard 200...299 ~= httpResponse.statusCode else {
                // Try to parse error message
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorData["error"] as? String {
                    throw EdgeFunctionError.serverError(errorMessage)
                } else {
                    throw EdgeFunctionError.httpError(httpResponse.statusCode)
                }
            }
            
            // Parse response
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return try decoder.decode(T.self, from: data)
            } catch {
                print("❌ Decode error: \(error)")
                print("📄 Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                throw EdgeFunctionError.decodingError
            }
            
        } catch {
            if error is EdgeFunctionError {
                throw error
            } else {
                throw EdgeFunctionError.networkError(error.localizedDescription)
            }
        }
    }

    // MARK: - Insight Feedback
    func submitInsightFeedback(artistId: String?, feedback: String) async throws -> EdgeFunctionResponse {
        let requestBody: [String: Any] = [
            "artist_id": artistId ?? NSNull(),
            "feedback": feedback
        ]

        return try await callEdgeFunction(endpoint: "/functions/v1/store-insight-feedback", body: requestBody)
    }

    // MARK: - Delete Account
    func deleteUserAccount() async throws -> EdgeFunctionResponse {
        // Get current user access token for authenticated request
        guard let accessToken = try await SupabaseService.shared.getCurrentAccessToken() else {
            throw EdgeFunctionError.authenticationRequired
        }

        // Call the edge function with user's JWT token
        return try await callAuthenticatedEdgeFunction(
            endpoint: "/functions/v1/delete-user-account",
            body: nil,
            userToken: accessToken
        )
    }
}

// MARK: - Data Models
struct EdgeFunctionUser: Codable {
    let success: Bool
    let userId: String?
    let email: String?
    let displayName: String?
    let profilePicture: String?
    let isNewUser: Bool?
    let sessionUrl: String?
    
    // For user management responses
    let user: UserDetails?
    
    struct UserDetails: Codable {
        let id: String
        let email: String
        let name: String
        let monthlyBudget: Double
        let emailVerified: Bool
        let authProvider: String?
        let createdAt: String?
        let lastLoginAt: String?
    }
}

struct EdgeFunctionResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
}

// MARK: - Error Types
enum EdgeFunctionError: LocalizedError {
    case invalidCredential
    case invalidURL
    case serializationError
    case invalidResponse
    case decodingError
    case networkError(String)
    case serverError(String)
    case httpError(Int)
    case missingParameter
    case authenticationRequired
    
    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid authentication credential"
        case .invalidURL:
            return "Invalid Edge Function URL"
        case .serializationError:
            return "Failed to serialize request data"
        case .invalidResponse:
            return "Invalid server response"
        case .decodingError:
            return "Failed to decode server response"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .missingParameter:
            return "Missing required parameter"
        case .authenticationRequired:
            return "Authentication required for this operation"
        }
    }
}

// MARK: - Usage Examples
/*

Example usage in your AuthenticationService:

// Apple Sign In with Edge Function
func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
    let result = try await EdgeFunctionService.shared.validateAppleSignIn(credential: credential)
    
    guard result.success, let userId = result.userId else {
        throw AuthenticationError.serverValidationFailed
    }
    
    // Create AuthUser from result
    let user = AuthUser(
        id: UUID(uuidString: userId) ?? UUID(),
        email: result.email ?? "",
        name: result.displayName ?? "Fan User",
        monthlyBudget: 0.0,
        createdAt: Date()
    )
    
    // Update authentication state
    await MainActor.run {
        self.currentUser = user
        self.isAuthenticated = true
    }
}

// Google Sign In with Edge Function
func signInWithGoogle(idToken: String, accessToken: String?) async throws {
    let result = try await EdgeFunctionService.shared.validateGoogleSignIn(
        idToken: idToken, 
        accessToken: accessToken
    )
    
    // Handle result similar to Apple Sign In
}

// Create user with Edge Function
func signUp(request: SignUpRequest) async throws {
    let result = try await EdgeFunctionService.shared.createUser(
        email: request.email,
        name: request.name,
        monthlyBudget: request.monthlyBudget,
        authProvider: "email",
        emailVerified: false
    )
    
    // Handle result
}

*/