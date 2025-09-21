#!/bin/bash

# Test Supabase Edge Functions locally
echo "🧪 Testing Supabase Edge Functions..."

# Start local Supabase (if not already running)
echo "🚀 Starting local Supabase..."
supabase start

# Test OpenAI Proxy Function
echo ""
echo "🤖 Testing OpenAI Proxy Function..."
curl -X POST "http://127.0.0.1:54321/functions/v1/openai-proxy" \
  -H "Authorization: Bearer REDACTED_SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o-mini",
    "messages": [{"role": "user", "content": "Hello, test message"}],
    "temperature": 0.7
  }'

echo ""
echo ""

# Test Get Upcoming Events Function
echo "🎪 Testing Get Upcoming Events Function..."
curl -X POST "http://127.0.0.1:54321/functions/v1/get-upcoming-events" \
  -H "Authorization: Bearer REDACTED_SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "genres": ["K-pop"],
    "location": "Los Angeles",
    "limit": 10
  }'

echo ""
echo ""

# Test Search Artists Function
echo "🔍 Testing Search Artists Function..."
curl -X POST "http://127.0.0.1:54321/functions/v1/search-artists" \
  -H "Authorization: Bearer REDACTED_SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "BTS",
    "limit": 5
  }'

echo ""
echo ""

# Test Generate Fan Insights Function
echo "💡 Testing Generate Fan Insights Function..."
curl -X POST "http://127.0.0.1:54321/functions/v1/generate-fan-insights" \
  -H "Authorization: Bearer REDACTED_SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user",
    "event_history": ["BTS Concert", "BLACKPINK World Tour"],
    "preferences": ["K-pop", "Pop Rock"]
  }'

echo ""
echo ""
echo "✅ Testing complete!"