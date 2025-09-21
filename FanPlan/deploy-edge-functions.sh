#!/bin/bash

# Deploy Edge Functions to Supabase
# Run this script to deploy all authentication functions

echo "🚀 Deploying Supabase Edge Functions for PiggyBong..."

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Please install it first:"
    echo "   npm install -g supabase"
    echo "   or visit: https://supabase.com/docs/guides/cli"
    exit 1
fi

# Check if logged into Supabase
if ! supabase projects list &> /dev/null; then
    echo "🔐 Please log into Supabase first:"
    echo "   supabase login"
    exit 1
fi

# Deploy Apple Sign In function
echo "🍎 Deploying Apple Sign In validation function..."
supabase functions deploy auth-apple --project-ref $SUPABASE_PROJECT_REF

if [ $? -eq 0 ]; then
    echo "✅ Apple Sign In function deployed successfully"
else
    echo "❌ Failed to deploy Apple Sign In function"
    exit 1
fi

# Deploy Google Sign In function
echo "🔍 Deploying Google Sign In validation function..."
supabase functions deploy auth-google --project-ref $SUPABASE_PROJECT_REF

if [ $? -eq 0 ]; then
    echo "✅ Google Sign In function deployed successfully"
else
    echo "❌ Failed to deploy Google Sign In function"
    exit 1
fi

# Deploy User Management function
echo "👤 Deploying User Management function..."
supabase functions deploy user-management --project-ref $SUPABASE_PROJECT_REF

if [ $? -eq 0 ]; then
    echo "✅ User Management function deployed successfully"
else
    echo "❌ Failed to deploy User Management function"
    exit 1
fi

echo ""
echo "🎉 All Edge Functions deployed successfully!"
echo ""
echo "📋 Function URLs:"
echo "   Apple Auth:  https://$SUPABASE_PROJECT_REF.supabase.co/functions/v1/auth-apple"
echo "   Google Auth: https://$SUPABASE_PROJECT_REF.supabase.co/functions/v1/auth-google"
echo "   User Mgmt:   https://$SUPABASE_PROJECT_REF.supabase.co/functions/v1/user-management"
echo ""
echo "🔧 Next steps:"
echo "1. Test the functions in Supabase dashboard"
echo "2. Update your iOS app to use these endpoints"
echo "3. Configure environment variables for production"
echo ""
echo "💡 Remember to set these environment variables in Supabase:"
echo "   - SUPABASE_URL"
echo "   - SUPABASE_SERVICE_ROLE_KEY"
echo "   - GOOGLE_CLIENT_ID (for Google validation)"
echo "   - APPLE_CLIENT_ID (for Apple validation)"