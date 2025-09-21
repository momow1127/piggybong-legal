import Foundation
import UserNotifications
import SwiftUI

// MARK: - Notification Delegate
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, Sendable {
    static let shared = NotificationDelegate()
    
    override private init() {
        super.init()
    }
    
    // MARK: - Foreground Notifications
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .badge, .sound])
        
        // Track the notification
        trackNotificationReceived(notification)
    }
    
    // MARK: - Notification Response
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        print("🔔 Notification action: \(actionIdentifier)")
        print("📱 User info: \(userInfo)")
        
        // Handle different action types
        switch actionIdentifier {
        case "VIEW_DETAILS", "VIEW_POST", "VIEW_EVENT", "VIEW_DATES":
            handleViewAction(userInfo: userInfo)
            
        case "GET_TICKETS":
            handleTicketAction(userInfo: userInfo)
            
        case "SAVE_FOR_TICKETS", "START_SAVING", "SET_GOAL":
            handleSavingAction(userInfo: userInfo)
            
        case "LISTEN_NOW":
            handleListenAction(userInfo: userInfo)
            
        case "PRE_ORDER":
            handlePreOrderAction(userInfo: userInfo)
            
        case "WATCH_LIVE":
            handleWatchLiveAction(userInfo: userInfo)
            
        case "SET_REMINDER":
            handleReminderAction(userInfo: userInfo)
            
        case "SHARE":
            handleShareAction(userInfo: userInfo)
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            handleDefaultAction(userInfo: userInfo)
            
        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            print("🚫 User dismissed notification")
            
        default:
            print("⚠️ Unknown notification action: \(actionIdentifier)")
        }
        
        // Mark notification as read
        if let updateId = userInfo["update_id"] as? String {
            markNotificationAsRead(updateId)
        }
        
        completionHandler()
    }
    
    // MARK: - Action Handlers
    private func handleViewAction(userInfo: [AnyHashable: Any]) {
        if let urlString = userInfo["url"] as? String,
           let url = URL(string: urlString) {
            openURL(url)
        } else {
            openAppToArtist(userInfo: userInfo)
        }
    }
    
    private func handleTicketAction(userInfo: [AnyHashable: Any]) {
        // Open ticketing app or website
        let ticketingSites = [
            "https://www.ticketmaster.com",
            "https://www.stubhub.com",
            "https://seatgeek.com"
        ]
        
        if let randomSite = ticketingSites.randomElement(),
           let url = URL(string: randomSite) {
            openURL(url)
        }
    }
    
    private func handleSavingAction(userInfo: [AnyHashable: Any]) {
        // Open app to goal creation screen
        NotificationCenter.default.post(
            name: NSNotification.Name("CreateGoalFromNotification"),
            object: nil,
            userInfo: userInfo
        )
        openAppToArtist(userInfo: userInfo)
    }
    
    private func handleListenAction(userInfo: [AnyHashable: Any]) {
        // Open music streaming apps
        let musicApps = [
            "https://open.spotify.com",
            "https://music.apple.com",
            "https://music.youtube.com"
        ]
        
        if let randomApp = musicApps.randomElement(),
           let url = URL(string: randomApp) {
            openURL(url)
        }
    }
    
    private func handlePreOrderAction(userInfo: [AnyHashable: Any]) {
        if let urlString = userInfo["url"] as? String,
           let url = URL(string: urlString) {
            openURL(url)
        } else {
            // Default to music store
            if let url = URL(string: "https://music.apple.com") {
                openURL(url)
            }
        }
    }
    
    private func handleWatchLiveAction(userInfo: [AnyHashable: Any]) {
        // Open live streaming platforms
        let liveApps = [
            "https://www.youtube.com",
            "https://www.instagram.com",
            "https://www.tiktok.com"
        ]
        
        if let randomApp = liveApps.randomElement(),
           let url = URL(string: randomApp) {
            openURL(url)
        }
    }
    
    private func handleReminderAction(userInfo: [AnyHashable: Any]) {
        // Schedule a follow-up reminder
        Task {
            await scheduleFollowUpReminder(userInfo: userInfo)
        }
    }
    
    private func handleShareAction(userInfo: [AnyHashable: Any]) {
        // Trigger share sheet in app
        NotificationCenter.default.post(
            name: NSNotification.Name("ShareFromNotification"),
            object: nil,
            userInfo: userInfo
        )
        openAppToArtist(userInfo: userInfo)
    }
    
    private func handleDefaultAction(userInfo: [AnyHashable: Any]) {
        // Open app to relevant screen
        openAppToArtist(userInfo: userInfo)
    }
    
    // MARK: - Helper Methods
    private func openURL(_ url: URL) {
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }
    
    private func openAppToArtist(userInfo: [AnyHashable: Any]) {
        // Post notification to navigate to artist in app
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenArtistFromNotification"),
            object: nil,
            userInfo: userInfo
        )
    }
    
    private func markNotificationAsRead(_ updateId: String) {
        Task { @MainActor in
            if let notificationId = UUID(uuidString: updateId) {
                ArtistNotificationService.shared.markNotificationAsRead(notificationId)
            }
        }
    }
    
    private func trackNotificationReceived(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        
        // Analytics tracking
        if let artistId = userInfo["artist_id"] as? String,
           let type = userInfo["type"] as? String {
            print("📊 Notification received: \(type) for artist \(artistId)")
            
            // Track engagement metrics
            UserDefaults.standard.set(Date(), forKey: "last_notification_received")
            
            let key = "notification_count_\(type)"
            let currentCount = UserDefaults.standard.integer(forKey: key)
            UserDefaults.standard.set(currentCount + 1, forKey: key)
        }
    }
    
    private func scheduleFollowUpReminder(userInfo: [AnyHashable: Any]) async {
        guard let artistName = userInfo["artist_id"] as? String else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🔔 Don't Forget!"
        content.body = "Remember to check updates for \(artistName)"
        content.sound = .default
        
        // Schedule for 1 hour later
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        let request = UNNotificationRequest(
            identifier: "reminder_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        try? await UNUserNotificationCenter.current().add(request)
        print("⏰ Follow-up reminder scheduled for \(artistName)")
    }
}

// MARK: - Deep Link Handler
extension NotificationDelegate {
    static func setupDeepLinkHandlers() {
        // Listen for app-specific deep link notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OpenArtistFromNotification"),
            object: nil,
            queue: .main
        ) { notification in
            handleArtistDeepLink(notification.userInfo)
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CreateGoalFromNotification"),
            object: nil,
            queue: .main
        ) { notification in
            handleGoalCreationDeepLink(notification.userInfo)
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ShareFromNotification"),
            object: nil,
            queue: .main
        ) { notification in
            handleShareDeepLink(notification.userInfo)
        }
    }
    
    private static func handleArtistDeepLink(_ userInfo: [AnyHashable: Any]?) {
        guard let userInfo = userInfo,
              let artistId = userInfo["artist_id"] as? String else { return }
        
        // Navigate to artist page
        print("🎯 Deep linking to artist: \(artistId)")
        
        // Post notification for navigation
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToArtist"),
                object: artistId
            )
        }
    }
    
    private static func handleGoalCreationDeepLink(_ userInfo: [AnyHashable: Any]?) {
        guard let userInfo = userInfo else { return }
        
        print("🎯 Deep linking to goal creation")
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToGoalCreation"),
                object: userInfo
            )
        }
    }
    
    private static func handleShareDeepLink(_ userInfo: [AnyHashable: Any]?) {
        guard let userInfo = userInfo else { return }
        
        print("🎯 Deep linking to share")
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("TriggerShare"),
                object: userInfo
            )
        }
    }
}