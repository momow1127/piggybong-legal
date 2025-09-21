#!/bin/bash

# Deploy Push Notification Edge Functions to Supabase
echo "🔔 Deploying PiggyBong Push Notification System..."

# Check if we're in the right directory
if [ ! -f "supabase/config.toml" ]; then
    echo "❌ Please run this script from the project root directory"
    exit 1
fi

# Deploy database schema first
echo "📋 Applying push notifications database schema..."
if [ -f "supabase/migrations/push_notifications_schema.sql" ]; then
    echo "   Schema file found - please run migration manually:"
    echo "   supabase db push"
else
    echo "   ⚠️  Schema file not found in migrations/"
fi

echo ""
echo "🚀 Deploying Edge Functions..."

# Deploy send-push-notification function
echo "📤 Deploying send-push-notification function..."
supabase functions deploy send-push-notification

if [ $? -eq 0 ]; then
    echo "   ✅ send-push-notification deployed successfully"
else
    echo "   ❌ Failed to deploy send-push-notification"
    exit 1
fi

# Deploy apn-service function
echo "📱 Deploying apn-service function..."
supabase functions deploy apn-service

if [ $? -eq 0 ]; then
    echo "   ✅ apn-service deployed successfully"
else
    echo "   ❌ Failed to deploy apn-service"
    exit 1
fi

echo ""
echo "🎉 Push Notification System Deployed Successfully!"
echo ""
echo "📋 Next Steps:"
echo "1. Export your .p12 certificates from Keychain Access:"
echo "   - Right-click 'Apple Push Se...enwong.PiggyBong' → Export"
echo "   - Right-click 'Apple Sandbo...enwong.PiggyBong' → Export"
echo "2. Convert certificates to environment variables"
echo "3. Set up proper APN JWT authentication in the functions"
echo "4. Test push notifications in your iOS app"
echo ""
echo "🔗 Function URLs:"
echo "   Send Push: https://lxnenbhkmdvjsmnripax.supabase.co/functions/v1/send-push-notification"
echo "   APN Service: https://lxnenbhkmdvjsmnripax.supabase.co/functions/v1/apn-service"