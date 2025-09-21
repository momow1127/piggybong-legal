import Foundation

// MARK: - Supabase Advanced Database Service
/// Handles advanced database operations like fan goals, AI tips, and user artists
class SupabaseAdvancedService {
    private let baseURL: String
    private let apiKey: String
    private weak var authService: SupabaseAuthService?
    
    init(baseURL: String, apiKey: String, authService: SupabaseAuthService) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.authService = authService
    }
    
    // MARK: - Error Types
    enum AdvancedError: LocalizedError {
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
            throw AdvancedError.invalidURL
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
                throw AdvancedError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                return data
            case 401:
                throw AdvancedError.unauthorized
            case 404:
                throw AdvancedError.notFound
            case 408: // Request Timeout
                throw NetworkError.timeout
            case 503, 504: // Service/Gateway Unavailable
                throw NetworkError.hostUnreachable
            default:
                // Sanitize error messages for production
                let sanitizedError = ValidationService.shared.sanitizeError(
                    AdvancedError.serverError("HTTP \(httpResponse.statusCode)")
                )
                throw sanitizedError
            }
        }
    }
    
    // MARK: - User Artists Management
    
    func getUserArtists(userId: UUID) async throws -> [DatabaseUserArtist] {
        print("🔍 Fetching user artists for userId: \(userId.uuidString)")

        do {
            // Use longer timeout for complex queries with joins
            let data = try await makeRequest(
                path: "/user_artists?user_id=eq.\(userId.uuidString)&is_active=eq.true&select=*,artists(name,image_url)&order=priority_rank.asc",
                timeout: NetworkManager.quickFetchTimeout // 20 seconds instead of 15
            )

            print("✅ Successfully fetched user artists data (\(data.count) bytes)")

            let decoder = JSONDecoder()
            let artists = try decoder.decode([DatabaseUserArtist].self, from: data)

            print("✅ Decoded \(artists.count) user artists")
            return artists

        } catch {
            print("❌ Failed to fetch user artists: \(error)")
            print("   - Error type: \(type(of: error))")
            print("   - User ID: \(userId.uuidString)")
            print("   - Auth token available: \(authService?.currentAccessToken != nil)")

            // Don't swallow errors - let the calling code handle them properly
            throw error
        }
    }
    
    func createUserArtist(userId: UUID, artistId: UUID, priorityRank: Int, monthlyAllocation: Double) async throws -> UUID {
        let userArtistData = [
            "user_id": userId.uuidString,
            "artist_id": artistId.uuidString,
            "priority_rank": priorityRank,
            "monthly_allocation": monthlyAllocation
        ] as [String: Any]
        
        let jsonData = try JSONSerialization.data(withJSONObject: userArtistData)
        
        do {
            let responseData = try await makeRequest(
                path: "/user_artists",
                method: "POST",
                body: jsonData,
                headers: ["Prefer": "return=representation"]
            )
            
            let decoder = JSONDecoder()
            let userArtists = try decoder.decode([DatabaseUserArtist].self, from: responseData)
            guard let userArtist = userArtists.first else {
                throw AdvancedError.dataParsingError
            }
            
            print("✅ User artist created successfully: \(userArtist.id)")
            return userArtist.id
        } catch {
            print("❌ Failed to create user artist: \(error)")
            throw error
        }
    }
    
    func updateUserArtistAllocation(userId: UUID, artistId: UUID, monthlyAllocation: Double) async throws {
        let updateData = ["monthly_allocation": monthlyAllocation]
        let jsonData = try JSONSerialization.data(withJSONObject: updateData)
        
        do {
            _ = try await makeRequest(
                path: "/user_artists?user_id=eq.\(userId.uuidString)&artist_id=eq.\(artistId.uuidString)",
                method: "PATCH",
                body: jsonData
            )
            print("✅ User artist allocation updated successfully")
        } catch {
            print("❌ Failed to update user artist allocation: \(error)")
            throw error
        }
    }
    
    // MARK: - Enhanced Goals with Fan Context
    
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
        let goalData = [
            "user_id": userId.uuidString,
            "artist_id": artistId?.uuidString,
            "name": name,
            "target_amount": targetAmount,
            "current_amount": 0.0,
            "deadline": ISO8601DateFormatter().string(from: deadline),
            "category": category,
            "priority": priority,
            "goal_type": goalType,
            "is_time_sensitive": isTimeSensitive,
            "event_date": eventDate.map { ISO8601DateFormatter().string(from: $0) },
            "countdown_context": countdownContext
        ] as [String: Any?]
        
        let jsonData = try JSONSerialization.data(withJSONObject: goalData.compactMapValues { $0 })
        
        do {
            let responseData = try await makeRequest(
                path: "/goals",
                method: "POST",
                body: jsonData,
                headers: ["Prefer": "return=representation"]
            )
            
            let decoder = JSONDecoder()
            let goals = try decoder.decode([DatabaseGoal].self, from: responseData)
            guard let goal = goals.first else {
                throw AdvancedError.dataParsingError
            }
            
            print("✅ Fan goal created successfully: \(goal.id)")
            return goal.id
        } catch {
            print("❌ Failed to create fan goal: \(error)")
            throw error
        }
    }
    
    // MARK: - AI Tips Management
    
    func getActiveAITips(userId: UUID) async throws -> [DatabaseAITip] {
        do {
            let data = try await makeRequest(path: "/ai_tips?user_id=eq.\(userId.uuidString)&is_active=eq.true&order=created_at.desc")
            let decoder = JSONDecoder()
            return try decoder.decode([DatabaseAITip].self, from: data)
        } catch {
            print("❌ Failed to fetch AI tips: \(error)")
            return []
        }
    }
    
    func markAITipAsRead(tipId: UUID) async throws {
        let updateData = ["is_read": true]
        let jsonData = try JSONSerialization.data(withJSONObject: updateData)
        
        do {
            _ = try await makeRequest(
                path: "/ai_tips?id=eq.\(tipId.uuidString)",
                method: "PATCH",
                body: jsonData
            )
            print("✅ AI tip marked as read")
        } catch {
            print("❌ Failed to mark AI tip as read: \(error)")
            throw error
        }
    }
    
    // MARK: - Fan Activity Timeline
    
    func getFanActivity(userId: UUID, limit: Int = 20) async throws -> [DatabaseFanActivity] {
        do {
            let data = try await makeRequest(path: "/fan_activity?user_id=eq.\(userId.uuidString)&order=created_at.desc&limit=\(limit)")
            let decoder = JSONDecoder()
            return try decoder.decode([DatabaseFanActivity].self, from: data)
        } catch {
            print("❌ Failed to fetch fan activity: \(error)")
            return []
        }
    }
}