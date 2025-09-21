import SwiftUI
import UserNotifications

// MARK: - Permission ViewModel
@MainActor
class PermissionViewModel: ObservableObject {
    @Published var notificationPermission: UNAuthorizationStatus = .notDetermined
    @Published var isRequestingPermission = false
    @Published var isAnimating = false
    
    init() {
        checkCurrentPermissions()
    }
    
    func checkCurrentPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationPermission = settings.authorizationStatus
            }
        }
    }
    
    func requestNotificationPermission() async {
        print("🔔 requestNotificationPermission called")
        print("🔔 Current permission status: \(notificationPermission)")
        
        // Always refresh the current status first
        await refreshPermissionStatus()
        
        guard notificationPermission == .notDetermined else {
            print("🔔 Permission already determined: \(notificationPermission)")
            // If permission was denied, guide user to settings
            if notificationPermission == .denied {
                print("🔔 Permission denied, opening settings")
                openSettings()
            }
            return
        }
        
        isRequestingPermission = true
        print("🔔 About to request authorization...")
        
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound, .criticalAlert]
            )
            
            print("🔔 Authorization result: granted=\(granted)")
            self.notificationPermission = granted ? .authorized : .denied
            
            if granted {
                // Register for remote notifications
                print("🔔 Registering for remote notifications...")
                await UIApplication.shared.registerForRemoteNotificationsAsync()
                print("✅ Notification permission granted and registered")
                
                // Schedule a test notification
                scheduleTestNotification()
            } else {
                print("❌ Notification permission denied by user")
            }
        } catch {
            print("❌ Error requesting notification permission: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            self.notificationPermission = .denied
        }
        
        isRequestingPermission = false
    }
    
    private func refreshPermissionStatus() async {
        return await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    self.notificationPermission = settings.authorizationStatus
                    print("🔔 Refreshed permission status: \(settings.authorizationStatus)")
                    continuation.resume()
                }
            }
        }
    }
    
    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Welcome to PiggyBong!"
        content.body = "You're all set to receive updates about your favorite K-pop artists! 🎵"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "welcome_notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling test notification: \(error)")
            } else {
                print("✅ Test notification scheduled")
            }
        }
    }
}

// MARK: - UIApplication Extension
extension UIApplication {
    @MainActor
    func registerForRemoteNotificationsAsync() async {
        registerForRemoteNotifications()
    }
}