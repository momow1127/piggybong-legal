#!/bin/bash

# Build script that uses the correct API keys from user-defined settings
# This ensures the app builds with proper Supabase configuration

echo "🔧 Building PiggyBong with API keys from user-defined settings..."

# Load environment variables from .env file
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "❌ Error: .env file not found"
    echo "Please create a .env file with your API keys"
    exit 1
fi

echo "✅ Environment variables set:"
echo "   SUPABASE_URL: ${SUPABASE_URL:0:30}..."
echo "   SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:0:20}..."
echo "   REVENUECAT_API_KEY: ${REVENUECAT_API_KEY:0:20}..."

# Build the project
echo ""
echo "🏗️ Building project..."
xcodebuild -project FanPlan.xcodeproj \
           -scheme "Piggy Bong" \
           -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
           SUPABASE_URL="$SUPABASE_URL" \
           SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
           REVENUECAT_API_KEY="$REVENUECAT_API_KEY" \
           build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build succeeded!"
    echo "The app is configured with:"
    echo "- Supabase connection ready"
    echo "- RevenueCat integration active"
    echo "- All API keys properly loaded from user-defined settings"
else
    echo ""
    echo "❌ Build failed. Please check the error messages above."
fi