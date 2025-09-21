# PiggyBong iOS Authentication Debugging Guide

## Current Issues Identified

Your authentication was failing because the app was using **mock authentication** instead of real Supabase integration. The following issues have been fixed:

### ✅ Fixed Issues:

1. **Config.swift**: Updated with real Supabase credentials
2. **SupabaseService.swift**: Now uses actual configuration instead of placeholders  
3. **AuthManager.swift**: Replaced mock authentication with real Supabase integration
4. **OAuth Integration**: Added Google Sign-In and Apple Sign-In support
5. **UI**: Created proper authentication flow with AuthenticationView

## Required Steps to Complete Setup

### 1. Supabase Dashboard Configuration

**Google OAuth Setup:**
1. Go to your Supabase dashboard: https://YOUR-PROJECT.supabase.co
2. Navigate to Authentication > Settings > Auth Providers
3. Enable Google provider with these settings:
   - Client ID: `301452889528-rqd96cu7r6gtu46fmvafrdfbhsjn9vq1.apps.googleusercontent.com`
   - Client Secret: (Get from Google Console)
   - Redirect URL: `https://YOUR-PROJECT.supabase.co/auth/v1/callback`

**Apple OAuth Setup:**
1. Enable Apple provider in Supabase
2. Configure with your Bundle ID: `carmenwong.PiggyBong`
3. Add redirect URL: `https://YOUR-PROJECT.supabase.co/auth/v1/callback`

### 2. Google Cloud Console Configuration

1. Go to https://console.cloud.google.com/
2. Navigate to APIs & Services > Credentials
3. Find your OAuth 2.0 Client ID: `301452889528-rqd96cu7r6gtu46fmvafrdfbhsjn9vq1.apps.googleusercontent.com`
4. Add authorized redirect URIs:
   - `https://YOUR-PROJECT.supabase.co/auth/v1/callback`
   - `carmenwong.piggybong://auth/callback` (for mobile)

### 3. iOS App Configuration Checks

**Info.plist (Already Configured):**
```xml
<!-- URL Schemes for OAuth callbacks -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>301452889528-rqd96cu7r6gtu46fmvafrdfbhsjn9vq1.apps.googleusercontent.com</string>
        </array>
    </dict>
</array>

<!-- Configuration Keys -->
<key>SUPABASE_URL</key>
<string>https://YOUR-PROJECT.supabase.co</string>
<key>GOOGLE_CLIENT_ID</key>
<string>301452889528-rqd96cu7r6gtu46fmvafrdfbhsjn9vq1.apps.googleusercontent.com</string>
```

### 4. Network and SSL Debugging

**Common Network Issues:**

1. **App Transport Security (ATS)**: Your Info.plist allows HTTPS to supabase.co ✅

2. **SSL Certificate Issues**: 
   - Test Supabase connectivity: `curl -I https://YOUR-PROJECT.supabase.co`
   - Ensure device trusts the certificate

3. **Network Connectivity**: 
   - Test on device vs simulator
   - Check corporate/school network restrictions
   - Try different networks (cellular vs WiFi)

## Debugging Steps for Specific Errors

### Google Sign-In "Unacceptable audience in id_token"

**Root Cause**: Mismatch between Google Client ID in app and Supabase configuration

**Solution**:
1. Verify Google Client ID in Supabase matches: `301452889528-rqd96cu7r6gtu46fmvafrdfbhsjn9vq1.apps.googleusercontent.com`
2. Ensure OAuth consent screen is properly configured
3. Check that the Google project has correct bundle ID

### Apple Sign-In "Nonces mismatch" 

**Root Cause**: Nonce validation issues between iOS and Supabase

**Solution**:
1. Ensure Apple Services ID matches Bundle ID: `carmenwong.PiggyBong`
2. Configure proper redirect URLs in Apple Developer Console
3. Verify App ID has Sign in with Apple capability enabled

### HTTP 404 Errors

**Root Cause**: Incorrect endpoint URLs or missing configuration

**Solution**:
1. Verify Supabase URL: `https://YOUR-PROJECT.supabase.co`
2. Check Supabase project is active and not paused
3. Verify Auth API is enabled in Supabase dashboard

## Testing Checklist

### Prerequisites:
- [ ] Supabase project is active
- [ ] Google OAuth is configured in Supabase
- [ ] Apple OAuth is configured in Supabase  
- [ ] iOS app has correct Bundle ID: `carmenwong.PiggyBong`
- [ ] URL schemes are properly configured

### Test Each Auth Method:

**Email/Password:**
- [ ] Sign up with new email
- [ ] Verify email confirmation (check Supabase settings)
- [ ] Sign in with existing credentials
- [ ] Test password reset flow

**Google Sign-In:**
- [ ] Test on device (not simulator for full OAuth flow)
- [ ] Verify Google account picker appears
- [ ] Check successful redirect back to app
- [ ] Verify user data is properly stored

**Apple Sign-In:**
- [ ] Test on device (required for Apple Sign-In)
- [ ] Verify Apple ID picker appears
- [ ] Test "Hide My Email" option
- [ ] Check successful authentication

## Advanced Debugging

### Enable Debug Logging:

Add to `AppDelegate` or app initialization:
```swift
#if DEBUG
// Enable Supabase debug logging
client.auth.debug = true

// Enable Google Sign-In debug logging
GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
    print("Google Sign-In restore: user=\\(user?.profile?.email), error=\\(error)")
}
#endif
```

### Network Monitoring:

1. Use Charles Proxy or similar to monitor HTTP traffic
2. Check request/response headers for OAuth flows
3. Verify JWT tokens are being properly generated
4. Monitor redirect URLs and parameters

### Common Error Messages and Solutions:

| Error | Solution |
|-------|----------|
| "Invalid client" | Check Google Client ID configuration |
| "redirect_uri_mismatch" | Add correct redirect URIs to OAuth config |
| "Invalid JWT" | Check token expiration and signing |
| "User not found" | Verify user creation in Supabase |
| "Network error" | Check internet connection and SSL certificates |

## Production Considerations

1. **Environment Configuration**: Switch to production OAuth credentials
2. **SSL Pinning**: Consider implementing SSL pinning for security
3. **Error Handling**: Implement comprehensive error handling for network failures
4. **Offline Support**: Handle authentication state when offline
5. **Session Management**: Implement proper token refresh logic

## Support Resources

- **Supabase Docs**: https://supabase.com/docs/guides/auth
- **Google Sign-In iOS**: https://developers.google.com/identity/sign-in/ios
- **Apple Sign-In**: https://developer.apple.com/sign-in-with-apple/
- **Supabase Discord**: https://discord.supabase.com/

The authentication implementation has been updated to use real Supabase integration. Test each auth method after configuring the OAuth providers in your respective dashboards.