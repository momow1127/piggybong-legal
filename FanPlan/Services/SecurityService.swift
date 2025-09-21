import Foundation
import FirebaseAppCheck
import FirebaseCrashlytics
import FirebaseAnalytics
import CryptoKit
import UIKit

// MARK: - Security Service
actor SecurityService {
    static let shared = SecurityService()

    private var failedAttempts = 0
    private var lastSecurityCheck = Date()

    private init() {}

    // MARK: - App Check Setup
    func setupAppCheck() async {
        #if DEBUG
        print("🔒 Security: Setting up App Check for DEBUG")
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)

        // Log debug token for Firebase Console
        do {
            let token = try await AppCheck.appCheck().token(forcingRefresh: false)
            print("🔒 App Check Debug Token: \(token.token)")
            print("📝 Add this token to Firebase Console > App Check > Apps > Debug tokens")
        } catch {
            print("❌ App Check token error: \(error)")
        }
        #else
        print("🔒 Security: Setting up App Check for PRODUCTION")
        let providerFactory = DeviceCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)

        // Test production token
        do {
            let token = try await AppCheck.appCheck().token(forcingRefresh: false)
            print("✅ App Check DeviceCheck token obtained successfully")
        } catch {
            print("❌ DeviceCheck token error: \(error)")
            print("💡 Ensure device is physical (not simulator) and DeviceCheck is configured in Firebase")
        }
        #endif

        print("✅ App Check configured successfully")
    }

    // MARK: - Jailbreak Detection
    func checkDeviceSecurity() -> Bool {
        #if targetEnvironment(simulator)
        return true // Allow simulator for development
        #else

        let isJailbroken = JailbreakDetector.isJailbroken()

        if isJailbroken {
            logSecurityEvent("jailbreak_detected", severity: "high")
            print("⚠️ Security: Jailbroken device detected")
        }

        return !isJailbroken
        #endif
    }

    // MARK: - Security Monitoring
    func logSecurityEvent(_ event: String, severity: String = "medium") {
        // Log to console
        print("🚨 Security Event: \(event) (severity: \(severity))")

        // Log to Crashlytics
        Crashlytics.crashlytics().log("SECURITY: \(event)")
        Crashlytics.crashlytics().setCustomValue(severity, forKey: "security_severity")

        // Log to Firebase Analytics
        Analytics.logEvent("security_event", parameters: [
            "event_type": event,
            "severity": severity,
            "timestamp": Date().timeIntervalSince1970,
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ])

        // Critical events get immediate attention
        if severity == "critical" {
            sendCriticalAlert(event)
        }
    }

    private func sendCriticalAlert(_ event: String) {
        // Record critical error
        let error = NSError(domain: "SecurityError", code: 9001, userInfo: [
            "event": event,
            "timestamp": Date().description
        ])

        Crashlytics.crashlytics().record(error: error)
        print("🚨 CRITICAL SECURITY ALERT: \(event)")
    }

    // MARK: - Authentication Security
    func trackFailedLogin() {
        failedAttempts += 1

        if failedAttempts >= 3 {
            logSecurityEvent("multiple_failed_logins", severity: "medium")
        }

        if failedAttempts >= 5 {
            logSecurityEvent("suspicious_login_pattern", severity: "high")
        }
    }

    func resetFailedAttempts() {
        failedAttempts = 0
    }

    // MARK: - API Security
    func validateRequest() -> Bool {
        // Rate limiting - basic implementation
        let now = Date()
        let timeSinceLastCheck = now.timeIntervalSince(lastSecurityCheck)

        if timeSinceLastCheck < 0.1 { // 100ms minimum between requests
            logSecurityEvent("rapid_api_requests", severity: "medium")
            return false
        }

        lastSecurityCheck = now
        return true
    }

    // MARK: - Data Validation
    func validateUserInput(_ input: String, type: InputType) -> Bool {
        switch type {
        case .email:
            return isValidEmail(input)
        case .username:
            return isValidUsername(input)
        case .amount:
            return isValidAmount(input)
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func isValidUsername(_ username: String) -> Bool {
        // Allow only alphanumeric and underscores, 3-20 characters
        let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        let usernamePredicate = NSPredicate(format:"SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: username)
    }

    private func isValidAmount(_ amount: String) -> Bool {
        guard let value = Double(amount) else { return false }
        return value >= 0 && value <= 10000 // Reasonable limits
    }
}

// MARK: - Input Types
enum InputType {
    case email
    case username
    case amount
}

// MARK: - Jailbreak Detector
class JailbreakDetector {
    static func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else

        // Check for common jailbreak files
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/private/var/tmp/cydia.log",
            "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
            "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist"
        ]

        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }

        // Check if we can write to system directories
        let testPath = "/private/jailbreak_test.txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true // If we can write to system, device is jailbroken
        } catch {
            // Normal - can't write to system directories
        }

        // Check for suspicious apps
        let suspiciousApps = [
            "cydia://",
            "sileo://",
            "zbra://",
            "undecimus://",
            "checkra1n://"
        ]

        for app in suspiciousApps {
            if let url = URL(string: app), UIApplication.shared.canOpenURL(url) {
                return true
            }
        }

        return false
        #endif
    }
}

// MARK: - Secure Storage Helper
class SecureStorage {
    private static let keychain = "com.piggybong.keychain"

    static func store(_ value: String, forKey key: String) -> Bool {
        let data = value.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychain,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func retrieve(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychain,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let data = result as? Data,
           let string = String(data: data, encoding: .utf8) {
            return string
        }

        return nil
    }

    static func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychain,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}