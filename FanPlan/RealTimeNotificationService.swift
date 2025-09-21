import Foundation
import UserNotifications
import BackgroundTasks

// MARK: - Real-Time K-Pop Notification Service
@MainActor
class RealTimeNotificationService: ObservableObject {
    static let shared = RealTimeNotificationService()
    
    @Published var isMonitoring = false
    @Published var lastCheckTime = Date()
    @Published var monitoredArtists: Set<String> = []
    
    private let eventService = EventService.shared
    private let notificationService = ArtistNotificationService.shared
    private let databaseService = DatabaseService.shared
    private var monitoringTimer: Timer?
    private let monitoringInterval: TimeInterval = 300 // 5 minutes for real-time
    
    // K-pop comeback keywords for detection
    private let comebackKeywords = [
        "comeback", "new album", "새 앨범", "컴백", "발매", "release", "dropped", "출시", 
        "MV", "뮤직비디오", "music video", "티저", "teaser", "unveil", "announce", "발표"
    ]
    
    private let urgentKeywords = [
        "surprise", "emergency", "긴급", "깜짝", "suddenly", "unexpected", "갑자기", "즉석"
    ]
    
    private init() {
        loadSettings()
        registerBackgroundTasks()
        updateMonitoredArtistsFromUserSelection()
        
        // Listen for artist changes
        NotificationCenter.default.addObserver(
            forName: .userArtistsUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateMonitoredArtistsFromUserSelection()
            }
        }
    }
    
    // MARK: - Public Methods
    
    func startRealTimeMonitoring() {
        guard !isMonitoring else { return }
        
        print("🚀 Starting real-time K-pop comeback monitoring...")
        isMonitoring = true
        
        // Immediate check
        Task {
            await checkForNewEvents(isBackground: false)
        }
        
        // Set up periodic monitoring
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { _ in
            Task { @MainActor in
                await self.checkForNewEvents(isBackground: false)
            }
        }
        
        saveSettings()
    }
    
    func stopRealTimeMonitoring() {
        print("⏹️ Stopping real-time monitoring...")
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        saveSettings()
    }
    
    // MARK: - Event Monitoring
    
    private func checkForNewEvents(isBackground: Bool) async {
        print("🔍 Checking for new K-pop events... (Background: \(isBackground))")
        lastCheckTime = Date()
        
        // Get current events
        let previousEventCount = eventService.events.count
        await eventService.refreshEvents()
        
        let newEvents = eventService.events
        print("📊 Events check: \(previousEventCount) → \(newEvents.count)")
        
        // Check for comeback-related events
        await processNewEvents(newEvents, isBackground: isBackground)
    }
    
    private func processNewEvents(_ events: [KPopEvent], isBackground: Bool) async {
        let recentCutoff = Date().addingTimeInterval(-3600) // Last hour
        let recentEvents = events.filter { $0.publishedDate > recentCutoff }
        
        print("🆕 Processing \(recentEvents.count) recent events...")
        
        for event in recentEvents {
            await analyzeEventForNotification(event, isBackground: isBackground)
        }
    }
    
    private func analyzeEventForNotification(_ event: KPopEvent, isBackground: Bool) async {
        // Check if event mentions monitored artists
        let eventText = "\(event.title) \(event.summary ?? "")".lowercased()
        
        let mentionedArtists = monitoredArtists.filter { artist in
            eventText.contains(artist.lowercased())
        }
        
        guard !mentionedArtists.isEmpty else { return }
        
        // Check for comeback keywords
        let isComebackRelated = comebackKeywords.contains { keyword in
            eventText.contains(keyword.lowercased())
        }
        
        let isUrgent = urgentKeywords.contains { keyword in
            eventText.contains(keyword.lowercased())
        }
        
        if isComebackRelated || isUrgent {
            print("🚨 COMEBACK DETECTED: \(mentionedArtists.joined(separator: ", ")) - \(event.title)")
            
            for artist in mentionedArtists {
                await triggerComebackNotification(
                    artist: artist, 
                    event: event, 
                    isUrgent: isUrgent,
                    isBackground: isBackground
                )
            }
        }
    }
    
    // MARK: - Notification Triggering
    
    private func triggerComebackNotification(artist: String, event: KPopEvent, isUrgent: Bool, isBackground: Bool) async {
        let artistNotification = ArtistNotification(
            id: UUID(),
            artistId: artist.lowercased(),
            artistName: artist,
            updateId: event.id.uuidString,
            type: isUrgent ? .toursAndEvents : .comeback,
            title: isUrgent ? "🚨 BREAKING: \(artist)" : "🎉 \(artist) COMEBACK!",
            body: event.title,
            scheduledDate: Date(),
            isRead: false
        )
        
        // Send system notification
        await sendSystemNotification(artistNotification, isBackground: isBackground)
        
        // Trigger in-app notification (only if app is active)
        if !isBackground {
            notificationService.triggerInAppNotification(artistNotification)
            print("📱 In-app notification triggered for \(artist)")
        }
        
        // Log the notification
        print("📢 SENT NOTIFICATION: \(artist) - \(event.title)")
    }
    
    private func sendSystemNotification(_ notification: ArtistNotification, isBackground: Bool) async {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        content.badge = 1
        
        // Add rich media if possible
        content.categoryIdentifier = "COMEBACK"
        content.userInfo = [
            "artist_id": notification.artistId,
            "type": notification.type.rawValue,
            "update_id": notification.updateId
        ]
        
        // For urgent notifications, use critical alert (requires special entitlement)
        if notification.type == .toursAndEvents {
            content.sound = .defaultCritical
        }
        
        let request = UNNotificationRequest(
            identifier: "comeback_\(notification.artistId)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Immediate delivery
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ System notification sent for \(notification.artistName)")
        } catch {
            print("❌ Failed to send system notification: \(error)")
        }
    }
    
    // MARK: - Background Tasks
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.piggybong.kpop-monitoring",
            using: nil
        ) { task in
            self.handleBackgroundMonitoring(task: task as! BGAppRefreshTask)
        }
    }
    
    private func handleBackgroundMonitoring(task: BGAppRefreshTask) {
        print("🔄 Background K-pop monitoring triggered")
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        Task {
            await checkForNewEvents(isBackground: true)
            task.setTaskCompleted(success: true)
            
            // Schedule next background refresh
            scheduleBackgroundAppRefresh()
        }
    }
    
    func scheduleBackgroundAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.piggybong.kpop-monitoring")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("📅 Background refresh scheduled")
        } catch {
            print("❌ Failed to schedule background refresh: \(error)")
        }
    }
    
    // MARK: - Dynamic Artist Management
    
    @MainActor
    func updateMonitoredArtistsFromUserSelection() {
        let userSelectedArtists = Set(databaseService.userArtists.map { $0.name })
        
        if userSelectedArtists != monitoredArtists {
            monitoredArtists = userSelectedArtists
            print("🎯 Updated monitored artists: \(Array(monitoredArtists).sorted().joined(separator: ", "))")
            saveSettings()
            
            // Restart monitoring with new artist list if currently active
            if isMonitoring {
                stopRealTimeMonitoring()
                startRealTimeMonitoring()
            }
        }
    }
    
    // MARK: - Dynamic Test Functions
    
    var userSelectedArtists: [Artist] {
        Array(databaseService.userArtists.prefix(2)) // Show test buttons for first 2 artists
    }
    
    func testNotificationForArtist(_ artist: Artist) async {
        print("🧪 Testing \(artist.name) comeback notification...")
        
        let testEvent = KPopEvent(
            id: UUID(),
            title: "🎉 \(artist.name) Drops Surprise New Content!",
            summary: "\(artist.name) has just announced their highly anticipated comeback with new music that fans have been waiting for!",
            url: URL(string: "https://soompi.com")!,
            imageURL: nil,
            publishedDate: Date(),
            category: .comeback,
            isBreaking: false,
            matchedArtists: [artist.name],
            source: .soompi
        )
        
        await triggerComebackNotification(
            artist: artist.name,
            event: testEvent,
            isUrgent: false,
            isBackground: false
        )
    }
    
    func testUrgentNotificationForArtist(_ artist: Artist) async {
        print("🧪 Testing URGENT \(artist.name) notification...")
        
        let testEvent = KPopEvent(
            id: UUID(),
            title: "🚨 BREAKING: \(artist.name) Surprise Announcement!",
            summary: "URGENT: \(artist.name) just made a shocking announcement that has fans going absolutely wild! This is huge news!",
            url: URL(string: "https://soompi.com")!,
            imageURL: nil,
            publishedDate: Date(),
            category: .comeback,
            isBreaking: true,
            matchedArtists: [artist.name],
            source: .soompi
        )
        
        await triggerComebackNotification(
            artist: artist.name,
            event: testEvent,
            isUrgent: true,
            isBackground: false
        )
    }
    
    // MARK: - Settings Persistence
    
    private func saveSettings() {
        UserDefaults.standard.set(isMonitoring, forKey: "realtime_monitoring_enabled")
        // Don't save monitored artists to UserDefaults - they come from user's selection
    }
    
    private func loadSettings() {
        isMonitoring = UserDefaults.standard.bool(forKey: "realtime_monitoring_enabled")
        // Monitored artists will be loaded from user's database selection
    }
}

// MARK: - Extensions for test events

extension EventCategory {
    static let breaking = EventCategory.all  // Use existing category for now
}

// MARK: - Notification Names
extension Notification.Name {
    static let userArtistsUpdated = Notification.Name("userArtistsUpdated")
}