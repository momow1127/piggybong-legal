#!/bin/bash

# Deploy all Supabase Edge Functions
echo "🚀 Deploying Supabase Edge Functions..."

# Check if we're logged in to Supabase
if ! supabase projects list &> /dev/null; then
    echo "❌ Please login to Supabase first with: supabase login"
    exit 1
fi

# Deploy critical dashboard functions first
echo "🏠 Deploying fan-dashboard function..."
supabase functions deploy fan-dashboard

echo "💰 Deploying add-purchase function..."
supabase functions deploy add-purchase

# Deploy supporting functions
echo "📡 Deploying openai-proxy function..."
supabase functions deploy openai-proxy

echo "🎪 Deploying get-upcoming-events function..."
supabase functions deploy get-upcoming-events

echo "🔍 Deploying search-artists function..."
supabase functions deploy search-artists

echo "💡 Deploying generate-fan-insights function..."
supabase functions deploy generate-fan-insights

echo "🎯 Deploying n8n-artist-webhook function..."
supabase functions deploy n8n-artist-webhook

echo "👥 Deploying manage-artist-subscription function..."
supabase functions deploy manage-artist-subscription

echo "📰 Deploying get-artist-updates function..."
supabase functions deploy get-artist-updates

echo "👤 Deploying get-user-artists function..."
supabase functions deploy get-user-artists

echo "📊 Deploying get-user-events function..."
supabase functions deploy get-user-events

echo "🔔 Deploying push notification functions..."
supabase functions deploy send-push-notification
supabase functions deploy apn-service

echo "✅ All functions deployed successfully!"

# Set environment variables (you'll need to run this manually with your actual keys)
echo ""
echo "🔑 Don't forget to set your environment variables:"
echo "supabase secrets set OPENAI_API_KEY=your_openai_key_here"
echo "supabase secrets set TICKETMASTER_API_KEY=your_ticketmaster_key_here"