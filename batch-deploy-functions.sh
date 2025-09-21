#!/bin/bash

export SUPABASE_ACCESS_TOKEN="sbp_faf757a21960bf335174f4ede88d5a4153325b4f"

echo "🚀 BATCH DEPLOYING ALL FIXED EDGE FUNCTIONS"
echo "============================================"

# Critical functions first
CRITICAL_FUNCTIONS=(
  "manage-goals"
  "manage-subscription"
  "manage-artist-subscription"
  "manage-event-subscriptions"
  "search-artists"
  "get-artist-updates"
  "generate-fan-insights"
  "handle-subscription-webhook"
  "n8n-artist-webhook"
  "cleanup-expired-codes"
)

# Deploy critical functions
echo "📋 Phase 1: Deploying critical functions..."
for func in "${CRITICAL_FUNCTIONS[@]}"; do
  echo "🔧 Deploying $func..."
  supabase functions deploy "$func" --no-verify-jwt --project-ref lxnenbhkmdvjsmnripax
  if [ $? -eq 0 ]; then
    echo "   ✅ $func deployed successfully"
  else
    echo "   ❌ $func deployment failed"
  fi
  echo ""
done

echo "✅ Critical functions deployment completed!"
echo ""
echo "📊 Check deployment status:"
echo "   Dashboard: https://supabase.com/dashboard/project/lxnenbhkmdvjsmnripax/functions"
echo ""
echo "🧪 Next: Test the deployed functions"