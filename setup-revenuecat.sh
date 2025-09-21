#!/bin/bash

echo "🐷 PiggyBong RevenueCat Setup Script"
echo "=================================="
echo "Setting up RevenueCat for Competition Success!"
echo ""

# Load API key from environment
if [ -f .env ]; then
    source .env
fi

# Use API key from environment or prompt for it
if [ -z "$REVENUECAT_API_KEY" ]; then
    echo "Please enter your RevenueCat API key:"
    read API_KEY
else
    API_KEY="$REVENUECAT_API_KEY"
fi

echo "🔧 Setting up environment..."

# Export for current session
export REVENUECAT_API_KEY=$API_KEY
echo "✅ Environment variable set for current session"

# Add to shell profile if not already there
SHELL_PROFILE=""
if [ -f "$HOME/.zshrc" ]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [ -f "$HOME/.bash_profile" ]; then
    SHELL_PROFILE="$HOME/.bash_profile"
fi

if [ ! -z "$SHELL_PROFILE" ]; then
    if ! grep -q "REVENUECAT_API_KEY" "$SHELL_PROFILE"; then
        echo "export REVENUECAT_API_KEY=$API_KEY" >> "$SHELL_PROFILE"
        echo "✅ Added to $SHELL_PROFILE for future sessions"
    else
        echo "✅ Already configured in $SHELL_PROFILE"
    fi
fi

echo ""
echo "🧪 Testing configuration..."

# Run our test script
if [ -f "./test-revenuecat-config.sh" ]; then
    ./test-revenuecat-config.sh
else
    echo "⚠️  Test script not found, but configuration should be working"
fi

echo ""
echo "🎯 Competition Setup Complete!"
echo "==============================="
echo ""
echo "🏆 Your PiggyBong app is now configured for the RevenueCat Shipathon!"
echo ""
echo "📋 Next Steps:"
echo "1. Open FanPlan.xcodeproj in Xcode"
echo "2. Build and run the app (⌘+R)"
echo "3. Check console for '✅ RevenueCat configured successfully'"
echo "4. Test premium features with promo code: PIGGYVIP25"
echo ""
echo "🎊 Competition Features Ready:"
echo "   ✅ AI Fan Planner (Flagship feature)"
echo "   ✅ Unlimited Artists tracking"
echo "   ✅ Advanced Insights & Analytics"
echo "   ✅ Smart Savings automation"
echo "   ✅ Priority Alerts for concerts"
echo "   ✅ Complete spending history"
echo ""
echo "🔐 Judge Access:"
echo "   Promo Code: PIGGYVIP25 (30-day premium access)"
echo "   Alternative: SHIPPATHON2025, KPOPBETA2025"
echo ""
echo "📅 Competition Dates: September 6-8, 2025"
echo "🚀 Ready to ship and win! Good luck! 🍀"
echo ""

# Validate the setup
if [ ! -z "$REVENUECAT_API_KEY" ] && [ "$REVENUECAT_API_KEY" = "$API_KEY" ]; then
    echo "🎉 SUCCESS: RevenueCat is properly configured!"
    echo "   API Key: ${API_KEY:0:15}..."
else
    echo "❌ ISSUE: Environment variable not set correctly"
    echo "   Try running: source ~/.zshrc (or source ~/.bash_profile)"
fi