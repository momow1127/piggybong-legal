import Foundation
import SwiftUI

// MARK: - Error Types and Data Source Results

/// Comprehensive error handling for EventService operations
enum EventServiceError: LocalizedError {
    case bothSourcesFailed(rssError: Error?, concertError: Error?)
    case networkUnavailable
    case authenticationRequired

    var errorDescription: String? {
        switch self {
        case .bothSourcesFailed(let rssError, let concertError):
            var details: [String] = []
            if let rss = rssError {
                details.append("News: \(rss.localizedDescription)")
            }
            if let concert = concertError {
                details.append("Concerts: \(concert.localizedDescription)")
            }
            return "Unable to load events from any source. Please check your connection and try again."
        case .networkUnavailable:
            return "No internet connection available. Please check your network and try again."
        case .authenticationRequired:
            return "Please sign in to view personalized events and updates."
        }
    }

    var failureReason: String? {
        switch self {
        case .bothSourcesFailed:
            return "Both news and concert data sources failed to respond"
        case .networkUnavailable:
            return "Network connectivity issues"
        case .authenticationRequired:
            return "User authentication needed for personalized content"
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .networkUnavailable, .authenticationRequired:
            return true
        case .bothSourcesFailed:
            return false
        }
    }
}

/// Wrapper for data source results with proper success/failure handling
enum DataSourceResult<T> {
    case success(T)
    case empty
    case failed(Error)

    /// Indicates if this result contains usable content
    var hasContent: Bool {
        switch self {
        case .success(let data):
            // Handle arrays specifically
            if let array = data as? [Any] {
                return !array.isEmpty
            }
            return true
        case .empty, .failed:
            return false
        }
    }

    /// Extract data if available
    var data: T? {
        if case .success(let data) = self {
            return data
        }
        return nil
    }

    /// Extract error if failed
    var error: Error? {
        if case .failed(let error) = self {
            return error
        }
        return nil
    }
}

// MARK: - Event Service
@MainActor
class EventService: ObservableObject {
    static let shared = EventService()
    
    @Published var events: [KPopEvent] = []
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var lastRefreshDate: Date?
    @Published var hasPartialData = false
    @Published var warningMessage: String?
    
    private let refreshInterval: TimeInterval = 3 * 3600 // 3 hours
    private let maxCacheSize = 100
    private let authService = AuthenticationService.shared
    private let supabaseService = SupabaseService.shared
    
    private init() {
        // Load cached events on startup
        if let cached = loadCachedEvents() {
            events = cached
            print("💾 Loaded \(cached.count) cached events on startup")
        }

        Task {
            await loadEventsIfNeeded()
        }
    }
    
    // MARK: - Public Methods
    
    func loadEvents() async {
        await performLoad(forceRefresh: false)
    }
    
    func refreshEvents() async {
        await performLoad(forceRefresh: true)
    }
    
    // MARK: - Private Methods
    
    private func loadEventsIfNeeded() async {
        guard shouldRefresh else { return }
        await loadEvents()
    }
    
    private var shouldRefresh: Bool {
        guard let lastRefresh = lastRefreshDate else { return true }
        return Date().timeIntervalSince(lastRefresh) > refreshInterval
    }
    
    private func performLoad(forceRefresh: Bool) async {
        guard !isLoading else { return }

        if !forceRefresh && !shouldRefresh {
            return
        }

        await fetchAllEventsAndNews()
    }
    
    // MARK: - Main Fetch Function with Partial Success Support

    /// Fetches events from multiple sources with proper partial success handling
    func fetchAllEventsAndNews() async {
        isLoading = true

        // Clear all previous state to ensure clean retry behavior
        warningMessage = nil
        hasPartialData = false
        // Note: lastError is preserved until we determine the outcome

        // Get user's selected artists for filtering
        let userArtists = await getUserSelectedArtists()

        // STEP 1: Try database cache first for quick startup
        if !events.isEmpty {
            // We have some cached data, try background refresh
            print("📱 Using existing cached events, refreshing in background")
        }

        // STEP 2: Fetch both sources concurrently for optimal performance
        async let concertResult = fetchConcertEventsSafely(userArtists: userArtists)
        async let rssResult = fetchRSSNewsSafely()

        // Wait for both results
        let (concerts, news) = await (concertResult, rssResult)

        // STEP 3: Process results and determine success state
        await processDataSourceResults(concerts: concerts, news: news, userArtists: userArtists)

        isLoading = false
    }

    /// Processes the results from both data sources and updates UI state appropriately
    private func processDataSourceResults(
        concerts: DataSourceResult<[KPopEvent]>,
        news: DataSourceResult<[KPopEvent]>,
        userArtists: [String]
    ) async {
        var allEvents: [KPopEvent] = []
        var hasAnySuccess = false
        var errors: (concert: Error?, rss: Error?) = (nil, nil)
        var warnings: [String] = []

        // Process concert events
        switch concerts {
        case .success(let events):
            allEvents.append(contentsOf: events)
            hasAnySuccess = true
            print("✅ Loaded \(events.count) concert events")
        case .empty:
            hasAnySuccess = true // Empty is still a successful response
            print("📭 No concert events available")
            if !userArtists.isEmpty {
                warnings.append("No concerts found for your selected artists")
            }
        case .failed(let error):
            errors.concert = error
            print("⚠️ Concert fetch failed: \(error.localizedDescription)")
        }

        // Process RSS news
        switch news {
        case .success(let items):
            allEvents.append(contentsOf: items)
            hasAnySuccess = true
            print("✅ Loaded \(items.count) news items")
        case .empty:
            hasAnySuccess = true // Empty is still a successful response
            print("📭 No news items available")
            warnings.append("No recent news updates")
        case .failed(let error):
            errors.rss = error
            print("⚠️ RSS fetch failed: \(error.localizedDescription)")
        }

        // STEP 4: Update state based on results
        if hasAnySuccess {
            // Clear error since we got some data
            lastError = nil

            // Sort and limit events
            allEvents.sort {
                let date1 = $0.eventDate ?? $0.publishedDate
                let date2 = $1.eventDate ?? $1.publishedDate
                return date1 > date2
            }
            events = Array(allEvents.prefix(maxCacheSize))

            // Set partial data warning if one source failed
            if concerts.hasContent && !news.hasContent {
                hasPartialData = true
                warningMessage = "Concert events loaded • News updates temporarily unavailable"
            } else if news.hasContent && !concerts.hasContent {
                hasPartialData = true
                warningMessage = "News updates loaded • Concert events temporarily unavailable"
            } else if !warnings.isEmpty {
                warningMessage = warnings.joined(separator: " • ")
            }

            lastRefreshDate = Date()
            cacheEvents()

            // Sync user artist subscriptions in background
            Task {
                do {
                    try await syncUserArtistSubscriptions(userArtists: userArtists)
                    print("🔄 Synced user artist subscriptions")
                } catch {
                    print("⚠️ Failed to sync artist subscriptions: \(error)")
                }
            }

            print("📊 Successfully loaded \(events.count) total events")

        } else {
            // Both sources failed - this is a real error
            let serviceError = EventServiceError.bothSourcesFailed(
                rssError: errors.rss,
                concertError: errors.concert
            )
            lastError = serviceError.localizedDescription
            hasPartialData = false
            warningMessage = nil

            print("❌ Both sources failed - showing error to user")

            // Try to use cached events as fallback
            if let cached = loadCachedEvents(), !cached.isEmpty {
                events = cached
                warningMessage = "Showing cached events from your last update"
                print("💾 Using \(cached.count) cached events as fallback")
            }
        }
    }

    // MARK: - Safe Fetch Wrappers

    /// Safely fetches concert events without throwing exceptions
    private func fetchConcertEventsSafely(userArtists: [String]) async -> DataSourceResult<[KPopEvent]> {
        do {
            // Skip if no artists selected
            guard !userArtists.isEmpty else {
                print("ℹ️ No artists selected - skipping concert search")
                return .empty
            }

            let events = try await fetchEventsFromTicketmaster(artists: userArtists)
            return events.isEmpty ? .empty : .success(events)
        } catch {
            // Handle specific error types
            if let supabaseError = error as? SupabaseService.SupabaseError {
                switch supabaseError {
                case .unauthorized:
                    print("🔐 Ticketmaster auth issue - check API key in Supabase")
                    return .failed(EventServiceError.authenticationRequired)
                default:
                    // Handle empty data as success rather than error
                    if supabaseError.localizedDescription.contains("no data") {
                        return .empty
                    }
                    return .failed(error)
                }
            }
            return .failed(error)
        }
    }

    /// Safely fetches RSS news without throwing exceptions
    private func fetchRSSNewsSafely() async -> DataSourceResult<[KPopEvent]> {
        do {
            let items = try await fetchEventsFromSource(.soompi)
            return items.isEmpty ? .empty : .success(items)
        } catch {
            // Handle network and parsing errors
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    return .failed(EventServiceError.networkUnavailable)
                default:
                    return .failed(error)
                }
            }
            return .failed(error)
        }
    }

    // MARK: - Cache Management

    /// Loads cached events from local storage
    private func loadCachedEvents() -> [KPopEvent]? {
        guard let data = UserDefaults.standard.data(forKey: "CachedEvents"),
              let cached = try? JSONDecoder().decode([KPopEvent].self, from: data) else {
            return nil
        }

        // Filter out events older than 7 days
        let cutoffDate = Date().addingTimeInterval(-7 * 24 * 3600)
        let freshEvents = cached.filter { event in
            let eventDate = event.eventDate ?? event.publishedDate
            return eventDate > cutoffDate
        }

        return freshEvents.isEmpty ? nil : freshEvents
    }

    /// Saves current events to cache
    private func cacheEvents() {
        guard !events.isEmpty else { return }

        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: "CachedEvents")
            print("💾 Cached \(events.count) events")
        }
    }

    private func fetchEventsFromSource(_ source: EventSource) async throws -> [KPopEvent] {
        let url = source.rssURL
        
        print("📡 Fetching RSS from \(source.displayName): \(url)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw EventError.invalidResponse
        }
        
        let rssItems = try parseRSSData(data)
        let userArtists = await getUserSelectedArtists()
        
        return rssItems.compactMap { item in
            parseRSSItemToEvent(item, source: source, userArtists: userArtists)
        }
    }
    
    private func parseRSSData(_ data: Data) throws -> [RSSItem] {
        let parser = XMLParser(data: data)
        let rssParser = RSSParser()
        parser.delegate = rssParser
        
        guard parser.parse() else {
            throw EventError.parsingFailed
        }
        
        return rssParser.items
    }
    
    private func parseRSSItemToEvent(_ item: RSSItem, source: EventSource, userArtists: [String]) -> KPopEvent? {
        let titleRaw = item.title
        let title = titleRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty,
              !title.isEmpty else {
            return nil
        }
        
        let content = item.description ?? ""
        let publishedDate = parseDate(item.pubDate) ?? Date()
        
        // Categorize and analyze
        let category = EventKeywords.categorize(title: title, content: content)
        let isBreaking = EventKeywords.isBreaking(title: title, content: content, publishedDate: publishedDate)
        let matchedArtists = ArtistMatcher.findMatchingArtists(in: title + " " + content, userArtists: userArtists)
        
        // Parse URL
        var eventURL: URL?
        if let linkString = item.link, let url = URL(string: linkString) {
            eventURL = url
        }
        
        // Get image URL
        let imageURL = item.enclosure?.url != nil ? URL(string: item.enclosure!.url!) : nil
        
        return KPopEvent(
            title: title,
            summary: content.isEmpty ? nil : String(content.prefix(200)),
            url: eventURL,
            imageURL: imageURL,
            publishedDate: publishedDate,
            category: category,
            isBreaking: isBreaking,
            matchedArtists: matchedArtists,
            source: source
        )
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let formatters = [
            RFC822DateFormatter(),
            ISO8601DateFormatter(),
            standardDateFormatter()
        ]
        
        for formatter in formatters {
            if let formatter = formatter as? DateFormatter,
               let date = formatter.date(from: dateString) {
                return date
            } else if let formatter = formatter as? ISO8601DateFormatter,
                      let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    // MARK: - User Artists Integration
    
    private func getUserSelectedArtists() async -> [String] {
        // Primary: Try to get user artists from database (fan_idols)
        do {
            if let userId = authService.currentUser?.id {
                let fanIdols = try await supabaseService.getFanIdols(userId: userId)
                let artistNames = fanIdols.compactMap { $0.artist.name }
                if !artistNames.isEmpty {
                    print("💾 Loaded \(artistNames.count) user artists from database: \(artistNames.joined(separator: ", "))")
                    // Cache for offline use
                    cacheSelectedArtists(artistNames)
                    return artistNames
                }
            }
        } catch {
            print("⚠️ Database artist fetch failed: \(error.localizedDescription)")
            if let supabaseError = error as? SupabaseService.SupabaseError {
                switch supabaseError {
                case .unauthorized:
                    print("🔐 AUTH ISSUE: User not authenticated for getFanIdols")
                case .notFound:
                    print("🔍 NOT FOUND: No user artists found in fan_idols table")
                default:
                    print("📊 DATABASE ERROR: \(supabaseError.localizedDescription)")
                }
            }
        }
        
        // Secondary: Use cached onboarding data (offline fallback)
        let cachedArtists = getCachedSelectedArtists()
        if !cachedArtists.isEmpty {
            print("📱 Using \(cachedArtists.count) cached user-selected artists from onboarding: \(cachedArtists.joined(separator: ", "))")
            return cachedArtists
        }
        
        // Fallback: Use popular K-pop artists if no user selection
        let fallbackArtists = ["BTS", "BLACKPINK", "NewJeans", "TWICE", "SEVENTEEN", "Stray Kids"]
        print("⚠️ No user artists found - using fallback artists for API calls: \(fallbackArtists.joined(separator: ", "))")
        return fallbackArtists
    }
    
    private func getCachedSelectedArtists() -> [String] {
        if let data = UserDefaults.standard.data(forKey: "CachedSelectedArtists"),
           let artists = try? JSONDecoder().decode([String].self, from: data) {
            return artists
        }
        return []
    }
    
    private func cacheSelectedArtists(_ artists: [String]) {
        if let encoded = try? JSONEncoder().encode(artists) {
            UserDefaults.standard.set(encoded, forKey: "CachedSelectedArtists")
        }
    }
    
    private func RFC822DateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
    
    private func standardDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
    
    
    // MARK: - No Sample Events - Real Data Only
    // Removed sample events fallback - app now shows empty state when no real events are available

    /// Clear all cached events to force fresh API data
    func clearAllCaches() {
        UserDefaults.standard.removeObject(forKey: "CachedKPopEvents")
        UserDefaults.standard.removeObject(forKey: "LastEventRefreshDate")
        UserDefaults.standard.removeObject(forKey: "CachedSelectedArtists")
        events = []
        lastRefreshDate = nil
        print("🧹 Cleared all event caches - will fetch fresh data")
    }
    
    // MARK: - API Integration Methods
    
    /// Fetch events from Ticketmaster API via Supabase function
    private func fetchEventsFromTicketmaster(artists: [String]) async throws -> [KPopEvent] {
        let parameters: [String: Any] = [
            "genres": ["music"],
            "artists": artists,
            "limit": 50,
            "location": "US"
        ]
        
        let response: TicketmasterResponse = try await supabaseService.callFunction(
            functionName: "get-upcoming-events",
            parameters: parameters
        )
        
        return response.events.map { ticketmasterEvent in
            KPopEvent(
                title: ticketmasterEvent.name,
                summary: "\(ticketmasterEvent.artist) at \(ticketmasterEvent.venue), \(ticketmasterEvent.city)",
                url: URL(string: ticketmasterEvent.url),
                imageURL: ticketmasterEvent.image_url != nil ? URL(string: ticketmasterEvent.image_url!) : nil,
                publishedDate: Date(), // Current date as published
                category: .concerts, // Use modern category
                isBreaking: false,
                matchedArtists: artists.filter { artist in
                    ticketmasterEvent.artist.localizedCaseInsensitiveContains(artist) ||
                    ticketmasterEvent.name.localizedCaseInsensitiveContains(artist)
                },
                source: .ticketmaster,
                eventDate: parseTicketmasterDate(ticketmasterEvent.date, time: ticketmasterEvent.time),
                venue: ticketmasterEvent.venue,
                city: ticketmasterEvent.city,
                minPrice: ticketmasterEvent.min_price,
                maxPrice: ticketmasterEvent.max_price,
                currency: ticketmasterEvent.currency
            )
        }
    }
    
    /// Removed Spotify integration for now - focus on Ticketmaster and RSS
    /// This can be added back later when Spotify API integration is needed
    // private func fetchEventsFromSpotify(artists: [String]) async throws -> [KPopEvent] { ... }
    
    /// Filter RSS events by user's selected artists
    private func filterRSSEventsByArtists(_ events: [KPopEvent], userArtists: [String]) -> [KPopEvent] {
        guard !userArtists.isEmpty else { return events }
        
        return events.filter { event in
            // Check if any user artist is mentioned in title or summary
            for artist in userArtists {
                if event.title.localizedCaseInsensitiveContains(artist) ||
                   (event.summary?.localizedCaseInsensitiveContains(artist) ?? false) {
                    return true
                }
            }
            return false
        }
    }
    
    /// Parse Ticketmaster date and time strings
    private func parseTicketmasterDate(_ dateString: String?, time: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let time = time {
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let combinedString = "\(dateString) \(time)"
            return dateFormatter.date(from: combinedString)
        } else {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.date(from: dateString)
        }
    }
    
    // MARK: - Database Integration Methods
    
    /// Fetch personalized events using get-artists-events function (works with current backend)
    private func fetchCachedEventsFromDatabase(userArtists: [String]) async throws -> [KPopEvent] {
        guard !userArtists.isEmpty else {
            print("⚠️ No user artists for personalized events")
            return []
        }

        // Use the working get-artists-events function for Spotify releases
        struct ArtistEventsResponse: Codable {
            let items: [SpotifyEventItem]
            let total_count: Int
        }

        struct SpotifyEventItem: Codable {
            let title: String
            let content: String
            let source_url: String?
            let image_url: String?
            let published_at: String
            let category: String
            let artist_name: String
            let metadata: SpotifyMetadata?
        }

        struct SpotifyMetadata: Codable {
            let spotify_id: String
            let total_tracks: Int
        }

        let parameters: [String: Any] = [
            "artists": userArtists,
            "sources": ["spotify"],
            "limit": 20
        ]

        do {
            let response: ArtistEventsResponse = try await supabaseService.callFunction(
                functionName: "get-artists-events",
                parameters: parameters
            )

            print("📊 Fetched \(response.items.count) personalized Spotify events for artists: \(userArtists.joined(separator: ", "))")

            return response.items.compactMap { item in
                let publishedDate = parseSpotifyDate(item.published_at) ?? Date()

                return KPopEvent(
                    title: item.title,
                    summary: item.content,
                    url: item.source_url != nil ? URL(string: item.source_url!) : nil,
                    imageURL: item.image_url != nil ? URL(string: item.image_url!) : nil,
                    publishedDate: publishedDate,
                    category: EventCategory(rawValue: item.category) ?? .albums,
                    isBreaking: false,
                    matchedArtists: [item.artist_name],
                    source: .spotify
                )
            }
        } catch {
            print("⚠️ Failed to fetch personalized Spotify events: \(error)")
            return []
        }
    }

    /// Parse Spotify date format (YYYY-MM-DD)
    private func parseSpotifyDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: dateString)
    }
    
    /// Sync user's artist subscriptions in database for event filtering
    private func syncUserArtistSubscriptions(userArtists: [String]) async throws {
        guard let userId = authService.currentUser?.id else {
            print("⚠️ No authenticated user for artist sync")
            return
        }
        
        let parameters: [String: Any] = [
            "action": "sync",
            "user_id": userId.uuidString,
            "artist_names": userArtists
        ]
        
        struct SubscriptionResponse: Codable {
            let success: Bool
            let message: String?
        }
        
        do {
            let response: SubscriptionResponse = try await supabaseService.callFunction(
                functionName: "manage-event-subscriptions",
                parameters: parameters
            )
            
            if !response.success {
                print("⚠️ Artist subscription sync failed: \(response.message ?? "Unknown error")")
            }
        } catch {
            print("⚠️ Failed to sync artist subscriptions: \(error)")
            throw error
        }
    }
    
    /// Refresh events in background without blocking UI
    private func refreshEventsInBackground(userArtists: [String]) async {
        do {
            // Fetch fresh data from Ticketmaster (cached in database by the edge function)
            let _ = try await fetchEventsFromTicketmaster(artists: userArtists)
            print("🔄 Background refresh completed")
        } catch {
            print("⚠️ Background refresh failed: \(error)")
        }
    }
}

// MARK: - RSS Parser
class RSSParser: NSObject, XMLParserDelegate {
    var items: [RSSItem] = []
    private var currentItem: [String: String] = [:]
    private var currentElement: String = ""
    private var isInItem = false
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "item" {
            isInItem = true
            currentItem = [:]
        } else if elementName == "enclosure" && isInItem {
            currentItem["enclosureURL"] = attributeDict["url"]
            currentItem["enclosureType"] = attributeDict["type"]
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if isInItem {
            let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedString.isEmpty {
                if currentItem[currentElement] == nil {
                    currentItem[currentElement] = trimmedString
                } else {
                    currentItem[currentElement]! += trimmedString
                }
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            isInItem = false
            
            let enclosure = currentItem["enclosureURL"] != nil ? 
                RSSItem.RSSEnclosure(
                    url: currentItem["enclosureURL"],
                    type: currentItem["enclosureType"]
                ) : nil
            
            let item = RSSItem(
                title: currentItem["title"] ?? "",
                description: currentItem["description"],
                link: currentItem["link"],
                pubDate: currentItem["pubDate"],
                guid: currentItem["guid"],
                enclosure: enclosure
            )
            
            items.append(item)
        }
        currentElement = ""
    }
}

// MARK: - Event Error
enum EventError: LocalizedError {
    case invalidResponse
    case parsingFailed
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .parsingFailed:
            return "Failed to parse RSS feed"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
