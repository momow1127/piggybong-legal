#!/bin/bash

# PiggyBong Supabase Setup Script
echo "🐷 PiggyBong Supabase Setup"
echo "=========================="

# Check if supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Installing..."
    brew install supabase/tap/supabase
fi

# Check if Docker is running (required for local development)
if ! docker info &> /dev/null; then
    echo "⚠️  Docker is not running. You have two options:"
    echo ""
    echo "Option 1: Start Docker Desktop and run this script again for local development"
    echo "Option 2: Set up a cloud Supabase project at https://app.supabase.com/"
    echo ""
    echo "For cloud setup:"
    echo "1. Create a new project at https://app.supabase.com/"
    echo "2. Get your Project URL and anon key from Settings > API"
    echo "3. Set environment variables:"
    echo "   export SUPABASE_URL=\"https://your-project-id.supabase.co\""
    echo "   export SUPABASE_ANON_KEY=\"your-anon-key-here\""
    echo "4. Run the database schema in the SQL Editor:"
    echo "   Copy and paste the contents of database_schema.sql"
    echo ""
    exit 1
fi

# Check if supabase project is initialized
if [ ! -f "supabase/config.toml" ]; then
    echo "📁 Initializing Supabase project..."
    supabase init
fi

echo "🚀 Starting local Supabase..."
supabase start

# Check if start was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Supabase is running locally!"
    echo ""
    echo "📊 Supabase Studio: http://127.0.0.1:54323"
    echo "🔌 API URL: http://127.0.0.1:54321"
    echo "🔑 Anon Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
    echo ""
    echo "🎯 Next steps:"
    echo "1. Open Supabase Studio in your browser"
    echo "2. Go to SQL Editor"
    echo "3. Copy and paste the contents of database_schema.sql"
    echo "4. Run the script to create tables and sample data"
    echo "5. Your app will automatically connect to the local database"
    echo ""
    echo "🛑 To stop Supabase later: supabase stop"
else
    echo "❌ Failed to start Supabase. Check the error above."
    exit 1
fi