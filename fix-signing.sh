#!/bin/bash

# Fix Xcode signing and provisioning issues for PiggyBong
echo "🔧 Fixing Xcode signing configuration..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Step 1: Clean derived data${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/FanPlan-*
echo "✅ Cleaned derived data"

echo -e "${BLUE}Step 2: Build without signing for simulator${NC}"
source .env.local
export SUPABASE_URL SUPABASE_ANON_KEY REVENUECAT_API_KEY

if xcodebuild -project FanPlan.xcodeproj -scheme "Piggy Bong" \
    -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
    -configuration Debug \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGN_IDENTITY="" \
    PROVISIONING_PROFILE="" \
    build > build.log 2>&1; then
    echo "✅ Build successful without signing"
else
    echo -e "${RED}❌ Build failed. Check build.log for details${NC}"
    tail -20 build.log
    exit 1
fi

echo -e "${BLUE}Step 3: Check if simulator is running${NC}"
if xcrun simctl list devices | grep -q "iPhone.*Booted"; then
    echo "✅ Simulator is running"
    DEVICE_ID=$(xcrun simctl list devices | grep "iPhone.*Booted" | head -1 | sed -n 's/.*(\([^)]*\)).*/\1/p')
    echo "Using device: $DEVICE_ID"
    
    echo -e "${BLUE}Step 4: Install app on simulator${NC}"
    APP_PATH="/Users/momow1127/Library/Developer/Xcode/DerivedData/FanPlan-"*"/Build/Products/Debug-iphonesimulator/Piggy Bong.app"
    
    if ls $APP_PATH > /dev/null 2>&1; then
        if xcrun simctl install "$DEVICE_ID" "$APP_PATH"; then
            echo "✅ App installed successfully"
            
            echo -e "${BLUE}Step 5: Launch app${NC}"
            if xcrun simctl launch "$DEVICE_ID" "carmenwong.PiggyBong"; then
                echo "✅ App launched successfully"
            else
                echo -e "${YELLOW}⚠️ App installation succeeded but launch failed${NC}"
                echo "You can manually launch the app from the simulator"
            fi
        else
            echo -e "${YELLOW}⚠️ App install failed, but build was successful${NC}"
            echo "You may need to manually install from Xcode"
        fi
    else
        echo -e "${RED}❌ App bundle not found at expected path${NC}"
        echo "Expected: $APP_PATH"
    fi
else
    echo -e "${YELLOW}⚠️ No simulator running. Please start iPhone 16 Pro simulator first${NC}"
    echo "Run: xcrun simctl boot \"iPhone 16 Pro\""
fi

echo ""
echo -e "${GREEN}🎯 Summary:${NC}"
echo "• Build configuration fixed for simulator development"
echo "• Code signing disabled for local development"
echo "• App should run in simulator without provisioning issues"
echo ""
echo -e "${BLUE}💡 For device testing:${NC}"
echo "1. Update bundle identifier in Xcode to match your Apple ID"
echo "2. Select your personal team in signing settings"
echo "3. Let Xcode automatically manage provisioning"
echo ""
echo -e "${BLUE}📱 Current status:${NC}"
ls -la "/Users/momow1127/Library/Developer/Xcode/DerivedData/FanPlan-"*"/Build/Products/Debug-iphonesimulator/" 2>/dev/null | grep "Piggy Bong.app" && echo "✅ App bundle exists" || echo "❌ App bundle missing"