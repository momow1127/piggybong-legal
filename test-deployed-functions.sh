#!/bin/bash

echo "🧪 Testing Deployed Functions..."

SUPABASE_URL="https://lxnenbhkmdvjsmnripax.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4bmVuYmhrbWR2anNtbnJpcGF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyNzYyODQsImV4cCI6MjA2ODg1MjI4NH0.ykqeirIevUiJLWOMDznw7Sw0H1EZRqqXETrT23_VOv0"

echo "🔍 Testing get-upcoming-events (fixed with CORS)..."
curl -X POST "${SUPABASE_URL}/functions/v1/get-upcoming-events" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -d '{
    "artists": ["BTS"],
    "genres": ["music"],
    "location": "Los Angeles",
    "limit": 5
  }' \
  -w "\nStatus: %{http_code}\n"

echo -e "\n🔍 Testing send-verification-code (fixed with CORS)..."
curl -X POST "${SUPABASE_URL}/functions/v1/send-verification-code" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -d '{
    "email": "test@example.com",
    "type": "signup"
  }' \
  -w "\nStatus: %{http_code}\n"

echo -e "\n🔍 Testing cache-manager (fixed with CORS)..."
curl -X POST "${SUPABASE_URL}/functions/v1/cache-manager" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -d '{
    "action": "stats"
  }' \
  -w "\nStatus: %{http_code}\n"

echo -e "\n✅ Function testing complete!"
echo "📊 Check the responses above:"
echo "  - Status 200: ✅ Function working"
echo "  - Status 401/403: ❌ Authentication issue"
echo "  - Status 500: ❌ Function error"
echo "  - No CORS errors: ✅ CORS fix working"