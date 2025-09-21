import UIKit
import UserNotifications

// Quick test to check notification permission status
func debugNotificationStatus() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
        DispatchQueue.main.async {
            print("🔔 Notification Authorization Status: \(settings.authorizationStatus)")

            switch settings.authorizationStatus {
            case .notDetermined:
                print("📱 Status: NOT_DETERMINED - iOS popup WILL show")
            case .denied:
                print("❌ Status: DENIED - Need to open Settings app")
            case .authorized:
                print("✅ Status: AUTHORIZED - Already granted, no popup needed")
            case .provisional:
                print("⚠️ Status: PROVISIONAL - Limited notifications")
            case .ephemeral:
                print("📲 Status: EPHEMERAL - App clips only")
            @unknown default:
                print("❓ Status: UNKNOWN")
            }

            print("Alert Setting: \(settings.alertSetting)")
            print("Badge Setting: \(settings.badgeSetting)")
            print("Sound Setting: \(settings.soundSetting)")
        }
    }
}

// Call this in your app to debug
// debugNotificationStatus()