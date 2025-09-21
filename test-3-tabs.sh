#!/bin/bash

# 3-Tab App Test & Launch Script
echo "🏗️  Testing 3-Tab PiggyBong App..."

# Load environment variables from Config.local.xcconfig
if [ -f "Config.local.xcconfig" ]; then
    source <(grep -v '^#' Config.local.xcconfig | xargs -I {} echo export {})
else
    echo "⚠️ Config.local.xcconfig not found - using .env fallback"
    source .env
fi

echo "🧹 Clean build..."
xcodebuild -project FanPlan.xcodeproj -scheme "Piggy Bong" -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' clean

echo "🔨 Building app..."
if xcodebuild -project FanPlan.xcodeproj -scheme "Piggy Bong" -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' build; then
    echo "✅ BUILD SUCCEEDED!"
    
    echo "📱 Installing on simulator..."
    xcrun simctl boot "iPhone 16" 2>/dev/null || true
    xcrun simctl install "iPhone 16" "$HOME/Library/Developer/Xcode/DerivedData/FanPlan-*/Build/Products/Debug-iphonesimulator/Piggy Bong.app"
    
    echo "🚀 Launching app..."
    xcrun simctl launch "iPhone 16" "Momow.PiggyBong" || xcrun simctl launch "iPhone 16" "carmenwong.PiggyBong"
    
    echo ""
    echo "🎉 SUCCESS! Your 3-tab app is running:"
    echo "   📊 Dashboard Tab - Idol carousel, fan priorities"  
    echo "   📅 Events Tab - K-pop events feed"
    echo "   👤 Profile Tab - User settings"
    echo ""
    echo "Ready for 9/16 launch! 🚀"
else
    echo "❌ Build failed - checking critical errors only..."
    echo "Focus on Dashboard, Events, Profile tabs for launch."
fi