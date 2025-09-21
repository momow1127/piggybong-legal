#!/bin/bash

# Setup Apple Push Notification Certificates for Supabase Edge Functions
echo "🔐 Setting up Apple Push Notification Certificates..."

# Check if certificate files exist
if [ ! -f "development_key.pem" ]; then
    echo "❌ development_key.pem not found. Please convert your .p12 file first:"
    echo "   openssl pkcs12 -in PiggyBong_Development_Push.p12 -out development_key.pem -nodes -clcerts"
    exit 1
fi

if [ ! -f "production_key.pem" ]; then
    echo "❌ production_key.pem not found. Please convert your .p12 file first:"
    echo "   openssl pkcs12 -in PiggyBong_Production_Push.p12 -out production_key.pem -nodes -clcerts"
    exit 1
fi

echo "📄 Found certificate files..."

# Read certificate contents
DEVELOPMENT_CERT=$(cat development_key.pem)
PRODUCTION_CERT=$(cat production_key.pem)

# Set Supabase secrets
echo "🔑 Setting Supabase environment variables..."

echo "Setting APN_DEVELOPMENT_CERT..."
echo "$DEVELOPMENT_CERT" | supabase secrets set APN_DEVELOPMENT_CERT

echo "Setting APN_PRODUCTION_CERT..."
echo "$PRODUCTION_CERT" | supabase secrets set APN_PRODUCTION_CERT

# Set other Apple Developer credentials
echo "Setting APN_TEAM_ID..."
supabase secrets set APN_TEAM_ID="4V55KN5U7M"

echo "Setting APN_BUNDLE_ID..."
supabase secrets set APN_BUNDLE_ID="carmenwong.PiggyBong"

echo ""
echo "🎉 Certificate setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Deploy updated APN service: supabase functions deploy apn-service"
echo "2. Test push notifications from your app"
echo ""
echo "🗑️  Clean up certificate files:"
echo "   rm development_key.pem production_key.pem"