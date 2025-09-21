import Foundation
import SwiftUI

// MARK: - Real-Time Event Service
/// Service to handle real-time event fetching, caching, and artist subscription management
@MainActor
class RealTimeEventService: ObservableObject {
    static let shared = RealTimeEventService()
    
    @Published var isRefreshing = false
    @Published var lastError: String?
    @Published var connectionStatus: ConnectionStatus = .unknown
    
    private let supabaseService = SupabaseService.shared
    private let authService = AuthenticationService.shared
    private let maxRetries = 3
    
    enum ConnectionStatus {
        case unknown
        case connected
        case offline
        case apiKeyMissing
        case rateLimited
        
        var displayMessage: String {
            switch self {
            case .unknown: return "Checking connection..."
            case .connected: return "Connected to real-time events"
            case .offline: return "Offline - using cached events"
            case .apiKeyMissing: return "External API not configured"
            case .rateLimited: return "Rate limited - using cached events"
            }
        }
    }
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Check if Ticketmaster API is properly configured
    func checkAPIConfiguration() async -> Bool {
        // In production, this would check if TICKETMASTER_API_KEY is set in Supabase
        // For now, we'll assume it's configured if we can reach Supabase
        do {
            let testConnection = try await supabaseService.checkSupabaseConnectivity()
            connectionStatus = testConnection ? .connected : .offline
            return testConnection
        } catch {
            connectionStatus = .offline
            return false
        }
    }
    
    /// Fetch fresh events with retry logic and fallback to cached data
    func fetchEventsWithFallback(artists: [String], retryCount: Int = 0) async -> [KPopEvent] {
        isRefreshing = true
        lastError = nil
        
        defer {
            isRefreshing = false
        }
        
        // First, try to get cached events as baseline
        let cachedEvents = await getCachedEvents(artists: artists)
        
        // Try to fetch fresh events
        do {
            let freshEvents = try await fetchFreshEvents(artists: artists)
            if !freshEvents.isEmpty {
                connectionStatus = .connected
                return freshEvents
            }
        } catch {
            print("⚠️ Fresh event fetch failed: \(error)")
            lastError = error.localizedDescription
            
            // Determine connection status based on error
            if error.localizedDescription.contains("rate limit") {
                connectionStatus = .rateLimited
            } else if error.localizedDescription.contains("API key") {
                connectionStatus = .apiKeyMissing
            } else {
                connectionStatus = .offline
            }
            
            // Retry logic for network errors
            if retryCount < maxRetries && isRetriableError(error) {
                print("🔄 Retrying event fetch (attempt \(retryCount + 1)/\(maxRetries))")
                try? await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000)) // Exponential backoff
                return await fetchEventsWithFallback(artists: artists, retryCount: retryCount + 1)
            }
        }
        
        // Fallback to cached events
        connectionStatus = cachedEvents.isEmpty ? .offline : .connected
        return cachedEvents
    }
    
    /// Sync user's artist subscriptions for personalized event filtering
    func syncArtistSubscriptions(artists: [String]) async -> Bool {
        guard let userId = authService.currentUser?.id else {
            lastError = "User not authenticated"
            return false
        }
        
        do {
            let parameters: [String: Any] = [
                "action": "sync",
                "user_id": userId.uuidString,
                "artist_names": artists
            ]
            
            struct SubscriptionResponse: Codable {
                let success: Bool
                let message: String?
                let synced_artists: [String]?
            }
            
            let response: SubscriptionResponse = try await supabaseService.callFunction(
                functionName: "manage-event-subscriptions",
                parameters: parameters
            )
            
            if response.success {
                print("✅ Synced \(response.synced_artists?.count ?? 0) artist subscriptions")
                return true
            } else {
                lastError = response.message ?? "Sync failed"
                return false
            }
        } catch {
            lastError = "Failed to sync subscriptions: \(error.localizedDescription)"
            print("⚠️ \(lastError!)")
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchFreshEvents(artists: [String]) async throws -> [KPopEvent] {
        // Try Ticketmaster API first for concert events
        let ticketmasterEvents = await fetchTicketmasterEvents(artists: artists)
        
        // Try RSS feeds for news and updates
        let rssEvents = await fetchRSSEvents(artists: artists)
        
        // Combine and deduplicate
        var allEvents = ticketmasterEvents
        allEvents.append(contentsOf: rssEvents)
        
        // Sort by relevance and date
        allEvents.sort { event1, event2 in
            // Breaking news first
            if event1.isBreaking != event2.isBreaking {
                return event1.isBreaking
            }
            
            // Events with dates next
            let date1 = event1.eventDate ?? event1.publishedDate
            let date2 = event2.eventDate ?? event2.publishedDate
            
            return date1 > date2
        }
        
        return Array(allEvents.prefix(50)) // Limit to 50 events
    }
    
    private func fetchTicketmasterEvents(artists: [String]) async -> [KPopEvent] {
        struct TicketmasterResponse: Codable {
            let events: [TicketmasterEvent]
            let total_count: Int
        }

        struct TicketmasterEvent: Codable {
            let name: String
            let artist: String
            let url: String
            let image_url: String?
            let date: String
            let time: String?
            let venue: String
            let city: String
            let min_price: Double?
            let max_price: Double?
            let currency: String?
        }

        do {
            let parameters: [String: Any] = [
                "artists": artists,
                "genres": ["music"],
                "limit": 30,
                "location": "US"
            ]
            
            let response: TicketmasterResponse = try await supabaseService.callFunction(
                functionName: "get-upcoming-events",
                parameters: parameters
            )
            
            return response.events.map { ticketmasterEvent in
                KPopEvent(
                    title: ticketmasterEvent.name,
                    summary: "\(ticketmasterEvent.artist) live at \(ticketmasterEvent.venue), \(ticketmasterEvent.city)",
                    url: URL(string: ticketmasterEvent.url),
                    imageURL: ticketmasterEvent.image_url != nil ? URL(string: ticketmasterEvent.image_url!) : nil,
                    publishedDate: Date(),
                    category: .concerts,
                    isBreaking: false,
                    matchedArtists: artists.filter { artist in
                        ticketmasterEvent.name.localizedCaseInsensitiveContains(artist) ||
                        ticketmasterEvent.artist.localizedCaseInsensitiveContains(artist)
                    },
                    source: .ticketmaster,
                    eventDate: parseDate(ticketmasterEvent.date, time: ticketmasterEvent.time),
                    venue: ticketmasterEvent.venue,
                    city: ticketmasterEvent.city,
                    minPrice: ticketmasterEvent.min_price,
                    maxPrice: ticketmasterEvent.max_price,
                    currency: ticketmasterEvent.currency
                )
            }
        } catch {
            print("⚠️ Ticketmaster fetch failed: \(error)")
            lastError = "Ticketmaster fetch failed: \(error.localizedDescription)"
            return []
        }
    }
    
    private func fetchRSSEvents(artists: [String]) async -> [KPopEvent] {
        // This would integrate with RSS parsing from EventService
        // For now, return empty array to focus on Ticketmaster integration
        return []
    }
    
    private func getCachedEvents(artists: [String]) async -> [KPopEvent] {
        guard let userId = authService.currentUser?.id else {
            return []
        }
        
        do {
            struct DatabaseEventResponse: Codable {
                let events: [DatabaseEvent]
                let totalCount: Int
            }
            
            struct DatabaseEvent: Codable {
                let id: String
                let title: String
                let summary: String?
                let url: String?
                let imageURL: String?
                let publishedDate: String
                let category: String
                let isBreaking: Bool
                let matchedArtists: [String]
                let source: String
                let eventDate: String?
                let venue: String?
                let city: String?
                let minPrice: Double?
                let maxPrice: Double?
                let currency: String?
            }
            
            let parameters: [String: Any] = [
                "user_id": userId.uuidString,
                "limit": 50
            ]
            
            let response: DatabaseEventResponse = try await supabaseService.callFunction(
                functionName: "get-user-events",
                parameters: parameters
            )
            
            return response.events.compactMap { dbEvent in
                let publishedDate = ISO8601DateFormatter().date(from: dbEvent.publishedDate) ?? Date()
                let eventDate = dbEvent.eventDate != nil ? ISO8601DateFormatter().date(from: dbEvent.eventDate!) : nil
                
                return KPopEvent(
                    id: UUID(uuidString: dbEvent.id) ?? UUID(),
                    title: dbEvent.title,
                    summary: dbEvent.summary,
                    url: dbEvent.url != nil ? URL(string: dbEvent.url!) : nil,
                    imageURL: dbEvent.imageURL != nil ? URL(string: dbEvent.imageURL!) : nil,
                    publishedDate: publishedDate,
                    category: EventCategory(rawValue: dbEvent.category) ?? .other,
                    isBreaking: dbEvent.isBreaking,
                    matchedArtists: dbEvent.matchedArtists,
                    source: EventSource(rawValue: dbEvent.source) ?? .soompi,
                    eventDate: eventDate,
                    venue: dbEvent.venue,
                    city: dbEvent.city,
                    minPrice: dbEvent.minPrice,
                    maxPrice: dbEvent.maxPrice,
                    currency: dbEvent.currency
                )
            }
        } catch {
            print("⚠️ Failed to get cached events: \(error)")
            return []
        }
    }
    
    private func parseDate(_ dateString: String?, time: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let time = time {
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter.date(from: "\(dateString) \(time)")
        } else {
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.date(from: dateString)
        }
    }
    
    private func isRetriableError(_ error: Error) -> Bool {
        let errorMessage = error.localizedDescription.lowercased()
        return errorMessage.contains("network") ||
               errorMessage.contains("timeout") ||
               errorMessage.contains("connection") ||
               errorMessage.contains("500") ||
               errorMessage.contains("502") ||
               errorMessage.contains("503")
    }
}