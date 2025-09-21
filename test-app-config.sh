#!/bin/bash

# Test App Configuration
# This script helps debug configuration issues in the app

echo "🔍 Testing App Configuration..."
echo ""

# Check .env file
echo "📄 Checking .env file:"
if [ -f ".env" ]; then
    echo "✅ .env file exists"
    echo "SUPABASE_URL: $(grep SUPABASE_URL .env | cut -d'=' -f2)"
    echo "SUPABASE_ANON_KEY: $(grep SUPABASE_ANON_KEY .env | cut -d'=' -f2 | cut -c1-20)..."
else
    echo "❌ .env file not found"
fi
echo ""

# Check if environment variables are loaded
echo "🌍 Checking environment variables:"
echo "SUPABASE_URL: ${SUPABASE_URL:-'Not set'}"
echo "SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:0:20}..."
echo ""

# Test Xcode build with environment variables
echo "🔨 Testing Xcode build with environment variables..."
source .env

if xcodebuild -project FanPlan.xcodeproj -scheme "Piggy Bong" \
    -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \
    SUPABASE_URL="$SUPABASE_URL" \
    SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    REVENUECAT_API_KEY="$REVENUECAT_API_KEY" \
    build 2>/dev/null 1>/dev/null; then
    echo "✅ Build successful with environment variables"
else
    echo "❌ Build failed - checking configuration..."
fi

echo ""
echo "🔧 Quick Fix for Apple Sign In Error:"
echo "The 'placeholder.supabase.co' error means the app isn't loading Supabase config properly."
echo ""
echo "Solution 1: Add to Xcode Environment Variables"
echo "1. In Xcode, go to: Product → Scheme → Edit Scheme"
echo "2. Select 'Run' on the left"
echo "3. Go to 'Arguments' tab"
echo "4. In 'Environment Variables', add:"
echo "   SUPABASE_URL = $SUPABASE_URL"
echo "   SUPABASE_ANON_KEY = $SUPABASE_ANON_KEY"
echo "   REVENUECAT_API_KEY = $REVENUECAT_API_KEY"
echo ""
echo "Solution 2: Use the build command with env vars:"
echo "SUPABASE_URL=\"$SUPABASE_URL\" SUPABASE_ANON_KEY=\"$SUPABASE_ANON_KEY\" REVENUECAT_API_KEY=\"$REVENUECAT_API_KEY\" xcodebuild -project FanPlan.xcodeproj -scheme \"Piggy Bong\" -destination 'platform=iOS Simulator,name=iPhone 16' build"