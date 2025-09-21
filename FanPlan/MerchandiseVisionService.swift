import Foundation
import SwiftUI
import Vision
import CoreML
import UIKit

// MARK: - Merchandise Vision Recognition Service
@MainActor
class MerchandiseVisionService: ObservableObject {
    static let shared = MerchandiseVisionService()
    
    @Published var recognizedItems: [RecognizedItem] = []
    @Published var isProcessing = false
    @Published var lastProcessedImage: UIImage?
    @Published var processingProgress: Double = 0.0
    
    private let merchandiseClassifier: VNCoreMLModel?
    private let textRecognizer = VNRecognizeTextRequest()
    
    private init() {
        // Initialize Core ML model (you would need to train and add a custom model)
        // For now, we'll use Vision's built-in capabilities
        merchandiseClassifier = nil
        setupTextRecognizer()
    }
    
    // MARK: - Main Image Processing
    func processImage(_ image: UIImage, for artist: FanArtist? = nil) async -> MerchandiseRecognitionResult {
        isProcessing = true
        processingProgress = 0.0
        lastProcessedImage = image
        
        guard let cgImage = image.cgImage else {
            isProcessing = false
            return MerchandiseRecognitionResult(success: false, error: "Invalid image")
        }
        
        var recognizedItems: [RecognizedItem] = []
        
        // Step 1: Object Detection (30%)
        processingProgress = 0.1
        let objectDetectionResults = await detectObjects(in: cgImage)
        recognizedItems.append(contentsOf: objectDetectionResults)
        processingProgress = 0.3
        
        // Step 2: Text Recognition (60%)
        let textResults = await recognizeText(in: cgImage)
        recognizedItems.append(contentsOf: textResults)
        processingProgress = 0.6
        
        // Step 3: Classification Enhancement (80%)
        let enhancedResults = await enhanceWithClassification(recognizedItems, image: cgImage, artist: artist)
        recognizedItems = enhancedResults
        processingProgress = 0.8
        
        // Step 4: Smart Categorization (100%)
        let categorizedResults = categorizeItems(recognizedItems, artist: artist)
        processingProgress = 1.0
        
        self.recognizedItems = categorizedResults
        
        // Generate purchase suggestion
        let suggestion = generatePurchaseSuggestion(from: categorizedResults, artist: artist)
        
        isProcessing = false
        
        return MerchandiseRecognitionResult(
            success: true,
            recognizedItems: categorizedResults,
            suggestedPurchase: suggestion,
            confidence: calculateOverallConfidence(categorizedResults)
        )
    }
    
    // MARK: - Object Detection
    private func detectObjects(in cgImage: CGImage) async -> [RecognizedItem] {
        return await withCheckedContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                guard let results = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let items = results.compactMap { observation -> RecognizedItem? in
                    guard observation.confidence > 0.5 else { return nil }
                    
                    // Map generic objects to K-pop merchandise categories
                    let category = self.mapObjectToMerchandiseCategory(observation.identifier)
                    
                    return RecognizedItem(
                        type: .object,
                        text: observation.identifier,
                        category: category,
                        confidence: Double(observation.confidence),
                        boundingBox: CGRect.zero,
                        source: "Object Detection"
                    )
                }
                
                continuation.resume(returning: items)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    // MARK: - Text Recognition
    private func recognizeText(in cgImage: CGImage) async -> [RecognizedItem] {
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let results = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var items: [RecognizedItem] = []
                
                for observation in results {
                    guard let topCandidate = observation.topCandidates(1).first,
                          topCandidate.confidence > 0.7 else { continue }
                    
                    let text = topCandidate.string
                    
                    // Check if text contains K-pop related keywords
                    let category = self.classifyTextAsMerchandise(text)
                    if category != .other {
                        items.append(RecognizedItem(
                            type: .text,
                            text: text,
                            category: category,
                            confidence: Double(topCandidate.confidence),
                            boundingBox: observation.boundingBox,
                            source: "Text Recognition"
                        ))
                    }
                    
                    // Extract price information
                    if let price = self.extractPrice(from: text) {
                        items.append(RecognizedItem(
                            type: .price,
                            text: "$\(price)",
                            category: .other,
                            confidence: Double(topCandidate.confidence),
                            boundingBox: observation.boundingBox,
                            source: "Price Detection",
                            extractedPrice: price
                        ))
                    }
                    
                    // Extract artist names
                    if let artist = self.extractArtistName(from: text) {
                        items.append(RecognizedItem(
                            type: .artist,
                            text: artist,
                            category: .other,
                            confidence: Double(topCandidate.confidence),
                            boundingBox: observation.boundingBox,
                            source: "Artist Detection"
                        ))
                    }
                }
                
                continuation.resume(returning: items)
            }
            
            // Configure for better text recognition
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    // MARK: - Classification Enhancement
    private func enhanceWithClassification(_ items: [RecognizedItem], image: CGImage, artist: FanArtist?) async -> [RecognizedItem] {
        // In a real implementation, you would use a custom trained model here
        // For now, we'll enhance with rule-based logic
        
        var enhancedItems = items
        
        // Group items by proximity (items close together are likely related)
        let groupedItems = groupItemsByProximity(items)
        
        for group in groupedItems {
            // If we find both an object and text in the same area, combine their confidence
            if let objectItem = group.first(where: { $0.type == .object }),
               let textItem = group.first(where: { $0.type == .text }) {
                
                // Create a combined item with higher confidence
                let combinedConfidence = (objectItem.confidence + textItem.confidence) / 2.0
                let enhancedCategory = refineCategory(objectItem.category, textItem.category)
                
                let combinedItem = RecognizedItem(
                    type: .combined,
                    text: "\(objectItem.text) - \(textItem.text)",
                    category: enhancedCategory,
                    confidence: combinedConfidence,
                    boundingBox: unionBoundingBox(objectItem.boundingBox, textItem.boundingBox),
                    source: "Combined Analysis"
                )
                
                enhancedItems.append(combinedItem)
            }
        }
        
        return enhancedItems
    }
    
    // MARK: - Smart Categorization
    private func categorizeItems(_ items: [RecognizedItem], artist: FanArtist?) -> [RecognizedItem] {
        return items.map { item in
            var categorizedItem = item
            
            // Enhance categorization based on context
            if let artist = artist {
                categorizedItem.suggestedArtist = artist.name
                
                // If text contains artist name, boost confidence
                if item.text.localizedCaseInsensitiveContains(artist.name) {
                    categorizedItem.confidence = min(categorizedItem.confidence + 0.2, 1.0)
                }
            }
            
            // Add smart category suggestions
            categorizedItem.smartSuggestions = generateSmartSuggestions(for: item)
            
            return categorizedItem
        }
    }
    
    // MARK: - Helper Functions
    private func setupTextRecognizer() {
        textRecognizer.recognitionLevel = .accurate
        textRecognizer.usesLanguageCorrection = true
    }
    
    private func mapObjectToMerchandiseCategory(_ objectType: String) -> FanCategory {
        let lowercaseType = objectType.lowercased()
        
        switch lowercaseType {
        case let type where type.contains("shirt") || type.contains("clothing"):
            return .merch
        case let type where type.contains("book") || type.contains("magazine"):
            return .albums
        case let type where type.contains("bag") || type.contains("backpack"):
            return .merch
        case let type where type.contains("poster"):
            return .merch
        case let type where type.contains("disc") || type.contains("cd"):
            return .albums
        default:
            return .other
        }
    }
    
    private func classifyTextAsMerchandise(_ text: String) -> FanCategory {
        let lowercaseText = text.lowercased()
        
        // K-pop specific keywords
        let albumKeywords = ["album", "ep", "single", "mini album", "full album", "ost", "soundtrack"]
        let merchKeywords = ["hoodie", "shirt", "sweater", "bag", "poster", "keychain", "badge", "pin", "sticker"]
        let photocardKeywords = ["photocard", "pc", "photo card", "trading card", "postcard"]
        let digitalKeywords = ["digital", "stream", "download", "online"]
        
        for keyword in albumKeywords {
            if lowercaseText.contains(keyword) {
                return .albums
            }
        }
        
        for keyword in merchKeywords {
            if lowercaseText.contains(keyword) {
                return .merch
            }
        }
        
        for keyword in photocardKeywords {
            if lowercaseText.contains(keyword) {
                return .albums
            }
        }
        
        for keyword in digitalKeywords {
            if lowercaseText.contains(keyword) {
                return .subscriptions
            }
        }
        
        return .other
    }
    
    private func extractPrice(from text: String) -> Double? {
        // Regular expression to find price patterns
        let pricePattern = #"[$£€¥₩]?\s?([0-9]+(?:[.,][0-9]{2})?)"#
        
        do {
            let regex = try NSRegularExpression(pattern: pricePattern, options: [])
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            
            for match in matches {
                if let range = Range(match.range(at: 1), in: text) {
                    let priceString = String(text[range]).replacingOccurrences(of: ",", with: "")
                    if let price = Double(priceString) {
                        return price
                    }
                }
            }
        } catch {
            print("Error in price extraction: \(error)")
        }
        
        return nil
    }
    
    private func extractArtistName(from text: String) -> String? {
        // Common K-pop artist names to look for
        let knownArtists = [
            "BTS", "BLACKPINK", "TWICE", "Red Velvet", "aespa", "ITZY", "i-dle",
            "NewJeans", "IVE", "LE SSERAFIM", "SEVENTEEN", "Stray Kids", "ATEEZ",
            "MAMAMOO", "EVERGLOW", "NMIXX", "Girls' Generation", "SHINee", "NCT",
            "ENHYPEN", "TXT", "TREASURE", "WINNER", "iKON"
        ]
        
        let lowercaseText = text.lowercased()
        
        for artist in knownArtists {
            if lowercaseText.contains(artist.lowercased()) {
                return artist
            }
        }
        
        return nil
    }
    
    private func groupItemsByProximity(_ items: [RecognizedItem]) -> [[RecognizedItem]] {
        // Simple proximity grouping based on bounding box centers
        var groups: [[RecognizedItem]] = []
        var processedItems: Set<UUID> = []
        
        for item in items {
            if processedItems.contains(item.id) { continue }
            
            var currentGroup = [item]
            processedItems.insert(item.id)
            
            let itemCenter = CGPoint(
                x: item.boundingBox.midX,
                y: item.boundingBox.midY
            )
            
            // Find nearby items (within 0.1 normalized distance)
            for otherItem in items {
                if processedItems.contains(otherItem.id) { continue }
                
                let otherCenter = CGPoint(
                    x: otherItem.boundingBox.midX,
                    y: otherItem.boundingBox.midY
                )
                
                let distance = sqrt(
                    pow(itemCenter.x - otherCenter.x, 2) + 
                    pow(itemCenter.y - otherCenter.y, 2)
                )
                
                if distance < 0.15 { // Threshold for "nearby"
                    currentGroup.append(otherItem)
                    processedItems.insert(otherItem.id)
                }
            }
            
            groups.append(currentGroup)
        }
        
        return groups
    }
    
    private func refineCategory(_ category1: FanCategory, _ category2: FanCategory) -> FanCategory {
        // Prioritize more specific categories
        if category1 != .other && category2 == .other {
            return category1
        } else if category2 != .other && category1 == .other {
            return category2
        } else if category1 == category2 {
            return category1
        } else {
            return category1 // Default to first category if different
        }
    }
    
    private func unionBoundingBox(_ box1: CGRect, _ box2: CGRect) -> CGRect {
        return box1.union(box2)
    }
    
    private func calculateOverallConfidence(_ items: [RecognizedItem]) -> Double {
        guard !items.isEmpty else { return 0.0 }
        
        let totalConfidence = items.reduce(0.0) { $0 + $1.confidence }
        return totalConfidence / Double(items.count)
    }
    
    private func generateSmartSuggestions(for item: RecognizedItem) -> [String] {
        switch item.category {
        case .albums:
            return ["Add to album collection goal", "Check for limited editions", "Look for signed copies"]
        case .merch:
            return ["Compare prices online", "Check official store", "Look for bundle deals"]
        case .subscriptions:
            return ["Check streaming platforms", "Look for exclusive content", "Compare digital vs physical"]
        default:
            return ["Research item", "Compare prices", "Check authenticity"]
        }
    }
    
    private func generatePurchaseSuggestion(
        from items: [RecognizedItem], 
        artist: FanArtist?
    ) -> PurchaseSuggestion? {
        
        // Find the most confident item with a price
        guard let mainItem = items.max(by: { $0.confidence < $1.confidence }),
              let price = items.first(where: { $0.extractedPrice != nil })?.extractedPrice else {
            return nil
        }
        
        let artistName = items.first(where: { $0.type == .artist })?.text ?? artist?.name ?? "Unknown Artist"
        
        return PurchaseSuggestion(
            description: mainItem.text,
            category: mainItem.category,
            artistName: artistName,
            estimatedPrice: price,
            confidence: mainItem.confidence,
            notes: "Detected from image: \(mainItem.source)"
        )
    }
}

// MARK: - Supporting Models
struct RecognizedItem: Identifiable {
    let id = UUID()
    let type: RecognitionType
    let text: String
    let category: FanCategory
    var confidence: Double
    let boundingBox: CGRect
    let source: String
    let extractedPrice: Double?
    var suggestedArtist: String?
    var smartSuggestions: [String]
    
    init(type: RecognitionType, text: String, category: FanCategory, confidence: Double, boundingBox: CGRect, source: String, extractedPrice: Double? = nil, suggestedArtist: String? = nil, smartSuggestions: [String] = []) {
        self.type = type
        self.text = text
        self.category = category
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.source = source
        self.extractedPrice = extractedPrice
        self.suggestedArtist = suggestedArtist
        self.smartSuggestions = smartSuggestions
    }
    
    var confidenceText: String {
        return "\(Int(confidence * 100))% confident"
    }
    
    var typeIcon: String {
        switch type {
        case .object: return "cube"
        case .text: return "textformat"
        case .price: return "dollarsign.circle"
        case .artist: return "person.circle"
        case .combined: return "sparkles"
        }
    }
}

enum RecognitionType {
    case object, text, price, artist, combined
}

struct MerchandiseRecognitionResult {
    let success: Bool
    let recognizedItems: [RecognizedItem]?
    let suggestedPurchase: PurchaseSuggestion?
    let confidence: Double?
    let error: String?
    
    init(success: Bool, recognizedItems: [RecognizedItem]? = nil, suggestedPurchase: PurchaseSuggestion? = nil, confidence: Double? = nil, error: String? = nil) {
        self.success = success
        self.recognizedItems = recognizedItems
        self.suggestedPurchase = suggestedPurchase
        self.confidence = confidence
        self.error = error
    }
}

struct PurchaseSuggestion {
    let description: String
    let category: FanCategory
    let artistName: String
    let estimatedPrice: Double
    let confidence: Double
    let notes: String?
    
    func toFanPurchase(userId: UUID, artistId: UUID) -> FanPurchase {
        return FanPurchase(
            id: UUID(),
            artistId: artistId,
            artistName: artistName,
            amount: estimatedPrice,
            category: category,
            description: description,
            contextNote: notes,
            isComebackRelated: false,
            venueLocation: nil,
            albumVersion: nil,
            purchaseDate: Date()
        )
    }
}
