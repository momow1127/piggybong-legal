import Foundation
import SwiftUI
import UserNotifications

// MARK: - Event Prediction Service
@MainActor
class EventPredictionService: ObservableObject {
    static let shared = EventPredictionService()
    
    @Published var predictedEvents: [PredictedEvent] = []
    @Published var eventAlerts: [EventAlert] = []
    @Published var isAnalyzing = false
    @Published var lastUpdate: Date?
    
    private let supabaseService = SupabaseService.shared
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {
        setupNotificationCategories()
    }
    
    // MARK: - Event Prediction Engine
    func predictUpcomingEvents(for artists: [FanArtist], userGoals: [FanGoal]) async {
        isAnalyzing = true
        
        var predictions: [PredictedEvent] = []
        
        for artist in artists {
            // 1. Concert Tour Predictions
            let concertPredictions = await predictConcertTours(for: artist)
            predictions.append(contentsOf: concertPredictions)
            
            // 2. Album Release Predictions
            let albumPredictions = await predictAlbumReleases(for: artist)
            predictions.append(contentsOf: albumPredictions)
            
            // 3. Merchandise Drop Predictions
            let merchPredictions = await predictMerchDrops(for: artist)
            predictions.append(contentsOf: merchPredictions)
            
            // 4. Special Event Predictions (anniversaries, birthdays)
            let specialEventPredictions = predictSpecialEvents(for: artist)
            predictions.append(contentsOf: specialEventPredictions)
        }
        
        // Sort by relevance and date
        self.predictedEvents = predictions
            .sorted { event1, event2 in
                // Prioritize higher confidence and sooner dates
                if event1.confidenceScore != event2.confidenceScore {
                    return event1.confidenceScore > event2.confidenceScore
                }
                return event1.predictedDate < event2.predictedDate
            }
            .prefix(20)
            .map { $0 }
        
        // Generate alerts for high-confidence predictions
        await generateEventAlerts()
        
        self.lastUpdate = Date()
        isAnalyzing = false
    }
    
    // MARK: - Concert Tour Prediction
    private func predictConcertTours(for artist: FanArtist) async -> [PredictedEvent] {
        var predictions: [PredictedEvent] = []
        
        // Analyze historical tour patterns
        let historicalData = await fetchHistoricalTourData(artistName: artist.name)
        
        // Pattern 1: Regular tour cycles (every 1-2 years)
        if let lastTour = historicalData.lastTourDate {
            let monthsSinceLastTour = Calendar.current.dateComponents([.month], from: lastTour, to: Date()).month ?? 0
            
            if monthsSinceLastTour >= 18 { // 1.5 years
                let predictedDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
                predictions.append(PredictedEvent(
                    artistName: artist.name,
                    eventType: .concertTour,
                    title: "\(artist.name) World Tour",
                    predictedDate: predictedDate,
                    confidenceScore: 0.8,
                    reasoning: "Artists typically tour every 18-24 months",
                    estimatedCost: 150.0,
                    preparationTime: 90,
                    sources: ["Historical pattern analysis"]
                ))
            }
        }
        
        // Pattern 2: Post-album tour announcements
        if historicalData.recentAlbumRelease {
            let tourDate = Calendar.current.date(byAdding: .month, value: 4, to: Date()) ?? Date()
            predictions.append(PredictedEvent(
                artistName: artist.name,
                eventType: .concertTour,
                title: "\(artist.name) Album Promotion Tour",
                predictedDate: tourDate,
                confidenceScore: 0.7,
                reasoning: "Tours typically follow 3-6 months after album release",
                estimatedCost: 200.0,
                preparationTime: 60,
                sources: ["Album release correlation"]
            ))
        }
        
        return predictions
    }
    
    // MARK: - Album Release Prediction
    private func predictAlbumReleases(for artist: FanArtist) async -> [PredictedEvent] {
        var predictions: [PredictedEvent] = []
        
        let historicalData = await fetchHistoricalReleaseData(artistName: artist.name)
        
        // Pattern 1: Regular release cycles
        if let lastRelease = historicalData.lastAlbumDate {
            let monthsSinceLastRelease = Calendar.current.dateComponents([.month], from: lastRelease, to: Date()).month ?? 0
            
            // Most K-pop artists release annually or bi-annually
            if monthsSinceLastRelease >= 10 {
                let releaseDate = Calendar.current.date(byAdding: .month, value: 2, to: Date()) ?? Date()
                predictions.append(PredictedEvent(
                    artistName: artist.name,
                    eventType: .albumRelease,
                    title: "\(artist.name) New Album",
                    predictedDate: releaseDate,
                    confidenceScore: 0.75,
                    reasoning: "Average gap between albums is 12-18 months",
                    estimatedCost: 25.0,
                    preparationTime: 30,
                    sources: ["Release pattern analysis"]
                ))
            }
        }
        
        // Pattern 2: Seasonal release patterns (Q4 holiday releases are common)
        let currentMonth = Calendar.current.component(.month, from: Date())
        if currentMonth <= 8 { // Before September
            let holidayReleaseDate = Calendar.current.date(from: DateComponents(year: Calendar.current.component(.year, from: Date()), month: 11)) ?? Date()
            predictions.append(PredictedEvent(
                artistName: artist.name,
                eventType: .albumRelease,
                title: "\(artist.name) Holiday Special Album",
                predictedDate: holidayReleaseDate,
                confidenceScore: 0.6,
                reasoning: "Many artists release special albums for holidays",
                estimatedCost: 30.0,
                preparationTime: 14,
                sources: ["Seasonal pattern analysis"]
            ))
        }
        
        return predictions
    }
    
    // MARK: - Merchandise Drop Prediction
    private func predictMerchDrops(for artist: FanArtist) async -> [PredictedEvent] {
        var predictions: [PredictedEvent] = []
        
        // Pattern 1: Anniversary merchandise
        let debutDate = await fetchArtistDebutDate(artistName: artist.name)
        if let debut = debutDate {
            let debutMonth = Calendar.current.component(.month, from: debut)
            let debutDay = Calendar.current.component(.day, from: debut)
            let currentYear = Calendar.current.component(.year, from: Date())
            
            if let anniversaryDate = Calendar.current.date(from: DateComponents(year: currentYear, month: debutMonth, day: debutDay)),
               anniversaryDate > Date() {
                predictions.append(PredictedEvent(
                    artistName: artist.name,
                    eventType: .merchandise,
                    title: "\(artist.name) Anniversary Collection",
                    predictedDate: anniversaryDate,
                    confidenceScore: 0.9,
                    reasoning: "Anniversary merchandise is almost guaranteed",
                    estimatedCost: 50.0,
                    preparationTime: 7,
                    sources: ["Anniversary date calculation"]
                ))
            }
        }
        
        // Pattern 2: Pre-tour merchandise
        for prediction in predictedEvents where prediction.eventType == .concertTour && prediction.artistName == artist.name {
            let merchDate = Calendar.current.date(byAdding: .day, value: -30, to: prediction.predictedDate) ?? Date()
            if merchDate > Date() {
                predictions.append(PredictedEvent(
                    artistName: artist.name,
                    eventType: .merchandise,
                    title: "\(artist.name) Tour Merchandise Pre-Sale",
                    predictedDate: merchDate,
                    confidenceScore: 0.8,
                    reasoning: "Tour merchandise typically drops 2-4 weeks before tour",
                    estimatedCost: 75.0,
                    preparationTime: 3,
                    sources: ["Tour correlation analysis"]
                ))
            }
        }
        
        return predictions
    }
    
    // MARK: - Special Events Prediction
    private func predictSpecialEvents(for artist: FanArtist) -> [PredictedEvent] {
        var predictions: [PredictedEvent] = []
        
        // Birthday events (if we have member birthday data)
        // This would typically come from a database of artist information
        let mockBirthdays = [
            "BTS": [("RM", 12, 20), ("Jin", 12, 4), ("Suga", 3, 9), ("J-Hope", 2, 18)],
            "BLACKPINK": [("Jisoo", 1, 3), ("Jennie", 1, 16), ("Rosé", 2, 11), ("Lisa", 3, 27)]
        ]
        
        if let birthdays = mockBirthdays[artist.name] {
            let currentYear = Calendar.current.component(.year, from: Date())
            
            for (member, month, day) in birthdays {
                if let birthdayDate = Calendar.current.date(from: DateComponents(year: currentYear, month: month, day: day)),
                   birthdayDate > Date() {
                    predictions.append(PredictedEvent(
                        artistName: artist.name,
                        eventType: .specialEvent,
                        title: "\(member) Birthday Celebration",
                        predictedDate: birthdayDate,
                        confidenceScore: 1.0,
                        reasoning: "Birthday dates are confirmed",
                        estimatedCost: 20.0,
                        preparationTime: 14,
                        sources: ["Artist birthday database"]
                    ))
                }
            }
        }
        
        return predictions
    }
    
    // MARK: - Alert Generation
    private func generateEventAlerts() async {
        var alerts: [EventAlert] = []
        
        for event in predictedEvents {
            let daysUntilEvent = Calendar.current.dateComponents([.day], from: Date(), to: event.predictedDate).day ?? 0
            
            // High-confidence events within 30 days
            if event.confidenceScore >= 0.8 && daysUntilEvent <= 30 && daysUntilEvent >= 0 {
                alerts.append(EventAlert(
                    event: event,
                    alertType: .prepare,
                    message: "\(event.title) is likely happening in \(daysUntilEvent) days! Start saving $\(Int(event.estimatedCost)) now.",
                    urgency: daysUntilEvent <= 7 ? .high : .medium
                ))
            }
            
            // Budget preparation alerts
            if daysUntilEvent <= event.preparationTime && daysUntilEvent >= 0 {
                alerts.append(EventAlert(
                    event: event,
                    alertType: .budget,
                    message: "Time to start budgeting for \(event.title)! You'll need approximately $\(Int(event.estimatedCost)).",
                    urgency: .medium
                ))
            }
        }
        
        self.eventAlerts = alerts
        
        // Schedule notifications
        await scheduleNotifications(for: alerts)
    }
    
    // MARK: - Data Fetching (Mock implementations)
    private func fetchHistoricalTourData(artistName: String) async -> HistoricalTourData {
        // Mock implementation - in real app, this would query Spotify API, Ticketmaster, etc.
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let mockData: [String: HistoricalTourData] = [
            "BTS": HistoricalTourData(
                lastTourDate: Calendar.current.date(byAdding: .year, value: -2, to: Date()),
                averageTourGap: 18,
                recentAlbumRelease: false
            ),
            "BLACKPINK": HistoricalTourData(
                lastTourDate: Calendar.current.date(byAdding: .year, value: -1, to: Date()),
                averageTourGap: 24,
                recentAlbumRelease: true
            )
        ]
        
        return mockData[artistName] ?? HistoricalTourData(lastTourDate: nil, averageTourGap: 24, recentAlbumRelease: false)
    }
    
    private func fetchHistoricalReleaseData(artistName: String) async -> HistoricalReleaseData {
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let mockData: [String: HistoricalReleaseData] = [
            "BTS": HistoricalReleaseData(
                lastAlbumDate: Calendar.current.date(byAdding: .month, value: -8, to: Date()),
                averageReleaseGap: 12,
                seasonalPattern: [11, 6] // November and June
            ),
            "NewJeans": HistoricalReleaseData(
                lastAlbumDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()),
                averageReleaseGap: 8,
                seasonalPattern: [3, 8, 12]
            )
        ]
        
        return mockData[artistName] ?? HistoricalReleaseData(lastAlbumDate: nil, averageReleaseGap: 12, seasonalPattern: [])
    }
    
    private func fetchArtistDebutDate(artistName: String) async -> Date? {
        let mockDebutDates: [String: Date] = [
            "BTS": Calendar.current.date(from: DateComponents(year: 2013, month: 6, day: 13)) ?? Date(),
            "BLACKPINK": Calendar.current.date(from: DateComponents(year: 2016, month: 8, day: 8)) ?? Date(),
            "NewJeans": Calendar.current.date(from: DateComponents(year: 2022, month: 8, day: 1)) ?? Date()
        ]
        
        return mockDebutDates[artistName]
    }
    
    // MARK: - Notifications
    private func setupNotificationCategories() {
        let prepareCategory = UNNotificationCategory(
            identifier: "EVENT_PREPARE",
            actions: [
                UNNotificationAction(identifier: "VIEW_EVENT", title: "View Details"),
                UNNotificationAction(identifier: "START_SAVING", title: "Start Saving")
            ],
            intentIdentifiers: []
        )
        
        let budgetCategory = UNNotificationCategory(
            identifier: "EVENT_BUDGET",
            actions: [
                UNNotificationAction(identifier: "SET_GOAL", title: "Set Goal"),
                UNNotificationAction(identifier: "VIEW_BUDGET", title: "Check Budget")
            ],
            intentIdentifiers: []
        )
        
        notificationCenter.setNotificationCategories([prepareCategory, budgetCategory])
    }
    
    private func scheduleNotifications(for alerts: [EventAlert]) async {
        for alert in alerts.prefix(5) { // Limit to avoid spam
            let content = UNMutableNotificationContent()
            content.title = "\(alert.event.artistName) Event Alert"
            content.body = alert.message
            content.sound = .default
            content.categoryIdentifier = alert.alertType == .prepare ? "EVENT_PREPARE" : "EVENT_BUDGET"
            
            // Schedule for appropriate time
            let triggerDate = Calendar.current.date(byAdding: .day, value: -alert.event.preparationTime, to: alert.event.predictedDate) ?? Date()
            
            if triggerDate > Date() {
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                
                let request = UNNotificationRequest(
                    identifier: "event_\(alert.event.id)",
                    content: content,
                    trigger: trigger
                )
                
                try? await notificationCenter.add(request)
            }
        }
    }
    
    // MARK: - User Actions
    func createGoalFromPrediction(_ event: PredictedEvent) -> FanGoal {
        return FanGoal(
            id: UUID(),
            name: event.title,
            targetAmount: event.estimatedCost,
            currentAmount: 0,
            deadline: event.predictedDate,
            category: event.eventType == .concertTour ? .concert : event.eventType == .albumRelease ? .album : .merchandise,
            artistName: event.artistName,
            goalType: event.eventType == .concertTour ? .concertTickets : .albumCollection,
            countdownContext: event.reasoning,
            isTimeSensitive: true,
            eventDate: event.predictedDate,
            presaleDate: nil,
            celebrationMilestone: nil,
            imageURL: nil
        )
    }
    
    func dismissAlert(_ alert: EventAlert) {
        eventAlerts.removeAll { $0.id == alert.id }
    }
}

// MARK: - Supporting Models
struct PredictedEvent: Identifiable {
    let id = UUID()
    let artistName: String
    let eventType: PredictedEventType
    let title: String
    let predictedDate: Date
    let confidenceScore: Double // 0.0 to 1.0
    let reasoning: String
    let estimatedCost: Double
    let preparationTime: Int // Days needed to prepare
    let sources: [String]
    
    var confidenceText: String {
        switch confidenceScore {
        case 0.9...1.0: return "Very Likely"
        case 0.8..<0.9: return "Likely"
        case 0.6..<0.8: return "Possible"
        case 0.4..<0.6: return "Maybe"
        default: return "Unlikely"
        }
    }
    
    var confidenceColor: Color {
        switch confidenceScore {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
    
    var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: predictedDate).day ?? 0
    }
    
    var typeIcon: String {
        switch eventType {
        case .concertTour: return "music.mic.circle.fill"
        case .albumRelease: return "opticaldisc.fill"
        case .merchandise: return "bag.circle.fill"
        case .specialEvent: return "star.circle.fill"
        }
    }
}

enum PredictedEventType: String, CaseIterable {
    case concertTour = "concert_tour"
    case albumRelease = "album_release"
    case merchandise = "merchandise"
    case specialEvent = "special_event"
    
    var displayName: String {
        switch self {
        case .concertTour: return "Concert Tour"
        case .albumRelease: return "Album Release"
        case .merchandise: return "Merchandise Drop"
        case .specialEvent: return "Special Event"
        }
    }
}

struct EventAlert: Identifiable {
    let id = UUID()
    let event: PredictedEvent
    let alertType: AlertType
    let message: String
    let urgency: AlertUrgency
    let createdAt = Date()
}

enum AlertType {
    case prepare, budget, reminder
}

enum AlertUrgency {
    case low, medium, high
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Historical Data Models
struct HistoricalTourData {
    let lastTourDate: Date?
    let averageTourGap: Int // months
    let recentAlbumRelease: Bool
}

struct HistoricalReleaseData {
    let lastAlbumDate: Date?
    let averageReleaseGap: Int // months
    let seasonalPattern: [Int] // months when releases typically happen
}
