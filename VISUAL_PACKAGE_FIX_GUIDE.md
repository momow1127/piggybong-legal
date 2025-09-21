# 📱 Visual Guide: Remove Duplicate Packages in Xcode

## Step-by-Step Instructions with Exact Locations

### Step 1: Open Your Project
1. **Double-click** `FanPlan.xcodeproj` to open in Xcode
2. Wait for Xcode to fully load

### Step 2: Navigate to Package Dependencies
1. In the **left sidebar** (Project Navigator), click on the **very top item** - it should say "FanPlan" with a blue folder icon
2. This opens the project settings in the main area

### Step 3: Find Package Dependencies Tab
Look at the **top of the main area** - you'll see several tabs:
```
General | Signing & Capabilities | Resource Tags | Info | Build Settings | Build Phases | Build Rules | Package Dependencies
```
3. **Click on "Package Dependencies"** (the last tab)

### Step 4: You'll See a List Like This:
```
📦 Package Dependencies:
├── RevenueCat (https://github.com/RevenueCat/purchases-ios.git)
├── Supabase (https://github.com/supabase/supabase-swift)
├── GoogleSignIn (https://github.com/google/GoogleSignIn-iOS)
├── AppAuth (https://github.com/openid/AppAuth-iOS.git)
├── [Maybe some duplicates or broken entries]
```

### Step 5: Remove ALL Packages (Don't worry, we'll add them back!)
For **each package** in the list:
1. **Click on the package name** (it will highlight in blue)
2. **Press the "-" button** at the bottom of the list
   - OR right-click and select "Remove Package"
3. **Confirm removal** when Xcode asks

### Step 6: Clean Everything
After removing all packages:
1. **Menu: Product → Clean Build Folder**
2. **Menu: Product → Resolve Package Dependencies** (should be quick/empty now)

### Step 7: Add Packages Back One by One
Click the **"+" button** at the bottom of the Package Dependencies list and add:

**Package 1:**
- URL: `https://github.com/supabase/supabase-swift`
- Click "Add Package"
- Choose "Supabase" in the popup, click "Add Package"

**Package 2:**  
- URL: `https://github.com/RevenueCat/purchases-ios.git`
- Click "Add Package"
- Choose "RevenueCat" in the popup, click "Add Package"

**Package 3:**
- URL: `https://github.com/google/GoogleSignIn-iOS`
- Click "Add Package"  
- Choose "GoogleSignIn" in the popup, click "Add Package"

**Package 4:**
- URL: `https://github.com/openid/AppAuth-iOS.git`
- Click "Add Package"
- Choose "AppAuth" in the popup, click "Add Package"

### Step 8: Test Build
1. **Menu: Product → Clean Build Folder**
2. **Menu: Product → Build**

## 🎯 What You're Looking For

**BEFORE (Problem):**
- Duplicate entries in Package Dependencies
- Build fails with GUID error
- Some packages might show as "broken" or "missing"

**AFTER (Fixed):**
- Clean list with no duplicates
- Each package shows version number
- Build succeeds without GUID errors

## 📍 Exact Location Visual Reference

```
Xcode Window Layout:
┌─────────────────────────────────────────┐
│ File Edit View... (Menu Bar)             │
├─────────────┬───────────────────────────┤
│ Navigator   │ Main Editor Area          │
│ (Left)      │                          │
│             │ ┌─ General               │
│ 📁 FanPlan ← │ ├─ Signing & Capabilities│
│   📄 Files  │ ├─ Resource Tags         │
│   📁 Folder │ ├─ Info                  │
│             │ ├─ Build Settings        │
│             │ ├─ Build Phases          │
│             │ ├─ Build Rules           │
│             │ └─ Package Dependencies ← │
│             │                          │
│             │   📦 Package List HERE   │
│             │   ├── Supabase           │
│             │   ├── RevenueCat         │
│             │   └── [+ - buttons]      │
└─────────────┴───────────────────────────┘
```

## 🆘 If You Get Lost
1. **Click the blue "FanPlan" at the very top of the left sidebar**
2. **Look for tabs across the top of the main area**  
3. **Click "Package Dependencies" tab**
4. **You should see a list of packages with + and - buttons**

That's where you remove and add packages! 🎯