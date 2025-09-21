#!/bin/bash

echo "🔍 Google Client ID Configuration Check"
echo "========================================"

echo "1. Info.plist GOOGLE_CLIENT_ID:"
PLIST_GOOGLE_ID=$(grep -A1 "GOOGLE_CLIENT_ID" Info.plist | grep "<string>" | sed 's/.*<string>//;s/<\/string>.*//' | tr -d ' ')
echo "   $PLIST_GOOGLE_ID"

echo ""
echo "2. .env GOOGLE_CLIENT_ID:"
ENV_GOOGLE_ID=$(grep "GOOGLE_CLIENT_ID" .env | cut -d'=' -f2)
echo "   $ENV_GOOGLE_ID"

echo ""
echo "3. URL Scheme Check:"
EXPECTED_SCHEME="com.googleusercontent.apps.$(echo $PLIST_GOOGLE_ID | cut -d'-' -f1)"
echo "   Expected URL scheme: $EXPECTED_SCHEME"
if grep -q "$EXPECTED_SCHEME" Info.plist; then
    echo "   ✅ URL scheme found in Info.plist"
else
    echo "   ❌ URL scheme missing in Info.plist"
fi

echo ""
echo "4. Problem Diagnosis:"
if [ -z "$PLIST_GOOGLE_ID" ] || [ "$PLIST_GOOGLE_ID" = "\$(GOOGLE_CLIENT_ID)" ]; then
    echo "   ❌ Info.plist has placeholder or empty value"
elif [ -z "$ENV_GOOGLE_ID" ]; then
    echo "   ❌ .env missing GOOGLE_CLIENT_ID"
elif [ "$PLIST_GOOGLE_ID" != "$ENV_GOOGLE_ID" ]; then
    echo "   ⚠️  Info.plist and .env have different values"
else
    echo "   ✅ Configuration looks correct"
fi