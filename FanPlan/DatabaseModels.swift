import Foundation
import SwiftUI

// MARK: - Database Models
// These models match the database schema exactly for JSON serialization

struct DatabaseUser: Codable {
    let id: UUID
    let authUserId: UUID?
    let email: String
    let name: String
    let monthlyBudget: Double
    let currency: String
    let termsAcceptedAt: String?
    let privacyAcceptedAt: String?
    let termsVersion: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case authUserId = "auth_user_id"
        case email
        case name
        case monthlyBudget = "monthly_budget"
        case currency
        case termsAcceptedAt = "terms_accepted_at"
        case privacyAcceptedAt = "privacy_accepted_at"
        case termsVersion = "terms_version"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Custom initializer from decoder with safe defaults
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required fields
        id = try container.decode(UUID.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        monthlyBudget = try container.decodeIfPresent(Double.self, forKey: .monthlyBudget) ?? 0.0
        currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? "USD"

        // Optional fields with safe defaults
        authUserId = try container.decodeIfPresent(UUID.self, forKey: .authUserId)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Fan User"
        termsAcceptedAt = try container.decodeIfPresent(String.self, forKey: .termsAcceptedAt)
        privacyAcceptedAt = try container.decodeIfPresent(String.self, forKey: .privacyAcceptedAt)
        termsVersion = try container.decodeIfPresent(String.self, forKey: .termsVersion)
        let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt)
        let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        let formatter = ISO8601DateFormatter()
        createdAt = createdAtString.flatMap { formatter.date(from: $0) }
        updatedAt = updatedAtString.flatMap { formatter.date(from: $0) }
    }

    // Custom encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(authUserId, forKey: .authUserId)
        try container.encode(email, forKey: .email)
        try container.encode(name, forKey: .name)
        try container.encode(monthlyBudget, forKey: .monthlyBudget)
        try container.encode(currency, forKey: .currency)
        try container.encodeIfPresent(termsAcceptedAt, forKey: .termsAcceptedAt)
        try container.encodeIfPresent(privacyAcceptedAt, forKey: .privacyAcceptedAt)
        try container.encodeIfPresent(termsVersion, forKey: .termsVersion)
        let formatter = ISO8601DateFormatter()
        let createdAtString = createdAt.map { formatter.string(from: $0) }
        let updatedAtString = updatedAt.map { formatter.string(from: $0) }
        try container.encodeIfPresent(createdAtString, forKey: .createdAt)
        try container.encodeIfPresent(updatedAtString, forKey: .updatedAt)
    }

    // Convenience initializer for creating fallback profiles
    init(
        id: UUID,
        authUserId: UUID?,
        email: String,
        name: String,
        monthlyBudget: Double,
        currency: String,
        termsAcceptedAt: String? = nil,
        privacyAcceptedAt: String? = nil,
        termsVersion: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.authUserId = authUserId
        self.email = email
        self.name = name
        self.monthlyBudget = monthlyBudget
        self.currency = currency
        self.termsAcceptedAt = termsAcceptedAt
        self.privacyAcceptedAt = privacyAcceptedAt
        self.termsVersion = termsVersion
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct DatabaseArtist: Codable {
    let id: UUID
    let name: String
    let type: String
    let agency: String
    let debutYear: Int
    let genres: [String]?
    let imageUrl: String?
    let spotifyId: String?
    let popularity: Int?
    let keywords: [String]?
    let priorityLevel: String?
    let hasUsTours: Bool?
    let isActive: Bool?
    let createdAt: String
    let updatedAt: String?
    
    // Legacy fields for compatibility (marked as optional)
    let groupName: String?
    let isFollowing: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case agency
        case debutYear = "debut_year"
        case genres
        case imageUrl = "image_url"
        case spotifyId = "spotify_id"
        case popularity
        case keywords
        case priorityLevel = "priority_level"
        case hasUsTours = "has_us_tours"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        
        // Legacy fields
        case groupName = "group_name"
        case isFollowing = "is_following"
    }
    
}

struct DatabasePurchase: Codable {
    let id: UUID
    let userId: UUID
    let artistId: UUID
    let amount: Double
    let category: String
    let description: String
    let notes: String?
    let purchaseDate: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case artistId = "artist_id"
        case amount
        case category
        case description
        case notes
        case purchaseDate = "purchase_date"
        case createdAt = "created_at"
    }
}

struct DatabaseBudget: Codable {
    let id: UUID
    let userId: UUID
    let month: Int
    let year: Int
    let totalBudget: Double
    let spent: Double
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case month
        case year
        case totalBudget = "total_budget"
        case spent
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct DatabaseGoal: Codable {
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
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case artistId = "artist_id"
        case name
        case targetAmount = "target_amount"
        case currentAmount = "current_amount"
        case deadline
        case category
        case imageUrl = "image_url"
        case priority
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Fan Experience Models

struct DatabaseUserArtist: Codable {
    let id: UUID
    let userId: UUID
    let artistId: UUID
    let priorityRank: Int
    let monthlyAllocation: Double
    let totalSpent: Double
    let monthSpent: Double
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case artistId = "artist_id"
        case priorityRank = "priority_rank"
        case monthlyAllocation = "monthly_allocation"
        case totalSpent = "total_spent"
        case monthSpent = "month_spent"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct DatabaseAITip: Codable {
    let id: UUID
    let userId: UUID
    let artistId: UUID?
    let tipType: String
    let message: String
    let isPremium: Bool
    let isRead: Bool
    let isActive: Bool
    let expiresAt: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case artistId = "artist_id"
        case tipType = "tip_type"
        case message
        case isPremium = "is_premium"
        case isRead = "is_read"
        case isActive = "is_active"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
    }
}

struct DatabaseGoalProgress: Codable {
    let id: UUID
    let goalId: UUID
    let amountAdded: Double
    let note: String?
    let celebrationTriggered: Bool
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case goalId = "goal_id"
        case amountAdded = "amount_added"
        case note
        case celebrationTriggered = "celebration_triggered"
        case createdAt = "created_at"
    }
}

struct DatabaseFanActivity: Codable {
    let id: UUID
    let userId: UUID
    let artistId: UUID?
    let activityType: String
    let title: String
    let description: String?
    let amount: Double?
    let metadata: [String: String]?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case artistId = "artist_id"
        case activityType = "activity_type"
        case title
        case description
        case amount
        case metadata
        case createdAt = "created_at"
    }
}

// MARK: - Fan Idols Model
struct DatabaseFanIdol: Codable {
    let id: UUID
    let userId: UUID
    let artistId: UUID
    let priorityRank: Int
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case artistId = "artist_id"
        case priorityRank = "priority_rank"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Fan Idol with Artist Info
struct DatabaseFanIdolWithArtist: Codable {
    let id: UUID
    let userId: UUID
    let artistId: UUID
    let priorityRank: Int
    let createdAt: String
    let updatedAt: String
    let artist: DatabaseArtist
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case artistId = "artist_id"
        case priorityRank = "priority_rank"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case artist
    }
}

// MARK: - Subscription Status Model
struct SubscriptionStatus: Codable {
    let isPro: Bool
    let idolLimit: Int
    let remainingSlots: Int?
    
    enum CodingKeys: String, CodingKey {
        case isPro = "is_pro"
        case idolLimit = "idol_limit"
        case remainingSlots = "remaining_slots"
    }
}

// MARK: - Enhanced Purchase Model
struct EnhancedDatabasePurchase: Codable {
    let id: UUID
    let userId: UUID
    let artistId: UUID
    let amount: Double
    let category: String
    let description: String
    let notes: String?
    let purchaseDate: String
    let createdAt: String
    
    // Fan-specific fields
    let contextNote: String?
    let fanCategory: String
    let isComebackRelated: Bool
    let venueLocation: String?
    let albumVersion: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case artistId = "artist_id"
        case amount
        case category
        case description
        case notes
        case purchaseDate = "purchase_date"
        case createdAt = "created_at"
        case contextNote = "context_note"
        case fanCategory = "fan_category"
        case isComebackRelated = "is_comeback_related"
        case venueLocation = "venue_location"
        case albumVersion = "album_version"
    }
}

// MARK: - Enhanced Goal Model
struct EnhancedDatabaseGoal: Codable {
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
    
    // Fan-specific fields
    let goalType: String
    let countdownContext: String?
    let isTimeSensitive: Bool
    let eventDate: String?
    let presaleDate: String?
    let celebrationMilestone: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case artistId = "artist_id"
        case name
        case targetAmount = "target_amount"
        case currentAmount = "current_amount"
        case deadline
        case category
        case imageUrl = "image_url"
        case priority
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case goalType = "goal_type"
        case countdownContext = "countdown_context"
        case isTimeSensitive = "is_time_sensitive"
        case eventDate = "event_date"
        case presaleDate = "presale_date"
        case celebrationMilestone = "celebration_milestone"
    }
}

// MARK: - API Response Models

struct BiasBudgetStatus: Codable {
    let artistName: String
    let priorityRank: Int
    let monthlyAllocation: Double
    let monthSpent: Double
    let remainingBudget: Double
    let spentPercentage: Double
    
    enum CodingKeys: String, CodingKey {
        case artistName = "artist_name"
        case priorityRank = "priority_rank"
        case monthlyAllocation = "monthly_allocation"
        case monthSpent = "month_spent"
        case remainingBudget = "remaining_budget"
        case spentPercentage = "spent_percentage"
    }
}

struct FanGoalWithCountdown: Codable {
    let goalId: UUID
    let goalName: String
    let artistName: String?
    let targetAmount: Double
    let currentAmount: Double
    let progressPercentage: Double
    let daysUntilEvent: Int?
    let countdownContext: String?
    let isUrgent: Bool
    
    enum CodingKeys: String, CodingKey {
        case goalId = "goal_id"
        case goalName = "goal_name"
        case artistName = "artist_name"
        case targetAmount = "target_amount"
        case currentAmount = "current_amount"
        case progressPercentage = "progress_percentage"
        case daysUntilEvent = "days_until_event"
        case countdownContext = "countdown_context"
        case isUrgent = "is_urgent"
    }
}

struct DashboardHomeResponse: Codable {
    let biasBudgetStatus: [BiasBudgetStatus]
    let fanGoals: [FanGoalWithCountdown]
    let aiTip: DatabaseAITip?
    let recentActivity: [DatabaseFanActivity]
    let upcomingEvents: [UpcomingEvent]
    
    enum CodingKeys: String, CodingKey {
        case biasBudgetStatus = "bias_budget_status"
        case fanGoals = "fan_goals"
        case aiTip = "ai_tip"
        case recentActivity = "recent_activity"
        case upcomingEvents = "upcoming_events"
    }
}

// UpcomingEvent is defined in FanExperienceModels.swift

// MARK: - Fan Category Enums

enum DBFanCategory: String, CaseIterable, Codable {
    case concertPrep = "concert_prep"
    case albumHunting = "album_hunting"
    case merchHaul = "merch_haul"
    case photocardCollecting = "photocard_collecting"
    case digitalContent = "digital_content"
    case fanmeetPrep = "fanmeet_prep"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .concertPrep: return "Concert Prep"
        case .albumHunting: return "Album Hunting"
        case .merchHaul: return "Merch Haul"
        case .photocardCollecting: return "Photocard Collecting"
        case .digitalContent: return "Digital Content"
        case .fanmeetPrep: return "Fanmeet Prep"
        case .other: return "Other"
        }
    }
    
    var emoji: String {
        switch self {
        case .concertPrep: return "🎤"
        case .albumHunting: return "💿"
        case .merchHaul: return "👕"
        case .photocardCollecting: return "📸"
        case .digitalContent: return "📱"
        case .fanmeetPrep: return "💜"
        case .other: return "✨"
        }
    }
    
    func toUI() -> FanCategory {
        switch self {
        case .concertPrep: return .concerts
        case .albumHunting: return .albums
        case .merchHaul: return .merch
        case .photocardCollecting: return .albums
        case .digitalContent: return .subscriptions
        case .fanmeetPrep: return .events
        case .other: return .other
        }
    }
}

enum DBGoalType: String, CaseIterable, Codable {
    case concertTickets = "concert_tickets"
    case albumCollection = "album_collection"
    case merchHaul = "merch_haul"
    case fanmeetTickets = "fanmeet_tickets"
    case digitalSubscriptions = "digital_subscriptions"
    case photocardsComplete = "photocards_complete"
    case general = "general"
    
    var displayName: String {
        switch self {
        case .concertTickets: return "Concert Tickets"
        case .albumCollection: return "Album Collection"
        case .merchHaul: return "Merchandise"
        case .fanmeetTickets: return "Fanmeet Tickets"
        case .digitalSubscriptions: return "Digital Subscriptions"
        case .photocardsComplete: return "Photocard Collection"
        case .general: return "General Savings"
        }
    }
    
    func toUI() -> FanCategory {
        switch self {
        case .concertTickets: return .concerts
        case .albumCollection: return .albums
        case .merchHaul: return .merch
        case .fanmeetTickets: return .concerts
        case .digitalSubscriptions: return .subscriptions
        case .photocardsComplete: return .albums
        case .general: return .other
        }
    }
}

// MARK: - Conversion Extensions
extension DatabaseUser {
    var createdAtDate: Date? {
        return createdAt
    }
    
    func toDashboardUser() -> DashboardUser {
        return DashboardUser(
            id: id,
            name: name,
            totalSaved: 0.0, // This would be calculated from transactions
            monthlyBudget: monthlyBudget,
            totalMonthlyBudget: monthlyBudget,
            totalMonthSpent: 0.0, // This would be calculated from current month purchases
            joinedDate: createdAtDate ?? Date()
        )
    }
}

extension DatabaseArtist {
    func toArtist() -> Artist {
        return Artist(
            id: id,
            name: name,
            group: groupName ?? name,
            imageURL: imageUrl
        )
    }
}

extension DatabasePurchase {
    func toDashboardTransaction(artistName: String?) -> DashboardTransaction {
        let purchaseCategory: TransactionCategory
        switch category {
        case "album": purchaseCategory = .album
        case "concert": purchaseCategory = .concert
        case "merchandise": purchaseCategory = .merchandise
        case "digital": purchaseCategory = .subscription
        default: purchaseCategory = .other
        }
        
        let date = ISO8601DateFormatter().date(from: purchaseDate) ?? Date()
        
        return DashboardTransaction(
            id: id,
            title: description,
            subtitle: artistName,
            amount: -amount, // Negative for expenses
            type: .expense,
            category: purchaseCategory,
            date: date,
            artistName: artistName
        )
    }
}

// DatabaseGoal conversion removed - goal functionality no longer supported

// MARK: - Enhanced Model Conversions

extension DatabaseUserArtist {
    func toFanArtist(artistName: String, artistImageURL: String?) -> FanArtist {
        return FanArtist(
            id: artistId,
            name: artistName,
            priorityRank: priorityRank,
            monthlyAllocation: monthlyAllocation,
            monthSpent: monthSpent,
            totalSpent: totalSpent,
            remainingBudget: monthlyAllocation - monthSpent,
            spentPercentage: monthlyAllocation > 0 ? (monthSpent / monthlyAllocation) * 100 : 0,
            imageURL: artistImageURL,
            timeline: [],
            wishlistItems: [],
            priorities: []
        )
    }
}

// EnhancedDatabaseGoal conversion removed - goal functionality no longer supported

extension EnhancedDatabasePurchase {
    func toFanPurchase(artistName: String?) -> FanPurchase {
        let purchaseCategory = DBFanCategory(rawValue: fanCategory)?.toUI() ?? .other
        let date = ISO8601DateFormatter().date(from: purchaseDate) ?? Date()
        
        return FanPurchase(
            id: id,
            artistId: artistId,
            artistName: artistName ?? "Unknown Artist",
            amount: amount,
            category: purchaseCategory,
            description: description,
            contextNote: contextNote,
            isComebackRelated: isComebackRelated,
            venueLocation: venueLocation,
            albumVersion: albumVersion,
            purchaseDate: date
        )
    }
}

// MARK: - User Priority Model
struct DatabaseUserPriority: Codable {
    let id: UUID
    let userId: UUID
    let artistId: UUID?
    let category: String
    let priority: Int // 1 = high, 2 = medium, 3 = low
    let monthlyAllocation: Double?
    let spent: Double
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case artistId = "artist_id"
        case category
        case priority
        case monthlyAllocation = "monthly_allocation"
        case spent
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Fan Idol Extensions

extension DatabaseFanIdol {
    func toIdolModel(with artist: DatabaseArtist) -> IdolModel {
        return IdolModel(
            id: artistId.uuidString,
            name: artist.name,
            profileImageURL: artist.imageUrl ?? ""
        )
    }
}

extension DatabaseFanIdolWithArtist {
    func toIdolModel() -> IdolModel {
        return IdolModel(
            id: artistId.uuidString,
            name: artist.name,
            profileImageURL: artist.imageUrl ?? ""
        )
    }
    
    func toDashboardArtist() -> DashboardArtist {
        return DashboardArtist(
            id: artistId,
            name: artist.name,
            imageURL: artist.imageUrl,
            upcomingEvents: 0, // TODO: Calculate from events table
            budgetAllocated: 0.0, // TODO: Calculate from user_artists table
            budgetSpent: 0.0 // TODO: Calculate from purchases table
        )
    }
}

// MARK: - User Priority Extensions

extension DatabaseUserPriority {
    func toUserPriority() -> UserPriority {
        return UserPriority(
            id: id,
            artistId: artistId ?? UUID(),
            category: FanCategory.fromString(category),
            priority: priority,
            monthlyAllocation: monthlyAllocation ?? 0.0,
            spent: spent
        )
    }
}
