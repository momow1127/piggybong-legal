import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Setup notification categories
        NotificationManager.shared.setupNotificationCategories()
        
        // Check if app was launched from notification
        if let notificationUserInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            // Handle launch from notification
            NotificationManager.shared.handleRemoteNotification(userInfo: notificationUserInfo)
        }
        
        return true
    }
    
    // MARK: - Remote Notification Registration
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationManager.shared.handleRemoteNotificationRegistration(deviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationManager.shared.handleRemoteNotificationRegistrationError(error)
    }
    
    // MARK: - Remote Notification Handling
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        NotificationManager.shared.handleRemoteNotification(userInfo: userInfo)
        
        // Determine the result based on what you did with the notification
        // For now, we'll assume new data was fetched
        completionHandler(.newData)
    }
    
    // MARK: - Background App Refresh
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle background app refresh
        // This is where you might fetch new content or update the app
        
        // For example, check for new concerts, album releases, etc.
        // checkForNewContent { hasNewContent in
        //     completionHandler(hasNewContent ? .newData : .noData)
        // }
        
        completionHandler(.noData)
    }
    
    // MARK: - URL Scheme Handling (Deep Links)
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle deep links from notifications or other sources
        
        if url.scheme == "piggybong" {
            handleDeepLink(url: url)
            return true
        }
        
        return false
    }
    
    // MARK: - Orientation Support (Portrait Only)
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
    
    private func handleDeepLink(url: URL) {
        // Parse the URL and navigate to the appropriate screen
        let pathComponents = url.pathComponents
        
        if pathComponents.count > 1 {
            switch pathComponents[1] {
            case "event":
                if pathComponents.count > 2 {
                    let eventId = pathComponents[2]
                    // Navigate to event with ID
                    NotificationCenter.default.post(
                        name: .notificationTappedViewEvent,
                        object: nil,
                        userInfo: ["eventId": eventId]
                    )
                }
            case "concert":
                if pathComponents.count > 2 {
                    let concertId = pathComponents[2]
                    // Navigate to concert with ID
                    NotificationCenter.default.post(
                        name: .notificationTappedBuyTickets,
                        object: nil,
                        userInfo: ["concertId": concertId]
                    )
                }
            default:
                // Navigate to main dashboard
                NotificationCenter.default.post(
                    name: .notificationTappedDefault,
                    object: nil,
                    userInfo: ["deepLink": url.absoluteString]
                )
            }
        }
    }
}