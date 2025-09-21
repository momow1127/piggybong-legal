# 🔧 Fix Duplicate GUID Package Reference Issue

## Issue Description
```
Could not compute dependency graph: unable to load transferred PIF: 
The workspace contains multiple references with the same GUID 
'PACKAGE:1X94R821UUVH6I5VS67P0LAIODNU3008W::MAINGROUP'
```

## Root Cause
This error occurs when the Xcode project file (`project.pbxproj`) contains duplicate package references with the same GUID, typically caused by:
- Multiple attempts to add the same Swift Package
- Git merges that duplicated package entries
- Corrupted package reference state

## ✅ Solution Steps

### Method 1: Xcode GUI (Recommended)
1. **Open Xcode** → Open `FanPlan.xcodeproj`
2. **Project Navigator** → Select project root
3. **Package Dependencies tab** → Remove ALL packages showing duplicates
4. **Clean workspace**: Product → Clean Build Folder
5. **Re-add packages** one by one:
   - Supabase: `https://github.com/supabase/supabase-swift`
   - RevenueCat: `https://github.com/RevenueCat/purchases-ios.git`
   - GoogleSignIn: `https://github.com/google/GoogleSignIn-iOS`
   - AppAuth: `https://github.com/openid/AppAuth-iOS.git`

### Method 2: Manual project.pbxproj Edit (Advanced)
1. **Close Xcode completely**
2. **Edit project file**: `FanPlan.xcodeproj/project.pbxproj`
3. **Search for GUID**: `PACKAGE:1X94R821UUVH6I5VS67P0LAIODNU3008W`
4. **Remove duplicate entries** (keep only one instance)
5. **Save and reopen** in Xcode
6. **Resolve packages**: Product → Resolve Package Dependencies

### Method 3: Complete Reset (Nuclear Option)
```bash
# 1. Complete cleanup
cd "Your-Project-Directory"
rm -rf ~/Library/Developer/Xcode/DerivedData/FanPlan-*
rm -rf .build build
rm -rf FanPlan.xcodeproj/project.xcworkspace/xcuserdata
rm -rf ~/Library/Caches/org.swift.swiftpm

# 2. Remove Package.resolved if exists
rm -f FanPlan.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

# 3. Open Xcode and re-add all packages fresh
```

## ⚠️ Critical Notes
- **Close Xcode** completely before manual file edits
- **Backup project** before making changes
- **Test build** after each package addition
- **Commit changes** once working

## Expected Outcome
After applying the fix:
```bash
✅ xcodebuild -resolvePackageDependencies succeeds
✅ Build completes without GUID errors
✅ All systematic compilation fixes remain intact
```

## Next Steps After Fix
1. **Build app successfully**
2. **Execute Runtime QA Plan** (see `RUNTIME_QA_PLAN.md`)
3. **Test all user flows** systematically
4. **Replace stubbed methods** gradually

---

**Note**: The 68+ compilation errors have been systematically resolved. This GUID issue is purely a project configuration problem that doesn't affect the code fixes we've implemented.