import Foundation
import UserNotifications
import UIKit

@MainActor
class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()

    @Published var isRegistered = false
    @Published var deviceToken: String?
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private override init() {
        super.init()
        checkCurrentAuthorizationStatus()
    }

    // MARK: - Permission Request

    func requestPushNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])

            await MainActor.run {
                self.authorizationStatus = granted ? .authorized : .denied
            }

            if granted {
                await registerForRemoteNotifications()
            }

            return granted
        } catch {
            print("❌ Push notification permission error: \(error)")
            return false
        }
    }

    private func checkCurrentAuthorizationStatus() {
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.isRegistered = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Device Token Registration

    @MainActor
    private func registerForRemoteNotifications() async {
        guard UIApplication.shared.applicationState == .active else {
            print("⚠️ App not active, skipping remote notification registration")
            return
        }

        UIApplication.shared.registerForRemoteNotifications()
    }

    func didReceiveDeviceToken(_ token: Data) {
        let deviceToken = token.map { String(format: "%02.2hhx", $0) }.joined()
        print("📱 Device token received: \(deviceToken)")

        Task { @MainActor in
            self.deviceToken = deviceToken
            await registerDeviceWithSupabase(token: deviceToken)
        }
    }

    func didFailToReceiveDeviceToken(error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
    }

    // MARK: - Supabase Registration

    private func registerDeviceWithSupabase(token: String) async {
        guard let supabaseUrl = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String else {
            print("❌ Missing Supabase configuration")
            return
        }

        // Get user session token from Supabase client
        guard let userSession = try? await SupabaseService.shared.client.auth.session else {
            print("❌ User not authenticated - cannot register device")
            return
        }

        // Get device info
        let device = UIDevice.current
        let deviceInfo = [
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            "device_model": device.model,
            "os_version": device.systemVersion
        ]

        let requestBody = [
            "action": "register_device",
            "device_token": token,
            "platform": "ios",
            "device_info": deviceInfo
        ] as [String: Any]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

            var request = URLRequest(url: URL(string: "\(supabaseUrl)/functions/v1/manage-notifications")!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(userSession.accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✅ Device registered successfully with Supabase")
                    await MainActor.run {
                        self.isRegistered = true
                    }
                } else {
                    print("❌ Device registration failed: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Response: \(responseString)")
                    }
                }
            }
        } catch {
            print("❌ Device registration error: \(error)")
        }
    }

    // MARK: - Notification Preferences

    func updateNotificationPreferences(_ preferences: NotificationPreferences) async -> Bool {
        guard let supabaseUrl = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String else {
            print("❌ Missing Supabase configuration")
            return false
        }

        // Get user session token from Supabase client
        guard let userSession = try? await SupabaseService.shared.client.auth.session else {
            print("❌ User not authenticated - cannot update preferences")
            return false
        }

        let requestBody = [
            "action": "update_preferences",
            "preferences": [
                "push_notifications_enabled": preferences.pushNotificationsEnabled,
                "concert_notifications": preferences.concertNotifications,
                "album_notifications": preferences.albumNotifications,
                "news_notifications": preferences.newsNotifications,
                "ticket_notifications": preferences.ticketNotifications
            ]
        ] as [String: Any]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

            var request = URLRequest(url: URL(string: "\(supabaseUrl)/functions/v1/manage-notifications")!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(userSession.accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }

            return false
        } catch {
            print("❌ Preferences update error: \(error)")
            return false
        }
    }
}

// MARK: - Data Models

struct NotificationPreferences {
    var pushNotificationsEnabled: Bool = true
    var concertNotifications: Bool = true
    var albumNotifications: Bool = true
    var newsNotifications: Bool = true
    var ticketNotifications: Bool = true

    static let `default` = NotificationPreferences()
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationService: UNUserNotificationCenterDelegate {

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        let userInfo = response.notification.request.content.userInfo
        print("📱 Notification tapped: \(userInfo)")

        // Handle notification tap based on type
        if let notificationType = userInfo["notification_type"] as? String {
            switch notificationType {
            case "concert":
                // Navigate to concerts screen
                NotificationCenter.default.post(name: .navigateToConcerts, object: nil)
            case "album":
                // Navigate to releases screen
                NotificationCenter.default.post(name: .navigateToReleases, object: nil)
            case "news":
                // Navigate to news screen
                NotificationCenter.default.post(name: .navigateToNews, object: nil)
            default:
                break
            }
        }

        completionHandler()
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        // Show notification even when app is in foreground
        completionHandler([.banner, .badge, .sound])
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToConcerts = Notification.Name("navigateToConcerts")
    static let navigateToReleases = Notification.Name("navigateToReleases")
    static let navigateToNews = Notification.Name("navigateToNews")
}