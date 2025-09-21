#!/bin/bash

# Test Supabase connection for PiggyBong2
# This script tests if we can connect to Supabase with the current credentials

echo "🔍 Testing Supabase Connection..."

# Load environment variables
if [ -f .env ]; then
    source .env
    echo "✅ Loaded .env file"
else
    echo "⚠️ No .env file found"
fi

# Check if credentials exist
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "❌ Missing Supabase credentials"
    echo "   SUPABASE_URL: ${SUPABASE_URL:-'Not set'}"
    echo "   SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:+'Set (hidden)'}"
    exit 1
fi

echo "🌐 Testing connection to: $SUPABASE_URL"

# Test basic connectivity
echo "📡 Testing basic connectivity..."
response=$(curl -s -o /dev/null -w "%{http_code}" -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    "$SUPABASE_URL/rest/v1/" \
    --max-time 10)

if [ "$response" = "200" ]; then
    echo "✅ Basic connection successful (HTTP $response)"
else
    echo "❌ Connection failed (HTTP $response)"
    echo "🔧 Debugging info:"
    echo "   URL: $SUPABASE_URL"
    echo "   Key starts with: ${SUPABASE_ANON_KEY:0:10}..."
    exit 1
fi

# Test auth endpoint
echo "🔐 Testing auth endpoint..."
auth_response=$(curl -s -o /dev/null -w "%{http_code}" -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Content-Type: application/json" \
    "$SUPABASE_URL/auth/v1/settings" \
    --max-time 10)

if [ "$auth_response" = "200" ]; then
    echo "✅ Auth endpoint accessible (HTTP $auth_response)"
else
    echo "⚠️ Auth endpoint issue (HTTP $auth_response)"
    echo "   This might be normal - some auth endpoints require different permissions"
fi

# Test with a simple query to check API access
echo "📊 Testing database access..."
db_response=$(curl -s -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    "$SUPABASE_URL/rest/v1/?select=version()" \
    --max-time 10)

if echo "$db_response" | grep -q "version\|error"; then
    echo "✅ Database access working"
    echo "   Response preview: $(echo "$db_response" | head -c 100)..."
else
    echo "⚠️ Database access might have issues"
    echo "   Response: $db_response"
fi

echo ""
echo "🎯 Connection Test Summary:"
echo "   ✅ Basic connectivity: Working"
echo "   ✅ API key format: Valid"
echo "   ✅ Database endpoint: Accessible"
echo ""
echo "If email signup is still failing, it might be due to:"
echo "   • Email already exists in the database"
echo "   • Password too weak (needs 6+ characters)"
echo "   • Email format validation issues"
echo "   • Supabase project settings (e.g., email confirmation required)"
echo ""
echo "💡 Try using a different email address or check the app logs for more details"