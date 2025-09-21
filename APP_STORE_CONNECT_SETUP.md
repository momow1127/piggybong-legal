# 🍎 **App Store Connect & RevenueCat Setup - CRITICAL**

Since you've upgraded to the paid Apple Developer Program, you need to configure the actual subscription products for the button to work.

## 🚨 **STEP 1: App Store Connect Setup**

### **1.1 Create Your App**
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. **My Apps → Create New App**
3. **Bundle ID**: `carmenwong.PiggyBong`
4. **App Name**: `Piggy Bong` or `PiggyBong`

### **1.2 Configure Subscription**
1. **Features → In-App Purchases → Manage**
2. **Create Subscription Group**:
   - **Reference Name**: `Stan Plus Premium`
   - **Group ID**: Will be auto-generated

3. **Create Subscription**:
   - **Product ID**: `stan_plus_monthly` ⚠️ **EXACT MATCH REQUIRED**
   - **Reference Name**: `Stan Plus Monthly`
   - **Duration**: `1 Month`
   - **Price**: `$2.99` (Tier 4)
   
4. **Free Trial**:
   - **Enable Introductory Offer**: ✅
   - **Type**: `Free Trial`
   - **Duration**: `7 Days`

5. **App Store Localization**:
   - **Display Name**: `Stan Plus Premium`
   - **Description**: `Unlimited artist tracking, AI concierge, smart savings insights, and priority concert alerts for K-pop fans.`

6. **Review Information**:
   - **Screenshot**: Upload paywall screenshot
   - **Review Notes**: `Premium subscription for enhanced K-pop fan experience`

7. **Click "Save" and "Submit for Review"**

## 🚨 **STEP 2: RevenueCat Dashboard Setup**

### **2.1 Project Configuration**
1. Go to [RevenueCat Dashboard](https://app.revenuecat.com)
2. **Select your project** or **Create New Project**
3. **Project Settings → Apps → iOS**
4. **Bundle ID**: `carmenwong.PiggyBong`
5. **App Store Connect App-Specific Password**: Generate from Apple ID settings

### **2.2 Add Products**
1. **Products → Create Product**
2. **Product ID**: `stan_plus_monthly` ⚠️ **MUST MATCH App Store Connect**
3. **Type**: `Subscription`
4. **Display Name**: `Stan Plus Premium`

### **2.3 Configure Offerings**
1. **Offerings → Create Offering**
2. **Identifier**: `default`
3. **Description**: `Default offering`
4. **Add Package**:
   - **Identifier**: `monthly`
   - **Product**: `stan_plus_monthly`
   - **Display Name**: `Monthly`

5. **Make this the current offering** ✅

### **2.4 API Keys** ✅ Already Configured
- Your API key is already set: `your-revenuecat-api-key-here`
- App ID: `app4d04e412ab`

## 🚨 **STEP 3: Test Configuration**

### **3.1 Create Sandbox User**
1. **App Store Connect → Users and Access → Sandbox**
2. **Create new sandbox user**
3. **Email**: Use a test email (not your real Apple ID)
4. **Region**: Your region (US, etc.)
5. **Save**

### **3.2 Configure iOS Device**
1. **Settings → App Store → Sandbox Account**
2. **Sign in** with sandbox user
3. **Sign out** of regular App Store account if needed

### **3.3 Test the Button**
1. **Build and run** your app on device (not simulator)
2. **Navigate to paywall**
3. **Tap "Try Free for 7 Days"**
4. **iOS should show subscription dialog**
5. **Confirm with Touch ID/Face ID**

## ⚠️ **IMPORTANT NOTES**

### **Timeline**
- **App Store Connect review**: 24-48 hours
- **RevenueCat sync**: 15-30 minutes
- **First test**: May take 5-10 minutes to sync

### **Product ID Must Match Exactly**
```
App Store Connect: stan_plus_monthly
RevenueCat: stan_plus_monthly
Your Code: RevenueCatConfig.Products.stanPlusMonthly = "stan_plus_monthly"
```

### **Testing Requirements**
- **Real iOS device** (not simulator) for testing purchases
- **Sandbox Apple ID** for testing
- **App signed** with your paid developer account

## 🎯 **Once Configured**

Your button will:
1. ✅ Load real subscription from App Store Connect
2. ✅ Show actual pricing ($2.99/month, 7-day trial)  
3. ✅ Process real sandbox purchases
4. ✅ Work identically in production

## 📞 **If You Need Help**

The most common issues are:
1. **Product ID mismatch** between App Store Connect and RevenueCat
2. **Subscription not approved** in App Store Connect
3. **Not signed in to sandbox account** on device
4. **Testing on simulator** instead of real device

**Complete these steps and your button will work with real In-App Purchases! 🚀**
