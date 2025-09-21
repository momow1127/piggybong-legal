import Foundation
import SwiftUI

// MARK: - Budget Chat Assistant Service
@MainActor
class BudgetChatService: ObservableObject {
    static let shared = BudgetChatService()
    
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var currentTyping: String = ""
    
    private let supabase = SupabaseService.shared
    private let maxMessagesInContext = 20
    
    private init() {
        setupInitialMessage()
    }
    
    // MARK: - Chat Interface
    func sendMessage(_ text: String, userData: FanDashboardData) async {
        // Add user message
        let userMessage = ChatMessage(
            content: text,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        isLoading = true
        
        do {
            let response = try await generateAIResponse(for: text, with: userData)
            
            // Simulate typing effect
            await simulateTypingEffect(response)
            
            let aiMessage = ChatMessage(
                content: response,
                isUser: false,
                timestamp: Date(),
                suggestions: generateFollowUpSuggestions(for: text, response: response, userData: userData)
            )
            messages.append(aiMessage)
            
        } catch {
            let errorMessage = ChatMessage(
                content: "Sorry, I'm having trouble connecting right now. Let me help you with some quick budget tips instead!",
                isUser: false,
                timestamp: Date(),
                suggestions: getOfflineSuggestions()
            )
            messages.append(errorMessage)
        }
        
        isLoading = false
        currentTyping = ""
        
        // Keep conversation manageable
        if messages.count > maxMessagesInContext {
            messages.removeFirst(messages.count - maxMessagesInContext)
        }
    }
    
    // MARK: - AI Integration via Supabase Edge Function
    private func generateAIResponse(for userMessage: String, with userData: FanDashboardData) async throws -> String {
        let systemPrompt = buildSystemPrompt(with: userData)
        let conversationHistory = buildConversationHistory()
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "\(conversationHistory)\n\nUser: \(userMessage)"]
            ],
            "max_tokens": 450,
            "temperature": 0.6
        ]
        
        do {
            struct OpenAIResponse: Codable {
                let choices: [OpenAIChoice]
                let error: String?
                
                struct OpenAIChoice: Codable {
                    let message: OpenAIMessage
                    
                    struct OpenAIMessage: Codable {
                        let content: String
                    }
                }
            }
            
            let response: OpenAIResponse = try await supabase.callFunction(
                functionName: "openai-proxy", 
                parameters: requestBody
            )
            
            if let error = response.error {
                print("OpenAI API Error: \(error)")
                return generateOfflineResponse(for: userMessage, with: userData)
            }
            
            return response.choices.first?.message.content ?? "I'm not sure how to help with that. Could you try rephrasing?"
            
        } catch {
            print("AI Chat Error: \(error)")
            return generateOfflineResponse(for: userMessage, with: userData)
        }
    }
    
    // MARK: - Context Building
    private func buildSystemPrompt(with userData: FanDashboardData) -> String {
        let totalBudget = userData.totalMonthlyBudget
        let totalSpent = userData.totalMonthSpent
        let remaining = totalBudget - totalSpent
        
        let topArtists = userData.fanArtists.prefix(3).map { "\($0.name) (Priority #\($0.priorityRank))" }.joined(separator: ", ")
        
        let urgentGoals = userData.urgentGoals.map { "\($0.name) - \(Int($0.progressPercentage))% complete" }.joined(separator: ", ")
        
        return """
        You are PiggyBot, an expert K-pop budget assistant with deep knowledge of the industry. You help fans make smart financial decisions while supporting their favorite artists.
        
        User's Current Situation:
        - Monthly Budget: $\(Int(totalBudget))
        - Spent This Month: $\(Int(totalSpent))
        - Remaining: $\(Int(remaining))
        - Top Artists: \(topArtists)
        - Urgent Goals: \(urgentGoals.isEmpty ? "None" : urgentGoals)
        
        Your expertise includes:
        - Album types (standard, deluxe, limited edition pricing patterns)
        - Concert ticketing strategies (presales, fan club benefits)
        - Merchandise market trends and resale values
        - Comeback prediction patterns and typical costs
        - Regional price differences and shipping considerations
        
        Communication style:
        - Use K-pop terminology naturally (bias, ult, comeback, era, photocard, etc.)
        - Reference specific industry patterns (comeback cycles, tour announcements)
        - Provide budget allocation percentages for different spending categories
        - Give time-sensitive advice (presale dates, limited releases)
        - Balance fan enthusiasm with practical financial wisdom
        
        Always provide:
        1. Specific dollar amounts or percentages
        2. Timeline-based recommendations
        3. One actionable next step
        
        Keep responses under 120 words for mobile readability.
        """
    }
    
    private func buildConversationHistory() -> String {
        let recentMessages = messages.suffix(8) // Increased for better context
        let context = recentMessages.map { message in
            let role = message.isUser ? "User" : "Assistant"
            return "\(role): \(message.content)"
        }.joined(separator: "\n")
        
        // Add context separator if there's history
        return recentMessages.isEmpty ? "" : "Previous conversation context:\n\(context)\n\nCurrent question:"
    }
    
    // MARK: - Offline Fallback
    private func generateOfflineResponse(for userMessage: String, with userData: FanDashboardData) -> String {
        let lowercaseMessage = userMessage.lowercased()
        
        // Budget status queries
        if lowercaseMessage.contains("budget") || lowercaseMessage.contains("money") || lowercaseMessage.contains("spent") {
            let remaining = userData.totalMonthlyBudget - userData.totalMonthSpent
            let percentageUsed = (userData.totalMonthSpent / userData.totalMonthlyBudget) * 100
            
            if remaining < 20 {
                return "Budget alert! Only $\(Int(remaining)) left this month (\(Int(percentageUsed))% used). Focus on your #1 bias or essential preorders. Consider setting aside $\(Int(remaining * 0.7)) for emergencies and $\(Int(remaining * 0.3)) for must-haves."
            } else if remaining < 50 {
                return "You have $\(Int(remaining)) remaining (\(Int(percentageUsed))% budget used). Perfect for 1-2 albums or targeted merch. Prioritize limited editions or items that typically sell out first."
            } else {
                return "Great budget position! $\(Int(remaining)) available (\(Int(100 - percentageUsed))% remaining). Consider allocating 60% for planned purchases, 25% for surprise drops, and 15% savings buffer."
            }
        }
        
        // Goal-related queries
        if lowercaseMessage.contains("goal") || lowercaseMessage.contains("save") || lowercaseMessage.contains("concert") {
            if let topGoal = userData.urgentGoals.first {
                return "Your \(topGoal.name) goal is \(Int(topGoal.progressPercentage))% complete! You need $\(Int(topGoal.remainingAmount)) more. Try saving $\(Int(topGoal.remainingAmount / 4)) per week to stay on track!"
            } else {
                return "Great job staying on top of your goals! Consider setting up a new savings goal for upcoming comebacks or concerts. What artist event are you most excited about?"
            }
        }
        
        // Artist-related queries
        if lowercaseMessage.contains("artist") || lowercaseMessage.contains("bias") || lowercaseMessage.contains("group") {
            if let topBias = userData.topBias {
                return "Your top bias is \(topBias.name)! You've allocated $\(Int(topBias.monthlyAllocation)) monthly for them and spent $\(Int(topBias.monthSpent)) so far. \(topBias.budgetStatus.message)"
            } else {
                return "I'd love to help you plan spending for your favorite artists! Which K-pop group or artist are you most interested in right now?"
            }
        }
        
        // Default helpful response
        return "I'm here to help you manage your K-pop budget! You can ask me about your spending, goals, favorite artists, or get advice on upcoming purchases. What would you like to know?"
    }
    
    // MARK: - Suggestions
    private func generateFollowUpSuggestions(for userMessage: String, response: String, userData: FanDashboardData? = nil) -> [String] {
        let lowercaseMessage = userMessage.lowercased()
        let lowercaseResponse = response.lowercased()
        
        // Context-aware suggestions based on message content
        if lowercaseMessage.contains("budget") && lowercaseResponse.contains("remaining") {
            return ["Plan my next purchase", "Album vs merch priorities", "Comeback preparation tips"]
        } else if lowercaseMessage.contains("concert") || lowercaseMessage.contains("tour") {
            return ["Ticket buying strategy", "Travel budget planning", "Concert outfit budget"]
        } else if lowercaseMessage.contains("album") || lowercaseMessage.contains("preorder") {
            return ["Preorder vs retail timing", "Version comparison help", "Shipping cost tips"]
        } else if lowercaseMessage.contains("goal") {
            return ["Adjust saving timeline", "Break down goal steps", "Find similar goals"]
        } else if lowercaseMessage.contains("artist") || lowercaseMessage.contains("bias") {
            return ["Comeback predictions", "Compare artist costs", "Fan benefits analysis"]
        } else {
            // Default suggestions based on user's current financial state
            let remaining = (userData?.totalMonthlyBudget ?? 0) - (userData?.totalMonthSpent ?? 0)
            if remaining > 100 {
                return ["Plan major purchase", "Set new savings goal", "Explore new artists"]
            } else {
                return ["Money-saving tips", "Prioritize purchases", "Budget stretching ideas"]
            }
        }
    }
    
    private func getOfflineSuggestions() -> [String] {
        return [
            "Check my budget status",
            "Help with saving tips",
            "Plan for upcoming releases",
            "Review my goals"
        ]
    }
    
    // MARK: - Typing Animation
    private func simulateTypingEffect(_ text: String) async {
        currentTyping = ""
        let words = text.components(separatedBy: " ")
        
        for (index, word) in words.enumerated() {
            if index == 0 {
                currentTyping = word
            } else {
                currentTyping += " " + word
            }
            
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
        }
    }
    
    // MARK: - Conversation Management
    private func setupInitialMessage() {
        let welcomeMessage = ChatMessage(
            content: "Hi! I'm PiggyBot, your K-pop budget assistant! 💝 I'm here to help you manage your spending on your favorite artists, plan for comebacks, and reach your fan goals. What would you like to know about your budget?",
            isUser: false,
            timestamp: Date(),
            suggestions: [
                "Show my budget summary",
                "Help me plan for a concert",
                "Check my artist spending",
                "Give me saving tips"
            ]
        )
        messages = [welcomeMessage]
    }
    
    func clearConversation() {
        messages.removeAll()
        setupInitialMessage()
    }
    
    // MARK: - Quick Actions
    func getBudgetSummary(userData: FanDashboardData) {
        let summary = generateBudgetSummary(userData: userData)
        let message = ChatMessage(
            content: summary,
            isUser: false,
            timestamp: Date(),
            suggestions: ["Help me save more", "Plan next purchase", "Set new goal"]
        )
        messages.append(message)
    }
    
    private func generateBudgetSummary(userData: FanDashboardData) -> String {
        let remaining = userData.totalMonthlyBudget - userData.totalMonthSpent
        let percentage = (userData.totalMonthSpent / userData.totalMonthlyBudget) * 100
        
        var summary = "📊 **Budget Summary**\n"
        summary += "Monthly Budget: $\(Int(userData.totalMonthlyBudget))\n"
        summary += "Spent: $\(Int(userData.totalMonthSpent)) (\(Int(percentage))%)\n"
        summary += "Remaining: $\(Int(remaining))\n\n"
        
        if let topBias = userData.topBias {
            summary += "Top spending: \(topBias.name) ($\(Int(topBias.monthSpent)))\n"
        }
        
        if !userData.urgentGoals.isEmpty {
            summary += "Urgent goals: \(userData.urgentGoals.count)\n"
        }
        
        summary += "\nWhat would you like to focus on next?"
        return summary
    }
}

// MARK: - Models
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    let suggestions: [String]?
    
    init(content: String, isUser: Bool, timestamp: Date, suggestions: [String]? = nil) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.suggestions = suggestions
    }
}

// MARK: - Chat Models (using Supabase edge functions for AI)

enum ChatError: LocalizedError {
    case invalidURL
    case networkError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError:
            return "Network connection failed"
        case .decodingError:
            return "Failed to process response"
        }
    }
}
