# Fix Crashlytics dSYM and App Check Issues

## ✅ Current Status Analysis

### dSYM Configuration (GOOD)
- ✅ `DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym"` - Correct
- ✅ Crashlytics upload script is present and configured
- ✅ Firebase SDK 12.3.0 is installed

### App Check Configuration (NEEDS VERIFICATION)
- ✅ DeviceCheck provider correctly configured in code
- ✅ Key ID and Team ID match in Firebase Console
- ❓ Enforcement mode may be too strict

## 🔧 Solutions to Implement

### 1. Enhanced dSYM Upload Script
Your current script is basic. Let's make it more robust:

```bash
# Enhanced Crashlytics script with better error handling
"${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"

# Verify dSYM files exist
if [ -d "${DWARF_DSYM_FOLDER_PATH}" ]; then
    echo "✅ dSYM files found at: ${DWARF_DSYM_FOLDER_PATH}"

    # Upload dSYMs explicitly
    find "${DWARF_DSYM_FOLDER_PATH}" -name "*.dSYM" | while read dsym; do
        echo "📤 Uploading dSYM: $dsym"
        "${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols" \
            -gsp "${PROJECT_DIR}/GoogleService-Info.plist" \
            -p ios "$dsym"
    done
else
    echo "⚠️ No dSYM files found at: ${DWARF_DSYM_FOLDER_PATH}"
fi

# Create marker file
touch "${TARGET_TEMP_DIR}/CrashlyticsUpload.marker"
```

### 2. App Check Debug Configuration
Add debug logging to understand App Check failures:

```swift
// In AppDelegate.swift - enhance the App Check setup
#if DEBUG
// Enable debug logging for App Check
AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
print("🔒 App Check: Using DEBUG provider factory")

// Log the debug token for Firebase Console
Task {
    do {
        let token = try await AppCheck.appCheck().token(forcingRefresh: false)
        print("🔒 App Check Debug Token: \(token.token)")
        print("📝 Add this token to Firebase Console > App Check > Apps > Debug tokens")
    } catch {
        print("❌ App Check token error: \(error)")
    }
}
#else
AppCheck.setAppCheckProviderFactory(DeviceCheckProviderFactory())
print("🔒 App Check: Using PRODUCTION DeviceCheck provider")
#endif
```

### 3. Firebase Console Settings to Check

#### App Check Enforcement:
1. Go to Firebase Console > App Check
2. Find your iOS app
3. Check current enforcement mode:
   - ✅ **"Unenforced"** - Good for development
   - ⚠️ **"Enforced"** - May block legitimate requests
   - 🔧 **"Enforced for new apps only"** - Safe middle ground

#### Debug Tokens (for development):
1. In Firebase Console > App Check > Debug tokens
2. Add the debug token printed in console logs
3. This allows development builds to bypass DeviceCheck

## 🚀 Implementation Steps

### Step 1: Update Build Script
Update the Crashlytics upload script in Xcode build phases.

### Step 2: Enhanced App Check Logging
Add the debug configuration to AppDelegate.

### Step 3: Firebase Console Configuration
- Set App Check to "Unenforced" during development
- Add debug tokens for development builds
- Monitor App Check metrics in Firebase Console

### Step 4: Testing Strategy
1. **Debug builds**: Use debug provider + debug tokens
2. **Release builds**: Use DeviceCheck provider
3. **Physical device testing**: Required for DeviceCheck
4. **Crashlytics verification**: Force a test crash to verify symbolication

## 📊 Monitoring & Verification

### Check dSYM Upload Success:
- Firebase Console > Crashlytics > Missing dSYMs
- Should show no missing dSYMs after successful build

### Check App Check Status:
- Firebase Console > App Check > Metrics
- Should show successful token verifications
- Monitor failure rates and error types

### Testing Commands:
```bash
# Build with verbose logging
xcodebuild -project FanPlan.xcodeproj -scheme "Piggy Bong" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -configuration Debug build

# Check for dSYM generation
find ~/Library/Developer/Xcode/DerivedData -name "*.dSYM" -newer /tmp/build_start

# Monitor Firebase logs
# Look for "App Check token" and "Crashlytics upload" messages
```

This comprehensive approach should resolve both the dSYM symbolication and App Check attestation issues.