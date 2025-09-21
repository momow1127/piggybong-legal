# 🔗 Magic Link Email Authentication Setup Guide

## ✅ ALREADY CONFIGURED IN YOUR APP:

Your app has magic link functionality built in! Here's what's already working:

### **1. Code Implementation:**
- ✅ `sendMagicLink()` function in SupabaseService
- ✅ Magic link callback handling in FanPlanApp
- ✅ URL scheme: `piggybong://`
- ✅ Deep link processing

### **2. Current Magic Link Flow:**
1. User enters email in your app
2. App calls `sendMagicLink(email, redirectTo)`
3. Supabase sends email with magic link
4. User clicks link in email
5. Opens app via `piggybong://` URL scheme
6. App processes the authentication

## 🔧 SUPABASE DASHBOARD SETUP NEEDED:

### **Step 1: Configure Email Templates**

Go to your Supabase Dashboard:
👉 https://supabase.com/dashboard/project/YOUR-PROJECT-REF/auth/templates

**1. Enable Email Authentication:**
- Go to **Authentication > Settings > Email**
- Enable **"Enable email confirmations"**
- Enable **"Enable email change confirmations"**

**2. Configure Email Templates:**
- Go to **Authentication > Email Templates**
- Edit **"Magic Link"** template
- Set **Subject**: `Sign in to Piggy Bong`
- Set **Redirect URL**: `piggybong://login-callback`

### **Step 2: Configure URL Redirects**

Go to **Authentication > URL Configuration**:
- Add **Site URL**: `piggybong://`
- Add **Redirect URLs**:
  - `piggybong://login-callback`
  - `piggybong://auth/callback`

### **Step 3: Email Settings**

Go to **Authentication > Settings**:
- **Confirm email**: Enable
- **Double confirm email changes**: Enable
- **Enable phone confirmations**: Disable (unless you want SMS)

## 📱 TESTING MAGIC LINKS:

### **Method 1: iOS Simulator (Recommended)**
1. **Run app in iOS Simulator**
2. **Enter your email** in the sign-in form
3. **Tap "Send Magic Link"**
4. **Check your email** (Gmail, etc.)
5. **Copy the magic link URL**
6. **In Simulator**: Device > Device > Safari
7. **Paste the URL** - it should open your app

### **Method 2: Physical Device**
1. **Run app on iPhone**
2. **Enter email and send magic link**
3. **Open Mail app on same device**
4. **Tap the magic link** - should open your app

## 🔍 DEBUGGING MAGIC LINKS:

### **Check Xcode Console for:**
```
🔗 Sending magic link via Supabase...
✅ Magic link sent successfully
🔐 Processing magic link authentication...
✅ Magic link session created successfully!
```

### **Common Issues:**

**❌ Email not received:**
- Check spam folder
- Verify email in Supabase Dashboard > Authentication > Users
- Check Supabase logs for delivery errors

**❌ Link doesn't open app:**
- Verify URL scheme `piggybong://` in Info.plist
- Check redirect URL in Supabase matches `piggybong://login-callback`

**❌ App opens but auth fails:**
- Check Xcode console for error messages
- Verify Supabase project URL and key are correct

## 🧪 QUICK TEST SCRIPT:

```bash
# Test magic link endpoint
curl -X POST "https://YOUR-PROJECT.supabase.co/auth/v1/magiclink" \
  -H "Content-Type: application/json" \
  -H "apikey: YOUR_ANON_KEY" \
  -d '{
    "email": "your-test@email.com",
    "redirectTo": "piggybong://login-callback"
  }'
```

## ✨ MAGIC LINK ADVANTAGES:

- ✅ **Works in Simulator** (unlike Apple Sign-In)
- ✅ **No OAuth setup complexity** (unlike Google)
- ✅ **No third-party dependencies**
- ✅ **Great for testing**
- ✅ **Secure passwordless auth**

---

**Your magic link code is ready! Just configure the Supabase Dashboard settings above.** 🚀