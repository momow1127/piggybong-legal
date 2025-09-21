#!/bin/bash

echo "🧪 Testing Edge Function API Call..."

# Your Supabase URL and keys (replace with actual values)
SUPABASE_URL="https://lxnenbhkmdvjsmnripax.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4bmVuYmhrbWR2anNtbnJpcGF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyNzYyODQsImV4cCI6MjA2ODg1MjI4NH0.ykqeirIevUiJLWOMDznw7Sw0H1EZRqqXETrT23_VOv0"

echo "📡 Making test request to your deployed function..."

curl -X POST "${SUPABASE_URL}/functions/v1/get-upcoming-events" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -d '{
    "artists": ["BTS", "Blackpink"],
    "genres": ["music"],
    "location": "Los Angeles",
    "limit": 10
  }' \
  --verbose

echo -e "\n\n✅ Test completed. Check the response above for errors."