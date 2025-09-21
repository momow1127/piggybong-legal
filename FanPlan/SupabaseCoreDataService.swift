import Foundation

// MARK: - Supabase Core Data Service
/// Handles core data operations like purchases, budgets, and goals
class SupabaseCoreDataService {
    private let baseURL: String
    private let apiKey: String
    private weak var authService: SupabaseAuthService?
    
    init(baseURL: String, apiKey: String, authService: SupabaseAuthService) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.authService = authService
    }
    
    // MARK: - Error Types
    enum CoreDataError: LocalizedError {
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
            throw CoreDataError.invalidURL
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
                throw CoreDataError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                return data
            case 401:
                throw CoreDataError.unauthorized
            case 404:
                throw CoreDataError.notFound
            case 408: // Request Timeout
                throw NetworkError.timeout
            case 503, 504: // Service/Gateway Unavailable
                throw NetworkError.hostUnreachable
            default:
                // Sanitize error messages for production
                let sanitizedError = ValidationService.shared.sanitizeError(
                    CoreDataError.serverError("HTTP \(httpResponse.statusCode)")
                )
                throw sanitizedError
            }
        }
    }
    
    // MARK: - Purchases
    
    func getPurchases(for userId: UUID, limit: Int = 20) async throws -> [DashboardTransaction] {
        do {
            let data = try await makeRequest(path: "/purchases?user_id=eq.\(userId.uuidString)&select=*,artists(name)&order=purchase_date.desc&limit=\(limit)")
            let decoder = JSONDecoder()
            
            struct PurchaseWithArtist: Codable {
                let id: UUID
                let userId: UUID
                let artistId: UUID
                let amount: Double
                let category: String
                let description: String
                let notes: String?
                let purchaseDate: String
                let createdAt: String
                let artists: ArtistName?
                
                struct ArtistName: Codable {
                    let name: String
                }
                
                enum CodingKeys: String, CodingKey {
                    case id, amount, category, description, notes, artists
                    case userId = "user_id"
                    case artistId = "artist_id"
                    case purchaseDate = "purchase_date"
                    case createdAt = "created_at"
                }
            }
            
            let purchasesWithArtists = try decoder.decode([PurchaseWithArtist].self, from: data)
            
            return purchasesWithArtists.map { purchase in
                let category: TransactionCategory
                switch purchase.category {
                case "album": category = .album
                case "concert": category = .concert
                case "merchandise": category = .merchandise
                case "digital": category = .subscription
                default: category = .other
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let date = dateFormatter.date(from: purchase.purchaseDate) ?? Date()
                
                return DashboardTransaction(
                    id: purchase.id,
                    title: purchase.description,
                    subtitle: purchase.artists?.name,
                    amount: -purchase.amount,
                    type: .expense,
                    category: category,
                    date: date,
                    artistName: purchase.artists?.name
                )
            }
        } catch {
            print("❌ Failed to fetch purchases: \(error)")
            // Return empty array instead of mock data for real integration
            return []
        }
    }
    
    func createPurchase(userId: UUID, artistId: UUID, amount: Double, category: String, description: String, notes: String? = nil) async throws -> UUID {
        let purchaseData = [
            "user_id": userId.uuidString,
            "artist_id": artistId.uuidString,
            "amount": amount,
            "category": category,
            "description": description,
            "notes": notes,
            "purchase_date": DateFormatter.dateOnly.string(from: Date())
        ] as [String: Any?]
        
        let jsonData = try JSONSerialization.data(withJSONObject: purchaseData.compactMapValues { $0 })
        
        do {
            let responseData = try await makeRequest(
                path: "/purchases",
                method: "POST",
                body: jsonData,
                headers: ["Prefer": "return=representation"]
            )
            
            let decoder = JSONDecoder()
            let purchases = try decoder.decode([DatabasePurchase].self, from: responseData)
            guard let purchase = purchases.first else {
                throw CoreDataError.dataParsingError
            }
            
            print("✅ Purchase created successfully: \(purchase.id)")
            return purchase.id
        } catch {
            print("❌ Failed to create purchase: \(error)")
            throw error
        }
    }
    
    func updatePurchase(id: UUID, amount: Double? = nil, description: String? = nil, notes: String? = nil) async throws {
        var updateData: [String: Any] = [:]
        if let amount = amount { updateData["amount"] = amount }
        if let description = description { updateData["description"] = description }
        if let notes = notes { updateData["notes"] = notes }
        
        guard !updateData.isEmpty else { return }
        
        let jsonData = try JSONSerialization.data(withJSONObject: updateData)
        
        do {
            _ = try await makeRequest(
                path: "/purchases?id=eq.\(id.uuidString)",
                method: "PATCH",
                body: jsonData
            )
            print("✅ Purchase updated successfully")
        } catch {
            print("❌ Failed to update purchase: \(error)")
            throw error
        }
    }
    
    func deletePurchase(id: UUID) async throws {
        do {
            _ = try await makeRequest(
                path: "/purchases?id=eq.\(id.uuidString)",
                method: "DELETE"
            )
            print("✅ Purchase deleted successfully")
        } catch {
            print("❌ Failed to delete purchase: \(error)")
            throw error
        }
    }
    
    // MARK: - Budgets
    
    func getBudget(userId: UUID, month: Int, year: Int) async throws -> DatabaseBudget? {
        do {
            let data = try await makeRequest(path: "/budgets?user_id=eq.\(userId.uuidString)&month=eq.\(month)&year=eq.\(year)&select=*")
            let decoder = JSONDecoder()
            let budgets = try decoder.decode([DatabaseBudget].self, from: data)
            return budgets.first
        } catch {
            print("❌ Failed to fetch budget: \(error)")
            return nil
        }
    }
    
    func createBudget(userId: UUID, month: Int, year: Int, totalBudget: Double) async throws -> UUID {
        let budgetData = [
            "user_id": userId.uuidString,
            "month": month,
            "year": year,
            "total_budget": totalBudget,
            "spent": 0.0
        ] as [String: Any]
        
        let jsonData = try JSONSerialization.data(withJSONObject: budgetData)
        
        do {
            let responseData = try await makeRequest(
                path: "/budgets",
                method: "POST",
                body: jsonData,
                headers: ["Prefer": "return=representation"]
            )
            
            let decoder = JSONDecoder()
            let budgets = try decoder.decode([DatabaseBudget].self, from: responseData)
            guard let budget = budgets.first else {
                throw CoreDataError.dataParsingError
            }
            
            print("✅ Budget created successfully: \(budget.id)")
            return budget.id
        } catch {
            print("❌ Failed to create budget: \(error)")
            throw error
        }
    }
    
    func updateBudgetSpent(userId: UUID, month: Int, year: Int, additionalAmount: Double, getUser: @escaping (UUID) async throws -> DatabaseUser) async throws {
        // First get current budget
        guard let currentBudget = try await getBudget(userId: userId, month: month, year: year) else {
            // Create budget if it doesn't exist
            let user = try await getUser(userId)
            _ = try await createBudget(userId: userId, month: month, year: year, totalBudget: user.monthlyBudget)
            return
        }
        
        let newSpent = currentBudget.spent + additionalAmount
        let updateData = ["spent": newSpent]
        let jsonData = try JSONSerialization.data(withJSONObject: updateData)
        
        do {
            _ = try await makeRequest(
                path: "/budgets?id=eq.\(currentBudget.id.uuidString)",
                method: "PATCH",
                body: jsonData
            )
            print("✅ Budget spending updated successfully")
        } catch {
            print("❌ Failed to update budget spending: \(error)")
            throw error
        }
    }
    
    // MARK: - Goals (REMOVED)
    // Goal functionality has been removed from the app
    
    // getGoals method removed - goal functionality no longer supported
    /*
    func getGoals(for userId: UUID) async throws -> [Goal] {
        do {
            let data = try await makeRequest(path: "/goals?user_id=eq.\(userId.uuidString)&select=*,artists(name)&order=created_at.desc")
            let decoder = JSONDecoder()
            
            struct GoalWithArtist: Codable {
                let id: UUID
                let userId: UUID
                let artistId: UUID?
                let name: String
                let targetAmount: Double
                let currentAmount: Double
                let deadline: String
                let category: String
                let imageUrl: String?
                let priority: String
                let createdAt: String
                let updatedAt: String
                let artists: ArtistName?
                
                struct ArtistName: Codable {
                    let name: String
                }
                
                enum CodingKeys: String, CodingKey {
                    case id, name, deadline, category, priority, artists
                    case userId = "user_id"
                    case artistId = "artist_id"
                    case targetAmount = "target_amount"
                    case currentAmount = "current_amount"
                    case imageUrl = "image_url"
                    case createdAt = "created_at"
                    case updatedAt = "updated_at"
                }
            }
            
            let goalsWithArtists = try decoder.decode([GoalWithArtist].self, from: data)
            
            return goalsWithArtists.map { goal in
                let goalCategory: FanCategory
                switch goal.category {
                case "concert": goalCategory = .concerts
                case "album": goalCategory = .albums
                case "merchandise": goalCategory = .merch
                case "fanmeet": goalCategory = .events
                default: goalCategory = .other
                }
                
                let goalPriority: GoalPriority
                switch goal.priority {
                case "high": goalPriority = .high
                case "low": goalPriority = .low
                default: goalPriority = .medium
                }
                
                let deadlineDate = ISO8601DateFormatter().date(from: goal.deadline) ?? Date()
                let createdDate = ISO8601DateFormatter().date(from: goal.createdAt) ?? Date()
                
                return Goal(
                    id: goal.id,
                    name: goal.name,
                    targetAmount: goal.targetAmount,
                    currentAmount: goal.currentAmount,
                    deadline: deadlineDate,
                    category: goalCategory,
                    imageURL: goal.imageUrl,
                    artistName: goal.artists?.name,
                    priority: goalPriority,
                    createdAt: createdDate
                )
            }
        } catch {
            print("❌ Failed to fetch goals: \(error)")
            return []
        }
    }
    
    // createGoal method removed - goal functionality no longer supported
    /*
    func createGoal(userId: UUID, artistId: UUID?, name: String, targetAmount: Double, deadline: Date, category: String, priority: String = "medium") async throws -> UUID {
        let goalData = [
            "user_id": userId.uuidString,
            "artist_id": artistId?.uuidString,
            "name": name,
            "target_amount": targetAmount,
            "current_amount": 0.0,
            "deadline": ISO8601DateFormatter().string(from: deadline),
            "category": category,
            "priority": priority
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
                throw CoreDataError.dataParsingError
            }
            
            print("✅ Goal created successfully: \(goal.id)")
            return goal.id
        } catch {
            print("❌ Failed to create goal: \(error)")
            throw error
        }
    }
    */
    
    func updateGoalProgress(goalId: UUID, additionalAmount: Double) async throws {
        // This would typically be done via a database function to ensure atomicity
        let updateData = ["current_amount": "current_amount + \(additionalAmount)"]
        let jsonData = try JSONSerialization.data(withJSONObject: updateData)
        
        do {
            _ = try await makeRequest(
                path: "/goals?id=eq.\(goalId.uuidString)",
                method: "PATCH",
                body: jsonData
            )
            print("✅ Goal progress updated successfully")
        } catch {
            print("❌ Failed to update goal progress: \(error)")
            throw error
        }
    }
    */
    // Goal methods commented out - functionality no longer supported
}

// MARK: - DateFormatter Extension
fileprivate extension DateFormatter {
    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}