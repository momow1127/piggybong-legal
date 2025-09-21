#!/bin/bash

# App Store Screenshot Generator for PiggyBong2
echo "📱 Generating App Store Screenshots for PiggyBong2..."

# Create screenshots directory
mkdir -p Screenshots/{iPhone_6.7,iPhone_6.5,iPad_12.9}

# Required screenshot sizes for App Store
echo "Required screenshot sizes:"
echo "📱 iPhone 6.7\" (Pro Max): 1290×2796"
echo "📱 iPhone 6.5\": 1242×2688"
echo "📱 iPad 12.9\": 2048×2732"

echo ""
echo "📋 Screenshot Guidelines:"
echo "1. Launch iOS Simulator"
echo "2. Select device (iPhone 15 Pro Max, iPhone 11 Pro Max, iPad Pro 12.9\")"
echo "3. Run PiggyBong app in simulator"
echo "4. Navigate to key screens and capture:"
echo "   - 🏠 Home Dashboard (main features visible)"
echo "   - 💫 Onboarding/Welcome screen"
echo "   - 💰 Budget tracking screen"
echo "   - 🎤 Artist/Idol selection screen"
echo "   - 📊 Analytics/insights screen"

echo ""
echo "📸 To capture screenshots:"
echo "Device → Screenshot (Cmd+S)"
echo "Or: xcrun simctl io booted screenshot screenshot.png"

echo ""
echo "💡 Pro Tips:"
echo "- Use mockup data showing K-pop artists (BTS, BLACKPINK, etc.)"
echo "- Show realistic spending amounts (\$25-150 range)"
echo "- Include concert dates and upcoming events"
echo "- Highlight the app's core value (K-pop budget management)"

# Launch simulator with the correct device
echo ""
echo "🚀 Launching iOS Simulator..."

# Check available simulators
echo "Available simulators:"
xcrun simctl list devices available | grep -E "(iPhone 15 Pro Max|iPhone 11 Pro Max|iPad Pro.*12\.9)"

echo ""
echo "Commands to launch simulators:"
echo "📱 iPhone 15 Pro Max: xcrun simctl boot 'iPhone 15 Pro Max'"
echo "📱 iPhone 11 Pro Max: xcrun simctl boot 'iPhone 11 Pro Max'" 
echo "📱 iPad Pro 12.9\": xcrun simctl boot 'iPad Pro (12.9-inch)'"

echo ""
echo "🎯 Next steps:"
echo "1. Run this script: ./generate-screenshots.sh"
echo "2. Launch simulator with desired device"
echo "3. Build and run PiggyBong2 app"
echo "4. Navigate to each key screen and screenshot"
echo "5. Save screenshots to Screenshots/ folder with proper names"

echo ""
echo "📝 Screenshot naming convention:"
echo "Screenshots/iPhone_6.7/01-dashboard.png"
echo "Screenshots/iPhone_6.7/02-onboarding.png"
echo "Screenshots/iPhone_6.7/03-budget.png"
echo "Screenshots/iPhone_6.7/04-artists.png"
echo "Screenshots/iPhone_6.7/05-analytics.png"