# 🚀 Final Setup Instructions

## ✅ What's Already Done:
- RevenueCat SDK added to project ✅
- API key configured: `appl_XXXXXXXXXXXXXXXXXXXXXXX` ✅
- Promo code changed to: `PIGGYVIP25` ✅
- Paywall UI created ✅
- Premium feature gates ready ✅

## 🔧 Quick Fix Needed (2 minutes):

### 1. Link RevenueCat to Target
1. Open Xcode: `FanPlan.xcodeproj`
2. Click on "Piggy Bong" target (left sidebar)
3. Go to "Frameworks, Libraries, and Embedded Content"
4. Click the "+" button
5. Select "RevenueCat" from the list
6. Click "Add"

### 2. Build & Test
```bash
# Build the project
xcodebuild -project FanPlan.xcodeproj -scheme "Piggy Bong" -destination 'platform=iOS Simulator,name=iPhone 16' build

# Or just hit Cmd+R in Xcode
```

## 🎯 Demo Flow:
1. Open app → see free user with 2 artist limit
2. Try to add 3rd artist → paywall appears
3. Enter promo code: `PIGGYVIP25`
4. Shows premium features unlocked

## 📱 Current Status:
- **Free Tier**: Track 2 artists max
- **Premium**: $2.99/month after 7-day trial
- **Promo Code**: `PIGGYVIP25` for judges
- **Due Today**: $0.00 (clear trial messaging)

## 🛠 If Build Still Fails:
The conditional imports (`#if canImport(RevenueCat)`) will prevent crashes, but you need to link the package to use full functionality.

That's it! Your hackathon demo is ready! 🎉