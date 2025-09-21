import Foundation
import Combine
import Supabase

// MARK: - Supabase Service Coordinator
/// Main service that coordinates authentication and database operations
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    private let baseURL: String
    private let apiKey: String
    
    // Service dependencies
    public let authService: SupabaseAuthService
    public let databaseService: SupabaseDatabaseService
    
    // Supabase Swift SDK client
    public let client: SupabaseClient
    
    private init() {
        // Secure credential loading with build configuration priority
        
        // Option 1: Try build configuration first (production/App Store)
        if SupabaseConfig.isValid {
            self.baseURL = SupabaseConfig.url
            self.apiKey = SupabaseConfig.anonKey
            print("⚙️ Using build configuration Supabase: \(SupabaseConfig.url.prefix(25))...")
        }
        // Option 2: Try environment variables (development/CI)
        else if let envURL = ProcessInfo.processInfo.environment["SUPABASE_URL"],
           let envKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"],
           !envURL.isEmpty && !envKey.isEmpty && envKey != "your-anon-key-here" {
            // Use environment variables (development/cloud)
            self.baseURL = envURL
            self.apiKey = envKey
            print("🔗 Using environment Supabase: \(envURL.prefix(25))...")
        }
        // Option 3: Try local development environment
        else if let localURL = ProcessInfo.processInfo.environment["SUPABASE_LOCAL_URL"],
                  let localKey = ProcessInfo.processInfo.environment["SUPABASE_LOCAL_ANON_KEY"],
                  !localURL.isEmpty && !localKey.isEmpty && localKey != "local-key-required" {
            // Use local development environment
            self.baseURL = localURL
            self.apiKey = localKey
            print("🏠 Using local Supabase: \(localURL)")
        } else {
            // Fallback to placeholder values that will fail gracefully
            self.baseURL = "https://placeholder.supabase.co"
            self.apiKey = "placeholder-key"
            print("⚠️ No valid Supabase credentials found. Configure build settings or environment variables.")
            print("🔧 Debug info: \(SupabaseConfig.debugDescription)")
        }
        
        // Initialize Supabase Swift SDK client
        guard let supabaseURL = URL(string: baseURL) else {
            fatalError("Invalid Supabase URL configuration: '\(baseURL)'. Check your build settings or environment variables.")
        }

        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: apiKey
        )
        
        // Initialize services
        self.authService = SupabaseAuthService(baseURL: baseURL, apiKey: apiKey)
        self.databaseService = SupabaseDatabaseService(baseURL: baseURL, apiKey: apiKey, authService: authService)
        
        print("🐷 PiggyBong SupabaseService initialized with SDK client")
        print("📱 SDK client URL: \(baseURL)")
        print("🔑 SDK client configured: ✅")
    }
    
    // MARK: - Public API Access
    /// Public access to base URL for legacy compatibility
    public var supabaseURL: String { baseURL }
    
    /// Public access to anonymous key for legacy compatibility
    public var anonKey: String { apiKey }
    
    // MARK: - Legacy Type Aliases for Backward Compatibility
    typealias AuthResponse = SupabaseAuthService.AuthResponse
    typealias AuthUser = SupabaseAuthService.AuthUser
    typealias AuthSession = SupabaseAuthService.AuthSession
    
    // MARK: - Error Types
    enum SupabaseError: LocalizedError {
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
        case decodingFailed(String)
        case functionError(String)
        
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
            case .decodingFailed(let message):
                return "Failed to decode response: \(message)"
            case .functionError(let message):
                return "Function error: \(message)"
            }
        }
    }
    
    // MARK: - Authentication Methods (Delegated to AuthService)
    
    /// Sign up a new user with email and password
    func signUp(email: String, password: String) async throws -> AuthUser {
        return try await authService.signUp(email: email, password: password)
    }
    
    /// Sign in an existing user
    func signIn(email: String, password: String) async throws -> AuthUser {
        return try await authService.signIn(email: email, password: password)
    }
    
    /// Sign out the current user
    func signOut() async throws {
        try await authService.signOut()
    }

    /// Sign in anonymously for testing/demo purposes
    func signInAnonymously() async throws -> AuthUser {
        return try await authService.signInAnonymously()
    }

    /// Get current authenticated user
    func getCurrentUser() async throws -> AuthUser? {
        return try await authService.getCurrentUser()
    }

    /// Get current access token from session
    func getCurrentAccessToken() async throws -> String? {
        // Try to get token from Supabase SDK session first
        do {
            let session = try await client.auth.session
            print("✅ Got access token from SDK session")
            // Also update auth service token for consistency
            authService.accessToken = session.accessToken
            return session.accessToken
        } catch {
            print("⚠️ Failed to get SDK session: \(error)")
        }

        // Fallback to auth service token
        if let token = authService.currentAccessToken {
            print("✅ Got access token from auth service")
            return token
        }

        print("❌ No access token available")
        return nil
    }

    /// Reset user password
    func resetPassword(email: String) async throws {
        try await authService.resetPassword(email: email)
    }
    
    /// Sign in with Google OAuth
    func signInWithGoogle(idToken: String, accessToken: String, nonce: String? = nil) async throws -> AuthUser {
        return try await authService.signInWithGoogle(idToken: idToken, accessToken: accessToken, nonce: nonce)
    }
    
    // MARK: - Email Verification with Codes
    func sendVerificationCode(email: String, type: String = "signup") async throws {
        let requestBody = [
            "email": email,
            "type": type
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw SupabaseError.dataParsingError
        }
        
        let response = try await makeEdgeFunctionRequest(
            functionName: "send-verification-code",
            body: jsonData
        )
        
        // Parse response to check for success
        if let jsonResponse = try? JSONSerialization.jsonObject(with: response) as? [String: Any],
           let success = jsonResponse["success"] as? Bool,
           !success {
            let message = jsonResponse["message"] as? String ?? "Failed to send verification code"
            throw SupabaseError.serverError(message)
        }
    }
    
    func verifyEmailCode(email: String, code: String) async throws -> Bool {
        let requestBody = [
            "email": email,
            "code": code
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw SupabaseError.dataParsingError
        }
        
        let response = try await makeEdgeFunctionRequest(
            functionName: "verify-email-code",
            body: jsonData
        )
        
        // Parse response
        guard let jsonResponse = try? JSONSerialization.jsonObject(with: response) as? [String: Any],
              let success = jsonResponse["success"] as? Bool,
              let verified = jsonResponse["verified"] as? Bool else {
            throw SupabaseError.dataParsingError
        }
        
        if !success {
            let message = jsonResponse["message"] as? String ?? "Verification failed"
            throw SupabaseError.serverError(message)
        }
        
        return verified
    }

    // MARK: - Magic Link Authentication
    func sendMagicLink(email: String, redirectTo: String) async throws {
        do {
            print("🔗 Sending magic link via Supabase...")

            // Enhanced magic link with better error handling
            try await client.auth.signInWithOTP(
                email: email,
                redirectTo: URL(string: redirectTo),
                captchaToken: nil
            )

            print("✅ Magic link sent successfully")

        } catch {
            print("❌ Magic link failed: \(error)")

            // Handle specific database errors
            let errorMessage = error.localizedDescription.lowercased()
            if errorMessage.contains("database error") || errorMessage.contains("saving new user") {
                print("🔧 Database schema issue detected - this might be resolved by:")
                print("   1. Enabling email auth in Supabase Dashboard > Authentication > Settings")
                print("   2. Ensuring 'Confirm email' is enabled")
                print("   3. Checking database triggers are working properly")
            }

            if let authError = error as? AuthError {
                throw SupabaseError.authenticationFailed(authError.localizedDescription)
            } else {
                throw SupabaseError.networkError(error)
            }
        }
    }

    // MARK: - Edge Function Helper
    private func makeEdgeFunctionRequest(functionName: String, body: Data) async throws -> Data {
        guard let url = URL(string: "\(baseURL)/functions/v1/\(functionName)") else {
            throw SupabaseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")

        // Try to get user's JWT token for authenticated requests
        do {
            let session = try await client.auth.session
            let userToken = session.accessToken
            request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
            print("🔐 Using authenticated user token for edge function: \(functionName)")
        } catch {
            print("⚠️ No user session found, using anon key for edge function: \(functionName) - \(error)")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = body
        
        do {
            let customSession = NetworkManager.createURLSession(timeout: NetworkManager.standardTimeout)
            let (data, response) = try await customSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.invalidResponse
            }
            
            // Check for HTTP errors
            if httpResponse.statusCode >= 400 {
                // Try to parse error message
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorJson["message"] as? String {
                    throw SupabaseError.serverError(message)
                } else {
                    throw SupabaseError.serverError("HTTP \(httpResponse.statusCode)")
                }
            }
            
            return data
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Resend verification email
    func resendVerificationEmail(email: String) async throws {
        try await authService.resendVerificationEmail(email: email)
    }
    
    // MARK: - Database Methods (Delegated to DatabaseService)
    
    func checkSupabaseConnectivity() async throws -> Bool {
        return try await databaseService.checkSupabaseConnectivity()
    }
    
    // MARK: - Enhanced User Management with Auth Integration
    
    /// Get user by email from the database
    func getUserByEmail(email: String) async throws -> DatabaseUser? {
        return try await databaseService.getUserByEmail(email: email)
    }
    
    /// Link auth user ID with database user record
    func linkAuthUser(userId: UUID, authId: UUID) async throws {
        try await databaseService.linkAuthUser(userId: userId, authId: authId)
    }
    
    func createUser(name: String, email: String, monthlyBudget: Double, termsAccepted: Bool = false, termsVersion: String? = nil) async throws -> UUID {
        return try await databaseService.createUser(name: name, email: email, monthlyBudget: monthlyBudget, termsAccepted: termsAccepted, termsVersion: termsVersion)
    }
    
    func getUser(id: UUID) async throws -> DatabaseUser {
        return try await databaseService.getUser(id: id)
    }
    
    func updateUserBudget(userId: UUID, monthlyBudget: Double) async throws {
        try await databaseService.updateUserBudget(userId: userId, monthlyBudget: monthlyBudget)
    }
    
    // MARK: - Artists
    func getArtists() async throws -> [Artist] {
        return try await databaseService.getArtists()
    }
    
    func createArtist(name: String, groupName: String?, imageUrl: String? = nil) async throws -> UUID {
        return try await databaseService.createArtist(name: name, groupName: groupName, imageUrl: imageUrl)
    }
    
    func searchArtists(query: String) async throws -> [Artist] {
        return try await databaseService.searchArtists(query: query)
    }
    
    // MARK: - Purchases
    func getPurchases(for userId: UUID, limit: Int = 20) async throws -> [DashboardTransaction] {
        return try await databaseService.getPurchases(for: userId, limit: limit)
    }
    
    func createPurchase(userId: UUID, artistId: UUID, amount: Double, category: String, description: String, notes: String? = nil) async throws -> UUID {
        return try await databaseService.createPurchase(userId: userId, artistId: artistId, amount: amount, category: category, description: description, notes: notes)
    }
    
    func updatePurchase(id: UUID, amount: Double? = nil, description: String? = nil, notes: String? = nil) async throws {
        try await databaseService.updatePurchase(id: id, amount: amount, description: description, notes: notes)
    }
    
    func deletePurchase(id: UUID) async throws {
        try await databaseService.deletePurchase(id: id)
    }
    
    // MARK: - Budgets
    func getBudget(userId: UUID, month: Int, year: Int) async throws -> DatabaseBudget? {
        return try await databaseService.getBudget(userId: userId, month: month, year: year)
    }
    
    func createBudget(userId: UUID, month: Int, year: Int, totalBudget: Double) async throws -> UUID {
        return try await databaseService.createBudget(userId: userId, month: month, year: year, totalBudget: totalBudget)
    }
    
    func updateBudgetSpent(userId: UUID, month: Int, year: Int, additionalAmount: Double) async throws {
        try await databaseService.updateBudgetSpent(userId: userId, month: month, year: year, additionalAmount: additionalAmount)
    }
    
    // MARK: - Goals (REMOVED)
    // Goal functionality has been removed from the app
    // Methods: getGoals, createGoal, updateGoalProgress - no longer supported
    
    // MARK: - Advanced Features (Delegated to DatabaseService)
    
    func callFunction<T: Codable>(functionName: String, parameters: [String: Any]) async throws -> T {
        guard let url = URL(string: "\(baseURL)/functions/v1/\(functionName)") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let token = authService.currentAccessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if !parameters.isEmpty {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters)
            request.httpBody = jsonData
        }
        
        do {
            let customSession = NetworkManager.createURLSession(timeout: NetworkManager.standardTimeout)
            let (data, response) = try await customSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                if T.self == String.self {
                    guard let stringResult = (String(data: data, encoding: .utf8) ?? "") as? T else {
                        throw SupabaseError.dataParsingError
                    }
                    return stringResult
                } else {
                    // CRITICAL: Use enhanced decoder for proper date handling
                    return try decodeSupabaseResponse(T.self, from: data)
                }
            case 401:
                throw SupabaseError.unauthorized
            case 404:
                throw SupabaseError.notFound
            default:
                let sanitizedError = ValidationService.shared.sanitizeError(
                    SupabaseError.serverError("HTTP \(httpResponse.statusCode)")
                )
                throw sanitizedError
            }
        } catch {
            if error is SupabaseError {
                throw error
            } else {
                throw SupabaseError.networkError(error)
            }
        }
    }
    
    // MARK: - User Artists Management
    
    func getUserArtists(userId: UUID) async throws -> [DatabaseUserArtist] {
        return try await databaseService.advancedService.getUserArtists(userId: userId)
    }
    
    func createUserArtist(userId: UUID, artistId: UUID, priorityRank: Int, monthlyAllocation: Double) async throws -> UUID {
        return try await databaseService.advancedService.createUserArtist(userId: userId, artistId: artistId, priorityRank: priorityRank, monthlyAllocation: monthlyAllocation)
    }
    
    func updateUserArtistAllocation(userId: UUID, artistId: UUID, monthlyAllocation: Double) async throws {
        try await databaseService.advancedService.updateUserArtistAllocation(userId: userId, artistId: artistId, monthlyAllocation: monthlyAllocation)
    }
    
    // MARK: - Goals (REMOVED)
    // Goal functionality has been removed from the app
    // createFanGoal method no longer supported
    
    // MARK: - Insights
    func getInsights(for userId: UUID) async throws -> [Insight] {
        // For now, return empty array since focus is on real data from events
        // Insights will be enhanced in future versions with real analytics
        return []
    }
    
    // MARK: - AI Tips Management
    
    func getActiveAITips(userId: UUID) async throws -> [DatabaseAITip] {
        return try await databaseService.advancedService.getActiveAITips(userId: userId)
    }
    
    func markAITipAsRead(tipId: UUID) async throws {
        try await databaseService.advancedService.markAITipAsRead(tipId: tipId)
    }
    
    // MARK: - Fan Activity Timeline
    
    func getFanActivity(userId: UUID, limit: Int = 20) async throws -> [DatabaseFanActivity] {
        return try await databaseService.advancedService.getFanActivity(userId: userId, limit: limit)
    }
    
    // MARK: - Fan Idols Management
    
    /// Get user's fan idols with artist information
    func getFanIdols(userId: UUID) async throws -> [DatabaseFanIdolWithArtist] {
        guard let url = URL(string: "\(baseURL)/rest/v1/fan_idols") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add user authentication token for RLS
        if let token = authService.currentAccessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            print("⚠️ No access token available for getFanIdols - using anon key only")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        // Filter by user and include artist info
        let queryItems = [
            URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString)"),
            URLQueryItem(name: "select", value: "id,user_id,artist_id,priority_rank,created_at,updated_at,artists(id,name,group_name,image_url,spotify_id,is_following,created_at)"),
            URLQueryItem(name: "order", value: "priority_rank.asc")
        ]
        
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = queryItems
        request.url = urlComponents.url
        
        do {
            let customSession = NetworkManager.createURLSession(timeout: NetworkManager.standardTimeout)
            let (data, response) = try await customSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                // CRITICAL: Use enhanced decoder for proper date handling
                return try decodeSupabaseResponse([DatabaseFanIdolWithArtist].self, from: data)
            case 401:
                throw SupabaseError.unauthorized
            case 404:
                return [] // No idols found
            default:
                throw SupabaseError.serverError("HTTP \(httpResponse.statusCode)")
            }
        } catch {
            if error is SupabaseError {
                throw error
            } else {
                throw SupabaseError.networkError(error)
            }
        }
    }
    
    /// Add a fan idol using Edge Function
    func addFanIdol(artistId: UUID, priorityRank: Int? = nil) async throws -> String {
        let parameters: [String: Encodable] = [
            "artistId": artistId.uuidString,
            "priorityRank": priorityRank
        ]
        
        struct FunctionResponse: Codable {
            let success: Bool
            let message: String
        }
        
        let response: FunctionResponse = try await callFunction(
            functionName: "add-fan-idol",
            parameters: parameters
        )
        
        guard response.success else {
            throw SupabaseError.serverError(response.message)
        }
        
        return response.message
    }
    
    /// Delete a fan idol using Edge Function
    func deleteFanIdol(idolId: UUID? = nil, artistId: UUID? = nil) async throws -> String {
        guard idolId != nil || artistId != nil else {
            throw SupabaseError.dataParsingError
        }
        
        var parameters: [String: Any] = [:]
        if let idolId = idolId {
            parameters["idolId"] = idolId.uuidString
        }
        if let artistId = artistId {
            parameters["artistId"] = artistId.uuidString
        }
        
        struct FunctionResponse: Codable {
            let success: Bool
            let message: String
        }
        
        let response: FunctionResponse = try await callFunction(
            functionName: "delete-fan-idol",
            parameters: parameters
        )
        
        guard response.success else {
            throw SupabaseError.serverError(response.message)
        }
        
        return response.message
    }
    
    /// Check subscription status and idol limits
    @MainActor
    func getSubscriptionStatus() -> (isPro: Bool, idolLimit: Int) {
        // Integrate with RevenueCat subscription status
        let revenueCatManager = RevenueCatManager.shared
        let isPro = revenueCatManager.isSubscriptionActive || revenueCatManager.hasValidPromoCode
        let idolLimit = isPro ? 6 : 3

        return (isPro: isPro, idolLimit: idolLimit)
    }
    
    /// Get current idol count for user
    func getFanIdolCount(userId: UUID) async throws -> Int {
        guard let url = URL(string: "\(baseURL)/rest/v1/fan_idols") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"  // Use HEAD to get count without data
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("exact", forHTTPHeaderField: "Prefer") // Get exact count
        
        let queryItems = [
            URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString)")
        ]
        
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = queryItems
        request.url = urlComponents.url
        
        do {
            let customSession = NetworkManager.createURLSession(timeout: NetworkManager.standardTimeout)
            let (_, response) = try await customSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                // Extract count from Content-Range header
                if let contentRange = httpResponse.value(forHTTPHeaderField: "Content-Range"),
                   let countString = contentRange.split(separator: "/").last,
                   let count = Int(countString) {
                    return count
                }
                return 0
            case 401:
                throw SupabaseError.unauthorized
            default:
                throw SupabaseError.serverError("HTTP \(httpResponse.statusCode)")
            }
        } catch {
            if error is SupabaseError {
                throw error
            } else {
                throw SupabaseError.networkError(error)
            }
        }
    }
}

// MARK: - Priority Management Extension
extension SupabaseService {
    
    /// Get user priorities - delegates to databaseService
    func getUserPriorities(userId: UUID) async throws -> [DatabaseUserPriority] {
        return try await databaseService.getUserPriorities(userId: userId)
    }
    
    /// Save onboarding priorities - delegates to databaseService
    func saveOnboardingPriorities(
        userId: UUID,
        categoryPriorities: [String: PriorityLevel]
    ) async throws {
        try await databaseService.saveOnboardingPriorities(
            userId: userId,
            categoryPriorities: categoryPriorities
        )
    }
    
    /// Update priority spent amount - delegates to databaseService
    func updatePrioritySpent(
        userId: UUID,
        categoryId: String,
        amount: Double
    ) async throws {
        try await databaseService.updatePrioritySpent(
            userId: userId,
            category: categoryId,
            additionalAmount: amount
        )
    }

    // MARK: - Artist Notifications

    /// Get artist updates from deployed Supabase function
    func getArtistUpdates(artistNames: [String], limit: Int = 50, offset: Int = 0) async throws -> [ArtistUpdate] {
        struct ArtistUpdatesRequest: Codable {
            let artist_names: [String]
            let limit: Int
            let offset: Int
        }

        struct ArtistUpdatesResponse: Codable {
            let success: Bool
            let updates: [ArtistUpdateDTO]
            let error: String?
        }

        struct ArtistUpdateDTO: Codable {
            let id: String
            let artist_name: String
            let update_type: String
            let title: String
            let description: String?
            let timestamp: String
            let source_url: String?
            let image_url: String?
            let is_breaking: Bool?
        }

        let request = ArtistUpdatesRequest(
            artist_names: artistNames,
            limit: limit,
            offset: offset
        )

        let response: ArtistUpdatesResponse = try await client.functions.invoke(
            "get-artist-updates",
            options: FunctionInvokeOptions(
                body: request
            )
        )

        let result = response

        if !result.success {
            throw SupabaseError.functionError(result.error ?? "Unknown error")
        }

        // Convert DTOs to ArtistUpdate model
        return result.updates.compactMap { dto -> ArtistUpdate? in
            guard let timestamp = DateDecodingManager.decodeDate(from: dto.timestamp) else {
                print("⚠️ Failed to decode timestamp: \(dto.timestamp)")
                return nil
            }

            return ArtistUpdate(
                id: dto.id,
                artistName: dto.artist_name,
                type: ArtistUpdateType.from(string: dto.update_type),
                title: dto.title,
                description: dto.description,
                timestamp: timestamp,
                sourceURL: dto.source_url,
                imageURL: dto.image_url,
                isBreaking: dto.is_breaking ?? false
            )
        }
    }
}

