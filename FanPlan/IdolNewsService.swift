import Foundation
import SwiftUI

// MARK: - Idol News Service
@MainActor
class IdolNewsService: ObservableObject {
    static let shared = IdolNewsService()
    
    @Published var newsItems: [IdolNewsItem] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var hasMore = true
    @Published var priorityFilter: PriorityFilter = .all
    @Published var cacheEnabled = true
    
    private let supabaseService = SupabaseService.shared
    private var currentOffset = 0
    private let pageSize = 20
    
    private init() {}
    
    // MARK: - Fetch Personalized News with Priority Filtering
    func fetchPersonalizedNews(refresh: Bool = false, priorityFilter: PriorityFilter? = nil) async {
        if refresh {
            currentOffset = 0
            hasMore = true
        }
        
        if let filter = priorityFilter {
            self.priorityFilter = filter
        }
        
        guard !isLoading else { return }
        isLoading = true
        error = nil
        
        do {
            // Get current user ID
            guard let userId = AuthenticationService.shared.currentUser?.id else {
                throw IdolNewsError.userNotAuthenticated
            }
            
            // Call Supabase function to get personalized news
            let parameters: [String: Any] = [
                "user_id": userId.uuidString,
                "limit": pageSize,
                "offset": currentOffset,
                "priority_filter": self.priorityFilter.rawValue
            ]
            
            let response: IdolNewsResponse = try await supabaseService.callFunction(
                functionName: "get-user-idol-news",
                parameters: parameters
            )
            
            if refresh {
                newsItems = response.items
            } else {
                newsItems.append(contentsOf: response.items)
            }
            
            currentOffset += response.items.count
            hasMore = response.items.count == pageSize
            
        } catch {
            self.error = error
            print("❌ Error fetching idol news: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Fetch News for Specific Artist
    func fetchArtistNews(artistName: String, artistId: UUID? = nil) async {
        isLoading = true
        error = nil
        
        do {
            let parameters: [String: Any] = [
                "artistName": artistName,
                "artistId": artistId?.uuidString as Any,
                "sources": ["spotify", "rss", "ticketmaster"],
                "userId": AuthenticationService.shared.currentUser?.id.uuidString as Any,
                "priorityFilter": self.priorityFilter.rawValue,
                "useCache": cacheEnabled
            ]
            
            let _: IdolNewsFetchResponse = try await supabaseService.callFunction(
                functionName: "fetch-idol-news",
                parameters: parameters
            )
            
            // Refresh the news list
            await fetchPersonalizedNews(refresh: true)
            
        } catch {
            self.error = error
            print("❌ Error fetching artist news: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Track Interactions
    func trackView(newsId: UUID) async {
        guard let userId = AuthenticationService.shared.currentUser?.id else { return }
        
        let parameters: [String: Any] = [
            "user_id": userId.uuidString,
            "news_id": newsId.uuidString
        ]
        
        do {
            let _: EmptyResponse = try await supabaseService.callFunction(
                functionName: "track-news-view",
                parameters: parameters
            )
        } catch {
            print("Error tracking view: \(error)")
        }
    }
    
    func toggleLike(newsId: UUID) async {
        guard let userId = AuthenticationService.shared.currentUser?.id else { return }
        
        // Find the news item and toggle its like status
        if let index = newsItems.firstIndex(where: { $0.id == newsId }) {
            newsItems[index].hasLiked.toggle()
            
            let parameters: [String: Any] = [
                "user_id": userId.uuidString,
                "news_id": newsId.uuidString,
                "interaction_type": newsItems[index].hasLiked ? "like" : "unlike"
            ]
            
            do {
                let _: EmptyResponse = try await supabaseService.callFunction(
                    functionName: "toggle-news-interaction",
                    parameters: parameters
                )
            } catch {
                // Revert on error
                newsItems[index].hasLiked.toggle()
                print("Error toggling like: \(error)")
            }
        }
    }
    
    func saveForLater(newsId: UUID) async {
        guard let userId = AuthenticationService.shared.currentUser?.id else { return }
        
        let parameters: [String: Any] = [
            "user_id": userId.uuidString,
            "news_id": newsId.uuidString,
            "interaction_type": "save"
        ]
        
        do {
            let _: EmptyResponse = try await supabaseService.callFunction(
                functionName: "save-news-item",
                parameters: parameters
            )
        } catch {
            print("Error saving news: \(error)")
        }
    }
    
    // MARK: - Priority and Cache Management
    func setPriorityFilter(_ filter: PriorityFilter) async {
        priorityFilter = filter
        await fetchPersonalizedNews(refresh: true)
    }
    
    func toggleCache() {
        cacheEnabled.toggle()
    }
    
    func clearCache() async {
        do {
            let _: EmptyResponse = try await supabaseService.callFunction(
                functionName: "clear-news-cache",
                parameters: [:]
            )
        } catch {
            print("Error clearing cache: \(error)")
        }
    }
    
    // MARK: - News Preferences
    func updateNewsPreferences(_ preferences: NewsPreferences) async {
        guard let userId = AuthenticationService.shared.currentUser?.id else { return }
        
        let parameters: [String: Any] = [
            "user_id": userId.uuidString,
            "min_priority": preferences.minPriority.rawValue,
            "source_preferences": preferences.sourcePreferences,
            "keyword_filters": preferences.keywordFilters,
            "notification_threshold": preferences.notificationThreshold.rawValue
        ]
        
        do {
            let _: EmptyResponse = try await supabaseService.callFunction(
                functionName: "update-news-preferences",
                parameters: parameters
            )
        } catch {
            print("Error updating preferences: \(error)")
        }
    }
}

// MARK: - Models
struct IdolNewsItem: Identifiable, Codable {
    let id: UUID
    let artistId: UUID?
    let artistName: String
    let title: String
    let description: String?
    let source: NewsSource
    let sourceUrl: String?
    let imageUrl: String?
    let newsType: NewsType
    let priority: NewsPriority
    let priorityScore: Int?
    let eventDate: Date?
    let createdAt: Date
    let metadata: [String: AnyCodable]?
    var isFollowing: Bool
    var hasViewed: Bool
    var hasLiked: Bool
    
    // Computed properties
    var formattedDate: String {
        if let eventDate = eventDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: eventDate)
        }
        return ""
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    var priorityColor: Color {
        switch priority {
        case .urgent: return .red
        case .high: return .orange
        case .normal: return .blue
        case .low: return .gray
        }
    }
    
    var typeIcon: String {
        switch newsType {
        case .release: return "music.note"
        case .concert: return "ticket.fill"
        case .news: return "newspaper.fill"
        case .social: return "bubble.left.fill"
        case .merch: return "bag.fill"
        }
    }
}

enum NewsSource: String, Codable {
    case spotify = "spotify"
    case rss = "rss"
    case ticketmaster = "ticketmaster"
    case twitter = "twitter"
    case instagram = "instagram"
    case youtube = "youtube"
    
    var displayName: String {
        switch self {
        case .spotify: return "Spotify"
        case .rss: return "News"
        case .ticketmaster: return "Ticketmaster"
        case .twitter: return "Twitter"
        case .instagram: return "Instagram"
        case .youtube: return "YouTube"
        }
    }
    
    var icon: String {
        switch self {
        case .spotify: return "music.note.list"
        case .rss: return "dot.radiowaves.left.and.right"
        case .ticketmaster: return "ticket"
        case .twitter: return "bubble.left"
        case .instagram: return "camera"
        case .youtube: return "play.rectangle"
        }
    }
}

enum NewsType: String, Codable {
    case release = "release"
    case concert = "concert"
    case news = "news"
    case social = "social"
    case merch = "merch"
    
    var displayName: String {
        switch self {
        case .release: return "New Release"
        case .concert: return "Concert"
        case .news: return "News"
        case .social: return "Social"
        case .merch: return "Merchandise"
        }
    }
}

enum NewsPriority: String, Codable, CaseIterable {
    case urgent = "urgent"
    case high = "high"
    case normal = "normal"
    case low = "low"
    
    var displayName: String {
        switch self {
        case .urgent: return "Urgent"
        case .high: return "High"
        case .normal: return "Normal"
        case .low: return "Low"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .urgent: return 0
        case .high: return 1
        case .normal: return 2
        case .low: return 3
        }
    }
}

enum PriorityFilter: String, Codable, CaseIterable {
    case all = "all"
    case high = "high"
    case mediumHigh = "medium_high"
    
    var displayName: String {
        switch self {
        case .all: return "All News"
        case .high: return "High Priority Only"
        case .mediumHigh: return "Medium & High Priority"
        }
    }
}

// MARK: - Response Models
struct IdolNewsResponse: Codable {
    let items: [IdolNewsItem]
    let hasMore: Bool
}

struct IdolNewsFetchResponse: Codable {
    let success: Bool
    let count: Int
    let items: [IdolNewsItem]
}

struct NewsPreferences: Codable {
    var minPriority: NewsPriority
    var sourcePreferences: [String: Bool]
    var keywordFilters: [String]
    var notificationThreshold: NewsPriority
    
    init() {
        self.minPriority = .normal
        self.sourcePreferences = [
            "spotify": true,
            "rss": true,
            "ticketmaster": true
        ]
        self.keywordFilters = []
        self.notificationThreshold = .high
    }
}

struct EmptyResponse: Codable {}

// MARK: - Errors
enum IdolNewsError: LocalizedError {
    case userNotAuthenticated
    case networkError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "Please sign in to view personalized news"
        case .networkError:
            return "Unable to fetch news. Please check your connection."
        case .decodingError:
            return "Error processing news data"
        }
    }
}

// Helper for encoding/decoding flexible JSON
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictionaryValue = try? container.decode([String: AnyCodable].self) {
            value = dictionaryValue.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if value is NSNull {
            try container.encodeNil()
        }
    }
}