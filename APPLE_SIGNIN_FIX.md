# Apple Sign In Configuration Guide

## Issue
Apple Sign In is failing on real device because the "Sign In with Apple" capability is not properly configured.

## Required Steps to Fix

### 1. Enable Sign In with Apple Capability in Xcode
1. Open `FanPlan.xcodeproj` in Xcode
2. Select the **"Piggy Bong"** target
3. Go to **"Signing & Capabilities"** tab
4. Click **"+ Capability"**
5. Add **"Sign In with Apple"**

### 2. Configure Apple Developer Account
1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select your App ID for bundle: `carmenwong.PiggyBong`
4. Edit the App ID and enable **"Sign In with Apple"**
5. Save the changes

### 3. Verify Bundle ID
Ensure your bundle ID matches exactly:
- Current bundle: `carmenwong.PiggyBong`
- This should match what's in Apple Developer Portal

### 4. Team Provisioning
Make sure you're signed in with the correct Apple Developer account that owns the App ID.

## Expected Result
Once configured properly:
- ✅ Apple Sign In will work on physical devices
- ✅ The authentication flow will complete successfully
- ✅ Users will be redirected to the onboarding flow

## Alternative for Testing
Until Apple Sign In is configured, you can:
- Use **"Continue with Email"** button
- Use **"🚀 DEV: SKIP TO DASHBOARD"** button for quick testing
- Test Google Sign In (already configured)

## Error Signs
If not configured, you'll see errors like:
- "The operation couldn't be completed"
- "Sign In with Apple failed"
- Authorization callback never fires

## Next Steps
1. Complete the Xcode capability setup first
2. Test on device
3. If still failing, verify Apple Developer Portal configuration