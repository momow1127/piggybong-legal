#!/bin/bash

# Setup Ticketmaster API Integration for PiggyBong
echo "🎫 Setting up Ticketmaster API integration..."

# Check if .env.local exists
if [ ! -f ".env.local" ]; then
    echo "❌ .env.local file not found!"
    echo "Please create .env.local first with Supabase credentials"
    exit 1
fi

# Check if TICKETMASTER_API_KEY is set
if grep -q "TICKETMASTER_API_KEY.*YOUR_TICKETMASTER_API_KEY_HERE" .env.local; then
    echo "⚠️  Ticketmaster API key needs to be configured!"
    echo ""
    echo "📋 To get your Ticketmaster API key:"
    echo "1. Go to https://developer.ticketmaster.com/products-and-docs/apis/getting-started/"
    echo "2. Create a free account"
    echo "3. Create a new app to get your API key"
    echo "4. Copy your Consumer Key (this is your API key)"
    echo ""
    echo "✏️  Then update .env.local with your actual API key:"
    echo "export TICKETMASTER_API_KEY=\"your_actual_api_key_here\""
    echo ""
    echo "🔧 After updating .env.local, deploy the edge function:"
    echo "supabase functions deploy get-upcoming-events --env-file .env.local"
elif grep -q "TICKETMASTER_API_KEY" .env.local; then
    echo "✅ Ticketmaster API key found in .env.local"

    # Check if supabase CLI is available
    if command -v supabase &> /dev/null; then
        echo "🚀 Deploying edge function with environment variables..."
        source .env.local
        supabase functions deploy get-upcoming-events --env-file .env.local
        echo "✅ Edge function deployed successfully!"
    else
        echo "⚠️  Supabase CLI not found. Please install it to deploy edge functions."
        echo "npm install -g supabase"
    fi
else
    echo "❌ TICKETMASTER_API_KEY not found in .env.local"
    echo "Please add: export TICKETMASTER_API_KEY=\"your_api_key_here\""
fi

echo ""
echo "📚 Additional setup notes:"
echo "• The edge function will be available at: /functions/v1/get-upcoming-events"
echo "• Make sure your Supabase project has edge functions enabled"
echo "• Test the API integration in the Events tab of your app"