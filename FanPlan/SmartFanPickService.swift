import Foundation
import SwiftUI

// MARK: - Insight Engine

class InsightEngine {
    
    // Select the most relevant insight based on context
    static func selectInsight(
        for event: SmartFanPickEvent,
        userPriorities: [UserPriority],
        currentArtistPriorities: [FanCategory: Int],
        isVIP: Bool
    ) -> [String] {
        
        var selectedInsights: [String] = []
        
        // Check for priority conflicts
        let hasHighPriorityConflict = userPriorities
            .filter { $0.priority == 1 }
            .count >= 2
        
        let hasMultipleMediumPriorities = userPriorities
            .filter { $0.priority == 2 }
            .count >= 3
        
        // Get event-specific insights
        switch event.eventType {
        case .tour, .fanmeet:
            selectedInsights.append(contentsOf: getTourInsights(
                event: event,
                hasConflict: hasHighPriorityConflict,
                isVIP: isVIP
            ))
            
        case .album:
            selectedInsights.append(contentsOf: getAlbumInsights(
                event: event,
                hasConflict: hasMultipleMediumPriorities,
                isVIP: isVIP
            ))
            
        case .merch:
            selectedInsights.append(contentsOf: getMerchInsights(
                event: event,
                isLimited: event.isLimitedEdition,
                isVIP: isVIP
            ))
            
        case .comeback:
            selectedInsights.append(contentsOf: getComebackInsights(
                event: event,
                hasConflict: hasHighPriorityConflict,
                isVIP: isVIP
            ))
            
        case .social:
            selectedInsights.append(contentsOf: getSocialInsights(
                event: event,
                isVIP: isVIP
            ))
        }
        
        // Limit insights based on VIP status
        let maxInsights = isVIP ? 3 : 1
        return Array(selectedInsights.prefix(maxInsights))
    }
    
    // Tour/Concert specific insights
    private static func getTourInsights(
        event: SmartFanPickEvent,
        hasConflict: Bool,
        isVIP: Bool
    ) -> [String] {
        
        var insights: [String] = []
        
        if hasConflict {
            insights.append("⚖️ You've already marked another High priority. Tours are big — consider reshuffling.")
        } else {
            insights.append("🔥 Concerts are often once-in-a-lifetime. Worth High priority if \(event.artistName) is your bias.")
        }
        
        if event.isUrgent {
            insights.append("⚡ Tickets sell fast! Presale starts soon — set your priority now.")
        }
        
        if isVIP {
            insights.append("💡 VIP Tip: Most \(event.artistName) fans book within 48 hours of announcement.")
        }
        
        return insights
    }
    
    // Album specific insights
    private static func getAlbumInsights(
        event: SmartFanPickEvent,
        hasConflict: Bool,
        isVIP: Bool
    ) -> [String] {
        
        var insights: [String] = []
        
        insights.append("💿 Albums often drop merch 2 weeks later. Consider spacing priorities.")
        
        if let eventDate = event.eventDate {
            let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: eventDate).day ?? 0
            if daysUntil <= 7 {
                insights.append("📅 Releasing this week! First-week sales matter most.")
            }
        }
        
        if isVIP {
            insights.append("✨ VIP Insight: Pre-orders usually include exclusive photocards worth 2-3x later.")
        }
        
        return insights
    }
    
    // Merch specific insights
    private static func getMerchInsights(
        event: SmartFanPickEvent,
        isLimited: Bool,
        isVIP: Bool
    ) -> [String] {
        
        var insights: [String] = []
        
        if isLimited {
            insights.append("⚡ Limited edition alert! These won't restock — decide quickly.")
        } else {
            insights.append("⏰ Standard merch usually restocks. No rush unless you love it.")
        }
        
        insights.append("💡 Many fans skip merch to save for concerts — does this fit your focus?")
        
        if isVIP {
            insights.append("📊 VIP Data: 65% of fans wait for tour merch over online drops.")
        }
        
        return insights
    }
    
    // Comeback specific insights
    private static func getComebackInsights(
        event: SmartFanPickEvent,
        hasConflict: Bool,
        isVIP: Bool
    ) -> [String] {
        
        var insights: [String] = []
        
        if hasConflict {
            insights.append("⚖️ Big comeback season! You might need to shuffle priorities across artists.")
        } else {
            insights.append("🔥 This matches your usual pattern — comebacks are your sweet spot!")
        }
        
        insights.append("💎 The full comeback includes album + stages + fan events. Plan accordingly.")
        
        if isVIP {
            insights.append("🎯 VIP Strategy: Save 30% more during comeback months for unexpected drops.")
        }
        
        return insights
    }
    
    // Social/Other insights
    private static func getSocialInsights(
        event: SmartFanPickEvent,
        isVIP: Bool
    ) -> [String] {
        
        var insights: [String] = []
        
        insights.append("📱 Social events are usually free to enjoy — keep as Low unless it's special.")
        insights.append("⏰ These announcements often lead to bigger news. Stay flexible.")
        
        if isVIP {
            insights.append("💡 VIP Pattern: Social teasers → Album in 2 weeks → Tour in 2 months.")
        }
        
        return insights
    }
}

// MARK: - Smart Fan Pick Service

@MainActor
class SmartFanPickService: ObservableObject {
    static let shared = SmartFanPickService()
    
    @Published var activeEvents: [SmartFanPickEvent] = []
    @Published var dismissedEventIds: Set<UUID> = []
    @Published var viewedEventIds: Set<UUID> = []
    @Published var currentEventIndex: Int = 0
    
    private init() {
        loadDismissedEvents()
        loadViewedEvents()
        checkForNewEvents()
    }
    
    // MARK: - Event Management
    
    func checkForNewEvents() {
        // No mock events - wait for real event detection
        // Later: Integrate with real event API
        
        activeEvents = []
        
        // TODO: Replace with actual event detection logic
        // This will integrate with:
        // - Artist social media monitoring
        // - Official announcement feeds
        // - Community detection systems
    }
    
    func getEventsForArtist(_ artistName: String) -> [SmartFanPickEvent] {
        return activeEvents.filter { $0.artistName == artistName }
    }
    
    func getNextEvent() -> SmartFanPickEvent? {
        guard !activeEvents.isEmpty else { return nil }
        
        // Cycle through events
        if currentEventIndex >= activeEvents.count {
            currentEventIndex = 0
        }
        
        let event = activeEvents[currentEventIndex]
        currentEventIndex += 1
        
        return event
    }
    
    func getCurrentEvent() -> SmartFanPickEvent? {
        return activeEvents.first { !$0.hasBeenViewed } ?? activeEvents.first
    }
    
    // MARK: - User Actions
    
    func markAsViewed(_ eventId: UUID) {
        viewedEventIds.insert(eventId)
        saveViewedEvents()
        
        // Update the event in the array
        if let index = activeEvents.firstIndex(where: { $0.id == eventId }) {
            activeEvents[index].hasBeenViewed = true
        }
    }
    
    func dismissEvent(_ eventId: UUID) {
        dismissedEventIds.insert(eventId)
        saveDismissedEvents()
        
        // Remove from active events
        activeEvents.removeAll { $0.id == eventId }
        
        // Reset index if needed
        if currentEventIndex >= activeEvents.count {
            currentEventIndex = 0
        }
    }
    
    func snoozeEvent(_ eventId: UUID, hours: Int = 24) {
        // Temporarily dismiss for X hours
        // This could be enhanced with actual snooze logic
        dismissEvent(eventId)
        
        // Schedule to reappear (simplified for MVP)
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(hours * 3600)) {
            self.dismissedEventIds.remove(eventId)
            self.checkForNewEvents()
        }
    }
    
    // MARK: - Persistence
    
    private func loadDismissedEvents() {
        if let data = UserDefaults.standard.data(forKey: "dismissedSmartPickEvents"),
           let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            dismissedEventIds = ids
        }
    }
    
    private func saveDismissedEvents() {
        if let data = try? JSONEncoder().encode(dismissedEventIds) {
            UserDefaults.standard.set(data, forKey: "dismissedSmartPickEvents")
        }
    }
    
    private func loadViewedEvents() {
        if let data = UserDefaults.standard.data(forKey: "viewedSmartPickEvents"),
           let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            viewedEventIds = ids
        }
    }
    
    private func saveViewedEvents() {
        if let data = try? JSONEncoder().encode(viewedEventIds) {
            UserDefaults.standard.set(data, forKey: "viewedSmartPickEvents")
        }
    }
    
    // MARK: - Analytics
    
    func trackEventAction(_ eventId: UUID, action: String) {
        // Track user interactions for future improvements
        print("Smart Pick Action: \(action) for event \(eventId)")
        // Later: Send to analytics service
    }
    
    // MARK: - VIP Features
    
    func getInsightsForEvent(
        _ event: SmartFanPickEvent,
        userPriorities: [UserPriority] = [],
        isVIP: Bool
    ) -> [String] {
        
        // Use the InsightEngine to get contextual insights
        return InsightEngine.selectInsight(
            for: event,
            userPriorities: userPriorities,
            currentArtistPriorities: [:], // This would come from user data
            isVIP: isVIP
        )
    }
    
    /// Gets user priorities from database for AI insights
    func loadUserPrioritiesForInsights() async -> [UserPriority] {
        return await DatabaseService.shared.getCurrentUserPriorities()
    }
}