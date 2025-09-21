#!/bin/bash

# Comprehensive Authentication Test Suite
# Tests all authentication configurations and connections

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                 🔍 COMPREHENSIVE AUTH TEST SUITE             ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

function test_result() {
    if [ "$1" = "PASS" ]; then
        echo -e "${GREEN}✅ PASS${NC}: $2"
        ((PASS_COUNT++))
    elif [ "$1" = "FAIL" ]; then
        echo -e "${RED}❌ FAIL${NC}: $2"
        ((FAIL_COUNT++))
    elif [ "$1" = "WARN" ]; then
        echo -e "${YELLOW}⚠️  WARN${NC}: $2"
        ((WARN_COUNT++))
    fi
}

echo -e "${YELLOW}📋 TEST 1: INFO.PLIST CONFIGURATION${NC}"
echo -e "${YELLOW}────────────────────────────────────${NC}"

# Test Supabase URL
SUPABASE_URL_PLIST=$(grep -A1 "SUPABASE_URL" Info.plist | grep "<string>" | sed 's/.*<string>//;s/<\/string>.*//' | tr -d '[:space:]')
if [[ "$SUPABASE_URL_PLIST" == "https://lxnenbhkmdvjsmnripax.supabase.co" ]]; then
    test_result "PASS" "Supabase URL in Info.plist"
elif [[ "$SUPABASE_URL_PLIST" == *"$("* ]]; then
    test_result "FAIL" "Supabase URL still has placeholder: $SUPABASE_URL_PLIST"
else
    test_result "WARN" "Unexpected Supabase URL: $SUPABASE_URL_PLIST"
fi

# Test Supabase Key
SUPABASE_KEY_PLIST=$(grep -A1 "SUPABASE_ANON_KEY" Info.plist | grep "<string>" | sed 's/.*<string>//;s/<\/string>.*//' | tr -d '[:space:]')
if [[ "$SUPABASE_KEY_PLIST" == "eyJ"* ]]; then
    test_result "PASS" "Supabase Anon Key in Info.plist (JWT format)"
elif [[ "$SUPABASE_KEY_PLIST" == *"$("* ]]; then
    test_result "FAIL" "Supabase Key still has placeholder: $SUPABASE_KEY_PLIST"
else
    test_result "FAIL" "Invalid Supabase Key format"
fi

# Test Google Client ID
GOOGLE_CLIENT_PLIST=$(grep -A1 "GOOGLE_CLIENT_ID" Info.plist | grep "<string>" | sed 's/.*<string>//;s/<\/string>.*//' | tr -d '[:space:]')
if [[ "$GOOGLE_CLIENT_PLIST" == *"apps.googleusercontent.com" ]]; then
    test_result "PASS" "Google Client ID in Info.plist"
else
    test_result "FAIL" "Invalid Google Client ID: $GOOGLE_CLIENT_PLIST"
fi

# Test Apple Client ID
APPLE_CLIENT_PLIST=$(grep -A1 "APPLE_CLIENT_ID" Info.plist | grep "<string>" | sed 's/.*<string>//;s/<\/string>.*//' | tr -d '[:space:]')
if [[ "$APPLE_CLIENT_PLIST" == "carmenwong.PiggyBong" ]]; then
    test_result "PASS" "Apple Client ID in Info.plist (Bundle ID format)"
elif [[ "$APPLE_CLIENT_PLIST" == "carmenwong.PiggyBong.auth" ]]; then
    test_result "FAIL" "Apple Client ID has wrong .auth suffix: $APPLE_CLIENT_PLIST"
else
    test_result "FAIL" "Invalid Apple Client ID: $APPLE_CLIENT_PLIST"
fi

echo ""
echo -e "${YELLOW}📡 TEST 2: SUPABASE CONNECTIVITY${NC}"
echo -e "${YELLOW}──────────────────────────────────${NC}"

# Test Supabase connection
SUPABASE_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$SUPABASE_URL_PLIST/rest/v1/" -H "apikey: $SUPABASE_KEY_PLIST")
if [ "$SUPABASE_RESPONSE" -eq 200 ] || [ "$SUPABASE_RESPONSE" -eq 401 ] || [ "$SUPABASE_RESPONSE" -eq 403 ]; then
    test_result "PASS" "Supabase API connection (HTTP $SUPABASE_RESPONSE)"
else
    test_result "FAIL" "Supabase API connection failed (HTTP $SUPABASE_RESPONSE)"
fi

# Test Google Auth endpoint
GOOGLE_AUTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$SUPABASE_URL_PLIST/auth/v1/authorize?provider=google")
if [ "$GOOGLE_AUTH_RESPONSE" -eq 302 ] || [ "$GOOGLE_AUTH_RESPONSE" -eq 303 ] || [ "$GOOGLE_AUTH_RESPONSE" -eq 200 ]; then
    test_result "PASS" "Google Auth endpoint (HTTP $GOOGLE_AUTH_RESPONSE)"
else
    test_result "WARN" "Google Auth endpoint unexpected response (HTTP $GOOGLE_AUTH_RESPONSE)"
fi

# Test Apple Auth endpoint
APPLE_AUTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$SUPABASE_URL_PLIST/auth/v1/authorize?provider=apple")
if [ "$APPLE_AUTH_RESPONSE" -eq 302 ] || [ "$APPLE_AUTH_RESPONSE" -eq 303 ] || [ "$APPLE_AUTH_RESPONSE" -eq 200 ]; then
    test_result "PASS" "Apple Auth endpoint (HTTP $APPLE_AUTH_RESPONSE)"
else
    test_result "WARN" "Apple Auth endpoint unexpected response (HTTP $APPLE_AUTH_RESPONSE)"
fi

echo ""
echo -e "${YELLOW}📱 TEST 3: IOS CONFIGURATION${NC}"
echo -e "${YELLOW}─────────────────────────────────${NC}"

# Test entitlements file
if [ -f "FanPlan/FanPlan.entitlements" ]; then
    if grep -q "com.apple.developer.applesignin" "FanPlan/FanPlan.entitlements"; then
        test_result "PASS" "Apple Sign-In entitlements configured"
    else
        test_result "FAIL" "Apple Sign-In entitlements missing"
    fi
else
    test_result "FAIL" "Entitlements file not found"
fi

# Test URL schemes
if grep -q "carmenwong.PiggyBong" Info.plist; then
    test_result "PASS" "URL schemes configured for callbacks"
else
    test_result "WARN" "URL schemes might not be configured"
fi

echo ""
echo -e "${YELLOW}🔧 TEST 4: PROJECT STRUCTURE${NC}"
echo -e "${YELLOW}───────────────────────────────────${NC}"

# Test key files exist
FILES_TO_CHECK=(
    "FanPlan/AuthenticationService.swift"
    "FanPlan/AuthenticationView.swift"
    "FanPlan/SupabaseService.swift"
    "FanPlan/FanPlanApp.swift"
)

for file in "${FILES_TO_CHECK[@]}"; do
    if [ -f "$file" ]; then
        test_result "PASS" "Core file exists: $file"
    else
        test_result "FAIL" "Missing core file: $file"
    fi
done

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                      📊 TEST SUMMARY                        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✅ PASSED: $PASS_COUNT tests${NC}"
echo -e "${YELLOW}⚠️  WARNINGS: $WARN_COUNT tests${NC}"
echo -e "${RED}❌ FAILED: $FAIL_COUNT tests${NC}"

echo ""
if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}🎉 OVERALL STATUS: READY TO TEST IN XCODE!${NC}"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Open project in Xcode"
    echo "2. Build and run on a PHYSICAL device (not simulator)"
    echo "3. Test Google Sign-In (works in simulator and device)"
    echo "4. Test Apple Sign-In (ONLY works on physical device)"
    echo "5. Test Email/Password authentication"
    echo ""
    echo -e "${YELLOW}For Supabase Dashboard:${NC}"
    echo "• Enable Google provider with Web OAuth credentials"
    echo "• Enable Apple provider with Client ID: carmenwong.PiggyBong"
else
    echo -e "${RED}🚨 CONFIGURATION ISSUES DETECTED${NC}"
    echo -e "${RED}Please fix the failed tests before proceeding${NC}"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"