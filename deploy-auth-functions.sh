#!/bin/bash

# Deploy Apple and Google Authentication Edge Functions
echo "🍎 Deploying Apple and Google Authentication Functions..."

# Check if we're logged in to Supabase
if ! supabase projects list &> /dev/null; then
    echo "❌ Please login to Supabase first with: supabase login"
    echo "   Or set SUPABASE_ACCESS_TOKEN environment variable"
    exit 1
fi

# Navigate to functions directory
cd supabase/functions

echo "🍎 Deploying Apple authentication function..."
supabase functions deploy auth-apple --project-ref lxnenbhkmdvjsmnripax

if [ $? -eq 0 ]; then
    echo "✅ Apple authentication function deployed successfully!"
else
    echo "❌ Failed to deploy Apple authentication function"
    exit 1
fi

echo "🔍 Deploying Google authentication function..."
supabase functions deploy auth-google --project-ref lxnenbhkmdvjsmnripax

if [ $? -eq 0 ]; then
    echo "✅ Google authentication function deployed successfully!"
else
    echo "❌ Failed to deploy Google authentication function"
    exit 1
fi

echo "🎉 All authentication functions deployed successfully!"
echo ""
echo "📋 Function URLs:"
echo "🍎 Apple Auth: https://lxnenbhkmdvjsmnripax.supabase.co/functions/v1/auth-apple"
echo "🔍 Google Auth: https://lxnenbhkmdvjsmnripax.supabase.co/functions/v1/auth-google"
echo ""
echo "💡 Test the functions using:"
echo "   curl -X POST https://lxnenbhkmdvjsmnripax.supabase.co/functions/v1/auth-apple"
echo "   curl -X POST https://lxnenbhkmdvjsmnripax.supabase.co/functions/v1/auth-google"