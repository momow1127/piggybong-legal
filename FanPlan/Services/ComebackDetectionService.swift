import Foundation
import UserNotifications

// Type aliases for compatibility - use main Artist type from FanExperienceModels

// MARK: - Comeback Detection Service
/// Detects and notifies users about K-pop comebacks and releases
@MainActor
class ComebackDetectionService: ObservableObject {
    static let shared = ComebackDetectionService()
    
    @Published var isMonitoring = false
    @Published var detectedComebacks: [ComebackEvent] = []
    @Published var upcomingComebacks: [ComebackEvent] = []
    
    private let supabaseService = SupabaseService.shared
    private let notificationService = ArtistNotificationService.shared
    private var monitoringTimer: Timer?
    private let checkInterval: TimeInterval = 60 // Check every minute for real-time
    
    // Comeback detection keywords with weights
    private let comebackKeywords: [String: Double] = [
        "comeback": 5.0,
        "new album": 4.5,
        "mini album": 4.5,
        "full album": 5.0,
        "single album": 3.5,
        "release": 3.0,
        "MV": 3.5,
        "music video": 4.0,
        "teaser": 3.0,
        "pre-release": 3.5,
        "title track": 3.5,
        "debut": 4.0,
        "collaboration": 3.0,
        // Korean keywords
        "컴백": 5.0,
        "새 앨범": 4.5,
        "발매": 3.5,
        "뮤직비디오": 4.0,
        "티저": 3.0
    ]
    
    private let urgencyKeywords: [String: Double] = [
        "surprise": 3.0,
        "sudden": 2.5,
        "breaking": 4.0,
        "urgent": 3.5,
        "just dropped": 4.0,
        "out now": 3.5,
        "깜짝": 3.0,
        "갑자기": 2.5,
        "긴급": 3.5
    ]
    
    private init() {
        scheduleUpcomingComebackChecks()
    }
    
    // MARK: - Public Methods
    
    /// Start monitoring for comebacks in real-time
    func startRealTimeMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        print("🚨 Started real-time comeback monitoring")
        
        // Start periodic checks
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkForNewComebacks()
            }
        }
        
        // Initial check
        Task {
            await checkForNewComebacks()
            await loadUpcomingComebacks()
        }
    }
    
    /// Stop real-time monitoring
    func stopMonitoring() {
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        print("⏹️ Stopped comeback monitoring")
    }
    
    /// Manually check for comebacks for a specific artist
    func checkComebacksFor(artist: String) async -> [ComebackEvent] {
        // Search comeback events for the given artist
        do {
            let allComebacks = try await fetchComebacksFromDatabase()
            return allComebacks.filter { $0.artistName.localizedCaseInsensitiveContains(artist) }
        } catch {
            print("❌ Error searching comebacks for \(artist): \(error)")
            return []
        }
    }
    
    /// Get user's followed artists and check their comebacks
    func checkUserArtistComebacks() async {
        let userArtists = await getUserFollowedArtists()
        
        for artist in userArtists {
            let comebacks = await checkComebacksFor(artist: artist.name)
            
            for comeback in comebacks {
                await notifyUserOfComeback(comeback, for: artist)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Check for new comebacks from all sources
    private func checkForNewComebacks() async {
        do {
            // Check database events for new/upcoming comebacks
            let dbComebacks = try await fetchComebacksFromDatabase()
            
            // Check RSS feeds for breaking news
            let rssComebacks = await fetchComebacksFromRSS()
            
            // Combine and deduplicate
            var allComebacks = dbComebacks + rssComebacks
            allComebacks = deduplicateComebacks(allComebacks)
            
            // Filter for new comebacks
            let newComebacks = filterNewComebacks(allComebacks)
            
            if !newComebacks.isEmpty {
                detectedComebacks.append(contentsOf: newComebacks)
                print("🎉 Detected \(newComebacks.count) new comebacks!")
                
                // Send notifications for breaking comebacks
                for comeback in newComebacks where comeback.isBreaking {
                    await sendBreakingComebackNotification(comeback)
                }
            }
            
        } catch {
            print("❌ Error checking for comebacks: \(error)")
        }
    }
    
    /// Fetch comeback events from Supabase database
    private func fetchComebacksFromDatabase() async throws -> [ComebackEvent] {
        // Query app_events for comeback-related events
        guard let url = URL(string: "\(Secrets.supabaseURL)/rest/v1/app_events") else {
            throw NSError(domain: "ComebackDetectionService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid Supabase URL configuration"
            ])
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(supabaseService.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseService.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let events = try JSONDecoder().decode([DatabaseEvent].self, from: data)
        
        return events.compactMap { event in
            guard let eventDate = parseEventDate(event.event_date) else { return nil }
            
            let comebackScore = calculateComebackScore(
                title: event.title,
                description: event.description ?? ""
            )
            
            guard comebackScore > 2.0 else { return nil } // Threshold for comeback detection
            
            return ComebackEvent(
                id: event.id?.uuidString ?? UUID().uuidString,
                artistName: event.artist_name,
                title: event.title,
                description: event.description,
                releaseDate: eventDate,
                type: determineComebackType(event.title, event.description ?? ""),
                source: .database,
                isBreaking: event.is_breaking ?? false,
                comebackScore: comebackScore
            )
        }
    }
    
    /// Fetch comeback information from RSS sources
    private func fetchComebacksFromRSS() async -> [ComebackEvent] {
        var comebacks: [ComebackEvent] = []
        
        // Check Soompi RSS for K-pop news
        if let soompiComebacks = await fetchFromSoompiRSS() {
            comebacks.append(contentsOf: soompiComebacks)
        }
        
        return comebacks
    }
    
    /// Fetch from Soompi RSS feed
    private func fetchFromSoompiRSS() async -> [ComebackEvent]? {
        do {
            guard let url = URL(string: "https://www.soompi.com/feed") else { return nil }
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Parse RSS XML (simplified)
            let rssString = String(data: data, encoding: .utf8) ?? ""
            return parseRSSForComebacks(rssString)
            
        } catch {
            print("❌ Error fetching Soompi RSS: \(error)")
            return nil
        }
    }
    
    /// Parse RSS content for comeback information
    private func parseRSSForComebacks(_ rssContent: String) -> [ComebackEvent] {
        var comebacks: [ComebackEvent] = []
        
        // Simple RSS parsing (in production, use a proper XML parser)
        let items = rssContent.components(separatedBy: "<item>")
        
        for item in items.dropFirst() { // Skip first element (RSS header)
            guard let title = extractRSSField(item, field: "title"),
                  let description = extractRSSField(item, field: "description"),
                  let pubDate = extractRSSField(item, field: "pubDate") else { continue }
            
            let comebackScore = calculateComebackScore(title: title, description: description)
            guard comebackScore > 3.0 else { continue } // Higher threshold for RSS
            
            let artistName = extractArtistFromTitle(title)
            guard !artistName.isEmpty else { continue }
            
            let comeback = ComebackEvent(
                id: UUID().uuidString,
                artistName: artistName,
                title: title,
                description: description,
                releaseDate: parseRSSDate(pubDate) ?? Date(),
                type: determineComebackType(title, description),
                source: .rss,
                isBreaking: comebackScore > 5.0,
                comebackScore: comebackScore
            )
            
            comebacks.append(comeback)
        }
        
        return comebacks
    }
    
    /// Calculate comeback score based on keywords
    private func calculateComebackScore(title: String, description: String) -> Double {
        let combinedText = "\(title) \(description)".lowercased()
        var score = 0.0
        
        // Check comeback keywords
        for (keyword, weight) in comebackKeywords {
            if combinedText.contains(keyword) {
                score += weight
            }
        }
        
        // Check urgency keywords
        for (keyword, weight) in urgencyKeywords {
            if combinedText.contains(keyword) {
                score += weight
            }
        }
        
        return score
    }
    
    /// Determine comeback type from content
    private func determineComebackType(_ title: String, _ description: String) -> ComebackType {
        let text = "\(title) \(description)".lowercased()
        
        if text.contains("full album") || text.contains("정규") {
            return .fullAlbum
        } else if text.contains("mini album") || text.contains("mini") {
            return .miniAlbum
        } else if text.contains("single") {
            return .single
        } else if text.contains("mv") || text.contains("music video") {
            return .musicVideo
        } else if text.contains("teaser") {
            return .teaser
        } else {
            return .other
        }
    }
    
    /// Get user's followed artists
    private func getUserFollowedArtists() async -> [Artist] {
        // This would fetch from user's selected artists in the database
        // For now, return popular artists as fallback
        return []
    }
    
    /// Send breaking comeback notification
    private func sendBreakingComebackNotification(_ comeback: ComebackEvent) async {
        let content = UNMutableNotificationContent()
        content.title = "🚨 \(comeback.artistName) Comeback!"
        content.body = comeback.title
        content.badge = 1
        content.sound = .default
        content.categoryIdentifier = "COMEBACK_ALERT"
        
        let request = UNNotificationRequest(
            identifier: "comeback-\(comeback.id)",
            content: content,
            trigger: nil // Send immediately
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("📱 Sent breaking comeback notification for \(comeback.artistName)")
        } catch {
            print("❌ Failed to send comeback notification: \(error)")
        }
    }
    
    /// Load upcoming comebacks for the next 7 days
    private func loadUpcomingComebacks() async {
        do {
            let comebacks = try await fetchComebacksFromDatabase()
            let upcoming = comebacks.filter { comeback in
                comeback.releaseDate > Date() && 
                comeback.releaseDate.timeIntervalSinceNow < 7 * 24 * 3600 // Next 7 days
            }
            
            upcomingComebacks = upcoming.sorted { $0.releaseDate < $1.releaseDate }
            print("📅 Loaded \(upcoming.count) upcoming comebacks")
        } catch {
            print("❌ Error loading upcoming comebacks: \(error)")
        }
    }
    
    /// Schedule checks for specific upcoming comeback times
    private func scheduleUpcomingComebackChecks() {
        // Schedule notifications for known upcoming comebacks
        // This would integrate with the iOS scheduling system
        print("📅 Scheduled upcoming comeback checks")
    }
    
    // MARK: - Helper Methods
    
    private func filterNewComebacks(_ comebacks: [ComebackEvent]) -> [ComebackEvent] {
        let existingIds = Set(detectedComebacks.map { $0.id })
        return comebacks.filter { !existingIds.contains($0.id) }
    }
    
    private func deduplicateComebacks(_ comebacks: [ComebackEvent]) -> [ComebackEvent] {
        var seen = Set<String>()
        return comebacks.filter { comeback in
            let key = "\(comeback.artistName)-\(comeback.title)"
            return seen.insert(key).inserted
        }
    }
    
    private func parseEventDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
    
    private func parseRSSDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return formatter.date(from: dateString)
    }
    
    private func extractRSSField(_ item: String, field: String) -> String? {
        guard let startRange = item.range(of: "<\(field)>"),
              let endRange = item.range(of: "</\(field)>") else { return nil }
        
        let start = startRange.upperBound
        let end = endRange.lowerBound
        return String(item[start..<end])
    }
    
    private func extractArtistFromTitle(_ title: String) -> String {
        // Extract artist name from title using common patterns
        let patterns = [
            "([A-Z][A-Za-z0-9 ]+) (Announces|Releases|Drops)",
            "([A-Z][A-Za-z0-9 ]+)'s",
            "([A-Z][A-Za-z0-9 ]+) To Release"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)),
               let range = Range(match.range(at: 1), in: title) {
                return String(title[range])
            }
        }
        
        return ""
    }
    
    private func notifyUserOfComeback(_ comeback: ComebackEvent, for artist: Artist) async {
        // Send personalized notification
        print("📱 Would notify user about \(comeback.artistName) comeback: \(comeback.title)")
    }
}

// MARK: - Supporting Models

struct ComebackEvent: Identifiable, Codable {
    let id: String
    let artistName: String
    let title: String
    let description: String?
    let releaseDate: Date
    let type: ComebackType
    let source: ComebackSource
    let isBreaking: Bool
    let comebackScore: Double
}

enum ComebackType: String, Codable, CaseIterable {
    case fullAlbum = "Full Album"
    case miniAlbum = "Mini Album"
    case single = "Single"
    case musicVideo = "Music Video"
    case teaser = "Teaser"
    case other = "Other"
}

enum ComebackSource: String, Codable {
    case database = "database"
    case rss = "rss"
    case api = "api"
}

struct DatabaseEvent: Codable {
    let id: UUID?
    let title: String
    let artist_name: String
    let event_date: String?
    let description: String?
    let is_breaking: Bool?
}

