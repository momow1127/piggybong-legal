#!/bin/bash

echo "🚀 Deploying get-user-artists function..."

# Try to link the project first
echo "🔗 Linking to Supabase project..."
supabase link --project-ref lxnenbhkmdvjs

# Then deploy the function
echo "📤 Deploying function..."
supabase functions deploy get-user-artists --project-ref lxnenbhkmdvjs

echo "✅ Deployment complete!"
echo ""
echo "Your function should now be available at:"
echo "https://lxnenbhkmdvjsmnripax.supabase.co/functions/v1/get-user-artists"