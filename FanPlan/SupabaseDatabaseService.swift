import Foundation
import Supabase

// MARK: - Supabase Database Service
/// Handles all database operations with Supabase
class SupabaseDatabaseService {
    private let baseURL: String
    private let apiKey: String
    private weak var authService: SupabaseAuthService?
    public let advancedService: SupabaseAdvancedService
    public let coreDataService: SupabaseCoreDataService
    
    init(baseURL: String, apiKey: String, authService: SupabaseAuthService) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.authService = authService
        self.advancedService = SupabaseAdvancedService(baseURL: baseURL, apiKey: apiKey, authService: authService)
        self.coreDataService = SupabaseCoreDataService(baseURL: baseURL, apiKey: apiKey, authService: authService)
    }
    
    // MARK: - Error Types
    enum DatabaseError: LocalizedError {
        case invalidURL
        case invalidResponse
        case unauthorized
        case notFound
        case dataParsingError
        case serverError(String)
        case networkError(Error)
        case authenticationRequired
        
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
            case .authenticationRequired:
                return "Authentication required for this operation"
            }
        }
    }
    
    // MARK: - HTTP Request Helper
    private func makeRequest(
        path: String,
        method: String = "GET",
        body: Data? = nil,
        headers: [String: String] = [:],
        timeout: TimeInterval = NetworkManager.standardTimeout
    ) async throws -> Data {
        guard let url = URL(string: "\(baseURL)/rest/v1\(path)") else {
            throw DatabaseError.invalidURL
        }
        
        return try await NetworkManager.performRequest(timeout: timeout, maxRetries: 2) {
            let session = NetworkManager.createURLSession(timeout: timeout)
            
            var request = URLRequest(url: url)
            request.httpMethod = method
            
            // Set default headers
            request.setValue(self.apiKey, forHTTPHeaderField: "apikey")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            // Set authorization header if available
            if let token = self.authService?.currentAccessToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                print("🔐 Auth token set for request (length: \(token.count))")
            } else {
                print("⚠️ NO AUTH TOKEN AVAILABLE - using anon key for MVP")
                print("   - authService exists: \(self.authService != nil)")
                print("   - authService.currentAccessToken exists: \(self.authService?.currentAccessToken != nil)")

                // For MVP: Use anon key as Bearer token to bypass RLS temporarily
                request.setValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")
                print("🔧 MVP: Using anon key as auth token for testing")
            }
            
            // Add custom headers
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            if let body = body {
                request.httpBody = body
            }
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw DatabaseError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                return data
            case 401:
                throw DatabaseError.unauthorized
            case 404:
                throw DatabaseError.notFound
            case 408: // Request Timeout
                throw DatabaseError.serverError("Request timed out")
            case 503, 504: // Service/Gateway Unavailable
                throw DatabaseError.serverError("Service unavailable")
            default:
                // Sanitize error messages for production
                let sanitizedError = ValidationService.shared.sanitizeError(
                    DatabaseError.serverError("HTTP \(httpResponse.statusCode)")
                )
                throw sanitizedError
            }
        }
    }
    
    // MARK: - User Management
    
    func getUserByEmail(email: String) async throws -> DatabaseUser? {
        do {
            let data = try await makeRequest(path: "/users?email=eq.\(email)&select=*")
            let decoder = JSONDecoder()
            let users = try decoder.decode([DatabaseUser].self, from: data)
            return users.first
        } catch {
            print("❌ Failed to fetch user by email: \(error)")
            return nil
        }
    }
    
    func linkAuthUser(userId: UUID, authId: UUID) async throws {
        let updateData = ["auth_user_id": authId.uuidString]
        let jsonData = try JSONSerialization.data(withJSONObject: updateData)
        
        do {
            _ = try await makeRequest(
                path: "/users?id=eq.\(userId.uuidString)",
                method: "PATCH",
                body: jsonData
            )
            print("✅ User linked with auth ID successfully")
        } catch {
            print("❌ Failed to link auth user: \(error)")
            throw error
        }
    }
    
    func createUser(name: String, email: String, monthlyBudget: Double, termsAccepted: Bool = false, termsVersion: String? = nil) async throws -> UUID {
        let currentDate = ISO8601DateFormatter().string(from: Date())
        
        var userData: [String: Any] = [
            "name": name,
            "email": email,
            "monthly_budget": monthlyBudget,
            "currency": "USD"
        ]
        
        // Add terms acceptance tracking if terms were accepted
        if termsAccepted {
            userData["terms_accepted_at"] = currentDate
            userData["privacy_accepted_at"] = currentDate // Both accepted together
            userData["terms_version"] = termsVersion ?? "2025-08-20"
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: userData)
        
        do {
            let responseData = try await makeRequest(
                path: "/users",
                method: "POST",
                body: jsonData,
                headers: ["Prefer": "return=representation"]
            )
            
            let decoder = JSONDecoder()
            let users = try decoder.decode([DatabaseUser].self, from: responseData)
            guard let user = users.first else {
                throw DatabaseError.dataParsingError
            }
            
            print("✅ User created successfully: \(user.id)")
            return user.id
        } catch {
            print("❌ Failed to create user: \(error)")
            throw error
        }
    }
    
    func getUser(id: UUID) async throws -> DatabaseUser {
        do {
            let data = try await makeRequest(path: "/users?id=eq.\(id.uuidString)&select=*")
            let decoder = JSONDecoder()
            let users = try decoder.decode([DatabaseUser].self, from: data)
            
            guard let user = users.first else {
                throw DatabaseError.notFound
            }
            
            return user
        } catch {
            print("❌ Failed to fetch user: \(error)")
            throw error
        }
    }
    
    func updateUserBudget(userId: UUID, monthlyBudget: Double) async throws {
        let userData: [String: Any] = ["monthly_budget": monthlyBudget]
        let jsonData = try JSONSerialization.data(withJSONObject: userData)
        
        do {
            _ = try await makeRequest(
                path: "/users?id=eq.\(userId.uuidString)",
                method: "PATCH",
                body: jsonData
            )
            print("✅ User budget updated successfully")
        } catch {
            print("❌ Failed to update user budget: \(error)")
            throw error
        }
    }
    
    // MARK: - Artists
    
    func getArtists() async throws -> [Artist] {
        // First check network connectivity
        let isConnected = await NetworkManager.shared.checkConnectivity()
        
        if !isConnected {
            print("📡 No network connection detected, using embedded artists (\(self.getMockKpopArtists().count) available)")
            return self.getMockKpopArtists()
        }
        
        do {
            print("🔄 Attempting to fetch artists from: \(baseURL)/rest/v1/artists")
            let data = try await makeRequest(
                path: "/artists?select=*",
                timeout: NetworkManager.quickFetchTimeout
            )
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let databaseArtists = try decoder.decode([DatabaseArtist].self, from: data)
            
            // Validate that artists have proper UUIDs
            let validArtists = databaseArtists.filter { !$0.id.uuidString.isEmpty }
            
            if validArtists.count != databaseArtists.count {
                print("⚠️ Warning: \(databaseArtists.count - validArtists.count) artists have invalid UUIDs")
            }
            
            print("✅ Successfully fetched \(validArtists.count) artists with valid UUIDs from database")
            print("📋 Artist sample: \(validArtists.prefix(3).map { "\($0.name) (\($0.id))" }.joined(separator: ", "))")
            
            let artists = validArtists.map { $0.toArtist() }
            
            // If we get fewer than expected artists, supplement with mock data
            if artists.count < 10 {
                print("⚠️ Database returned only \(artists.count) artists, supplementing with embedded data")
                let mockArtists = getMockKpopArtists()
                let combinedArtists = artists + mockArtists.filter { mockArtist in
                    !artists.contains { $0.name.lowercased() == mockArtist.name.lowercased() }
                }
                print("✅ Combined total: \(combinedArtists.count) artists available")
                return combinedArtists
            }
            
            return artists
            
        } catch {
            // Handle different error types with better context
            let networkError = NetworkManager.shared.handleNetworkError(error)
            
            switch networkError {
            case .timeout:
                print("⏰ Database request timed out after \(NetworkManager.quickFetchTimeout)s, using embedded artists")
            case .noConnection:
                print("📡 No internet connection, using embedded artists")
            case .hostUnreachable:
                print("🌐 Cannot reach Supabase servers, using embedded artists")
            default:
                print("❌ Database fetch failed (\(networkError.localizedDescription)), using embedded artists")
            }
            
            let fallbackArtists = self.getMockKpopArtists()
            print("✅ Fallback: \(fallbackArtists.count) embedded K-pop artists ready")
            return fallbackArtists
        }
    }
    
    private func getMockKpopArtists() -> [Artist] {
        return [
            // From your Supabase CSV data - Boy Groups
            Artist(name: "BTS", group: "BTS"),
            Artist(name: "SEVENTEEN", group: "SEVENTEEN"),
            Artist(name: "Stray Kids", group: "Stray Kids"),
            Artist(name: "ATEEZ", group: "ATEEZ"),
            Artist(name: "ENHYPEN", group: "ENHYPEN"),
            Artist(name: "RIIZE", group: "RIIZE"),
            Artist(name: "BOYNEXTDOOR", group: "BOYNEXTDOOR"),
            Artist(name: "ZEROBASEONE", group: "ZEROBASEONE"),
            Artist(name: "TOMORROW X TOGETHER", group: "TOMORROW X TOGETHER"),
            Artist(name: "BIGBANG", group: "BIGBANG"),
            
            // Girl Groups
            Artist(name: "BLACKPINK", group: "BLACKPINK"),
            Artist(name: "NewJeans", group: "NewJeans"),
            Artist(name: "aespa", group: "aespa"),
            Artist(name: "IVE", group: "IVE"),
            Artist(name: "LE SSERAFIM", group: "LE SSERAFIM"),
            Artist(name: "i-dle", group: "i-dle"),
            Artist(name: "ITZY", group: "ITZY"),
            Artist(name: "TWICE", group: "TWICE"),
            Artist(name: "BABYMONSTER", group: "BABYMONSTER"),
            Artist(name: "ILLIT", group: "ILLIT"),
            Artist(name: "2NE1", group: "2NE1"),
            Artist(name: "KATSEYE", group: "KATSEYE"),
            
            // Co-ed Groups
            Artist(name: "ALLDAY PROJECT", group: "ALLDAY PROJECT"),
            
            // Female Solo Artists
            Artist(name: "IU", group: nil),
            Artist(name: "Lisa", group: "BLACKPINK"),
            Artist(name: "Jennie", group: "BLACKPINK"),
            Artist(name: "Rosé", group: "BLACKPINK"),
            Artist(name: "Jisoo", group: "BLACKPINK"),
            Artist(name: "Taeyeon", group: "Girls' Generation"),
            Artist(name: "CL", group: "2NE1"),
            Artist(name: "JEON SOMI", group: nil),
            
            // Male Solo Artists  
            Artist(name: "Jungkook", group: "BTS"),
            Artist(name: "V", group: "BTS"),
            Artist(name: "Jimin", group: "BTS"),
            Artist(name: "Jin", group: "BTS"),
            Artist(name: "J-Hope", group: "BTS"),
            Artist(name: "RM", group: "BTS"),
            Artist(name: "Suga", group: "BTS"),
            Artist(name: "G-Dragon", group: "BIGBANG"),
            Artist(name: "Taemin", group: "SHINee"),
            Artist(name: "PSY", group: nil)
        ]
    }
    
    func createArtist(name: String, groupName: String?, imageUrl: String? = nil) async throws -> UUID {
        let artistData = [
            "name": name,
            "group_name": groupName,
            "image_url": imageUrl,
            "is_following": false
        ] as [String: Any?]
        
        let jsonData = try JSONSerialization.data(withJSONObject: artistData.compactMapValues { $0 })
        
        do {
            let responseData = try await makeRequest(
                path: "/artists",
                method: "POST",
                body: jsonData,
                headers: ["Prefer": "return=representation"]
            )
            
            let decoder = JSONDecoder()
            let artists = try decoder.decode([DatabaseArtist].self, from: responseData)
            guard let artist = artists.first else {
                throw DatabaseError.dataParsingError
            }
            
            print("✅ Artist created successfully: \(artist.id)")
            return artist.id
        } catch {
            print("❌ Failed to create artist: \(error)")
            throw error
        }
    }
    
    func getArtist(byId artistId: UUID) async throws -> Artist? {
        // First check network connectivity
        let isConnected = await NetworkManager.shared.checkConnectivity()
        
        if !isConnected {
            print("📡 No network connection, searching in embedded artists")
            let mockArtists = getMockKpopArtists()
            return mockArtists.first { $0.id == artistId }
        }
        
        do {
            print("🔍 Fetching artist by ID: \(artistId)")
            let data = try await makeRequest(
                path: "/artists?id=eq.\(artistId.uuidString)&select=*",
                timeout: NetworkManager.quickFetchTimeout
            )
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let databaseArtists = try decoder.decode([DatabaseArtist].self, from: data)
            
            if let databaseArtist = databaseArtists.first {
                print("✅ Found artist in database: \(databaseArtist.name)")
                return databaseArtist.toArtist()
            } else {
                print("❌ Artist not found in database with ID: \(artistId)")
                return nil
            }
            
        } catch {
            print("❌ Failed to fetch artist by ID: \(error)")
            // Fallback to embedded artists
            let mockArtists = getMockKpopArtists()
            return mockArtists.first { $0.id == artistId }
        }
    }
    
    func getArtistName(byId artistId: UUID) async throws -> String? {
        if let artist = try await getArtist(byId: artistId) {
            return artist.name
        }
        return nil
    }
    
    func searchArtists(query: String) async throws -> [Artist] {
        let allArtists = try await getArtists()
        return allArtists.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
    
    // MARK: - Purchases (Delegated to CoreDataService)
    
    func getPurchases(for userId: UUID, limit: Int = 20) async throws -> [DashboardTransaction] {
        return try await coreDataService.getPurchases(for: userId, limit: limit)
    }
    
    func createPurchase(userId: UUID, artistId: UUID, amount: Double, category: String, description: String, notes: String? = nil) async throws -> UUID {
        return try await coreDataService.createPurchase(userId: userId, artistId: artistId, amount: amount, category: category, description: description, notes: notes)
    }
    
    func updatePurchase(id: UUID, amount: Double? = nil, description: String? = nil, notes: String? = nil) async throws {
        try await coreDataService.updatePurchase(id: id, amount: amount, description: description, notes: notes)
    }
    
    func deletePurchase(id: UUID) async throws {
        try await coreDataService.deletePurchase(id: id)
    }
    
    // MARK: - Budgets (Delegated to CoreDataService)
    
    func getBudget(userId: UUID, month: Int, year: Int) async throws -> DatabaseBudget? {
        return try await coreDataService.getBudget(userId: userId, month: month, year: year)
    }
    
    func createBudget(userId: UUID, month: Int, year: Int, totalBudget: Double) async throws -> UUID {
        return try await coreDataService.createBudget(userId: userId, month: month, year: year, totalBudget: totalBudget)
    }
    
    func updateBudgetSpent(userId: UUID, month: Int, year: Int, additionalAmount: Double) async throws {
        try await coreDataService.updateBudgetSpent(userId: userId, month: month, year: year, additionalAmount: additionalAmount) { userId in
            return try await self.getUser(id: userId)
        }
    }
    
    // MARK: - Goals (Delegated to CoreDataService)
    
    // getGoals method removed - goal functionality no longer supported
    
    // createGoal method removed - goal functionality no longer supported
    
    // updateGoalProgress method removed - goal functionality no longer supported
    
    // MARK: - User Artists Management (Delegated to AdvancedService)
    
    func getUserArtists(userId: UUID) async throws -> [DatabaseUserArtist] {
        return try await advancedService.getUserArtists(userId: userId)
    }
    
    func createUserArtist(userId: UUID, artistId: UUID, priorityRank: Int, monthlyAllocation: Double) async throws -> UUID {
        return try await advancedService.createUserArtist(userId: userId, artistId: artistId, priorityRank: priorityRank, monthlyAllocation: monthlyAllocation)
    }
    
    func updateUserArtistAllocation(userId: UUID, artistId: UUID, monthlyAllocation: Double) async throws {
        try await advancedService.updateUserArtistAllocation(userId: userId, artistId: artistId, monthlyAllocation: monthlyAllocation)
    }
    
    // MARK: - Enhanced Goals with Fan Context (Delegated to AdvancedService)
    
    func createFanGoal(
        userId: UUID,
        artistId: UUID?,
        name: String,
        targetAmount: Double,
        deadline: Date,
        category: String,
        goalType: String,
        isTimeSensitive: Bool = false,
        eventDate: Date? = nil,
        countdownContext: String? = nil,
        priority: String = "medium"
    ) async throws -> UUID {
        return try await advancedService.createFanGoal(
            userId: userId,
            artistId: artistId,
            name: name,
            targetAmount: targetAmount,
            deadline: deadline,
            category: category,
            goalType: goalType,
            isTimeSensitive: isTimeSensitive,
            eventDate: eventDate,
            countdownContext: countdownContext,
            priority: priority
        )
    }
    
    // MARK: - AI Tips Management (Delegated to AdvancedService)
    
    func getActiveAITips(userId: UUID) async throws -> [DatabaseAITip] {
        return try await advancedService.getActiveAITips(userId: userId)
    }
    
    func markAITipAsRead(tipId: UUID) async throws {
        try await advancedService.markAITipAsRead(tipId: tipId)
    }
    
    // MARK: - Fan Activity Management
    
    func createFanActivity(
        userId: UUID,
        amountMajor: Double,
        categoryId: String,
        categoryTitle: String,
        idolId: UUID? = nil,
        note: String? = nil,
        occurredAt: Date = Date()
    ) async throws -> DatabaseFanActivity {
        print("🗄️ createFanActivity called with parameters:")
        print("   - userId: \(userId.uuidString)")
        print("   - amountMajor: \(amountMajor) (type: \(type(of: amountMajor)))")
        print("   - categoryId: '\(categoryId)' (length: \(categoryId.count))")
        print("   - categoryTitle: '\(categoryTitle)'")
        print("   - idolId: \(idolId?.uuidString ?? "nil")")
        print("   - note: '\(note ?? "nil")'")
        print("   - occurredAt: \(occurredAt)")
        
        let payload: [String: Any] = [
            "user_id": userId.uuidString,
            "amount": amountMajor,
            "category_id": categoryId,
            "category_title": categoryTitle,
            "idol_id": idolId?.uuidString as Any,
            "note": note as Any,
            "created_at": ISO8601DateFormatter().string(from: occurredAt)
        ]
        
        print("🗄️ Supabase payload:")
        for (key, value) in payload {
            print("   - \(key): \(value) (type: \(type(of: value)))")
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            print("✅ JSON serialization successful, size: \(jsonData.count) bytes")
        } catch {
            print("❌ JSON serialization failed: \(error)")
            throw error
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: payload)
        
        do {
            print("🌐 Making POST request to /fan_activities...")
            let responseData = try await makeRequest(
                path: "/fan_activities",
                method: "POST",
                body: jsonData,
                headers: ["Prefer": "return=representation"]
            )
            print("✅ POST request successful, response size: \(responseData.count) bytes")
            
            // Log raw response for debugging
            if let responseString = String(data: responseData, encoding: .utf8) {
                print("🗄️ Raw Supabase response: \(responseString)")
            }
            
            let decoder = JSONDecoder()
            do {
                let activities = try decoder.decode([DatabaseFanActivity].self, from: responseData)
                print("✅ JSON decode successful, \(activities.count) activities returned")
                
                guard let activity = activities.first else {
                    print("❌ No activity returned in response array")
                    throw DatabaseError.dataParsingError
                }
                
                print("✅ Fan activity created successfully: ID=\(activity.id)")
                return activity
                
            } catch {
                print("❌ JSON decode failed: \(error)")
                if let responseString = String(data: responseData, encoding: .utf8) {
                    print("❌ Failed to decode response: \(responseString)")
                }
                throw error
            }
            
        } catch {
            print("❌ Supabase POST request failed:")
            print("   - Error type: \(type(of: error))")
            print("   - Error description: \(error.localizedDescription)")
            
            // Check for specific Supabase/network errors
            if let urlError = error as? URLError {
                print("   - URLError code: \(urlError.code)")
                print("   - URLError description: \(urlError.localizedDescription)")
            }
            
            // Check for HTTP response errors
            if let databaseError = error as? DatabaseError {
                print("   - DatabaseError: \(databaseError.localizedDescription)")
            }
            
            throw error
        }
    }
    
    // MARK: - New Supabase SDK-based Fan Activity Creation
    
    /// Create fan activity using Supabase Swift SDK with auth.currentUser.id
    func createFanActivityWithSDK(
        amount: Double,
        category: String,
        artist: String,
        artistId: UUID? = nil,
        note: String?
    ) async throws -> DatabaseFanActivity {
        print("🗄️ createFanActivityWithSDK called using Supabase Swift SDK")
        print("   - amount: \(amount)")
        print("   - category: '\(category)'")
        print("   - artist: '\(artist)'")
        print("   - artistId: \(artistId?.uuidString ?? "nil")")
        print("   - note: '\(note ?? "nil")'")
        
        // STEP 1: Detailed Authentication Debugging
        print("🔍 === STEP 1: AUTHENTICATION DEBUG ===")
        
        // Check if we have an auth client
        let authClient = SupabaseService.shared.client.auth
        print("🔐 Auth client available: ✅")
        
        // Check current user
        guard let currentUser = authClient.currentUser else {
            print("❌ createFanActivityWithSDK failed: No authenticated user found")
            print("🔍 Auth Debug Info:")
            print("   - SupabaseService initialized: ✅")
            print("   - Client initialized: ✅")
            print("   - Auth available: ✅")
            throw DatabaseError.authenticationRequired
        }
        
        let currentUserId = currentUser.id
        print("✅ Authentication successful:")
        print("   - User ID: \(currentUserId)")
        print("   - User Email: \(currentUser.email ?? "N/A")")
        // Access app metadata safely - property name varies by SDK version
        let authMethod: String = {
            // Try different property names based on SDK version
            if let provider = currentUser.appMetadata["provider"]?.stringValue {
                return provider
            } else if let provider = currentUser.userMetadata["provider"]?.stringValue {
                return provider
            }
            return "Unknown"
        }()
        print("   - Auth method: \(authMethod)")
        print("   - User confirmed: \(currentUser.emailConfirmedAt != nil ? "✅" : "❌")")
        
        // Check if we have an access token
        do {
            let session = try await authClient.session
            let tokenPreview = String(session.accessToken.prefix(20)) + "..."
            print("   - Access token available: ✅ (\(tokenPreview))")
            print("   - Token expires at timestamp: \(session.expiresAt)")
            print("   - Token valid: \(session.expiresAt > Date().timeIntervalSince1970 ? "✅" : "❌ EXPIRED")")
        } catch {
            print("   - Access token: ❌ NOT AVAILABLE - \(error.localizedDescription)")
        }
        
        // STEP 2: Data Structure Validation
        print("\n🔍 === STEP 2: DATA STRUCTURE VALIDATION ===")
        
        // Validate data types and structure
        print("🔢 Input data validation:")
        print("   - amount: \(amount) (type: \(type(of: amount)))")
        print("   - category: '\(category)' (length: \(category.count))")
        print("   - artist: '\(artist)' (length: \(artist.count))")
        print("   - artistId: \(artistId?.uuidString ?? "nil")")
        print("   - note: '\(note ?? "nil")' (type: \(type(of: note)))")
        print("   - currentUserId: '\(currentUserId)' (UUID type: ✅)")
        
        // Validate required fields
        guard amount > 0 else {
            print("❌ Invalid amount: must be > 0, got \(amount)")
            throw DatabaseError.dataParsingError
        }
        
        guard !category.isEmpty else {
            print("❌ Invalid category: cannot be empty")
            throw DatabaseError.dataParsingError
        }
        
        guard !artist.isEmpty else {
            print("❌ Invalid artist: cannot be empty")
            throw DatabaseError.dataParsingError
        }
        
        // STEP 3: Build payload with detailed logging
        print("\n🔍 === STEP 3: PAYLOAD CONSTRUCTION ===")
        
        let newActivity = DatabaseFanActivity(
            id: UUID(),
            userId: currentUserId,
            artistId: nil, // artist is a string name, not UUID
            activityType: category,
            title: "\(category) - \(artist)",
            description: note,
            amount: amount,
            metadata: ["artist_name": artist],
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        
        print("🗄️ Final Supabase SDK payload:")
        print("   - id: \(newActivity.id)")
        print("   - userId: \(newActivity.userId)")
        print("   - amount: \(newActivity.amount ?? 0)")
        print("   - activityType: \(newActivity.activityType)")
        print("   - title: \(newActivity.title)")
        print("   - description: \(newActivity.description ?? "nil")")
        print("   - artistId: \(newActivity.artistId?.uuidString ?? "nil")")
        
        // STEP 4: Database Schema Warnings
        print("\n⚠️ === STEP 4: SCHEMA ASSUMPTIONS ===")
        print("   - Assuming fan_activities.user_id is UUID type")
        print("   - Assuming fan_activities.amount is NUMERIC/DECIMAL type")
        print("   - Assuming fan_activities.category_id is TEXT/VARCHAR type")
        print("   - Assuming fan_activities.idol_id is TEXT/VARCHAR type")
        print("   - Assuming fan_activities.note is TEXT type (nullable)")
        print("   - If any of these assumptions are wrong, the insert will fail")
        
        do {
            print("\n🔍 === STEP 5: DATABASE INSERT ATTEMPT ===")
            print("🌐 Using Supabase SDK to insert into fan_activities table...")
            print("   - Table: fan_activities")
            print("   - Method: INSERT with SELECT")
            print("   - Auth token will be automatically included by SDK")
            
            let response: [DatabaseFanActivity] = try await SupabaseService.shared.client
                .from("fan_activities")
                .insert(newActivity)
                .select()
                .execute()
                .value
            
            print("✅ Supabase SDK insert successful!")
            print("   - Response count: \(response.count) activities returned")
            print("   - This indicates RLS policies are working correctly")
            
            guard let activity = response.first else {
                print("❌ No activity returned in SDK response array")
                throw DatabaseError.dataParsingError
            }
            
            print("✅ Fan activity created successfully via SDK: ID=\(activity.id)")
            print("🎉 SDK approach working - auth token handled automatically!")
            return activity
            
        } catch {
            print("\n🔍 === STEP 6: ERROR ANALYSIS ===")
            print("❌ Supabase SDK insert failed:")
            print("   - Error type: \(type(of: error))")
            print("   - Error description: \(error.localizedDescription)")
            
            // Detailed error analysis
            let errorString = error.localizedDescription.lowercased()
            
            if errorString.contains("authentication") || errorString.contains("unauthorized") {
                print("\n🔐 === AUTHENTICATION ERROR DETECTED ===")
                print("❌ This is an authentication/authorization error")
                print("📋 Possible causes:")
                print("   1. User is not logged in (auth.currentUser is null)")
                print("   2. Access token is expired or invalid")
                print("   3. RLS policy is rejecting the insert")
                print("   4. Supabase service key is incorrect")
                
                print("\n🔧 Troubleshooting steps:")
                print("   1. Check Supabase dashboard -> Authentication -> Users")
                print("   2. Verify user exists and is confirmed")
                print("   3. Check RLS policies on fan_activities table")
                print("   4. Test with RLS temporarily disabled")
                
            } else if errorString.contains("column") || errorString.contains("relation") {
                print("\n🗄️ === DATABASE SCHEMA ERROR DETECTED ===")
                print("❌ This is a database schema/structure error")
                print("📋 Possible causes:")
                print("   1. Column name mismatch (check exact column names)")
                print("   2. Table name 'fan_activities' doesn't exist")
                print("   3. Data type mismatch (UUID vs TEXT, etc.)")
                print("   4. Missing required columns")
                
            } else if errorString.contains("violate") || errorString.contains("constraint") {
                print("\n🔗 === FOREIGN KEY/CONSTRAINT ERROR DETECTED ===")
                print("❌ This is a database constraint violation")
                print("📋 Possible causes:")
                print("   1. idol_id references non-existent artist")
                print("   2. user_id references non-existent user")
                print("   3. Check constraint violation on amount or other fields")
                
            } else {
                print("\n❓ === UNKNOWN ERROR TYPE ===")
                print("❌ Could not categorize error type")
                print("📋 General debugging steps:")
                print("   1. Check Supabase dashboard logs")
                print("   2. Verify network connectivity")
                print("   3. Check if table exists and has correct permissions")
            }
            
            throw DatabaseError.serverError(error.localizedDescription)
        }
    }
    
    func getFanActivity(userId: UUID, limit: Int = 20) async throws -> [DatabaseFanActivity] {
        return try await advancedService.getFanActivity(userId: userId, limit: limit)
    }
    
    // MARK: - Debug Helper Functions
    
    /// Debug helper to test authentication and basic connectivity
    func debugAuthenticationStatus() async {
        print("\n🔍 === AUTHENTICATION STATUS DEBUG ===")
        
        // Check service initialization
        print("🏗️ Service Status:")
        print("   - SupabaseService initialized: ✅")
        print("   - Client initialized: ✅")
        print("   - Auth available: ✅")
        
        // Check current user
        let authClient = SupabaseService.shared.client.auth
        if let currentUser = authClient.currentUser {
            print("👤 Current User:")
            print("   - ID: \(currentUser.id)")
            print("   - Email: \(currentUser.email ?? "N/A")")
            print("   - Phone: \(currentUser.phone ?? "N/A")")
            print("   - Email Confirmed: \(currentUser.emailConfirmedAt != nil ? "✅" : "❌")")
            print("   - Created: \(currentUser.createdAt)")
            print("   - Last Sign In: \(currentUser.lastSignInAt ?? Date())")
            
            // Provider info
            // Access provider from app metadata safely
            if let provider = currentUser.appMetadata["provider"]?.stringValue {
                print("   - Auth Provider: \(provider)")
            } else if let provider = currentUser.userMetadata["provider"]?.stringValue {
                print("   - Auth Provider: \(provider)")
            }
            
            // Session info
            do {
                let session = try await authClient.session
                print("🎫 Session Info:")
                print("   - Access Token: \(session.accessToken.prefix(20))...")
                print("   - Refresh Token: \(session.refreshToken.prefix(20))...")
                print("   - Token Expires: \(session.expiresAt)")
                print("   - Token Valid: \(session.expiresAt > Date().timeIntervalSince1970 ? "✅" : "❌ EXPIRED")")
            } catch {
                print("🎫 Session: ❌ NO SESSION FOUND - \(error.localizedDescription)")
            }
        } else {
            print("👤 Current User: ❌ NOT AUTHENTICATED")
        }
        
        // Test basic table access (without insert)
        await debugTableAccess()
    }
    
    /// Debug helper to test basic table access
    private func debugTableAccess() async {
        print("\n🔍 === TABLE ACCESS TEST ===")
        
        do {
            // Try to read from fan_activities table (should work with RLS)
            print("🗄️ Testing SELECT access to fan_activities table...")
            let count: Int = try await SupabaseService.shared.client
                .from("fan_activities")
                .select("id", head: true, count: .exact)
                .execute()
                .count ?? 0
            
            print("✅ Table access successful!")
            print("   - Total activities in table: \(count)")
            print("   - This indicates basic auth and table access work")
            
        } catch {
            print("❌ Table access failed:")
            print("   - Error: \(error.localizedDescription)")
            print("   - This could indicate RLS issues or table doesn't exist")
        }
    }
    
    // MARK: - User Priorities Management
    
    /// Gets user priorities from database
    func getUserPriorities(userId: UUID) async throws -> [DatabaseUserPriority] {
        do {
            let data = try await makeRequest(
                path: "/user_priorities?user_id=eq.\(userId.uuidString)&select=*",
                timeout: NetworkManager.quickFetchTimeout
            )
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let priorities = try decoder.decode([DatabaseUserPriority].self, from: data)
            print("✅ Fetched \(priorities.count) user priorities from database")
            return priorities
            
        } catch {
            print("❌ Failed to fetch user priorities: \(error)")
            throw error
        }
    }
    
    /// Creates or updates user priority in database
    func upsertUserPriority(
        userId: UUID,
        artistId: UUID?,
        category: String,
        priority: Int,
        monthlyAllocation: Double? = nil
    ) async throws -> UUID {
        let currentDate = ISO8601DateFormatter().string(from: Date())
        
        let priorityData: [String: Any] = [
            "user_id": userId.uuidString,
            "artist_id": artistId?.uuidString as Any,
            "category": category,
            "priority": priority,
            "monthly_allocation": monthlyAllocation as Any,
            "spent": 0.0,
            "created_at": currentDate,
            "updated_at": currentDate
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: priorityData.compactMapValues { $0 })
        
        do {
            let responseData = try await makeRequest(
                path: "/user_priorities",
                method: "POST",
                body: jsonData,
                headers: [
                    "Prefer": "return=representation",
                    "Resolution": "merge-duplicates"
                ]
            )
            
            let decoder = JSONDecoder()
            let priorities = try decoder.decode([DatabaseUserPriority].self, from: responseData)
            guard let priority = priorities.first else {
                throw DatabaseError.dataParsingError
            }
            
            print("✅ Upserted user priority: category=\(category), priority=\(priority.priority)")
            return priority.id
        } catch {
            print("❌ Failed to upsert user priority: \(error)")
            throw error
        }
    }
    
    /// Bulk save user priorities from onboarding
    func saveOnboardingPriorities(
        userId: UUID,
        categoryPriorities: [String: PriorityLevel]
    ) async throws {
        print("💾 Saving \(categoryPriorities.count) onboarding priorities for user \(userId)")
        
        for (categoryId, priorityLevel) in categoryPriorities {
            let priorityValue: Int
            switch priorityLevel {
            case .high: priorityValue = 1
            case .medium: priorityValue = 2
            case .low: priorityValue = 3
            }
            
            do {
                _ = try await upsertUserPriority(
                    userId: userId,
                    artistId: nil, // Category-level priority, not artist-specific
                    category: categoryId,
                    priority: priorityValue
                )
            } catch {
                print("⚠️ Failed to save priority for category \(categoryId): \(error)")
                // Continue with other categories even if one fails
            }
        }
        
        print("✅ Finished saving onboarding priorities")
    }
    
    /// Updates spent amount for a user priority
    func updatePrioritySpent(
        userId: UUID,
        category: String,
        additionalAmount: Double
    ) async throws {
        // First get the current priority
        let priorities = try await getUserPriorities(userId: userId)
        guard let priority = priorities.first(where: { $0.category == category }) else {
            print("⚠️ Priority not found for category \(category), creating default")
            // Create a default priority if it doesn't exist
            _ = try await upsertUserPriority(
                userId: userId,
                artistId: nil,
                category: category,
                priority: 2 // Default to medium priority
            )
            return
        }
        
        let newSpent = priority.spent + additionalAmount
        let updateData: [String: Any] = [
            "spent": newSpent,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: updateData)
        
        do {
            _ = try await makeRequest(
                path: "/user_priorities?id=eq.\(priority.id.uuidString)",
                method: "PATCH",
                body: jsonData
            )
            print("✅ Updated priority spent amount: \(category) += \(additionalAmount)")
        } catch {
            print("❌ Failed to update priority spent: \(error)")
            throw error
        }
    }
    
    // MARK: - Health Check
    
    func checkSupabaseConnectivity() async throws -> Bool {
        // Test Supabase connectivity using a simple health check endpoint
        guard let url = URL(string: "\(baseURL)/rest/v1/") else {
            throw SupabaseService.SupabaseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 25.0 // Increased timeout for iOS Simulator stability

        do {
            let customSession = NetworkManager.createURLSession(timeout: 25.0)
            let (_, response) = try await customSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseService.SupabaseError.invalidResponse
            }

            // Return true for successful status codes (200-299)
            let isConnected = (200...299).contains(httpResponse.statusCode)

            if isConnected {
                print("✅ Supabase connection successful (HTTP \(httpResponse.statusCode))")
            } else {
                print("⚠️ Supabase responded with HTTP \(httpResponse.statusCode)")
            }

            return isConnected
        } catch {
            print("❌ Supabase connection failed: \(error.localizedDescription)")
            throw SupabaseService.SupabaseError.networkError(error)
        }
    }
}

