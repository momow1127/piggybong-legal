import SwiftUI
import UserNotifications
import Combine

// MARK: - Artist Notification Service
@MainActor
class ArtistNotificationService: ObservableObject {
    // MARK: - Published Properties
    @Published var isNotificationsEnabled = false
    @Published var notificationSettings = ArtistNotificationSettings()
    @Published var scheduledNotifications: [ArtistNotification] = []
    @Published var recentNotifications: [ArtistNotification] = []
    
    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private let supabaseService = SupabaseService.shared
    
    // MARK: - Artist Following Cache
    private var followedArtistIds: Set<UUID> = []
    private var cacheTimestamp: Date = Date.distantPast
    private let cacheTimeToLive: TimeInterval = 300 // 5 minutes
    
    // MARK: - Singleton
    static let shared = ArtistNotificationService()
    
    private init() {
        setupNotificationCategories()
        checkNotificationStatus()
        loadSettings()
        
        // Warm the cache on init
        Task {
            await refreshFollowedArtistsCache()
        }
        
        // Refresh cache on app foreground
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.refreshFollowedArtistsCache()
            }
        }
    }
    
    // MARK: - Setup
    private func setupNotificationCategories() {
        // Comeback Category
        let comebackCategory = UNNotificationCategory(
            identifier: "COMEBACK",
            actions: [
                UNNotificationAction(identifier: "VIEW_DETAILS", title: "View Details", options: .foreground),
                UNNotificationAction(identifier: "SET_REMINDER", title: "Remind Me", options: []),
                UNNotificationAction(identifier: "SHARE", title: "Share", options: .foreground)
            ],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Tour Category
        let tourCategory = UNNotificationCategory(
            identifier: "TOUR",
            actions: [
                UNNotificationAction(identifier: "GET_TICKETS", title: "Get Tickets", options: .foreground),
                UNNotificationAction(identifier: "SAVE_FOR_TICKETS", title: "Start Saving", options: .foreground),
                UNNotificationAction(identifier: "VIEW_DATES", title: "View All Dates", options: .foreground)
            ],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Release Category
        let releaseCategory = UNNotificationCategory(
            identifier: "RELEASE",
            actions: [
                UNNotificationAction(identifier: "LISTEN_NOW", title: "Listen Now", options: .foreground),
                UNNotificationAction(identifier: "PRE_ORDER", title: "Pre-Order", options: .foreground)
            ],
            intentIdentifiers: [],
            options: []
        )
        
        // Social Media Category
        let socialCategory = UNNotificationCategory(
            identifier: "SOCIAL",
            actions: [
                UNNotificationAction(identifier: "VIEW_POST", title: "View Post", options: .foreground),
                UNNotificationAction(identifier: "WATCH_LIVE", title: "Watch Live", options: .foreground)
            ],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([
            comebackCategory,
            tourCategory,
            releaseCategory,
            socialCategory
        ])
    }
    
    // MARK: - Permission Management
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound, .providesAppNotificationSettings]
            )
            
            DispatchQueue.main.async {
                self.isNotificationsEnabled = granted
            }
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            
            return granted
        } catch {
            print("❌ Error requesting notification permission: \(error)")
            return false
        }
    }
    
    func checkNotificationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Permission Status
    @Published var permissionStatus: NotificationAuthStatus = .notDetermined
    
    // MARK: - Authorization Status Mapper
    func getNotificationAuthStatus() async -> NotificationAuthStatus {
        let settings = await notificationCenter.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .provisional: return .provisional
        case .authorized: return .authorized
        case .ephemeral: return .authorized
        @unknown default: return .denied
        }
    }
    
    // MARK: - Permission Management Methods
    func refreshPermissionStatus() async {
        let status = await getNotificationAuthStatus()
        DispatchQueue.main.async {
            self.permissionStatus = status
        }
    }
    
    func openSystemSettings() {
        Task {
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                await UIApplication.shared.open(settingsUrl)
            }
        }
    }
    
    // MARK: - Notification Scheduling
    func scheduleArtistUpdate(
        _ update: ArtistUpdate,
        for artist: Artist,
        type: ArtistUpdateType
    ) async {
        guard isNotificationsEnabled else { return }
        guard shouldNotify(for: type, artist: artist) else { return }
        
        let content = UNMutableNotificationContent()
        
        // Configure content based on simplified update type
        switch type.simplifiedCategory {
        case .comebacksAndReleases:
            content.title = "🎵 \(artist.name) New Release!"
            content.body = update.title
            content.categoryIdentifier = "COMEBACK"
            content.sound = .defaultCritical
            content.interruptionLevel = .timeSensitive
            
        case .toursAndEvents:
            content.title = "🎫 \(artist.name) Event Announcement"
            content.body = "\(update.title)\nDon't miss out!"
            content.categoryIdentifier = "TOUR"
            content.sound = .defaultCritical
            content.interruptionLevel = .timeSensitive
            
        case .merchDrops:
            content.title = "🛍️ \(artist.name) Merch Drop"
            content.body = "\(update.title)\nLimited stock available!"
            content.categoryIdentifier = "MERCH"
            content.sound = .default
            
        default:
            // Fallback for any unmapped legacy types
            content.title = "📢 \(artist.name) Update"
            content.body = update.title
            content.sound = .default
        }
        
        // Add user info for deep linking
        content.userInfo = [
            "artist_id": artist.id.uuidString,
            "update_id": update.id,
            "type": type.rawValue,
            "url": update.sourceURL ?? ""
        ]
        
        // Add image if available
        if let imageURL = update.imageURL {
            await attachImage(to: content, from: imageURL)
        }
        
        // Create trigger (immediate for breaking news)
        let trigger = update.isBreaking 
            ? UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            : UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "artist_\(artist.id.uuidString)_\(update.id)",
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        do {
            try await notificationCenter.add(request)
            
            // Track notification
            let notification = ArtistNotification(
                id: UUID(),
                artistId: artist.id.uuidString,
                artistName: artist.name,
                updateId: update.id,
                type: type,
                title: content.title,
                body: content.body,
                scheduledDate: Date(),
                isRead: false
            )
            
            DispatchQueue.main.async {
                self.scheduledNotifications.append(notification)
                self.saveRecentNotification(notification)
            }
            
            print("✅ Scheduled \(type.rawValue) notification for \(artist.name)")
        } catch {
            print("❌ Error scheduling notification: \(error)")
        }
    }
    
    // MARK: - Smart Notification Logic
    private func shouldNotify(for type: ArtistUpdateType, artist: Artist) -> Bool {
        // Check if artist is followed
        guard isArtistFollowed(artist) else { return false }
        
        // Check notification settings (simplified categories)
        switch type.simplifiedCategory {
        case .comebacksAndReleases:
            return notificationSettings.comebacksAndReleases
        case .toursAndEvents:
            return notificationSettings.toursAndEvents
        case .merchDrops:
            return notificationSettings.merchDrops
        default:
            // Legacy cases that don't map to core categories are disabled for MVP
            return false
        }
    }
    
    private func isArtistFollowed(_ artist: Artist) -> Bool {
        // Check if cache needs refresh (TTL expired)
        let now = Date()
        if now.timeIntervalSince(cacheTimestamp) > cacheTimeToLive {
            // Async refresh without blocking current check
            Task {
                await refreshFollowedArtistsCache()
            }
        }
        
        // Return current cache state (O(1) lookup)
        return followedArtistIds.contains(artist.id)
    }
    
    // MARK: - Cache Management
    private func refreshFollowedArtistsCache() async {
        guard let userId = AuthenticationService.shared.currentUser?.id else {
            print("❌ No authenticated user for followed artists cache")
            return
        }
        
        do {
            let userArtists = try await supabaseService.getUserArtists(userId: userId)
            
            // Extract artist IDs from response
            let artistIds = Set(userArtists.map { $0.artistId })
            
            // Update cache on main thread
            await MainActor.run {
                self.followedArtistIds = artistIds
                self.cacheTimestamp = Date()
                print("✅ Followed artists cache refreshed: \(artistIds.count) artists")
            }
        } catch {
            print("❌ Failed to refresh followed artists cache: \(error)")
            // Keep existing cache on error - don't crash or block
        }
    }

    // MARK: - Real Data Fetching

    /// Fetch real notifications from Supabase functions
    func fetchRealNotifications() async {
        guard let userId = AuthenticationService.shared.currentUser?.id else {
            print("❌ No authenticated user for notifications")
            return
        }

        do {
            // Get user's selected artists
            let userArtists = try await supabaseService.getUserArtists(userId: userId)
            let artistNames = userArtists.compactMap { userArtist in
                // Get artist name from the database
                // For now, use a simple mapping - this could be improved
                return userArtist.artistId.uuidString
            }

            guard !artistNames.isEmpty else {
                print("ℹ️ No artists selected for notifications")
                await MainActor.run {
                    self.recentNotifications = []
                }
                return
            }

            // Fetch artist updates from deployed function
            let artistUpdates = try await supabaseService.getArtistUpdates(
                artistNames: artistNames,
                limit: 20
            )

            // Convert to ArtistNotification objects
            let notifications = artistUpdates.map { update in
                ArtistNotification(
                    id: UUID(),
                    artistId: update.id,
                    artistName: update.artistName,
                    updateId: update.id,
                    type: update.type,
                    title: update.title,
                    body: update.description ?? update.title,
                    scheduledDate: update.timestamp,
                    isRead: false
                )
            }

            // Update on main thread
            await MainActor.run {
                self.recentNotifications = notifications
                print("✅ Fetched \(notifications.count) real notifications")
            }

        } catch {
            print("❌ Failed to fetch real notifications: \(error)")
            // Keep existing notifications on error
        }
    }

    // MARK: - Image Attachment
    private func attachImage(to content: UNMutableNotificationContent, from urlString: String) async {
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Save image to temp directory
            let fileManager = FileManager.default
            let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
            let tmpSubFolderURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(tmpSubFolderName, isDirectory: true)
            
            try fileManager.createDirectory(at: tmpSubFolderURL, withIntermediateDirectories: true)
            
            let imageFileIdentifier = UUID().uuidString + ".jpg"
            let fileURL = tmpSubFolderURL.appendingPathComponent(imageFileIdentifier)
            
            try data.write(to: fileURL)
            
            let imageAttachment = try UNNotificationAttachment(
                identifier: imageFileIdentifier,
                url: fileURL,
                options: nil
            )
            
            content.attachments = [imageAttachment]
        } catch {
            print("⚠️ Failed to attach image: \(error)")
        }
    }
    
    // MARK: - Recent Notifications
    private func saveRecentNotification(_ notification: ArtistNotification) {
        recentNotifications.insert(notification, at: 0)
        
        // Keep only last 50 notifications
        if recentNotifications.count > 50 {
            recentNotifications = Array(recentNotifications.prefix(50))
        }
        
        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(recentNotifications) {
            userDefaults.set(encoded, forKey: "recent_artist_notifications")
        }
    }
    
    func markNotificationAsRead(_ notificationId: UUID) {
        if let index = recentNotifications.firstIndex(where: { $0.id == notificationId }) {
            recentNotifications[index].isRead = true
            saveRecentNotifications()
        }
    }
    
    private func saveRecentNotifications() {
        if let encoded = try? JSONEncoder().encode(recentNotifications) {
            userDefaults.set(encoded, forKey: "recent_artist_notifications")
        }
    }
    
    // MARK: - Settings Management
    func updateSettings(_ settings: ArtistNotificationSettings) {
        notificationSettings = settings
        saveSettings()
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(notificationSettings) {
            userDefaults.set(encoded, forKey: "artist_notification_settings")
        }
    }
    
    private func loadSettings() {
        if let data = userDefaults.data(forKey: "artist_notification_settings"),
           let settings = try? JSONDecoder().decode(ArtistNotificationSettings.self, from: data) {
            notificationSettings = settings
        }
        
        if let data = userDefaults.data(forKey: "recent_artist_notifications"),
           let notifications = try? JSONDecoder().decode([ArtistNotification].self, from: data) {
            recentNotifications = notifications
        }
    }
    
    // MARK: - Badge Management
    func updateBadgeCount() {
        let unreadCount = recentNotifications.filter { !$0.isRead }.count
        Task {
            try? await notificationCenter.setBadgeCount(unreadCount)
        }
    }
    
    // MARK: - Clear Notifications
    func clearAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        scheduledNotifications.removeAll()
        recentNotifications.removeAll()
        saveRecentNotifications()
        updateBadgeCount()
    }
    
    func clearNotificationsForArtist(_ artistId: String) {
        // Remove pending notifications
        notificationCenter.getPendingNotificationRequests { requests in
            let toRemove = requests
                .filter { $0.content.userInfo["artist_id"] as? String == artistId }
                .map { $0.identifier }
            
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: toRemove)
        }
        
        // Remove from scheduled list
        scheduledNotifications.removeAll { $0.artistId == artistId }
        
        // Remove from recent list
        recentNotifications.removeAll { $0.artistId == artistId }
        saveRecentNotifications()
    }
}

// MARK: - Authorization Status
enum NotificationAuthStatus {
    case notDetermined, denied, provisional, authorized
    
    var displayText: String {
        switch self {
        case .notDetermined: return "Not set"
        case .denied: return "Off"
        case .provisional: return "On (silent)"
        case .authorized: return "On"
        }
    }
    
    var ctaText: String {
        switch self {
        case .notDetermined: return "Enable Notifications"
        case .denied: return "Open Settings"
        case .provisional: return "Enable Alerts"
        case .authorized: return "Manage in Settings"
        }
    }
}

// MARK: - Notification Models
struct ArtistNotification: Identifiable, Codable {
    let id: UUID
    let artistId: String
    let artistName: String
    let updateId: String
    let type: ArtistUpdateType
    let title: String
    let body: String
    let scheduledDate: Date
    var isRead: Bool
}

struct ArtistNotificationSettings: Codable, Equatable {
    // Core notification categories (simplified for MVP)
    var comebacksAndReleases: Bool = true  // Covers: comebacks, albums, singles, MVs
    var toursAndEvents: Bool = true        // Covers: tours, fan events, ticket sales
    var merchDrops: Bool = true            // Covers: merch, collabs, limited editions
    
    // Smart settings (simplified)
    var onlyHighPriorityArtists: Bool = false  // Limit to top 1-2 artists
    var quietHoursEnabled: Bool = false        // Pause 10pm-8am
    var quietHoursStart: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    var quietHoursEnd: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    
    // Legacy properties for backward compatibility (will deprecate)
    var comebackAlerts: Bool { comebacksAndReleases }
    var tourAlerts: Bool { toursAndEvents }
    var releaseAlerts: Bool { comebacksAndReleases }
    var tvAppearanceAlerts: Bool { false }
    var socialMediaAlerts: Bool { false }
    var merchAlerts: Bool { merchDrops }
    var awardAlerts: Bool { false }
    var collabAlerts: Bool { merchDrops }
    var groupSimilarUpdates: Bool { true }
}

enum ArtistUpdateType: String, Codable, CaseIterable {
    // Simplified categories for MVP
    case comebacksAndReleases = "comebacks_releases"  // Groups: comebacks, albums, singles, MVs
    case toursAndEvents = "tours_events"              // Groups: tours, fan events, concerts
    case merchDrops = "merch_drops"                   // Groups: merch, collabs, limited editions
    
    // Legacy cases for backward compatibility (map to new categories)
    case comeback = "comeback"
    case tour = "tour"
    case newRelease = "new_release"
    case tvAppearance = "tv_appearance"
    case socialMedia = "social_media"
    case merchandise = "merchandise"
    case award = "award"
    case collaboration = "collaboration"
    
    var displayName: String {
        switch self {
        case .comebacksAndReleases: return "Comebacks & Releases"
        case .toursAndEvents: return "Tours & Events"
        case .merchDrops: return "Merch Drops"
        // Legacy mappings
        case .comeback, .newRelease: return "Comebacks & Releases"
        case .tour: return "Tours & Events"
        case .merchandise, .collaboration: return "Merch Drops"
        case .tvAppearance, .socialMedia, .award: return "Other Updates"
        }
    }
    
    var icon: String {
        switch self {
        case .comebacksAndReleases, .comeback, .newRelease: return "music.note.list"
        case .toursAndEvents, .tour: return "ticket.fill"
        case .merchDrops, .merchandise, .collaboration: return "bag.fill"
        case .tvAppearance, .socialMedia, .award: return "ellipsis.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .comebacksAndReleases, .comeback, .newRelease: return .purple
        case .toursAndEvents, .tour: return .pink
        case .merchDrops, .merchandise, .collaboration: return .green
        case .tvAppearance, .socialMedia, .award: return .gray
        }
    }
    
    // Helper to get simplified category
    var simplifiedCategory: ArtistUpdateType {
        switch self {
        case .comeback, .newRelease, .comebacksAndReleases:
            return .comebacksAndReleases
        case .tour, .toursAndEvents:
            return .toursAndEvents
        case .merchandise, .collaboration, .merchDrops:
            return .merchDrops
        default:
            return self
        }
    }

    // Convert string to ArtistUpdateType
    static func from(string: String) -> ArtistUpdateType {
        return ArtistUpdateType(rawValue: string) ?? .newRelease
    }
}



// MARK: - Artist Update Model
struct ArtistUpdate: Identifiable, Codable {
    let id: String
    let artistName: String
    let type: ArtistUpdateType
    let title: String
    let description: String?
    let timestamp: Date
    let sourceURL: String?
    let imageURL: String?
    let isBreaking: Bool
}
