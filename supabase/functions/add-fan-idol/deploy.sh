#!/bin/bash

echo "🚀 Deploying add-fan-idol Edge Function..."

# Set environment variables
export SUPABASE_URL="https://lxnenbhkmdvjsmnripax.supabase.co"

# Deploy the function
supabase functions deploy add-fan-idol --project-ref lxnenbhkmdvjsmnripax --debug

echo "✅ Deployment completed!"