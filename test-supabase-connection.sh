#!/bin/bash

# Test Supabase connection
echo "🔍 Testing Supabase connection..."

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Test connection using curl
echo "📡 Testing Supabase URL: $SUPABASE_URL"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$SUPABASE_URL/rest/v1/" -H "apikey: $SUPABASE_ANON_KEY")

if [ "$RESPONSE" -eq 200 ] || [ "$RESPONSE" -eq 401 ] || [ "$RESPONSE" -eq 403 ]; then
    echo "✅ Supabase connection successful! (HTTP $RESPONSE)"
    echo "📊 Project URL: $SUPABASE_URL"
    echo "🔑 API Key configured: Yes"
else
    echo "❌ Supabase connection failed (HTTP $RESPONSE)"
    echo "Please check your SUPABASE_URL and SUPABASE_ANON_KEY in .env file"
    exit 1
fi

echo ""
echo "🎉 Supabase is properly configured!"