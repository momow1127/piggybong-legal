#!/bin/bash

# Deploy Idol News System
echo "🚀 Deploying Idol News System"
echo "=============================="

# Check environment variables
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "Setting up environment variables..."
    export SUPABASE_URL="https://lxnenbhkmdvjsmnripax.supabase.co"
    export SUPABASE_ANON_KEY="sb_publishable_QaTynG5yOffgJZYCzfF1Fg_Dbf1bmCH"
fi

echo "🔗 Project URL: $SUPABASE_URL"

# 1. Deploy the database migration
echo ""
echo "1. Applying database migration..."
echo "   Please manually run the SQL migration in Supabase dashboard:"
echo "   - Open: https://lxnenbhkmdvjsmnripax.supabase.co/project/default/sql"
echo "   - Copy contents of supabase/migrations/20250118_idol_news_schema.sql"
echo "   - Run the migration"
echo ""

# 2. Deploy Edge Functions (requires Supabase CLI with auth)
echo "2. Edge Functions Deployment:"
echo "   To deploy the Edge Functions, you need to:"
echo "   a) Login to Supabase CLI:"
echo "      supabase login"
echo "   b) Link your project:"
echo "      supabase link --project-ref lxnenbhkmdvjsmnripax"
echo "   c) Deploy functions:"
echo "      supabase functions deploy fetch-idol-news"
echo "      supabase functions deploy scheduled-news-fetch"
echo ""

# 3. Set up environment variables for functions
echo "3. Environment Variables Setup:"
echo "   You'll need to set these in your Supabase project settings:"
echo "   - SPOTIFY_CLIENT_ID"
echo "   - SPOTIFY_CLIENT_SECRET" 
echo "   - TICKETMASTER_API_KEY"
echo ""

# 4. Test the deployment
echo "4. Testing the deployment..."
echo "   Once functions are deployed, test with:"
echo "   curl -X POST '$SUPABASE_URL/functions/v1/fetch-idol-news' \\"
echo "        -H 'Authorization: Bearer $SUPABASE_ANON_KEY' \\"
echo "        -H 'Content-Type: application/json' \\"
echo "        -d '{\"artistName\": \"BTS\", \"sources\": [\"spotify\"]}'"
echo ""

echo "✅ Deployment guide complete!"
echo "📖 Manual steps required - see output above"