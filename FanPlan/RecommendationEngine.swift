import Foundation
import SwiftUI

// MARK: - Personalized Recommendation Engine
@MainActor
class RecommendationEngine: ObservableObject {
    static let shared = RecommendationEngine()
    
    @Published var artistRecommendations: [ArtistRecommendation] = []
    @Published var contentRecommendations: [ContentRecommendation] = []
    // Purchase recommendations removed - using PurchaseDecisionCalculatorView instead
    @Published var isGenerating = false
    
    private let userDefaults = UserDefaults.standard
    private let maxRecommendations = 10
    
    private init() {}
    
    // MARK: - Main Recommendation Generation
    func generatePersonalizedRecommendations(
        for user: DashboardUser,
        currentArtists: [FanArtist],
        purchases: [FanPurchase],
        // goals parameter removed - goal functionality no longer supported
        interactions: [UserInteraction] = []
    ) async {
        isGenerating = true
        
        // Generate different types of recommendations
        let artistRecs = await generateArtistRecommendations(
            currentArtists: currentArtists,
            purchases: purchases,
            interactions: interactions
        )
        
        let contentRecs = await generateContentRecommendations(
            currentArtists: currentArtists,
            purchases: purchases,
            user: user
        )
        
        // Purchase recommendations removed - using PurchaseDecisionCalculatorView
        /*
        let purchaseRecs = await generatePurchaseRecommendations(
            currentArtists: currentArtists,
            purchases: purchases,
            goals: goals,
            availableFanSpend: user.totalMonthlyBudget - user.totalMonthSpent  // Internal variable uses fan terminology
        )
        */
        
        // Apply collaborative filtering enhancement
        let enhancedArtistRecs = await enhanceWithCollaborativeFiltering(artistRecs, userId: user.id)
        
        self.artistRecommendations = enhancedArtistRecs
        self.contentRecommendations = contentRecs
        // self.purchaseRecommendations = purchaseRecs // Removed - using PurchaseDecisionCalculatorView
        
        isGenerating = false
        
        // Cache recommendations
        cacheRecommendations()
    }
    
    // MARK: - Artist Recommendations
    private func generateArtistRecommendations(
        currentArtists: [FanArtist],
        purchases: [FanPurchase],
        interactions: [UserInteraction]
    ) async -> [ArtistRecommendation] {
        
        var recommendations: [ArtistRecommendation] = []
        let currentArtistNames = Set(currentArtists.map { $0.name })
        
        // 1. Genre-based recommendations
        let genreRecommendations = await generateGenreBasedRecommendations(
            currentArtists: currentArtists
        )
        recommendations.append(contentsOf: genreRecommendations)
        
        // 2. Company/Label-based recommendations
        let labelRecommendations = await generateLabelBasedRecommendations(
            currentArtists: currentArtists
        )
        recommendations.append(contentsOf: labelRecommendations)
        
        // 3. Collaboration-based recommendations
        let collaborationRecommendations = await generateCollaborationRecommendations(
            currentArtists: currentArtists
        )
        recommendations.append(contentsOf: collaborationRecommendations)
        
        // 4. Trending artists in user's spending categories
        let trendingRecommendations = await generateTrendingRecommendations(
            basedOnPurchases: purchases
        )
        recommendations.append(contentsOf: trendingRecommendations)
        
        // Filter out already followed artists and rank by score
        return recommendations
            .filter { !currentArtistNames.contains($0.artistName) }
            .sorted { $0.score > $1.score }
            .prefix(maxRecommendations)
            .map { $0 }
    }
    
    private func generateGenreBasedRecommendations(currentArtists: [FanArtist]) async -> [ArtistRecommendation] {
        // Mock genre mapping - in real app, this would come from Spotify API or music database
        let genreMapping: [String: [String]] = [
            "BTS": ["K-Pop", "Hip-Hop", "R&B"],
            "BLACKPINK": ["K-Pop", "Pop", "EDM"],
            "NewJeans": ["K-Pop", "Y2K", "R&B"],
            "IVE": ["K-Pop", "Pop", "Dance"],
            "aespa": ["K-Pop", "Experimental", "Pop"]
        ]
        
        let similarArtists: [String: [String]] = [
            "K-Pop": ["ITZY", "i-dle", "TWICE", "Red Velvet", "SEVENTEEN", "Stray Kids"],
            "Hip-Hop": ["MAMAMOO", "CL", "Jay Park"],
            "R&B": ["IU", "Taeyeon", "Heize"],
            "Pop": ["TWICE", "Red Velvet", "Girls' Generation"],
            "EDM": ["ITZY", "i-dle"]
        ]
        
        var recommendations: [ArtistRecommendation] = []
        var artistScores: [String: Double] = [:]
        
        // Calculate scores based on user's current artists' genres
        for artist in currentArtists {
            if let genres = genreMapping[artist.name] {
                for genre in genres {
                    if let similarArtistList = similarArtists[genre] {
                        for similarArtist in similarArtistList {
                            artistScores[similarArtist, default: 0] += (artist.spentPercentage / 100.0) * 0.3
                        }
                    }
                }
            }
        }
        
        // Convert to recommendations
        for (artistName, score) in artistScores {
            let mainGenre = findMainGenre(for: artistName, in: similarArtists)
            recommendations.append(ArtistRecommendation(
                artistName: artistName,
                score: score,
                reasoning: "Similar genre to your favorite artists (\(mainGenre))",
                recommendationType: .genreSimilarity,
                imageURL: nil,
                spotifyURL: nil
            ))
        }
        
        return recommendations
    }
    
    private func generateLabelBasedRecommendations(currentArtists: [FanArtist]) async -> [ArtistRecommendation] {
        // Mock label mapping
        let labelMapping: [String: String] = [
            "BTS": "HYBE",
            "NewJeans": "HYBE",
            "BLACKPINK": "YG Entertainment",
            "IVE": "Starship Entertainment",
            "aespa": "SM Entertainment"
        ]
        
        let labelArtists: [String: [String]] = [
            "HYBE": ["TXT", "ENHYPEN", "LE SSERAFIM", "FROMIS_9"],
            "YG Entertainment": ["WINNER", "iKON", "TREASURE"],
            "SM Entertainment": ["Red Velvet", "NCT", "Girls' Generation", "SHINee"],
            "Starship Entertainment": ["MONSTA X", "CRAVITY"]
        ]
        
        var recommendations: [ArtistRecommendation] = []
        var processedLabels: Set<String> = []
        
        for artist in currentArtists {
            if let label = labelMapping[artist.name],
               !processedLabels.contains(label),
               let labelmates = labelArtists[label] {
                
                processedLabels.insert(label)
                
                for labelmate in labelmates {
                    recommendations.append(ArtistRecommendation(
                        artistName: labelmate,
                        score: 0.6 + (artist.spentPercentage / 100.0) * 0.2,
                        reasoning: "Same label as \(artist.name) (\(label))",
                        recommendationType: .labelConnection,
                        imageURL: nil,
                        spotifyURL: nil
                    ))
                }
            }
        }
        
        return recommendations
    }
    
    private func generateCollaborationRecommendations(currentArtists: [FanArtist]) async -> [ArtistRecommendation] {
        // Mock collaboration data
        let collaborations: [String: [String]] = [
            "BTS": ["Halsey", "Ed Sheeran", "Steve Aoki"],
            "BLACKPINK": ["Dua Lipa", "Selena Gomez"],
            "IVE": ["SEVENTEEN"] // Special stages, not official collabs
        ]
        
        var recommendations: [ArtistRecommendation] = []
        
        for artist in currentArtists {
            if let collabArtists = collaborations[artist.name] {
                for collabArtist in collabArtists {
                    recommendations.append(ArtistRecommendation(
                        artistName: collabArtist,
                        score: 0.5,
                        reasoning: "Has collaborated with \(artist.name)",
                        recommendationType: .collaboration,
                        imageURL: nil,
                        spotifyURL: nil
                    ))
                }
            }
        }
        
        return recommendations
    }
    
    private func generateTrendingRecommendations(basedOnPurchases purchases: [FanPurchase]) async -> [ArtistRecommendation] {
        // Analyze user's purchase patterns to recommend trending artists in similar categories
        let categorySpending = Dictionary(grouping: purchases) { $0.category }
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        
        // Mock trending artists by category
        let trendingByCategory: [FanCategory: [String]] = [
            .albums: ["LE SSERAFIM", "NMIXX", "KARD"],
            .concerts: ["i-dle", "ITZY", "EVERGLOW"],
            .merch: ["TWICE", "Red Velvet", "MAMAMOO"],
            .albums: ["SEVENTEEN", "Stray Kids", "ATEEZ"] // Photocards now part of albums
        ]
        
        var recommendations: [ArtistRecommendation] = []
        
        for (category, spending) in categorySpending {
            if let trendingArtists = trendingByCategory[category] {
                let categoryWeight = spending / purchases.reduce(0) { $0 + $1.amount }
                
                for artist in trendingArtists {
                    recommendations.append(ArtistRecommendation(
                        artistName: artist,
                        score: 0.4 + categoryWeight * 0.3,
                        reasoning: "Trending in \(category.displayName) - your top spending category",
                        recommendationType: .trending,
                        imageURL: nil,
                        spotifyURL: nil
                    ))
                }
            }
        }
        
        return recommendations
    }
    
    // MARK: - Content Recommendations
    private func generateContentRecommendations(
        currentArtists: [FanArtist],
        purchases: [FanPurchase],
        user: DashboardUser
    ) async -> [ContentRecommendation] {
        
        var recommendations: [ContentRecommendation] = []
        
        // 1. Album recommendations based on purchase history
        let albumRecs = generateAlbumRecommendations(currentArtists: currentArtists, purchases: purchases)
        recommendations.append(contentsOf: albumRecs)
        
        // 2. Merchandise recommendations based on spending patterns
        let merchRecs = generateMerchandiseRecommendations(currentArtists: currentArtists, purchases: purchases)
        recommendations.append(contentsOf: merchRecs)
        
        // 3. Experience recommendations (concerts, fanmeets)
        let experienceRecs = generateExperienceRecommendations(currentArtists: currentArtists, availableFanSpend: user.totalMonthlyBudget - user.totalMonthSpent)
        recommendations.append(contentsOf: experienceRecs)
        
        return recommendations.sorted { $0.priority > $1.priority }.prefix(maxRecommendations).map { $0 }
    }
    
    private func generateAlbumRecommendations(currentArtists: [FanArtist], purchases: [FanPurchase]) -> [ContentRecommendation] {
        var recommendations: [ContentRecommendation] = []
        
        // Find artists with low album purchase frequency
        for artist in currentArtists {
            let albumPurchases = purchases.filter { $0.artistName == artist.name && $0.category == .albums }
            let recentAlbumPurchases = albumPurchases.filter { 
                Calendar.current.dateComponents([.month], from: $0.purchaseDate, to: Date()).month ?? 0 < 6 
            }
            
            if recentAlbumPurchases.isEmpty {
                recommendations.append(ContentRecommendation(
                    title: "\(artist.name) Latest Album",
                    description: "You haven't purchased any \(artist.name) albums recently. Check out their latest release!",
                    contentType: .album,
                    artistName: artist.name,
                    estimatedPrice: 25.0,
                    priority: artist.priorityRank <= 2 ? 0.8 : 0.6,
                    reasoning: "Low recent album activity for high-priority artist",
                    imageURL: nil,
                    purchaseURL: nil
                ))
            }
        }
        
        return recommendations
    }
    
    private func generateMerchandiseRecommendations(currentArtists: [FanArtist], purchases: [FanPurchase]) -> [ContentRecommendation] {
        var recommendations: [ContentRecommendation] = []
        
        // Seasonal merchandise recommendations
        let currentMonth = Calendar.current.component(.month, from: Date())
        let seasonalItems: [Int: [(String, Double)]] = [
            12: [("Holiday Sweater", 45.0), ("Winter Scarf", 25.0)], // December
            6: [("Summer T-Shirt", 30.0), ("Concert Towel", 15.0)],   // June
            3: [("Spring Hoodie", 55.0), ("Light Jacket", 65.0)]      // March
        ]
        
        if let seasonalMerch = seasonalItems[currentMonth] {
            for artist in currentArtists.prefix(2) { // Top 2 artists only
                for (item, price) in seasonalMerch {
                    recommendations.append(ContentRecommendation(
                        title: "\(artist.name) \(item)",
                        description: "Perfect for the season! Limited time availability.",
                        contentType: .merchandise,
                        artistName: artist.name,
                        estimatedPrice: price,
                        priority: 0.7,
                        reasoning: "Seasonal merchandise for top bias",
                        imageURL: nil,
                        purchaseURL: nil
                    ))
                }
            }
        }
        
        return recommendations
    }
    
    private func generateExperienceRecommendations(currentArtists: [FanArtist], availableFanSpend: Double) -> [ContentRecommendation] {
        var recommendations: [ContentRecommendation] = []
        
        // Only recommend experiences if user has sufficient fan spending available
        guard availableFanSpend >= 100 else { return recommendations }
        
        for artist in currentArtists.prefix(3) {
            // Mock upcoming events
            let upcomingEvents = [
                ("Virtual Fanmeet", 50.0, "Join an intimate online fanmeet"),
                ("Concert Livestream", 25.0, "Watch the concert from home"),
                ("Fan Cafe Membership", 15.0, "Get exclusive access to fan content")
            ]
            
            for (eventType, price, description) in upcomingEvents {
                if price <= availableFanSpend {
                    recommendations.append(ContentRecommendation(
                        title: "\(artist.name) \(eventType)",
                        description: description,
                        contentType: .experience,
                        artistName: artist.name,
                        estimatedPrice: price,
                        priority: 0.6,
                        reasoning: "Experience within your planned spending for favorite artist",
                        imageURL: nil,
                        purchaseURL: nil
                    ))
                }
            }
        }
        
        return recommendations
    }
    
    // MARK: - Purchase Recommendations
    // Method removed - using PurchaseDecisionCalculatorView instead
    /*
    private func generatePurchaseRecommendations(
        currentArtists: [FanArtist],
        purchases: [FanPurchase],
        // goals parameter removed - goal functionality no longer supported
        availableFanSpend: Double  // Internal parameter uses fan terminology
    ) async -> [PurchaseRecommendation] {
        
        var recommendations: [PurchaseRecommendation] = []
        
        // 1. Goal-aligned purchase recommendations
        for goal in goals {
            if goal.progressPercentage < 80 && goal.remainingAmount <= availableFanSpend {
                recommendations.append(PurchaseRecommendation(
                    title: "Complete \(goal.name)",
                    description: "You're \(Int(goal.progressPercentage))% there! Just $\(Int(goal.remainingAmount)) more to reach your goal.",
                    estimatedCost: goal.remainingAmount,
                    priority: 0.9,
                    reasoning: "Close to completing goal",
                    relatedGoalId: goal.id,
                    relatedArtistName: nil,
                    suggestedActions: [
                        "Add $\(Int(goal.remainingAmount)) to this goal",
                        "Break it down: Save $\(Int(goal.remainingAmount/2)) this week and next"
                    ]
                ))
            }
        }
        
        // 2. Fan spending optimization recommendations
        let underutilizedArtists = currentArtists.filter { $0.spentPercentage < 30 && $0.remainingBudget > 20 }
        for artist in underutilizedArtists {
            recommendations.append(PurchaseRecommendation(
                title: "Focus on \(artist.name)",
                description: "You have $\(Int(artist.remainingBudget)) unspent for \(artist.name). Consider getting something special!",
                estimatedCost: min(artist.remainingBudget, 50.0),
                priority: 0.6,
                reasoning: "Underutilized artist allocation",
                relatedGoalId: nil,
                relatedArtistName: artist.name,
                suggestedActions: [
                    "Buy their latest album",
                    "Get some merchandise",
                    "Save for upcoming events"
                ]
            ))
        }
        
        return recommendations.sorted { $0.priority > $1.priority }
    }
    */
    
    // MARK: - Collaborative Filtering Enhancement
    private func enhanceWithCollaborativeFiltering(
        _ recommendations: [ArtistRecommendation],
        userId: UUID
    ) async -> [ArtistRecommendation] {
        // Mock collaborative filtering based on similar users
        // In a real implementation, this would use a proper ML model
        
        let similarUserPreferences = await fetchSimilarUserPreferences(userId: userId)
        
        return recommendations.map { rec in
            var enhancedRec = rec
            
            // Boost score if similar users also like this artist
            if similarUserPreferences.contains(rec.artistName) {
                enhancedRec.score = min(enhancedRec.score + 0.2, 1.0)
                enhancedRec.reasoning += " • Popular with users who have similar tastes"
            }
            
            return enhancedRec
        }
    }
    
    private func fetchSimilarUserPreferences(userId: UUID) async -> Set<String> {
        // Mock implementation - would use proper user similarity algorithm
        _ = userId // Silence unused parameter warning
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        return Set(["ITZY", "Red Velvet", "SEVENTEEN", "i-dle"])
    }
    
    // MARK: - Helper Functions
    private func findMainGenre(for artistName: String, in genreMap: [String: [String]]) -> String {
        for (genre, artists) in genreMap {
            if artists.contains(artistName) {
                return genre
            }
        }
        return "K-Pop"
    }
    
    // MARK: - Caching
    private func cacheRecommendations() {
        let encoder = JSONEncoder()
        
        if let artistData = try? encoder.encode(artistRecommendations) {
            userDefaults.set(artistData, forKey: "cached_artist_recommendations")
        }
        
        if let contentData = try? encoder.encode(contentRecommendations) {
            userDefaults.set(contentData, forKey: "cached_content_recommendations")
        }
        
        // Purchase recommendations caching removed
        /*
        if let purchaseData = try? encoder.encode(purchaseRecommendations) {
            userDefaults.set(purchaseData, forKey: "cached_purchase_recommendations")
        }
        */
    }
    
    func loadCachedRecommendations() {
        let decoder = JSONDecoder()
        
        if let artistData = userDefaults.data(forKey: "cached_artist_recommendations"),
           let cached = try? decoder.decode([ArtistRecommendation].self, from: artistData) {
            self.artistRecommendations = cached
        }
        
        if let contentData = userDefaults.data(forKey: "cached_content_recommendations"),
           let cached = try? decoder.decode([ContentRecommendation].self, from: contentData) {
            self.contentRecommendations = cached
        }
        
        // Purchase recommendations loading removed
        /*
        if let purchaseData = userDefaults.data(forKey: "cached_purchase_recommendations"),
           let cached = try? decoder.decode([PurchaseRecommendation].self, from: purchaseData) {
            self.purchaseRecommendations = cached
        }
        */
    }
}

// MARK: - Recommendation Models
struct ArtistRecommendation: Identifiable, Codable {
    let id: UUID
    let artistName: String
    var score: Double // 0.0 to 1.0
    var reasoning: String
    let recommendationType: RecommendationType
    let imageURL: String?
    let spotifyURL: String?
    
    var scoreText: String {
        return "\(Int(score * 100))% match"
    }
    
    var typeIcon: String {
        switch recommendationType {
        case .genreSimilarity: return "music.note.list"
        case .labelConnection: return "building.2"
        case .collaboration: return "person.2"
        case .trending: return "chart.line.uptrend.xyaxis"
        }
    }
    
    init(artistName: String, score: Double, reasoning: String, recommendationType: RecommendationType, imageURL: String? = nil, spotifyURL: String? = nil) {
        self.id = UUID()
        self.artistName = artistName
        self.score = score
        self.reasoning = reasoning
        self.recommendationType = recommendationType
        self.imageURL = imageURL
        self.spotifyURL = spotifyURL
    }
    
    enum RecommendationType: String, Codable {
        case genreSimilarity = "genre_similarity"
        case labelConnection = "label_connection"
        case collaboration = "collaboration"
        case trending = "trending"
    }
}

struct ContentRecommendation: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let contentType: ContentType
    let artistName: String
    let estimatedPrice: Double
    let priority: Double
    let reasoning: String
    let imageURL: String?
    let purchaseURL: String?
    
    var typeIcon: String {
        switch contentType {
        case .album: return "opticaldisc"
        case .merchandise: return "bag"
        case .experience: return "ticket"
        case .digital: return "iphone"
        }
    }
    
    init(title: String, description: String, contentType: ContentType, artistName: String, estimatedPrice: Double, priority: Double, reasoning: String, imageURL: String? = nil, purchaseURL: String? = nil) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.contentType = contentType
        self.artistName = artistName
        self.estimatedPrice = estimatedPrice
        self.priority = priority
        self.reasoning = reasoning
        self.imageURL = imageURL
        self.purchaseURL = purchaseURL
    }
    
    enum ContentType: String, Codable {
        case album, merchandise, experience, digital
    }
}

// PurchaseRecommendation struct removed - conflicted with PurchaseDecisionCalculatorView

struct UserInteraction: Codable {
    let artistName: String
    let interactionType: InteractionType
    let timestamp: Date
    let value: Double? // For ratings, purchase amounts, etc.
    
    enum InteractionType: String, Codable {
        case view, like, purchase, follow, search
    }
}
