# 🍎 Apple Sign-In Setup Guide

## ✅ CORRECT CONFIGURATION:

### **Apple Sign-In Client ID:**
```
carmenwong.PiggyBong
```
*This is your Bundle Identifier (same as your app's Bundle ID)*

### **Apple Developer Account Setup:**
1. Go to [developer.apple.com](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select **Identifiers**
4. Find your App ID: `carmenwong.PiggyBong`
5. Enable **"Sign In with Apple"** capability
6. Save configuration

### **Supabase Dashboard Setup:**
1. Go to: https://supabase.com/dashboard/project/YOUR-PROJECT-REF/auth/providers
2. Click on **Apple** provider
3. Toggle **Enable** to ON
4. Enter:
   - **Client ID**: `carmenwong.PiggyBong`
   - **Secret**: (Leave blank - Supabase handles this automatically)
   - **Redirect URL**: `https://YOUR-PROJECT.supabase.co/auth/v1/callback`
5. Click **Save**

## 📱 TESTING REQUIREMENTS:

### **❌ WILL NOT WORK:**
- iOS Simulator
- Device not signed into iCloud
- Device without 2FA enabled

### **✅ WILL WORK:**
- Physical iPhone/iPad
- Signed into iCloud
- Two-factor authentication enabled
- Valid Apple ID

## 🔧 KEY DIFFERENCES FROM GOOGLE:

| **Provider** | **Client ID Format** | **Where to Get** |
|--------------|---------------------|------------------|
| **Google** | `301452889528-xxx.apps.googleusercontent.com` | Google Cloud Console |
| **Apple** | `carmenwong.PiggyBong` | Your app's Bundle ID |

## 🎯 FINAL CHECKLIST:

- ✅ Bundle ID: `carmenwong.PiggyBong`
- ✅ Apple Client ID in Info.plist: `carmenwong.PiggyBong`
- ✅ Entitlements file has Apple Sign-In capability
- ✅ URL schemes configured for callbacks
- ⚠️ Enable Apple provider in Supabase Dashboard
- ⚠️ Test on physical device only

## 🚨 IMPORTANT NOTES:

1. **Apple Sign-In uses your Bundle ID as the Client ID** - this is different from Google
2. **The `.auth` suffix is for URL schemes**, not the Client ID
3. **Must test on real device** - Simulator doesn't support Apple Sign-In
4. **Supabase handles the secret automatically** for Apple Sign-In

---

**Your Apple Sign-In is now correctly configured! 🎉**