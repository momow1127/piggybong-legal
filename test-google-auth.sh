#!/bin/bash

# Google Auth Configuration Test Script for PiggyBong
# This script verifies that Google OAuth is properly configured

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}       🔍 Google Auth Configuration Test Script${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
    echo -e "${GREEN}✅ Environment file loaded${NC}"
else
    echo -e "${RED}❌ No .env file found${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}📋 Configuration Check:${NC}"
echo -e "${YELLOW}────────────────────────${NC}"

# Check if Google Client ID is set
if [ -z "$GOOGLE_CLIENT_ID" ]; then
    echo -e "${RED}❌ GOOGLE_CLIENT_ID not set in .env${NC}"
    exit 1
else
    echo -e "${GREEN}✅ GOOGLE_CLIENT_ID found:${NC} ${GOOGLE_CLIENT_ID:0:20}..."
fi

# Check if Supabase URL is set
if [ -z "$SUPABASE_URL" ]; then
    echo -e "${RED}❌ SUPABASE_URL not set in .env${NC}"
    exit 1
else
    echo -e "${GREEN}✅ SUPABASE_URL found:${NC} $SUPABASE_URL"
fi

# Check Info.plist for Google configuration
echo ""
echo -e "${YELLOW}📱 iOS App Configuration:${NC}"
echo -e "${YELLOW}────────────────────────${NC}"

INFO_PLIST="Info.plist"
if [ -f "$INFO_PLIST" ]; then
    PLIST_CLIENT_ID=$(grep -A1 "GOOGLE_CLIENT_ID" "$INFO_PLIST" | grep "<string>" | sed 's/.*<string>//;s/<\/string>.*//' | tr -d '[:space:]')

    if [ -n "$PLIST_CLIENT_ID" ]; then
        echo -e "${GREEN}✅ Google Client ID in Info.plist:${NC} ${PLIST_CLIENT_ID:0:20}..."

        # Check if it matches .env
        ENV_CLIENT_ID=$(echo "$GOOGLE_CLIENT_ID" | tr -d '[:space:]')
        if [ "$PLIST_CLIENT_ID" = "$ENV_CLIENT_ID" ]; then
            echo -e "${GREEN}✅ Client IDs match between .env and Info.plist${NC}"
        else
            echo -e "${YELLOW}⚠️  Client IDs differ between .env and Info.plist${NC}"
            echo "   Info.plist: $PLIST_CLIENT_ID"
            echo "   .env:       $ENV_CLIENT_ID"
        fi
    else
        echo -e "${RED}❌ No Google Client ID found in Info.plist${NC}"
    fi
else
    echo -e "${RED}❌ Info.plist not found${NC}"
fi

# Test Supabase Google Auth endpoint
echo ""
echo -e "${YELLOW}🔌 Supabase Provider Check:${NC}"
echo -e "${YELLOW}────────────────────────${NC}"

# Check if Google auth provider is accessible
GOOGLE_AUTH_URL="${SUPABASE_URL}/auth/v1/authorize?provider=google"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$GOOGLE_AUTH_URL")

if [ "$RESPONSE" -eq 302 ] || [ "$RESPONSE" -eq 303 ]; then
    echo -e "${GREEN}✅ Google auth endpoint is accessible (HTTP $RESPONSE)${NC}"
elif [ "$RESPONSE" -eq 200 ]; then
    echo -e "${GREEN}✅ Google auth endpoint responded (HTTP $RESPONSE)${NC}"
else
    echo -e "${YELLOW}⚠️  Unexpected response from Google auth endpoint (HTTP $RESPONSE)${NC}"
fi

# Check callback URL
CALLBACK_URL="${SUPABASE_URL}/auth/v1/callback"
echo -e "${GREEN}✅ Callback URL for Google Console:${NC}"
echo -e "   $CALLBACK_URL"

# Create verification Swift file
echo ""
echo -e "${YELLOW}📝 Creating iOS verification test...${NC}"
echo -e "${YELLOW}────────────────────────${NC}"

cat > test-google-config.swift << 'EOF'
import Foundation

// Test Google OAuth Configuration
print("🔍 Testing Google OAuth Configuration for iOS App\n")

// Load environment variables
let env = ProcessInfo.processInfo.environment

// Check Google Client ID
if let googleClientId = env["GOOGLE_CLIENT_ID"] {
    print("✅ GOOGLE_CLIENT_ID from environment: \(googleClientId.prefix(20))...")
} else {
    print("❌ GOOGLE_CLIENT_ID not found in environment")
}

// Check Supabase configuration
if let supabaseUrl = env["SUPABASE_URL"] {
    print("✅ SUPABASE_URL: \(supabaseUrl)")
    print("📍 Callback URL for Google Console:")
    print("   \(supabaseUrl)/auth/v1/callback")
} else {
    print("❌ SUPABASE_URL not found in environment")
}

// Check bundle identifier
let bundleId = "carmenwong.PiggyBong"
print("\n📱 Expected Bundle ID: \(bundleId)")
print("   Configure this in Google Cloud Console for iOS OAuth Client")

print("\n" + String(repeating: "=", count: 60))
print("📋 GOOGLE CLOUD CONSOLE SETUP CHECKLIST:")
print(String(repeating: "=", count: 60))
print("""

1️⃣  iOS OAuth Client:
   • Type: iOS
   • Bundle ID: carmenwong.PiggyBong
   • Client ID should match Info.plist

2️⃣  Web Application OAuth Client:
   • Type: Web Application
   • Authorized redirect URIs:
     - \(env["SUPABASE_URL"] ?? "[SUPABASE_URL]")/auth/v1/callback
   • Use this Client ID & Secret in Supabase Dashboard

3️⃣  Supabase Dashboard Configuration:
   • Go to: Authentication > Providers > Google
   • Enable: Google Provider
   • Client ID: [Web Application OAuth Client ID]
   • Client Secret: [Web Application OAuth Client Secret]

""")

print(String(repeating: "=", count: 60))
EOF

swift test-google-config.swift

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    📊 TEST SUMMARY${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

echo -e "
${YELLOW}Next Steps:${NC}
1. Ensure you have TWO OAuth clients in Google Cloud Console:
   - iOS client (for the app)
   - Web Application client (for Supabase)

2. In Google Cloud Console - Web Application client:
   - Add Authorized redirect URI: ${GREEN}$CALLBACK_URL${NC}

3. In Supabase Dashboard:
   - Add Web Application OAuth credentials
   - Enable Google provider

4. Build and test the app in Xcode

${YELLOW}Testing in the App:${NC}
1. Run the app in Xcode
2. Tap 'Sign in with Google'
3. Check Xcode console for any errors
4. Check Supabase Dashboard > Authentication > Logs
"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✨ Configuration test complete!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

# Cleanup
rm -f test-google-config.swift