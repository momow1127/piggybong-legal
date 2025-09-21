import Foundation
import SwiftUI

// MARK: - Smart Fan Pick Event Types

enum FanEventType: String, CaseIterable, Codable {
    case comeback = "comeback"
    case tour = "tour"
    case album = "album"
    case merch = "merch"
    case social = "social"
    case fanmeet = "fanmeet"
    
    var displayName: String {
        switch self {
        case .comeback: return "Comeback"
        case .tour: return "Tour"
        case .album: return "Album"
        case .merch: return "Merch"
        case .social: return "Social"
        case .fanmeet: return "Fanmeet"
        }
    }
    
    var icon: String {
        switch self {
        case .comeback: return "music.note.list"
        case .tour: return "mic.fill"
        case .album: return "opticaldisc.fill"
        case .merch: return "bag.fill"
        case .social: return "bubble.left.fill"
        case .fanmeet: return "person.3.fill"
        }
    }
    
    var badgeEmoji: String {
        switch self {
        case .comeback: return "✨"
        case .tour: return "🎤"
        case .album: return "💿"
        case .merch: return "🛍️"
        case .social: return "📱"
        case .fanmeet: return "🎉"
        }
    }
    
    var badgeText: String {
        switch self {
        case .comeback: return "COMEBACK ALERT"
        case .tour: return "TOUR INCOMING"
        case .album: return "ALBUM DROP"
        case .merch: return "MERCH RELEASE"
        case .social: return "SOCIAL UPDATE"
        case .fanmeet: return "FANMEET ANNOUNCED"
        }
    }
    
    var color: Color {
        switch self {
        case .comeback: return .purple
        case .tour: return .red
        case .album: return .blue
        case .merch: return .orange
        case .social: return .pink
        case .fanmeet: return .green
        }
    }
}

// MARK: - Insight Types

enum SmartPickInsightType: String, CaseIterable {
    case priorityReinforcement = "priority_reinforcement"
    case tradeoffReminder = "tradeoff_reminder"
    case timingInsight = "timing_insight"
    case socialBenchmarking = "social_benchmarking"
    case strategicSuggestion = "strategic_suggestion"
}

// MARK: - Recommended Priority

enum RecommendedPriority: String, CaseIterable, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"
    case waitAndSee = "wait_and_see"
    
    var displayText: String {
        switch self {
        case .high: return "🔥 This deserves HIGH priority"
        case .medium: return "💫 Consider MEDIUM priority"
        case .low: return "💭 Keep as LOW for now"
        case .waitAndSee: return "⏰ Wait for more details"
        }
    }
    
    var shortText: String {
        switch self {
        case .high: return "High Priority"
        case .medium: return "Medium Priority"
        case .low: return "Low Priority"
        case .waitAndSee: return "Wait & See"
        }
    }
    
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .gray
        case .waitAndSee: return .blue
        }
    }
}

// MARK: - Smart Fan Pick Event Model

struct SmartFanPickEvent: Identifiable, Codable {
    let id: UUID
    let artistId: UUID
    let artistName: String
    let eventType: FanEventType
    let eventTitle: String
    let eventDescription: String?
    let eventDate: Date?
    let detectedAt: Date
    let expiresAt: Date
    let recommendedPriority: RecommendedPriority
    let insights: [String]
    let imageURL: String?
    let isLimitedEdition: Bool
    let isUrgent: Bool
    var isDismissed: Bool
    var hasBeenViewed: Bool
    
    // Computed properties
    var isNew: Bool {
        let twoHoursAgo = Date().addingTimeInterval(-2 * 60 * 60)
        return detectedAt > twoHoursAgo && !hasBeenViewed
    }
    
    var isExpiring: Bool {
        let sixHoursFromNow = Date().addingTimeInterval(6 * 60 * 60)
        return expiresAt < sixHoursFromNow
    }
    
    var isExpired: Bool {
        return expiresAt < Date()
    }
    
    var timeUntilExpiry: String {
        let interval = expiresAt.timeIntervalSince(Date())
        if interval < 0 { return "Expired" }
        
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 24 {
            let days = hours / 24
            return "\(days)d left"
        } else if hours > 0 {
            return "\(hours)h left"
        } else {
            return "\(minutes)m left"
        }
    }
    
    var badge: String {
        return "\(eventType.badgeEmoji) \(eventType.badgeText)"
    }
    
    var currentInsight: String {
        // Rotate through insights based on view count or random
        return insights.randomElement() ?? "Stay focused on your priorities!"
    }
}

// MARK: - AI-Lite Insight Library

struct InsightLibrary {
    // Concert/Tour Insights
    static let tourInsights: [SmartPickInsightType: [String]] = [
        .priorityReinforcement: [
            "🔥 Concerts are often once-in-a-lifetime moments — worth High priority if this is your bias.",
            "🎤 Live performances create core memories. This could deserve your top focus.",
            "✨ Tours are rare and special — many fans make this their #1 priority."
        ],
        .tradeoffReminder: [
            "⚖️ Big tours usually mean higher costs. You might need to lower something else.",
            "💡 Concert tickets + travel + merch adds up. Consider adjusting other priorities.",
            "🎯 If you go High here, something else needs to be Medium or Low."
        ],
        .timingInsight: [
            "⏰ Tours often have multiple dates. Check if there's a weekend show that works better.",
            "📅 Presale starts soon — mark your priority now to prepare.",
            "🗓️ Most tours announce additional dates if the first ones sell out."
        ]
    ]
    
    // Album Insights
    static let albumInsights: [SmartPickInsightType: [String]] = [
        .priorityReinforcement: [
            "💿 Albums are a core memory builder. Fans often mark these as Medium or High.",
            "🎵 First-week sales matter to artists. Consider making this a priority if you stan.",
            "📀 Album collections last forever — a solid investment in your fan journey."
        ],
        .strategicSuggestion: [
            "✨ Albums are often followed by merch drops 2 weeks later. Consider spacing priorities.",
            "💡 Pre-orders usually come with exclusive photocards. Factor that into your decision.",
            "🎁 Deluxe versions might drop later — decide if you want standard or wait."
        ],
        .socialBenchmarking: [
            "👥 Most fans in your bias group pre-order within 48 hours.",
            "📊 Album purchases directly support comeback stages and promotions.",
            "🌟 Dedicated fans often buy multiple versions — but one is perfectly supportive too!"
        ]
    ]
    
    // Merch Insights
    static let merchInsights: [SmartPickInsightType: [String]] = [
        .timingInsight: [
            "⏰ Merch lines usually restock or rotate. No need to rush unless it's limited edition.",
            "📦 Standard merch restocks every 2-3 months. Limited editions are one-time only.",
            "🔄 If this isn't limited edition, you can safely mark as Low and revisit later."
        ],
        .socialBenchmarking: [
            "💡 Many fans skip merch to save for concerts — does this fit your focus?",
            "👕 Merch is nice-to-have for most fans, not must-have. Follow your comfort level.",
            "🎯 Survey shows: 60% of fans prioritize albums/concerts over merch."
        ],
        .priorityReinforcement: [
            "🛍️ Merch is a fun way to show support daily. Medium priority keeps it balanced.",
            "✨ Limited edition merch can become collector's items — High if you love exclusives.",
            "💝 Merch makes great gifts for fellow fans — consider that in your priority."
        ]
    ]
    
    // General/Comeback Insights
    static let comebackInsights: [SmartPickInsightType: [String]] = [
        .priorityReinforcement: [
            "🔥 This matches your top priority — good pick! Keep your focus strong.",
            "⭐ Comebacks are peak fan moments. Your current priority setting makes sense.",
            "💪 You're aligned with your fan goals. Stay consistent!"
        ],
        .tradeoffReminder: [
            "⚖️ You've already marked another High priority. Adding this might mean lowering something else.",
            "🎯 Remember: only 1-2 things can truly be High priority. Choose wisely.",
            "💭 Every High priority means less flexibility elsewhere. Still worth it?"
        ],
        .strategicSuggestion: [
            "📱 Comebacks usually span 3-4 weeks of content. Pace yourself!",
            "🎬 Music videos and stages are free to enjoy — factor that into priorities.",
            "💎 The full comeback experience includes album, performances, and fan events."
        ]
    ]
    
    // Get contextual insight
    static func getInsight(for eventType: FanEventType, insightType: SmartPickInsightType) -> String {
        let insights: [SmartPickInsightType: [String]]
        
        switch eventType {
        case .tour, .fanmeet:
            insights = tourInsights
        case .album:
            insights = albumInsights
        case .merch:
            insights = merchInsights
        case .comeback, .social:
            insights = comebackInsights
        }
        
        return insights[insightType]?.randomElement() ?? 
               "Your fan plan helps you stay focused — adjust only if this feels truly special."
    }
}

// MARK: - Mock Data

extension SmartFanPickEvent {
    static let mockEvents: [SmartFanPickEvent] = [
        // BTS Comeback Event (New - High Priority)
        SmartFanPickEvent(
            id: UUID(),
            artistId: UUID(),
            artistName: "BTS",
            eventType: .comeback,
            eventTitle: "2025 Comeback Announced!",
            eventDescription: "BTS confirms new album and world tour dates",
            eventDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
            detectedAt: Date().addingTimeInterval(-60 * 60), // 1 hour ago
            expiresAt: Date().addingTimeInterval(47 * 60 * 60), // 47 hours from now
            recommendedPriority: .high,
            insights: [
                InsightLibrary.getInsight(for: .comeback, insightType: .priorityReinforcement),
                InsightLibrary.getInsight(for: .comeback, insightType: .tradeoffReminder),
                InsightLibrary.getInsight(for: .comeback, insightType: .strategicSuggestion)
            ],
            imageURL: nil,
            isLimitedEdition: false,
            isUrgent: true,
            isDismissed: false,
            hasBeenViewed: false
        ),
        
        // NewJeans Album (Medium Priority)
        SmartFanPickEvent(
            id: UUID(),
            artistId: UUID(),
            artistName: "NewJeans",
            eventType: .album,
            eventTitle: "Get Up - Mini Album",
            eventDescription: "Pre-orders open for new mini album",
            eventDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
            detectedAt: Date().addingTimeInterval(-6 * 60 * 60), // 6 hours ago
            expiresAt: Date().addingTimeInterval(42 * 60 * 60), // 42 hours from now
            recommendedPriority: .medium,
            insights: [
                InsightLibrary.getInsight(for: .album, insightType: .priorityReinforcement),
                InsightLibrary.getInsight(for: .album, insightType: .strategicSuggestion),
                InsightLibrary.getInsight(for: .album, insightType: .socialBenchmarking)
            ],
            imageURL: nil,
            isLimitedEdition: false,
            isUrgent: false,
            isDismissed: false,
            hasBeenViewed: false
        ),
        
        // BLACKPINK Limited Merch (Wait & See)
        SmartFanPickEvent(
            id: UUID(),
            artistId: UUID(),
            artistName: "BLACKPINK",
            eventType: .merch,
            eventTitle: "Born Pink Tour Merch",
            eventDescription: "Exclusive tour merchandise available",
            eventDate: nil,
            detectedAt: Date().addingTimeInterval(-12 * 60 * 60), // 12 hours ago
            expiresAt: Date().addingTimeInterval(36 * 60 * 60), // 36 hours from now
            recommendedPriority: .waitAndSee,
            insights: [
                InsightLibrary.getInsight(for: .merch, insightType: .timingInsight),
                InsightLibrary.getInsight(for: .merch, insightType: .socialBenchmarking),
                InsightLibrary.getInsight(for: .merch, insightType: .priorityReinforcement)
            ],
            imageURL: nil,
            isLimitedEdition: true,
            isUrgent: false,
            isDismissed: false,
            hasBeenViewed: true
        )
    ]
    
    static func mockEvent(for artist: FanArtist) -> SmartFanPickEvent? {
        return mockEvents.first { $0.artistName == artist.name }
    }
}