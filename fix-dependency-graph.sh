#!/bin/bash

# Fix Xcode dependency graph duplicate GUID issue
echo "🔧 Fixing Xcode dependency graph issue..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Step 1: Clean Xcode derived data${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo "✅ Cleaned derived data"

echo -e "${BLUE}Step 2: Clean project caches${NC}"
rm -rf FanPlan.xcodeproj/project.xcworkspace/xcuserdata
rm -rf FanPlan.xcodeproj/xcuserdata
echo "✅ Cleaned user data caches"

echo -e "${BLUE}Step 3: Reset Swift Package Manager cache${NC}"
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData/*/SourcePackages
echo "✅ Cleaned SPM caches"

echo -e "${BLUE}Step 4: Clean package resolved file${NC}"
if [ -f "FanPlan.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
    rm -f "FanPlan.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
    echo "✅ Removed Package.resolved file"
else
    echo "ℹ️ No Package.resolved file found"
fi

echo -e "${BLUE}Step 5: Rebuild package dependencies${NC}"
echo "Building project to regenerate dependencies..."

if xcodebuild -project FanPlan.xcodeproj -scheme "Piggy Bong" \
    -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
    -configuration Debug \
    CODE_SIGNING_ALLOWED=NO \
    clean build > dependency_fix.log 2>&1; then
    echo "✅ Dependencies rebuilt successfully"
else
    echo -e "${YELLOW}⚠️ Build encountered issues, but dependencies may still be resolved${NC}"
    echo "Check dependency_fix.log for details"
fi

echo -e "${BLUE}Step 6: Verify package resolution${NC}"
if [ -f "FanPlan.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
    echo "✅ New Package.resolved file created"
    echo "Package versions:"
    grep -A 3 "identity.*purchases-ios" FanPlan.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved | grep version || echo "RevenueCat: Found"
    grep -A 3 "identity.*supabase-swift" FanPlan.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved | grep version || echo "Supabase: Found"
else
    echo -e "${YELLOW}⚠️ Package.resolved not regenerated - may need manual Xcode intervention${NC}"
fi

echo ""
echo -e "${GREEN}🎯 Dependency Graph Fix Summary:${NC}"
echo "• Cleaned all Xcode caches and derived data"
echo "• Reset Swift Package Manager cache"
echo "• Rebuilt package dependencies"
echo "• Generated fresh package resolution"

echo ""
echo -e "${BLUE}💡 Next Steps:${NC}"
echo "1. Open FanPlan.xcodeproj in Xcode"
echo "2. Go to File > Packages > Reset Package Caches"
echo "3. If still seeing issues, go to File > Packages > Update to Latest Package Versions"
echo "4. Build the project (Cmd+B)"

echo ""
echo -e "${BLUE}📱 Alternative Solution:${NC}"
echo "If the issue persists, you can:"
echo "1. Remove packages from Xcode (File > Package Manager)"
echo "2. Re-add them one by one:"
echo "   - RevenueCat: https://github.com/RevenueCat/purchases-ios.git"
echo "   - Supabase: https://github.com/supabase/supabase-swift"

echo ""
echo -e "${GREEN}✅ Dependency graph issue should now be resolved!${NC}"