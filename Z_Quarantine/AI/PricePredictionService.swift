import Foundation
import SwiftUI

// MARK: - Price Prediction Service
@MainActor
class PricePredictionService: ObservableObject {
    static let shared = PricePredictionService()
    
    @Published var predictions: [PricePrediction] = []
    @Published var alerts: [PriceAlert] = []
    @Published var isAnalyzing = false
    
    private let historicalData = PriceHistoryManager()
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadCachedPredictions()
    }
    
    // MARK: - Main Prediction Engine
    func predictPrices(for artists: [FanArtist], categories: [FanCategory]) async {
        isAnalyzing = true
        
        var allPredictions: [PricePrediction] = []
        
        for artist in artists {
            for category in categories {
                let predictions = await generatePredictions(
                    artist: artist,
                    category: category
                )
                allPredictions.append(contentsOf: predictions)
            }
        }
        
        // Sort by relevance and confidence
        self.predictions = allPredictions
            .sorted { $0.confidence > $1.confidence }
            .prefix(20)
            .map { $0 }
        
        // Generate price alerts
        await generatePriceAlerts()
        
        isAnalyzing = false
        cachePredictions()
    }
    
    // MARK: - Category-Specific Predictions
    private func generatePredictions(
        artist: FanArtist,
        category: FanCategory
    ) async -> [PricePrediction] {
        
        switch category {
        case .albumHunting:
            return await predictAlbumPrices(artist: artist)
        case .concertPrep:
            return await predictConcertPrices(artist: artist)
        case .merchHaul:
            return await predictMerchandisePrices(artist: artist)
        case .photocardCollecting:
            return await predictPhotocardPrices(artist: artist)
        case .digitalContent:
            return await predictDigitalPrices(artist: artist)
        default:
            return []
        }
    }
    
    // MARK: - Album Price Predictions
    private func predictAlbumPrices(artist: FanArtist) async -> [PricePrediction] {
        let basePrice = historicalData.getAverageAlbumPrice(for: artist.name)
        
        var predictions: [PricePrediction] = []
        
        // Regular edition prediction
        let regularEdition = PricePrediction(
            itemType: "Regular Album",
            artistName: artist.name,
            category: .albumHunting,
            currentPrice: basePrice,
            predictedPrice: basePrice * randomVariation(0.95, 1.1),
            confidence: 0.8,
            timeframe: "Next 30 days",
            reasoning: "Based on historical album pricing patterns",
            factors: [
                PriceFactor(name: "Historical average", impact: 0.6, description: "$\(Int(basePrice)) average for \(artist.name) albums"),
                PriceFactor(name: "Market stability", impact: 0.2, description: "Album prices typically remain stable"),
                PriceFactor(name: "Artist popularity", impact: adjustmentForPopularity(artist), description: "Popularity tier: #\(artist.priorityRank)")
            ],
            isIncreasing: false,
            volatility: 0.15
        )
        predictions.append(regularEdition)
        
        // Special edition prediction (higher price, more volatile)
        let specialEdition = PricePrediction(
            itemType: "Special/Limited Edition Album",
            artistName: artist.name,
            category: .albumHunting,
            currentPrice: basePrice * 1.5,
            predictedPrice: basePrice * 1.5 * randomVariation(0.9, 1.3),
            confidence: 0.6,
            timeframe: "Next 60 days",
            reasoning: "Limited editions show higher price volatility",
            factors: [
                PriceFactor(name: "Scarcity premium", impact: 0.4, description: "Limited quantity drives up prices"),
                PriceFactor(name: "Collector demand", impact: 0.3, description: "High collector interest"),
                PriceFactor(name: "Resale market", impact: 0.3, description: "Strong secondary market")
            ],
            isIncreasing: true,
            volatility: 0.35
        )
        predictions.append(specialEdition)
        
        return predictions
    }
    
    // MARK: - Concert Price Predictions
    private func predictConcertPrices(artist: FanArtist) async -> [PricePrediction] {
        let baseConcertPrice = historicalData.getAverageConcertPrice(for: artist.name)
        
        var predictions: [PricePrediction] = []
        
        // General admission prediction
        let gaTicket = PricePrediction(
            itemType: "General Admission Ticket",
            artistName: artist.name,
            category: .concertPrep,
            currentPrice: baseConcertPrice * 0.8,
            predictedPrice: baseConcertPrice * 0.8 * randomVariation(1.0, 1.4),
            confidence: 0.7,
            timeframe: "6 months out from announcement",
            reasoning: "Concert tickets typically increase as show date approaches",
            factors: [
                PriceFactor(name: "Demand surge", impact: 0.5, description: "High demand expected for \(artist.name)"),
                PriceFactor(name: "Venue capacity", impact: 0.3, description: "Limited seating drives price increases"),
                PriceFactor(name: "Secondary market", impact: 0.2, description: "Reseller activity affects pricing")
            ],
            isIncreasing: true,
            volatility: 0.45
        )
        predictions.append(gaTicket)
        
        // VIP package prediction
        let vipPackage = PricePrediction(
            itemType: "VIP Package",
            artistName: artist.name,
            category: .concertPrep,
            currentPrice: baseConcertPrice * 3.0,
            predictedPrice: baseConcertPrice * 3.0 * randomVariation(0.95, 1.2),
            confidence: 0.6,
            timeframe: "Presale to general sale",
            reasoning: "VIP packages have premium pricing with moderate increases",
            factors: [
                PriceFactor(name: "Exclusive access", impact: 0.6, description: "Meet & greet and exclusive perks"),
                PriceFactor(name: "Limited quantity", impact: 0.4, description: "Very limited VIP packages available")
            ],
            isIncreasing: true,
            volatility: 0.25
        )
        predictions.append(vipPackage)
        
        return predictions
    }
    
    // MARK: - Merchandise Price Predictions
    private func predictMerchandisePrices(artist: FanArtist) async -> [PricePrediction] {
        let baseMerchPrice = 35.0 // Average merch price
        
        var predictions: [PricePrediction] = []
        
        // Official merchandise
        let officialMerch = PricePrediction(
            itemType: "Official Merchandise",
            artistName: artist.name,
            category: .merchHaul,
            currentPrice: baseMerchPrice,
            predictedPrice: baseMerchPrice * randomVariation(0.9, 1.15),
            confidence: 0.75,
            timeframe: "Next 90 days",
            reasoning: "Official merchandise prices remain relatively stable",
            factors: [
                PriceFactor(name: "Brand control", impact: 0.5, description: "Official prices are controlled"),
                PriceFactor(name: "Production costs", impact: 0.3, description: "Material and shipping costs"),
                PriceFactor(name: "Exchange rates", impact: 0.2, description: "Currency fluctuations affect pricing")
            ],
            isIncreasing: false,
            volatility: 0.12
        )
        predictions.append(officialMerch)
        
        // Tour-exclusive merchandise
        let tourMerch = PricePrediction(
            itemType: "Tour-Exclusive Merchandise",
            artistName: artist.name,
            category: .merchHaul,
            currentPrice: baseMerchPrice * 1.3,
            predictedPrice: baseMerchPrice * 1.3 * randomVariation(1.1, 1.8),
            confidence: 0.5,
            timeframe: "After tour ends",
            reasoning: "Tour-exclusive items become valuable collectibles",
            factors: [
                PriceFactor(name: "Limited availability", impact: 0.6, description: "Only available at tour venues"),
                PriceFactor(name: "Collector premium", impact: 0.4, description: "High demand from collectors post-tour")
            ],
            isIncreasing: true,
            volatility: 0.55
        )
        predictions.append(tourMerch)
        
        return predictions
    }
    
    // MARK: - Photocard Price Predictions
    private func predictPhotocardPrices(artist: FanArtist) async -> [PricePrediction] {
        let baseCardPrice = 8.0
        
        var predictions: [PricePrediction] = []
        
        // Regular photocard
        let regularCard = PricePrediction(
            itemType: "Regular Photocard",
            artistName: artist.name,
            category: .photocardCollecting,
            currentPrice: baseCardPrice,
            predictedPrice: baseCardPrice * randomVariation(0.8, 1.5),
            confidence: 0.6,
            timeframe: "Based on member popularity",
            reasoning: "Photocard prices vary significantly by member popularity",
            factors: [
                PriceFactor(name: "Member bias ranking", impact: 0.5, description: "Popular members command higher prices"),
                PriceFactor(name: "Card condition", impact: 0.3, description: "Mint condition premium"),
                PriceFactor(name: "Album era", impact: 0.2, description: "Newer eras typically cost more")
            ],
            isIncreasing: false,
            volatility: 0.4
        )
        predictions.append(regularCard)
        
        // Special photocard (polaroids, signed, etc.)
        let specialCard = PricePrediction(
            itemType: "Special/Signed Photocard",
            artistName: artist.name,
            category: .photocardCollecting,
            currentPrice: baseCardPrice * 5.0,
            predictedPrice: baseCardPrice * 5.0 * randomVariation(1.0, 2.5),
            confidence: 0.4,
            timeframe: "Market dependent",
            reasoning: "Special cards are highly volatile based on authenticity and rarity",
            factors: [
                PriceFactor(name: "Authenticity verification", impact: 0.4, description: "Verified signatures command premium"),
                PriceFactor(name: "Extreme rarity", impact: 0.4, description: "Very limited special releases"),
                PriceFactor(name: "Market manipulation", impact: 0.2, description: "Artificial scarcity by resellers")
            ],
            isIncreasing: true,
            volatility: 0.8
        )
        predictions.append(specialCard)
        
        return predictions
    }
    
    // MARK: - Digital Content Predictions
    private func predictDigitalPrices(artist: FanArtist) async -> [PricePrediction] {
        let baseDigitalPrice = 12.0
        
        let digitalContent = PricePrediction(
            itemType: "Digital Album/Content",
            artistName: artist.name,
            category: .digitalContent,
            currentPrice: baseDigitalPrice,
            predictedPrice: baseDigitalPrice * randomVariation(0.95, 1.1),
            confidence: 0.9,
            timeframe: "Very stable",
            reasoning: "Digital content prices are highly stable and controlled",
            factors: [
                PriceFactor(name: "Platform control", impact: 0.7, description: "Streaming platforms set consistent pricing"),
                PriceFactor(name: "No scarcity", impact: 0.2, description: "Unlimited digital copies available"),
                PriceFactor(name: "Promotional pricing", impact: 0.1, description: "Occasional discounts and promotions")
            ],
            isIncreasing: false,
            volatility: 0.05
        )
        
        return [digitalContent]
    }
    
    // MARK: - Price Alert Generation
    private func generatePriceAlerts() async {
        var newAlerts: [PriceAlert] = []
        
        for prediction in predictions {
            // High volatility alert
            if prediction.volatility > 0.4 {
                newAlerts.append(PriceAlert(
                    prediction: prediction,
                    alertType: .volatility,
                    message: "⚠️ \(prediction.itemType) for \(prediction.artistName) shows high price volatility. Consider timing your purchase carefully.",
                    urgency: .medium
                ))
            }
            
            // Increasing price alert
            if prediction.isIncreasing && prediction.predictedPrice > prediction.currentPrice * 1.2 {
                newAlerts.append(PriceAlert(
                    prediction: prediction,
                    alertType: .increasing,
                    message: "⬆️ \(prediction.itemType) prices expected to rise by \(Int((prediction.predictedPrice / prediction.currentPrice - 1) * 100))%. Consider buying soon!",
                    urgency: .high
                ))
            }
            
            // Good deal alert
            if !prediction.isIncreasing && prediction.currentPrice > prediction.predictedPrice * 1.1 {
                newAlerts.append(PriceAlert(
                    prediction: prediction,
                    alertType: .goodDeal,
                    message: "💰 Good time to buy \(prediction.itemType)! Prices may drop in the \(prediction.timeframe.lowercased()).",
                    urgency: .low
                ))
            }
        }
        
        self.alerts = newAlerts.sorted { $0.urgency.rawValue > $1.urgency.rawValue }
    }
    
    // MARK: - Helper Functions
    private func randomVariation(_ min: Double, _ max: Double) -> Double {
        return Double.random(in: min...max)
    }
    
    private func adjustmentForPopularity(_ artist: FanArtist) -> Double {
        switch artist.priorityRank {
        case 1: return 0.3  // Top bias gets highest price impact
        case 2: return 0.2
        case 3: return 0.1
        default: return 0.05
        }
    }
    
    // MARK: - Specific Price Prediction
    func predictSpecificItem(
        itemName: String,
        artistName: String,
        category: FanCategory,
        currentPrice: Double?
    ) async -> PricePrediction? {
        
        let basePrice = currentPrice ?? historicalData.getAveragePrice(for: category, artist: artistName)
        
        return PricePrediction(
            itemType: itemName,
            artistName: artistName,
            category: category,
            currentPrice: basePrice,
            predictedPrice: basePrice * randomVariation(0.9, 1.3),
            confidence: 0.7,
            timeframe: "Next 30-60 days",
            reasoning: "Based on similar items and market trends",
            factors: [
                PriceFactor(name: "Market trends", impact: 0.4, description: "General market conditions"),
                PriceFactor(name: "Item specifics", impact: 0.3, description: "Unique characteristics of this item"),
                PriceFactor(name: "Artist popularity", impact: 0.3, description: "Artist's current market standing")
            ],
            isIncreasing: Bool.random(),
            volatility: Double.random(in: 0.1...0.5)
        )
    }
    
    // MARK: - Caching
    private func cachePredictions() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(predictions) {
            userDefaults.set(data, forKey: "cached_price_predictions")
        }
        if let alertData = try? encoder.encode(alerts) {
            userDefaults.set(alertData, forKey: "cached_price_alerts")
        }
    }
    
    private func loadCachedPredictions() {
        let decoder = JSONDecoder()
        if let data = userDefaults.data(forKey: "cached_price_predictions"),
           let cached = try? decoder.decode([PricePrediction].self, from: data) {
            self.predictions = cached
        }
        if let alertData = userDefaults.data(forKey: "cached_price_alerts"),
           let cachedAlerts = try? decoder.decode([PriceAlert].self, from: alertData) {
            self.alerts = cachedAlerts
        }
    }
    
    func dismissAlert(_ alert: PriceAlert) {
        alerts.removeAll { $0.id == alert.id }
    }
}

// MARK: - Price History Manager
class PriceHistoryManager {
    private let mockHistoricalData: [String: [FanCategory: Double]] = [
        "BTS": [
            .albumHunting: 28.0,
            .concertPrep: 180.0,
            .merchHaul: 45.0,
            .photocardCollecting: 12.0,
            .digitalContent: 12.99
        ],
        "BLACKPINK": [
            .albumHunting: 25.0,
            .concertPrep: 160.0,
            .merchHaul: 40.0,
            .photocardCollecting: 10.0,
            .digitalContent: 12.99
        ],
        "NewJeans": [
            .albumHunting: 22.0,
            .concertPrep: 120.0,
            .merchHaul: 35.0,
            .photocardCollecting: 8.0,
            .digitalContent: 12.99
        ]
    ]
    
    func getAverageAlbumPrice(for artistName: String) -> Double {
        return mockHistoricalData[artistName]?[.albumHunting] ?? 25.0
    }
    
    func getAverageConcertPrice(for artistName: String) -> Double {
        return mockHistoricalData[artistName]?[.concertPrep] ?? 150.0
    }
    
    func getAveragePrice(for category: FanCategory, artist: String) -> Double {
        return mockHistoricalData[artist]?[category] ?? {
            switch category {
            case .albumHunting: return 25.0
            case .concertPrep: return 150.0
            case .merchHaul: return 35.0
            case .photocardCollecting: return 8.0
            case .digitalContent: return 12.99
            default: return 20.0
            }
        }()
    }
}

// MARK: - Supporting Models
struct PricePrediction: Identifiable, Codable {
    var id = UUID()
    let itemType: String
    let artistName: String
    let category: FanCategory
    let currentPrice: Double
    let predictedPrice: Double
    let confidence: Double
    let timeframe: String
    let reasoning: String
    let factors: [PriceFactor]
    let isIncreasing: Bool
    let volatility: Double // 0.0 to 1.0
    
    var priceChange: Double {
        return predictedPrice - currentPrice
    }
    
    var priceChangePercentage: Double {
        guard currentPrice > 0 else { return 0 }
        return (predictedPrice / currentPrice - 1) * 100
    }
    
    var confidenceText: String {
        switch confidence {
        case 0.8...1.0: return "High Confidence"
        case 0.6..<0.8: return "Medium Confidence"
        case 0.4..<0.6: return "Low Confidence"
        default: return "Very Uncertain"
        }
    }
    
    var volatilityText: String {
        switch volatility {
        case 0.6...1.0: return "Very Volatile"
        case 0.4..<0.6: return "Volatile"
        case 0.2..<0.4: return "Moderate"
        default: return "Stable"
        }
    }
    
    var trendIcon: String {
        if abs(priceChangePercentage) < 5 {
            return "minus" // Stable
        } else {
            return isIncreasing ? "arrow.up" : "arrow.down"
        }
    }
    
    var trendColor: Color {
        if abs(priceChangePercentage) < 5 {
            return .blue // Stable
        } else {
            return isIncreasing ? .red : .green
        }
    }
}

struct PriceFactor: Codable {
    let name: String
    let impact: Double // 0.0 to 1.0
    let description: String
    
    var impactText: String {
        switch impact {
        case 0.7...1.0: return "Major Impact"
        case 0.4..<0.7: return "Moderate Impact"
        case 0.2..<0.4: return "Minor Impact"
        default: return "Minimal Impact"
        }
    }
}

struct PriceAlert: Identifiable, Codable {
    var id = UUID()
    let prediction: PricePrediction
    let alertType: AlertType
    let message: String
    let urgency: AlertUrgency
    var createdAt = Date()
    
    enum AlertType: String, Codable {
        case volatility, increasing, goodDeal, decreasing
        
        var icon: String {
            switch self {
            case .volatility: return "exclamationmark.triangle"
            case .increasing: return "arrow.up.circle"
            case .goodDeal: return "tag.circle"
            case .decreasing: return "arrow.down.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .volatility: return .orange
            case .increasing: return .red
            case .goodDeal: return .green
            case .decreasing: return .blue
            }
        }
    }
    
    enum AlertUrgency: Int, Codable {
        case low = 1, medium = 2, high = 3
        
        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .orange
            case .high: return .red
            }
        }
        
        var text: String {
            switch self {
            case .low: return "Low Priority"
            case .medium: return "Medium Priority"
            case .high: return "High Priority"
            }
        }
    }
}
