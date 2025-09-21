import SwiftUI
import Foundation
import Combine

@MainActor
class IdolUpdateService: ObservableObject {
    // MARK: - Published Properties
    @Published var updates: [IdolUpdate] = []
    @Published var breakingNews: [IdolUpdate] = []
    @Published var followedArtists: [ArtistProfile] = []
    @Published var isLoading = false
    @Published var isConnected = false
    @Published var lastUpdateTime: Date?
    @Published var configuration = NewsFeedConfiguration.default
    
    // MARK: - Private Properties
    private var updateTimer: Timer?
    
    // MARK: - Singleton
    static let shared = IdolUpdateService()
    
    private init() {
        setupInitialData()
    }
    
    // MARK: - Public Methods
    
    func startRealtimeUpdates() {
        guard !isLoading else { return }
        
        isLoading = true
        isConnected = true
        startPeriodicUpdates()
        
        Task {
            await fetchLatestUpdates()
            isLoading = false
        }
    }
    
    func stopRealtimeUpdates() {
        stopPeriodicUpdates()
        isConnected = false
    }
    
    func refreshAllUpdates() async {
        isLoading = true
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Get previous updates count for comparison
        let previousCount = updates.count
        
        // Update data
        updates = IdolUpdate.mockUpdates
        breakingNews = updates.filter { $0.isBreakingNews }
        lastUpdateTime = Date()
        
        // Check for new updates and send notifications
        if updates.count > previousCount {
            await scheduleNewUpdateNotifications()
        }
        
        isLoading = false
    }
    
    // MARK: - Notification Integration
    private func scheduleNewUpdateNotifications() async {
        let notificationService = ArtistNotificationService.shared
        
        // Get recent updates (last 5 minutes)
        let recentUpdates = updates.filter { update in
            return Date().timeIntervalSince(update.timestamp) < 300 // 5 minutes
        }
        
        for update in recentUpdates {
            // Find corresponding artist
            if let artist = followedArtists.first(where: { $0.id == update.artistId }) {
                // Convert to Artist model for notification service
                let artistForNotification = Artist(
                    name: artist.name,
                    group: artist.agency,
                    imageURL: artist.imageURL
                )
                
                // Convert to ArtistUpdate model
                let artistUpdate = ArtistUpdate(
                    id: update.id.uuidString,
                    artistName: artistForNotification.name,
                    type: update.toArtistUpdateType(),
                    title: update.title,
                    description: update.content,
                    timestamp: update.timestamp,
                    sourceURL: update.externalURL,
                    imageURL: update.imageURL,
                    isBreaking: update.isBreakingNews
                )
                
                // Schedule notification (type is already in artistUpdate)
                await notificationService.scheduleArtistUpdate(
                    artistUpdate,
                    for: artistForNotification,
                    type: artistUpdate.type
                )
            }
        }
    }
    
    func followArtist(_ artist: ArtistProfile) {
        if !followedArtists.contains(where: { $0.id == artist.id }) {
            followedArtists.append(artist)
            saveFollowedArtists()
            
            // Fetch updates for new artist
            Task {
                await fetchUpdatesForArtist(artist)
            }
        }
    }
    
    func unfollowArtist(_ artistId: String) {
        followedArtists.removeAll { $0.id == artistId }
        updates.removeAll { $0.artistId == artistId }
        saveFollowedArtists()
    }
    
    func updateConfiguration(_ newConfig: NewsFeedConfiguration) {
        configuration = newConfig
        saveConfiguration()
        
        // Restart with new config
        Task {
            await refreshAllUpdates()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupInitialData() {
        // Load saved data
        loadFollowedArtists()
        loadConfiguration()
        
        // Load real artist data from database
        Task {
            await loadRealArtistData()
        }
    }
    
    /// Loads real artist data from database instead of mock data
    private func loadRealArtistData() async {
        do {
            // Get real artists from Supabase
            let supabaseService = SupabaseService.shared
            let artists = try await supabaseService.getArtists()
            
            // Convert to ArtistProfile format for compatibility
            let artistProfiles = artists.map { artist in
                ArtistProfile(
                    id: artist.id.uuidString,
                    name: artist.name,
                    koreanName: nil,
                    group: artist.group,
                    agency: nil,
                    debutDate: nil,
                    socialHandles: ArtistProfile.SocialHandles(
                        twitter: nil,
                        instagram: nil,
                        youtube: nil,
                        tiktok: nil,
                        weibo: nil,
                        vlive: nil,
                        universe: nil,
                        bubble: nil
                    ),
                    tags: [],
                    imageURL: artist.imageURL,
                    isFollowing: false,
                    notificationSettings: ArtistProfile.NotificationSettings(
                        enablePushNotifications: true,
                        breakingNewsOnly: false,
                        quietHours: nil,
                        updateTypes: [.social, .news, .comeback, .concert, .album]
                    )
                )
            }
            
            // Update followed artists with real data
            DispatchQueue.main.async {
                self.followedArtists = artistProfiles
                print("✅ Loaded \(artistProfiles.count) real artists from database")
            }
            
            // Generate some sample updates for real artists
            await generateSampleUpdatesForRealArtists(artists: artists)
            
        } catch {
            print("⚠️ Failed to load real artist data, using fallback: \(error)")
            // Fallback to embedded data from OnboardingService
            let onboardingService = OnboardingService.shared
            let fallbackArtists = onboardingService.getFallbackArtists()
            
            let artistProfiles = fallbackArtists.map { popularArtist in
                ArtistProfile(
                    id: popularArtist.artist.id.uuidString,
                    name: popularArtist.artist.name,
                    koreanName: nil,
                    group: popularArtist.artist.group,
                    agency: nil,
                    debutDate: nil,
                    socialHandles: ArtistProfile.SocialHandles(
                        twitter: nil,
                        instagram: nil,
                        youtube: nil,
                        tiktok: nil,
                        weibo: nil,
                        vlive: nil,
                        universe: nil,
                        bubble: nil
                    ),
                    tags: [],
                    imageURL: nil,
                    isFollowing: false,
                    notificationSettings: ArtistProfile.NotificationSettings(
                        enablePushNotifications: true,
                        breakingNewsOnly: false,
                        quietHours: nil,
                        updateTypes: [.social, .news, .comeback, .concert, .album]
                    )
                )
            }
            
            DispatchQueue.main.async {
                self.followedArtists = artistProfiles
                print("✅ Loaded \(artistProfiles.count) fallback artists")
            }
            
            updates = IdolUpdate.mockUpdates
            breakingNews = updates.filter { $0.isBreakingNews }
        }
    }
    
    /// Generates sample updates for real artists to provide content
    private func generateSampleUpdatesForRealArtists(artists: [Artist]) async {
        let sampleUpdateTemplates = [
            ("shared new behind-the-scenes photos", UpdateType.social, Platform.instagram),
            ("announced upcoming fan meeting", UpdateType.announcement, Platform.twitter),
            ("released new music video teaser", UpdateType.album, Platform.youtube),
            ("performed at special event", UpdateType.concert, Platform.soompi),
            ("won award at music show", UpdateType.award, Platform.allkpop)
        ]
        
        var newUpdates: [IdolUpdate] = []
        
        for artist in artists.prefix(10) { // Generate for first 10 artists
            if let template = sampleUpdateTemplates.randomElement() {
                let update = IdolUpdate(
                    artistId: artist.id.uuidString,
                    artistName: artist.name,
                    title: "\(artist.name) \(template.0)",
                    content: "Latest update from \(artist.name): \(template.0)",
                    aiSummary: "\(artist.name) \(template.0)",
                    originalContent: "\(artist.name) \(template.0)",
                    updateType: template.1,
                    platform: template.2,
                    timestamp: Date().addingTimeInterval(-Double.random(in: 3600...86400)), // 1-24 hours ago
                    sentiment: .positive,
                    tags: ["kpop", "update"],
                    engagementScore: Double.random(in: 70...100),
                    isBreakingNews: Bool.random() && Double.random(in: 0...1) < 0.2 // 20% chance
                )
                newUpdates.append(update)
            }
        }
        
        DispatchQueue.main.async {
            self.updates = newUpdates.sorted { $0.timestamp > $1.timestamp }
            self.breakingNews = self.updates.filter { $0.isBreakingNews }
            print("✅ Generated \(newUpdates.count) sample updates for real artists")
        }
    }
    
    private func fetchUpdatesForArtist(_ artist: ArtistProfile) async {
        // Implementation for fetching specific artist updates
        // In a real app, this would make API calls to social media platforms
    }
    
    private func fetchLatestUpdates() async {
        // Implementation for initial fetch
        await refreshAllUpdates()
    }
    
    private func startPeriodicUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: configuration.refreshInterval, repeats: true) { _ in
            Task {
                await self.refreshAllUpdates()
            }
        }
    }
    
    private func stopPeriodicUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - Data Persistence
    
    private func saveFollowedArtists() {
        if let data = try? JSONEncoder().encode(followedArtists) {
            UserDefaults.standard.set(data, forKey: "followedArtists")
        }
    }
    
    private func loadFollowedArtists() {
        if let data = UserDefaults.standard.data(forKey: "followedArtists"),
           let artists = try? JSONDecoder().decode([ArtistProfile].self, from: data) {
            followedArtists = artists
        }
    }
    
    private func saveConfiguration() {
        if let data = try? JSONEncoder().encode(configuration) {
            UserDefaults.standard.set(data, forKey: "newsFeedConfiguration")
        }
    }
    
    private func loadConfiguration() {
        if let data = UserDefaults.standard.data(forKey: "newsFeedConfiguration"),
           let config = try? JSONDecoder().decode(NewsFeedConfiguration.self, from: data) {
            configuration = config
        }
    }
}