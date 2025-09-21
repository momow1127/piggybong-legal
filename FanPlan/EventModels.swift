import Foundation
import SwiftUI

// MARK: - Event Category
enum EventCategory: String, CaseIterable, Identifiable, Codable {
    case concertsShows = "Concerts & Shows"
    case albumsPhotocards = "Albums & Photocards"
    case officialMerch = "Official Merch"
    case fanEvents = "Fan Events (KCON, Hi-Touch)"
    case subscriptionsApps = "Subscriptions & Fan Apps"
    case other = "Other"
    
    // Legacy compatibility cases
    case all = "all"
    case comeback = "comeback"
    case concert = "concert"
    case merch = "merch"
    case social = "social"
    case release = "release"
    
    // Enhanced categorization cases
    case livestream = "livestream"
    case collaboration = "collaboration"
    case award = "award"
    case charity = "charity"
    case interview = "interview"
    
    // Additional legacy cases referenced in code
    case concerts = "concerts"
    case albums = "albums"
    case events = "events" 
    case subscriptions = "subscriptions"
    case concertPrep = "concertPrep"
    case album = "album"
    case albumHunting = "albumHunting"
    case merchandise = "merchandise"
    case fanmeetPrep = "fanmeetPrep"
    case fanmeet = "fanmeet"
    case digitalContent = "digitalContent"
    case experience = "experience"
    case photocardCollecting = "photocardCollecting"
    
    var id: String { rawValue }

    // MARK: - Main Categories for UI
    static let mainCategories: [EventCategory] = [
        .all,
        .concertsShows,
        .albumsPhotocards,
        .officialMerch,
        .fanEvents,
        .subscriptionsApps
    ]
    
    var displayName: String {
        switch self {
        case .concertsShows: return "Concerts & Shows"
        case .albumsPhotocards: return "Albums & Photocards"
        case .officialMerch: return "Official Merch"
        case .fanEvents: return "Fan Events (KCON, Hi-Touch)"
        case .subscriptionsApps: return "Subscriptions & Fan Apps"
        case .other: return "Other"
        // Primary category cases  
        case .concerts: return "Concerts & Shows"
        case .albums: return "Albums & Photocards"
        case .merch: return "Official Merch"
        case .events: return "Fan Events (KCON, Hi-Touch)"
        case .subscriptions: return "Subscriptions & Fan Apps"
        // Legacy cases
        case .all: return "All"
        case .comeback: return "Comeback"
        case .concert: return "Concert"
        case .social: return "Social"
        case .release: return "Release"
        case .concertPrep: return "Concert Prep"
        case .album: return "Album"
        case .albumHunting: return "Album Hunting"
        case .merchandise: return "Merchandise"
        case .fanmeetPrep: return "Fanmeet Prep"
        case .fanmeet: return "Fanmeet"
        case .digitalContent: return "Digital Content"
        case .experience: return "Experience"
        case .photocardCollecting: return "Photocard Collecting"
        // Enhanced categories  
        case .livestream: return "Live Stream"
        case .collaboration: return "Collaboration"
        case .award: return "Award Show"
        case .charity: return "Charity Event"
        case .interview: return "Interview"
        }
    }
    
    var icon: String {
        switch self {
        case .concertsShows: return "🎤"
        case .albumsPhotocards: return "💿"
        case .officialMerch: return "🛍️"
        case .fanEvents: return "🎊"
        case .subscriptionsApps: return "📱"
        case .other: return "📦"
        // Primary category cases
        case .concerts: return "🎤"
        case .albums: return "💿"
        case .merch: return "🛍️"
        case .events: return "🎊"
        case .subscriptions: return "📱"
        // Legacy cases
        case .all: return "📺"
        case .comeback: return "🎵"
        case .concert: return "🎤"
        case .social: return "📱"
        case .release: return "💿"
        case .concertPrep: return "🎤"
        case .album: return "💿"
        case .albumHunting: return "💿"
        case .merchandise: return "🛍️"
        case .fanmeetPrep: return "🎊"
        case .fanmeet: return "🎊"
        case .digitalContent: return "📱"
        case .experience: return "📱"
        case .photocardCollecting: return "📸"
        // Enhanced categories
        case .livestream: return "📺"
        case .collaboration: return "🤝"
        case .award: return "🏆"
        case .charity: return "💝"
        case .interview: return "🎙️"
        }
    }
    
    var color: Color {
        switch self {
        case .concertsShows: return .purple
        case .albumsPhotocards: return .pink
        case .officialMerch: return .blue
        case .fanEvents: return .green
        case .subscriptionsApps: return .orange
        case .other: return .gray
        // Primary category cases
        case .concerts: return .purple
        case .albums: return .pink
        case .merch: return .blue
        case .events: return .green
        case .subscriptions: return .orange
        // Legacy cases
        case .all: return .piggyTextSecondary
        case .comeback: return .pink
        case .concert: return .purple
        case .social: return .green
        case .release: return .orange
        case .concertPrep: return .purple
        case .album: return .pink
        case .albumHunting: return .pink
        case .merchandise: return .blue
        case .fanmeetPrep: return .green
        case .fanmeet: return .green
        case .digitalContent: return .orange
        case .experience: return .orange
        case .photocardCollecting: return .pink
        // Enhanced categories
        case .livestream: return .blue
        case .collaboration: return .green
        case .award: return .yellow
        case .charity: return .red
        case .interview: return .purple
        }
    }
    
    // Map legacy categories to new categories
    var modernCategory: EventCategory {
        switch self {
        case .concert: return .concerts
        case .comeback, .release: return .albums
        case .merch: return .merch
        case .social: return .events
        case .all: return .other
        default: return self
        }
    }
    
}

// MARK: - K-Pop Event
struct KPopEvent: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let summary: String?
    let url: URL?
    let imageURL: URL?
    let publishedDate: Date
    let category: EventCategory
    let isBreaking: Bool
    let matchedArtists: [String]
    let source: EventSource
    
    // New fields for Ticketmaster events
    let eventDate: Date?
    let venue: String?
    let city: String?
    let minPrice: Double?
    let maxPrice: Double?
    let currency: String?
    
    // New field for Spotify events
    let spotifyID: String?
    
    init(
        id: UUID = UUID(),
        title: String,
        summary: String? = nil,
        url: URL? = nil,
        imageURL: URL? = nil,
        publishedDate: Date,
        category: EventCategory,
        isBreaking: Bool = false,
        matchedArtists: [String] = [],
        source: EventSource,
        eventDate: Date? = nil,
        venue: String? = nil,
        city: String? = nil,
        minPrice: Double? = nil,
        maxPrice: Double? = nil,
        currency: String? = nil,
        spotifyID: String? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.url = url
        self.imageURL = imageURL
        self.publishedDate = publishedDate
        self.category = category
        self.isBreaking = isBreaking
        self.matchedArtists = matchedArtists
        self.source = source
        self.eventDate = eventDate
        self.venue = venue
        self.city = city
        self.minPrice = minPrice
        self.maxPrice = maxPrice
        self.currency = currency
        self.spotifyID = spotifyID
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: publishedDate, relativeTo: Date())
    }
    
    var calculatorPrefill: PurchaseCalculatorPrefill {
        let suggestedPrice: Double
        let category: String
        
        // Use modern category for consistent mapping
        let modernCat = self.category.modernCategory
        
        switch modernCat {
        case .concerts:
            suggestedPrice = 150
            category = "Concerts & Shows"
        case .albums:
            suggestedPrice = 30
            category = "Albums & Photocards"
        case .merch:
            suggestedPrice = 60
            category = "Official Merch"
        case .events:
            suggestedPrice = 80
            category = "Fan Events (KCON, Hi-Touch)"
        case .subscriptions:
            suggestedPrice = 20
            category = "Subscriptions & Fan Apps"
        default:
            suggestedPrice = 40
            category = "Other"
        }
        
        let itemName = matchedArtists.isEmpty ? 
            "\(modernCat.displayName) Item" : 
            "\(matchedArtists.first ?? "Unknown") \(modernCat.displayName)"
        
        return PurchaseCalculatorPrefill(
            itemName: itemName,
            price: suggestedPrice,
            artistName: matchedArtists.first,
            category: category
        )
    }
}

// MARK: - Event Source
enum EventSource: String, Codable, CaseIterable {
    case soompi = "soompi"
    case ticketmaster = "ticketmaster"
    case spotify = "spotify"
    
    var displayName: String {
        switch self {
        case .soompi: return "Soompi"
        case .ticketmaster: return "Ticketmaster"
        case .spotify: return "Spotify"
        }
    }
    
    var rssURL: URL {
        switch self {
        case .soompi: 
            return URL(string: "https://www.soompi.com/feed")!
        case .ticketmaster:
            return URL(string: "https://app.ticketmaster.com/discovery/v2/events.json")!
        case .spotify:
            return URL(string: "https://api.spotify.com/v1/")!
        }
    }
    
    var baseURL: String {
        switch self {
        case .soompi: return "https://www.soompi.com"
        case .ticketmaster: return "https://app.ticketmaster.com"
        case .spotify: return "https://api.spotify.com"
        }
    }
}

// MARK: - RSS Item
struct RSSItem: Codable {
    let title: String
    let description: String?
    let link: String?
    let pubDate: String?
    let guid: String?
    let enclosure: RSSEnclosure?
    
    struct RSSEnclosure: Codable {
        let url: String?
        let type: String?
    }
}

// MARK: - RSS Feed
struct RSSFeed: Codable {
    let title: String?
    let description: String?
    let items: [RSSItem]
}

// MARK: - Purchase Calculator Prefill
struct PurchaseCalculatorPrefill {
    let itemName: String
    let price: Double
    let artistName: String?
    let category: String
}

// MARK: - Enhanced Event Categorization System
struct EventKeywords {
    // Enhanced keyword sets with weighted scoring
    private static let categoryKeywordWeights: [EventCategory: [(keyword: String, weight: Double)]] = [
        .albums: [
            ("comeback", 3.0), ("album", 3.0), ("single", 2.5), ("mini album", 3.5),
            ("ep", 2.5), ("mv", 2.0), ("music video", 2.5), ("pre-order", 2.5),
            ("preorder", 2.5), ("teaser", 2.0), ("concept photo", 2.0), ("track list", 2.0),
            ("tracklist", 2.0), ("release", 2.0), ("photocard", 3.0), ("photocards", 3.0),
            ("pc", 2.5), ("trading cards", 2.5), ("album cover", 2.0), ("cd", 2.5),
            ("vinyl", 2.5), ("limited edition album", 3.5), ("special edition", 3.0),
            ("collector edition", 3.0), ("full album", 3.0), ("repackage", 2.5)
        ],
        .concerts: [
            ("tour", 3.5), ("concert", 3.5), ("world tour", 4.0), ("showcase", 2.5),
            ("presale", 3.0), ("tickets", 2.5), ("venue", 2.0), ("live", 2.0),
            ("performance", 2.0), ("show", 2.0), ("festival", 2.5), ("stage", 1.5),
            ("concert hall", 2.5), ("arena", 2.5), ("stadium", 3.0), ("dome", 2.5),
            ("vip", 2.0), ("soundcheck", 2.5), ("meet & greet", 2.5), ("backstage", 2.0),
            ("encore", 2.0), ("setlist", 2.0), ("sold out", 2.5), ("general admission", 2.0)
        ],
        .merch: [
            ("merch", 3.0), ("merchandise", 3.0), ("lightstick", 3.5), ("official", 2.0),
            ("store", 2.0), ("drop", 2.5), ("limited edition", 3.0), ("collection", 2.5),
            ("hoodie", 2.5), ("shirt", 2.0), ("t-shirt", 2.0), ("keychain", 2.0),
            ("poster", 2.0), ("bag", 2.0), ("cap", 2.0), ("hat", 2.0), ("accessory", 2.0),
            ("plushie", 2.5), ("figurine", 2.5), ("pin", 2.0), ("badge", 2.0),
            ("sticker", 1.5), ("phone case", 2.0), ("mug", 2.0), ("tumbler", 2.0)
        ],
        .events: [
            ("fanmeet", 3.5), ("fansign", 3.5), ("fan meeting", 3.5), ("kcon", 3.5),
            ("hi-touch", 3.5), ("meet and greet", 3.0), ("convention", 2.5),
            ("fan event", 3.0), ("birthday", 2.0), ("anniversary", 2.5), ("debut anniversary", 3.0),
            ("instagram", 1.5), ("ig", 1.5), ("tiktok", 1.5), ("twitter", 1.5),
            ("weverse", 2.0), ("vlog", 2.0), ("behind", 1.5), ("selca", 1.5),
            ("post", 1.0), ("update", 1.0), ("sns", 1.5), ("live stream", 2.5),
            ("vlive", 2.5), ("instagram live", 2.5), ("fan cafe", 2.0)
        ],
        .subscriptions: [
            ("weverse", 2.5), ("subscription", 3.5), ("membership", 3.5), ("app", 2.0),
            ("platform", 2.0), ("streaming", 2.5), ("exclusive content", 3.0),
            ("bubble", 3.0), ("lysn", 3.0), ("vlive", 2.0), ("premium", 2.5),
            ("monthly subscription", 3.5), ("yearly subscription", 3.5), ("digital content", 2.5),
            ("fan kit", 2.5), ("membership benefits", 3.0), ("exclusive access", 2.5),
            ("early access", 2.5), ("member only", 2.5), ("vip membership", 3.0)
        ]
    ]
    
    private static let breakingKeywords = [
        ("breaking", 3.0), ("urgent", 2.5), ("just in", 2.5), ("confirmed", 2.0),
        ("official", 2.0), ("announces", 2.5), ("surprise", 3.0), ("exclusive", 2.0),
        ("first", 2.0), ("debuts", 2.5), ("leaked", 2.0), ("spoiler", 2.0),
        ("rumor confirmed", 3.0), ("officially announced", 3.0)
    ]
    
    /// Enhanced categorization with weighted keyword matching and contextual analysis
    /// - Parameters:
    ///   - title: Event title
    ///   - content: Event content/description
    /// - Returns: Most appropriate event category
    static func categorize(title: String, content: String) -> EventCategory {
        let text = (title + " " + content).lowercased()
        
        var categoryScores: [EventCategory: Double] = [:]
        
        // Calculate weighted scores for each category
        for (category, keywords) in categoryKeywordWeights {
            var score = 0.0
            var keywordMatches = 0
            
            for (keyword, weight) in keywords {
                if text.contains(keyword) {
                    score += weight
                    keywordMatches += 1
                    
                    // Bonus for title match (more significant)
                    if title.lowercased().contains(keyword) {
                        score += weight * 0.5
                    }
                }
            }
            
            // Bonus for multiple keyword matches in same category
            if keywordMatches > 1 {
                score += Double(keywordMatches - 1) * 0.5
            }
            
            categoryScores[category] = score
        }
        
        // Apply contextual adjustments
        categoryScores = applyContextualAdjustments(categoryScores, title: title, content: content, text: text)
        
        // Find the highest scoring category
        let bestMatch = categoryScores.max { $0.value < $1.value }
        
        if let category = bestMatch, category.value > 1.0 {
            print("🤖 Event categorization: '\(title)' → \(category.key.rawValue) (score: \(String(format: "%.1f", category.value)))")
            return category.key
        } else {
            print("⚠️ Event categorization fallback for: '\(title)'")
            return .other // Default fallback
        }
    }
    
    /// Apply contextual adjustments to category scores
    private static func applyContextualAdjustments(
        _ scores: [EventCategory: Double], 
        title: String, 
        content: String, 
        text: String
    ) -> [EventCategory: Double] {
        var adjustedScores = scores
        
        // Date-based context (if we can extract dates)
        let currentMonth = Calendar.current.component(.month, from: Date())
        
        // Concert season boost (spring/summer)
        if [3, 4, 5, 6, 7, 8].contains(currentMonth) {
            adjustedScores[.concerts] = (adjustedScores[.concerts] ?? 0) + 0.3
        }
        
        // Album release season boost (fall/winter for comebacks)
        if [9, 10, 11, 12, 1, 2].contains(currentMonth) {
            adjustedScores[.albums] = (adjustedScores[.albums] ?? 0) + 0.3
        }
        
        // Artist popularity context
        let popularArtists = ["bts", "blackpink", "newjeans", "twice", "seventeen", "stray kids"]
        for artist in popularArtists {
            if text.contains(artist) {
                // Popular artists boost concerts and merch
                adjustedScores[.concerts] = (adjustedScores[.concerts] ?? 0) + 0.5
                adjustedScores[.merch] = (adjustedScores[.merch] ?? 0) + 0.3
                break
            }
        }
        
        // Price indication context
        if text.contains("$") || text.contains("won") || text.contains("price") {
            // Likely merchandise or concert tickets
            adjustedScores[.merch] = (adjustedScores[.merch] ?? 0) + 0.5
            adjustedScores[.concerts] = (adjustedScores[.concerts] ?? 0) + 0.3
        }
        
        // Digital context
        if text.contains("online") || text.contains("digital") || text.contains("app") {
            adjustedScores[.subscriptions] = (adjustedScores[.subscriptions] ?? 0) + 0.5
        }
        
        return adjustedScores
    }
    
    /// Enhanced breaking news detection with weighted scoring
    /// - Parameters:
    ///   - title: Event title
    ///   - content: Event content
    ///   - publishedDate: When the event was published
    /// - Returns: True if considered breaking news
    static func isBreaking(title: String, content: String, publishedDate: Date) -> Bool {
        let text = (title + " " + content).lowercased()
        let titleText = title.lowercased()
        
        // Calculate breaking news score with weighted keywords
        var breakingScore = 0.0
        for (keyword, weight) in breakingKeywords {
            if text.contains(keyword) {
                breakingScore += weight
                
                // Extra weight for title matches
                if titleText.contains(keyword) {
                    breakingScore += weight * 0.5
                }
            }
        }
        
        // Time-based scoring (more recent = higher chance of being breaking)
        let hoursSincePublished = Date().timeIntervalSince(publishedDate) / 3600
        let timeWeight: Double
        
        switch hoursSincePublished {
        case 0..<1:   timeWeight = 2.0  // Very recent
        case 1..<6:   timeWeight = 1.5  // Recent
        case 6..<12:  timeWeight = 1.0  // Somewhat recent
        case 12..<24: timeWeight = 0.5  // Last day
        default:      timeWeight = 0.1  // Older
        }
        
        let finalScore = breakingScore * timeWeight
        
        // Threshold for breaking news (adjusted based on testing)
        let isBreaking = finalScore >= 3.0
        
        if isBreaking {
            print("🚨 Breaking news detected: '\(title)' (score: \(String(format: "%.1f", finalScore)))")
        }
        
        return isBreaking
    }
}

// MARK: - Artist Matching
struct ArtistMatcher {
    static let popularArtists = [
        "BTS", "BLACKPINK", "NewJeans", "TWICE", "SEVENTEEN", "Stray Kids",
        "IVE", "aespa", "ITZY", "i-dle", "Red Velvet", "ENHYPEN",
        "LE SSERAFIM", "NMIXX", "TREASURE", "ATEEZ", "TXT", "MAMAMOO",
        "EVERGLOW", "LOONA", "KARD", "DREAMCATCHER", "PURPLE KISS", "WJSN",
        "OH MY GIRL", "VIVIZ", "LIGHTSUM", "ILY:1", "KEP1ER", "FROMIS_9"
    ]
    
    static func findMatchingArtists(in text: String, userArtists: [String] = []) -> [String] {
        let searchText = text.lowercased()
        var matches: [String] = []
        
        // Check user's artists first (priority)
        for artist in userArtists {
            if searchText.contains(artist.lowercased()) {
                matches.append(artist)
            }
        }
        
        // Check popular artists
        for artist in popularArtists {
            if searchText.contains(artist.lowercased()) && !matches.contains(artist) {
                matches.append(artist)
            }
        }
        
        return matches
    }
}

// MARK: - Duplicate EventSource removed - already defined above

// MARK: - API Response Models

/// Response model for Ticketmaster API
struct TicketmasterResponse: Codable {
    let events: [TicketmasterEvent]
    let totalCount: Int
    
    enum CodingKeys: String, CodingKey {
        case events
        case totalCount = "total_count"
    }
}

struct TicketmasterEvent: Codable {
    let id: String
    let name: String
    let artist: String
    let venue: String
    let city: String
    let date: String?
    let time: String?
    let min_price: Double?
    let max_price: Double?
    let currency: String
    let url: String
    let image_url: String?
}

/// Response model for Spotify news API
struct SpotifyNewsResponse: Codable {
    let items: [SpotifyNewsItem]
}

struct SpotifyNewsItem: Codable {
    let title: String
    let content: String
    let source_url: String?
    let image_url: String?
    let published_at: String
    let category: String
    let artist_name: String
    let metadata: [String: String]?  // Simplified for Codable conformance
    
    enum CodingKeys: String, CodingKey {
        case title
        case content
        case source_url
        case image_url
        case published_at
        case category
        case artist_name
        case metadata
    }
    
    // Custom decoder removed - using default Codable implementation
}

// Helper for dynamic JSON keys
struct DynamicKey: CodingKey {
    let stringValue: String
    let intValue: Int? = nil
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        return nil
    }
}