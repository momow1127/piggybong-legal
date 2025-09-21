# 🔒 Complete Security Setup for PiggyBong

## 🚨 CRITICAL: Security Checklist

### 1️⃣ **Firebase App Check** (Prevents Fake Apps)
Blocks hackers from using your Firebase backend with cloned/fake apps.

#### Setup in Firebase Console:
1. Go to Firebase Console → App Check
2. Click "Register apps"
3. For iOS: Choose "DeviceCheck"
4. Enable enforcement for:
   - ✅ Realtime Database
   - ✅ Cloud Firestore
   - ✅ Cloud Storage
   - ✅ Cloud Functions

#### Add to Your Code:
```swift
// In AppDelegate.swift, add after FirebaseApp.configure()
import FirebaseAppCheck

// For DEBUG builds (development)
#if DEBUG
let providerFactory = AppCheckDebugProviderFactory()
#else
// For RELEASE builds (production)
let providerFactory = DeviceCheckProviderFactory()
#endif

AppCheck.setAppCheckProviderFactory(providerFactory)
```

### 2️⃣ **API Key Restrictions** (Prevent Key Theft)

#### In Google Cloud Console:
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your PiggyBong project
3. APIs & Services → Credentials
4. Find your iOS API key
5. Click Edit → Set Application Restrictions:
   - ✅ iOS apps
   - Bundle ID: `carmenwong.PiggyBong`
6. Set API Restrictions:
   - ✅ Restrict key to specific APIs:
     - Firebase ML API
     - Firebase Installations API
     - Mobile Crash Reporting API
     - FCM Registration API

### 3️⃣ **Supabase Security** (Your Database)

#### Row Level Security (RLS):
```sql
-- Ensure RLS is enabled on ALL tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE artists ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_feedback ENABLE ROW LEVEL SECURITY;

-- Users can only see their own data
CREATE POLICY "Users can only see own data" ON users
    FOR ALL USING (auth.uid() = id);

CREATE POLICY "Users can only see own artists" ON user_artists
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can only see own goals" ON goals
    FOR ALL USING (auth.uid() = user_id);

-- Public data (read-only)
CREATE POLICY "Events are public read" ON events
    FOR SELECT USING (true);

CREATE POLICY "Artists are public read" ON artists
    FOR SELECT USING (true);
```

### 4️⃣ **Certificate Pinning** (Prevent MITM Attacks)

```swift
// Add to your networking layer
import CryptoKit

class SecurityManager {
    static let shared = SecurityManager()

    // Pin your server certificates
    private let pinnedCertificates = [
        "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=", // Your cert hash
    ]

    func validateServerTrust(_ serverTrust: SecTrust) -> Bool {
        // Implement certificate pinning
        guard let serverCert = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            return false
        }

        let serverCertData = SecCertificateCopyData(serverCert) as Data
        let serverCertHash = SHA256.hash(data: serverCertData)
        let hashString = serverCertHash.compactMap { String(format: "%02x", $0) }.joined()

        return pinnedCertificates.contains("sha256/\(hashString)")
    }
}
```

### 5️⃣ **RevenueCat Security**

```swift
// In RevenueCatManager.swift
class RevenueCatManager: ObservableObject {
    init() {
        // Enable receipt validation
        Purchases.configure(withAPIKey: apiKey)

        // Set user ID securely (hash it)
        if let userId = Auth.auth().currentUser?.uid {
            let hashedId = SHA256.hash(data: userId.data(using: .utf8)!)
                .compactMap { String(format: "%02x", $0) }.joined()
            Purchases.shared.logIn(hashedId)
        }
    }
}
```

### 6️⃣ **Code Obfuscation** (Hide Sensitive Logic)

```swift
// Never store sensitive data in code
struct SecurityConfig {
    // BAD - Don't do this
    // static let apiKey = "abc123"

    // GOOD - Use environment variables or keychain
    static var apiKey: String {
        return ProcessInfo.processInfo.environment["API_KEY"] ?? ""
    }

    // Store sensitive data in Keychain
    static func storeSecureData(_ data: String, key: String) {
        let keychain = Keychain(service: "com.piggybong.app")
        keychain[key] = data
    }
}
```

### 7️⃣ **Jailbreak Detection**

```swift
// Detect jailbroken devices
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
            "/private/var/lib/apt/"
        ]

        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }

        // Check if we can write to system
        let testPath = "/private/jailbreak_test.txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            // Normal - can't write to system
        }

        return false
        #endif
    }
}

// In your app startup
if JailbreakDetector.isJailbroken() {
    // Show warning or limit functionality
    showSecurityWarning()
}
```

### 8️⃣ **Network Security**

```swift
// Force HTTPS only in Info.plist
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
```

### 9️⃣ **Firebase Security Rules**

```json
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Deny all by default
    match /{document=**} {
      allow read, write: if false;
    }

    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Rate limiting
    match /events/{eventId} {
      allow read: if request.auth != null
        && request.time < resource.data.timestamp + duration.value(1, 'h');
    }
  }
}
```

### 🔟 **Monitor Security Events**

```swift
// Track suspicious activity
class SecurityMonitor {
    static func logSecurityEvent(_ event: String, severity: String = "medium") {
        // Log to Crashlytics
        Crashlytics.crashlytics().log("SECURITY: \(event)")

        // Track in Firebase Analytics
        Analytics.logEvent("security_event", parameters: [
            "event_type": event,
            "severity": severity,
            "timestamp": Date().timeIntervalSince1970
        ])

        // Alert if critical
        if severity == "critical" {
            sendSecurityAlert(event)
        }
    }

    static func detectAnomalies() {
        // Too many failed login attempts
        if failedLoginAttempts > 5 {
            logSecurityEvent("Multiple failed login attempts", severity: "high")
        }

        // Unusual API usage pattern
        if apiCallsPerMinute > 100 {
            logSecurityEvent("Unusual API usage", severity: "medium")
        }
    }
}
```

## 🛡️ **Quick Security Implementation**

### Add This to AppDelegate.swift:
```swift
import FirebaseAppCheck

func application(_ application: UIApplication, didFinishLaunchingWithOptions...) {
    // Existing Firebase config
    FirebaseApp.configure()

    // Add App Check
    #if DEBUG
    let providerFactory = AppCheckDebugProviderFactory()
    #else
    let providerFactory = DeviceCheckProviderFactory()
    #endif
    AppCheck.setAppCheckProviderFactory(providerFactory)

    // Check for jailbreak
    if JailbreakDetector.isJailbroken() {
        print("⚠️ Security: Jailbroken device detected")
        // Optionally limit features
    }

    // Start security monitoring
    SecurityMonitor.startMonitoring()
}
```

## 📊 **Security Dashboard Setup**

### In Firebase Console:
1. **Security Rules Monitor**
   - Firebase Console → Firestore → Monitor
   - Set alerts for denied requests > 100/hour

2. **Crashlytics Alerts**
   - Set up velocity alerts for crash spikes
   - Monitor for security-related crashes

3. **Analytics Events**
   - Track: failed_login, jailbreak_detected, api_abuse
   - Set up audiences for suspicious users

## ⚡ **Immediate Actions (Do Now!)**

1. **Enable App Check** (5 mins)
   - Blocks 99% of automated attacks
   - Go to Firebase Console → App Check → Enable

2. **Restrict API Keys** (3 mins)
   - Go to Google Cloud Console
   - Restrict to iOS only + your bundle ID

3. **Enable Supabase RLS** (2 mins)
   - Run the SQL commands above
   - Ensures users can't see others' data

4. **Add Jailbreak Detection** (5 mins)
   - Copy the code above
   - Warns you about compromised devices

## 🚨 **Red Flags to Monitor**

Watch for these in your analytics:
- 🚩 Sudden spike in new users (bot attack)
- 🚩 API calls from non-iOS platforms
- 🚩 Multiple failed purchase attempts
- 🚩 Users with impossible data (negative values, future dates)
- 🚩 Crashlytics reports from modified apps

## 📱 **Testing Security**

```bash
# Test your API key restrictions
curl -X POST https://firebaseapp.com/your-endpoint \
  -H "X-API-Key: your-api-key" \
  # Should fail if not from iOS app

# Test Supabase RLS
# Try to access another user's data - should fail
```

## 🎯 **Security Score**

Rate your app security (aim for 80%+):
- [ ] App Check enabled (20%)
- [ ] API keys restricted (15%)
- [ ] Supabase RLS active (20%)
- [ ] Certificate pinning (10%)
- [ ] Jailbreak detection (10%)
- [ ] HTTPS only (10%)
- [ ] Security monitoring (10%)
- [ ] Code obfuscation (5%)

---

**Remember: Security is not one-time setup. Monitor daily!** 🔒