# 🔧 Supabase Google OAuth Configuration Checklist

## **Step 1: Check Supabase Dashboard Settings**

### Go to: **Supabase Dashboard → Authentication → Providers → Google**

Ensure these settings:

1. **Google Auth is ENABLED** ✅
   - Toggle switch should be ON

2. **Client ID Configuration:**
   ```
   Client ID: [Your Web Application OAuth 2.0 Client ID from Google Console]
   ```
   - This should be your **Web Client ID**, not iOS

3. **Client Secret:**
   ```
   Client Secret: [Your Client Secret from Google Console]
   ```
   - Get this from Google Console OAuth 2.0 credentials

4. **Authorized Client IDs (IMPORTANT for mobile):**
   ```
   [Your iOS Client ID from Google Console]
   ```
   - Add your iOS OAuth 2.0 Client ID here
   - This allows the iOS app to authenticate

5. **Skip nonce checks:** 
   - Consider enabling this if you're having issues

---

## **Step 2: Check Google Console Configuration**

### Go to: **Google Cloud Console → APIs & Services → Credentials**

You should have **TWO OAuth 2.0 Client IDs**:

### 1. **Web Application Client**
- Type: Web application
- Used for: Supabase Dashboard configuration
- Authorized redirect URIs should include:
  ```
  https://[your-project-ref].supabase.co/auth/v1/callback
  ```

### 2. **iOS Client**
- Type: iOS
- Bundle ID: Your app's bundle ID (e.g., `carmenwong.PiggyBong`)
- Used in: Your iOS app's GoogleService-Info.plist

---

## **Step 3: Verify Your iOS App Configuration**

### Check `GoogleService-Info.plist`:
```xml
<key>CLIENT_ID</key>
<string>[Your iOS Client ID]</string>
<key>REVERSED_CLIENT_ID</key>
<string>[Your Reversed iOS Client ID]</string>
```

### Check `Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>[Your REVERSED_CLIENT_ID from GoogleService-Info.plist]</string>
        </array>
    </dict>
</array>
```

---

## **Step 4: Test Configuration**

### Run this SQL in Supabase SQL Editor:
```sql
-- Check if Google provider is enabled
SELECT * FROM auth.providers WHERE provider = 'google';

-- Check recent auth attempts (last 24 hours)
SELECT 
    created_at,
    provider,
    email,
    raw_app_meta_data
FROM auth.users 
WHERE provider = 'google' 
ORDER BY created_at DESC 
LIMIT 10;

-- Check auth logs for errors
SELECT * FROM auth.audit_log_entries 
WHERE payload::text LIKE '%google%' 
ORDER BY created_at DESC 
LIMIT 20;
```

---

## **Step 5: Common Issues & Solutions**

### Issue: "Invalid request"
**Solution:** 
- Ensure iOS Client ID is in "Authorized Client IDs" in Supabase
- Check that Web Client credentials are correctly configured in Supabase

### Issue: "Invalid grant"
**Solution:**
- Token might be expired or malformed
- Ensure you're using the ID token, not access token

### Issue: "Provider not enabled"
**Solution:**
- Enable Google provider in Supabase Dashboard
- Save and wait 30 seconds for changes to propagate

---

## **Step 6: Debug Token**

Add this temporary debug code to see what tokens you're getting:

```swift
print("🔍 Google Sign-In Debug:")
print("ID Token: \(result.user.idToken?.tokenString ?? "nil")")
print("Access Token: \(result.user.accessToken.tokenString)")
print("User Email: \(result.user.profile?.email ?? "nil")")
print("Token Expiry: \(result.user.accessToken.expirationDate)")
```

---

## **Quick Fix Checklist:**

- [ ] Google provider enabled in Supabase
- [ ] Web Client ID & Secret in Supabase settings
- [ ] iOS Client ID in "Authorized Client IDs"
- [ ] GoogleService-Info.plist has correct iOS Client ID
- [ ] Info.plist has URL scheme configured
- [ ] Both Web and iOS OAuth clients exist in Google Console
- [ ] Supabase project URL is in Google's authorized redirects

---

## **If Still Failing:**

1. **Check Supabase Logs:**
   - Dashboard → Logs → Auth
   - Look for specific error messages

2. **Try Manual Test:**
   ```bash
   curl -X POST 'https://[your-project].supabase.co/auth/v1/token' \
     -H 'Content-Type: application/json' \
     -d '{
       "grant_type": "id_token",
       "provider": "google",
       "id_token": "[YOUR_ID_TOKEN_HERE]"
     }'
   ```

3. **Contact Supabase Support** with:
   - Your project ref
   - Error messages from logs
   - This checklist completed