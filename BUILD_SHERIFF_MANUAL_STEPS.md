# Build Sheriff - Manual Xcode Steps Required

## Critical: Remove Duplicate Files from Target Membership

⚠️ **DO NOT DELETE FILES** - Only remove from build target

### Files to Remove from Target Membership:

**CRITICAL - Multiple @main Entry Points:**
1. **PiggyBongApp.swift** (root level)
   - Remove from target membership (duplicate @main)
   
2. **PiggyBong-iOS/Sources/App/PiggyBongApp.swift**
   - Remove from target membership (duplicate @main)
   
**Keep ONLY:** `FanPlan/FanPlanApp.swift` with @main

**Artist Model Duplicates:**
3. **FanPlan/Artist.swift**
   - Select file in Project Navigator
   - File Inspector → Target Membership → Uncheck "Piggy Bong" target
   - Keep file on disk (duplicate of Artist in FanExperienceModels.swift)

4. **PiggyBong-iOS/Sources/Core/Models/Artist.swift** 
   - Select file in Project Navigator  
   - File Inspector → Target Membership → Uncheck any iOS targets
   - Keep file on disk (duplicate of Artist in FanExperienceModels.swift)

### Why This Fixes Duplicates:
- **Canonical Artist**: FanExperienceModels.swift (used by dashboard)
- **Canonical FanArtist**: FanExperienceModels.swift (dashboard model)
- **Canonical GoalCategory**: Services/OnboardingDataService.swift
- **Shims**: Convert between types at boundaries only

### Files Created (Should Auto-Add to Target):
- ✅ `FanPlan/Shims/GoalCategoryShim.swift` - GoalCategory typealias
- ✅ `FanPlan/Shims/ArtistShim.swift` - Artist ↔ FanArtist conversion

## After Target Membership Removal:

1. **Product → Clean Build Folder** (⇧⌘K)
2. **File → Packages → Reset Package Caches** 
3. **Product → Build** (⌘B)

## Expected Result:
- 0 duplicate symbol errors
- GoalCategory resolves via shim
- Artist/FanArtist conversions work at boundaries
- UI unchanged, onboarding → dashboard path works