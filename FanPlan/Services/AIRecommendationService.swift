import Foundation

// MARK: - AI Recommendation Service
@MainActor
class AIRecommendationService: ObservableObject {
    static let shared = AIRecommendationService()
    
    private let supabaseURL = Secrets.supabaseURL
    private let supabaseAnonKey = Secrets.supabaseAnonKey
    private let maxTokens = 100
    private let cacheKey = "ai_recommendations_cache"
    
    private init() {}
    
    // MARK: - Main Recommendation Function
    func generatePersonalizedRecommendation(
        itemName: String,
        artist: String,
        price: Double,
        topPriority: String,
        recentSpendBehavior: String
    ) async -> String {
        
        // Check cache first
        let cacheKey = "\(itemName.lowercased())_\(topPriority.lowercased())"
        if let cachedRecommendation = getCachedRecommendation(for: cacheKey) {
            print("📋 Using cached recommendation for: \(cacheKey)")
            return cachedRecommendation
        }
        
        // Try AI generation
        do {
            let aiRecommendation = try await callOpenAIAPI(
                itemName: itemName,
                artist: artist,
                price: price,
                topPriority: topPriority,
                recentSpendBehavior: recentSpendBehavior
            )
            
            // Cache successful result
            cacheRecommendation(aiRecommendation, for: cacheKey)
            return aiRecommendation
            
        } catch {
            print("🤖 AI API failed: \(error.localizedDescription)")
            // Fallback to static logic
            return generateStaticRecommendation(
                itemName: itemName,
                price: price,
                topPriority: topPriority,
                recentSpendBehavior: recentSpendBehavior
            )
        }
    }
    
    // MARK: - OpenAI API Integration
    private func callOpenAIAPI(
        itemName: String,
        artist: String,
        price: Double,
        topPriority: String,
        recentSpendBehavior: String
    ) async throws -> String {
        
        let prompt = constructPrompt(
            itemName: itemName,
            artist: artist,
            price: price,
            topPriority: topPriority,
            recentSpendBehavior: recentSpendBehavior
        )
        
        let url = URL(string: "\(supabaseURL)/functions/v1/openai-proxy")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": maxTokens,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIRecommendationError.apiError
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let message = openAIResponse.choices.first?.message.content else {
            throw AIRecommendationError.invalidResponse
        }
        
        // Ensure response is concise (max 2 sentences) and has emoji
        let cleanedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let truncatedMessage = truncateToTwoSentences(cleanedMessage)
        
        // Add fallback emoji if none detected
        if !containsEmoji(truncatedMessage) {
            return truncatedMessage + " 💖"
        }
        
        return truncatedMessage
    }
    
    // MARK: - Prompt Construction
    private func constructPrompt(
        itemName: String,
        artist: String,
        price: Double,
        topPriority: String,
        recentSpendBehavior: String
    ) -> String {
        return """
        You are a warm, helpful K-pop fan life coach. The fan is thinking about buying:
        - Item: \(itemName) by \(artist) ($\(price))
        - Their top priority is: \(topPriority).
        \(recentSpendBehavior.isEmpty ? "" : "They recently \(recentSpendBehavior).")

        Give a short, friendly suggestion (1–2 sentences) to help them decide whether this aligns with their fan goals. Be encouraging and use casual K-pop lingo. End with a cute emoji.
        """
    }
    
    // MARK: - Fallback Static Logic
    private func generateStaticRecommendation(
        itemName: String,
        price: Double,
        topPriority: String,
        recentSpendBehavior: String
    ) -> String {
        
        let priority = topPriority.lowercased()
        let hasRecentActivity = !recentSpendBehavior.isEmpty
        
        if priority.contains("high") || priority.contains("album") || priority.contains("concert") {
            return hasRecentActivity 
                ? "This totally matches your top priority! You recently \(recentSpendBehavior), so just make sure this fits your fan budget 💕🎟️"
                : "Yasss! This aligns perfectly with your highest priority - go for it bestie! ✨🤩"
                
        } else if priority.contains("medium") || priority.contains("merch") {
            return hasRecentActivity
                ? "This is a medium priority for you. You recently \(recentSpendBehavior) - maybe check if any high priority drops are coming up first? 🤔💭"
                : "This fits your medium priority goals! Just make sure it won't mess with your main fan priorities 🛍️💖"
                
        } else {
            return hasRecentActivity
                ? "This seems like lower priority hun. You recently \(recentSpendBehavior) - maybe save for your bias instead? 🥺💙"
                : "This might be worth waiting on! Focus on your top fan goals first and come back to this later 🎯✨"
        }
    }
    
    // MARK: - Caching System
    private func getCachedRecommendation(for key: String) -> String? {
        let cache = UserDefaults.standard.dictionary(forKey: cacheKey) as? [String: [String: Any]] ?? [:]
        
        guard let entry = cache[key],
              let recommendation = entry["recommendation"] as? String,
              let timestamp = entry["timestamp"] as? Date else {
            return nil
        }
        
        // Cache expires after 24 hours
        if Date().timeIntervalSince(timestamp) > 86400 {
            removeCachedRecommendation(for: key)
            return nil
        }
        
        return recommendation
    }
    
    private func cacheRecommendation(_ recommendation: String, for key: String) {
        var cache = UserDefaults.standard.dictionary(forKey: cacheKey) as? [String: [String: Any]] ?? [:]
        
        cache[key] = [
            "recommendation": recommendation,
            "timestamp": Date()
        ]
        
        UserDefaults.standard.set(cache, forKey: cacheKey)
    }
    
    private func removeCachedRecommendation(for key: String) {
        var cache = UserDefaults.standard.dictionary(forKey: cacheKey) as? [String: [String: Any]] ?? [:]
        cache.removeValue(forKey: key)
        UserDefaults.standard.set(cache, forKey: cacheKey)
    }
    
    // MARK: - Utility Functions
    private func truncateToTwoSentences(_ text: String) -> String {
        let sentences = text.components(separatedBy: ". ")
        if sentences.count <= 2 {
            return text
        }
        return sentences.prefix(2).joined(separator: ". ") + "."
    }
    
    private func containsEmoji(_ text: String) -> Bool {
        return text.unicodeScalars.contains { scalar in
            scalar.properties.isEmoji
        }
    }
}

// MARK: - Supporting Models
struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

struct OpenAIMessage: Codable {
    let content: String
}

enum AIRecommendationError: Error {
    case apiError
    case invalidResponse
    case networkError
}