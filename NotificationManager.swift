import Foundation
import UserNotifications
import UIKit

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isPermissionGranted = false
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Permission Management
    
    func requestPermission(completion: @escaping (Bool, Error?) -> Void) {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .badge, .sound, .criticalAlert]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.authorizationStatus = granted ? .authorized : .denied
                self?.isPermissionGranted = granted
                
                if granted {
                    // Register for remote notifications
                    UIApplication.shared.registerForRemoteNotifications()
                }
                
                completion(granted, error)
            }
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
                self?.isPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }
        UIApplication.shared.open(settingsUrl)
    }
    
    // MARK: - Local Notification Scheduling
    
    func scheduleLocalNotification(
        title: String,
        body: String,
        identifier: String,
        timeInterval: TimeInterval = 5,
        repeats: Bool = false,
        categoryIdentifier: String? = nil
    ) {
        guard isPermissionGranted else {
            print("Notification permission not granted")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        if let categoryId = categoryIdentifier {
            content.categoryIdentifier = categoryId
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: repeats)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Successfully scheduled notification: \(identifier)")
            }
        }
    }
    
    func scheduleEventReminder(
        eventName: String,
        eventDate: Date,
        reminderMinutes: Int = 30
    ) {
        guard isPermissionGranted else { return }
        
        let reminderDate = eventDate.addingTimeInterval(-TimeInterval(reminderMinutes * 60))
        
        // Don't schedule notifications for past events
        guard reminderDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Event Reminder"
        content.body = "\(eventName) starts in \(reminderMinutes) minutes!"
        content.sound = .default
        content.categoryIdentifier = "EVENT_REMINDER"
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let identifier = "event_reminder_\(eventName)_\(Int(eventDate.timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling event reminder: \(error.localizedDescription)")
            }
        }
    }
    
    func cancelNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    // MARK: - Badge Management
    
    func updateBadgeCount(_ count: Int) {
        UIApplication.shared.applicationIconBadgeNumber = count
    }
    
    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    // MARK: - Notification Categories
    
    func setupNotificationCategories() {
        let eventReminderCategory = UNNotificationCategory(
            identifier: "EVENT_REMINDER",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_EVENT",
                    title: "View Event",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "DISMISS",
                    title: "Dismiss",
                    options: []
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let concertAlertCategory = UNNotificationCategory(
            identifier: "CONCERT_ALERT",
            actions: [
                UNNotificationAction(
                    identifier: "BUY_TICKETS",
                    title: "Buy Tickets",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "SAVE_EVENT",
                    title: "Save for Later",
                    options: []
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            eventReminderCategory,
            concertAlertCategory
        ])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let identifier = response.notification.request.identifier
        let actionIdentifier = response.actionIdentifier
        
        print("Notification tapped - ID: \(identifier), Action: \(actionIdentifier)")
        
        // Handle different notification actions
        switch actionIdentifier {
        case "VIEW_EVENT":
            handleViewEvent(userInfo: userInfo)
        case "BUY_TICKETS":
            handleBuyTickets(userInfo: userInfo)
        case "SAVE_EVENT":
            handleSaveEvent(userInfo: userInfo)
        default:
            // Default tap action
            handleDefaultNotificationTap(userInfo: userInfo)
        }
        
        completionHandler()
    }
    
    private func handleViewEvent(userInfo: [AnyHashable: Any]) {
        // Navigate to event details
        NotificationCenter.default.post(
            name: .notificationTappedViewEvent,
            object: nil,
            userInfo: userInfo
        )
    }
    
    private func handleBuyTickets(userInfo: [AnyHashable: Any]) {
        // Open ticket purchasing flow
        NotificationCenter.default.post(
            name: .notificationTappedBuyTickets,
            object: nil,
            userInfo: userInfo
        )
    }
    
    private func handleSaveEvent(userInfo: [AnyHashable: Any]) {
        // Save event for later
        NotificationCenter.default.post(
            name: .notificationTappedSaveEvent,
            object: nil,
            userInfo: userInfo
        )
    }
    
    private func handleDefaultNotificationTap(userInfo: [AnyHashable: Any]) {
        // Handle default notification tap
        NotificationCenter.default.post(
            name: .notificationTappedDefault,
            object: nil,
            userInfo: userInfo
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let notificationTappedViewEvent = Notification.Name("notificationTappedViewEvent")
    static let notificationTappedBuyTickets = Notification.Name("notificationTappedBuyTickets")
    static let notificationTappedSaveEvent = Notification.Name("notificationTappedSaveEvent")
    static let notificationTappedDefault = Notification.Name("notificationTappedDefault")
}

// MARK: - Remote Notification Handling

extension NotificationManager {
    
    func handleRemoteNotificationRegistration(deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        
        // Send token to your backend server
        // This is where you'd typically send the token to your server
        // for push notification delivery
    }
    
    func handleRemoteNotificationRegistrationError(_ error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func handleRemoteNotification(userInfo: [AnyHashable: Any]) {
        print("Received remote notification: \(userInfo)")
        
        // Process the remote notification payload
        // Update app state, show alerts, etc.
        
        // If the app was launched from a notification, handle the deep linking
        if let eventId = userInfo["eventId"] as? String {
            // Navigate to specific event
            NotificationCenter.default.post(
                name: .notificationTappedViewEvent,
                object: nil,
                userInfo: ["eventId": eventId]
            )
        }
    }
}