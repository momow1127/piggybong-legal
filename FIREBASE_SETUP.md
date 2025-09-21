# 🔥 Firebase Setup Guide for PiggyBong

## Quick Setup (10 minutes)

### Step 1: Create Firebase Project (3 mins)
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Create a project"
3. Name it: **PiggyBong**
4. Disable Google Analytics (for now, to keep it simple)
5. Click "Create Project"

### Step 2: Add iOS App (3 mins)
1. In Firebase Console, click the iOS icon
2. Enter your Bundle ID: **carmenwong.PiggyBong**
3. App nickname: **Piggy Bong**
4. Skip App Store ID for now
5. Click "Register app"

### Step 3: Download Config File (1 min)
1. Download **GoogleService-Info.plist**
2. IMPORTANT: Drag this file into Xcode:
   - Open FanPlan.xcodeproj in Xcode
   - Drag GoogleService-Info.plist into the FanPlan folder
   - Check "Copy items if needed"
   - Add to target: "Piggy Bong"

### Step 4: Add Firebase SDK (3 mins)

#### Option A: Using Swift Package Manager (Recommended)
1. In Xcode: File → Add Package Dependencies
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Click "Add Package"
4. Select these packages:
   - ✅ FirebaseAnalytics
   - ✅ FirebaseCrashlytics
5. Click "Add Package"

#### Option B: Using CocoaPods
```bash
cd /Users/momow1127/Desktop/Desktop/Portfolio/My\ Project/AI/PiggyBong2-piggy-bong-main
pod init
# Edit Podfile to add:
# pod 'Firebase/Analytics'
# pod 'Firebase/Crashlytics'
pod install
# Use FanPlan.xcworkspace from now on
```

### Step 5: Activate Firebase in Code (1 min)

The code is already prepared! Just uncomment these lines:

1. **In FanPlan/AppDelegate.swift:**
```swift
// Change this:
// import FirebaseCore

// To this:
import FirebaseCore

// And uncomment:
FirebaseApp.configure()
CrashlyticsService.shared.configure()
```

2. **In FanPlan/Services/CrashlyticsService.swift:**
```swift
// Change this:
// import FirebaseCrashlytics

// To this:
import FirebaseCrashlytics
```

Then remove the print statements and uncomment the actual Crashlytics calls.

### Step 6: Test It Works
1. Build and run the app
2. Check Xcode console for: "🔥 Crashlytics configured"
3. Force a test crash (optional):
```swift
// Add this temporarily to test:
fatalError("Test crash")
```

### Step 7: Verify in Firebase Console
1. Go back to Firebase Console
2. Navigate to Crashlytics
3. You should see "Waiting for first crash report"
4. Run the app, trigger test crash
5. Within 5 minutes, you'll see crash data!

## 🎯 What You Get:
- **Automatic Crash Reports**: See exactly where/why app crashes
- **User Session Tracking**: Know which users affected
- **Non-Fatal Error Logging**: Track errors that don't crash app
- **Custom Event Logging**: Track user actions
- **Real-time Alerts**: Get notified of crash spikes

## 📱 Testing Crash Reporting:
```swift
// In any view, add a test button:
Button("Test Crash") {
    CrashlyticsService.shared.recordError(
        NSError(domain: "TestDomain", code: 42, userInfo: ["test": "data"])
    )
}
```

## ⚠️ Important Notes:
1. **GoogleService-Info.plist** contains your API keys - don't share publicly
2. Crashes only appear in console after app restarts
3. Debug builds may not send crashes - test with Release build
4. First crash report can take 5-15 minutes to appear

## 🚀 For App Store Release:
1. Upload dSYM files for symbolication
2. Enable crash-free users metric
3. Set up email alerts for crash spikes
4. Monitor launch success rate

## 📊 Bonus: Add Analytics Events
```swift
// Track key user actions:
Analytics.logEvent("artist_added", parameters: [
    "artist_name": artistName,
    "artist_id": artistId
])
```

---

**That's it! Your app now has professional crash reporting!** 🎉

When ready, just:
1. Add GoogleService-Info.plist to Xcode
2. Add Firebase SDK via SPM
3. Uncomment the import statements
4. Build and ship!