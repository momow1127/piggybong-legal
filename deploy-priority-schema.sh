#!/bin/bash

# Deploy user priorities schema to Supabase
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "🚀 Deploying User Priorities Schema to Supabase"
echo "=============================================="

# Load environment variables
if [ -f .env ]; then
    source .env
    echo "✅ Loaded environment variables"
else
    echo "❌ .env file not found!"
    exit 1
fi

# Check for required variables
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_SERVICE_ROLE_KEY" ]; then
    echo "❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env"
    exit 1
fi

# Extract project ID from URL
PROJECT_ID=$(echo $SUPABASE_URL | sed 's/https:\/\/\(.*\)\.supabase\.co/\1/')
echo "📊 Project ID: $PROJECT_ID"

# Deploy the schema using curl
echo "📤 Deploying schema..."

RESPONSE=$(curl -s -X POST \
  "${SUPABASE_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"$(cat database/user_priorities_schema.sql | sed 's/"/\\"/g' | tr '\n' ' ')\"}" 2>&1)

# Alternative: Direct SQL execution via Supabase SQL endpoint
echo "📝 Executing SQL via Supabase Dashboard API..."

# Create a temporary file with the SQL
SQL_FILE="database/user_priorities_schema.sql"

echo ""
echo "⚠️  MANUAL DEPLOYMENT REQUIRED"
echo "================================"
echo ""
echo "Please deploy the schema manually:"
echo ""
echo "1. Open Supabase Dashboard:"
echo "   ${GREEN}https://app.supabase.com/project/${PROJECT_ID}/sql/new${NC}"
echo ""
echo "2. Copy and paste the SQL from:"
echo "   ${GREEN}database/user_priorities_schema.sql${NC}"
echo ""
echo "3. Click 'Run' to execute the SQL"
echo ""
echo "The schema includes:"
echo "  ✅ user_priorities table"
echo "  ✅ Indexes for performance"
echo "  ✅ Row Level Security policies"
echo "  ✅ Auto-update triggers"
echo ""
echo "After deployment, the AI insights will use real user priorities!"

# Also create a migration file for Supabase CLI users
TIMESTAMP=$(date +%Y%m%d%H%M%S)
MIGRATION_FILE="supabase/migrations/${TIMESTAMP}_user_priorities.sql"

if [ ! -d "supabase/migrations" ]; then
    mkdir -p supabase/migrations
fi

cp database/user_priorities_schema.sql "$MIGRATION_FILE"
echo ""
echo "📁 Migration file created: $MIGRATION_FILE"
echo "   (For Supabase CLI users: run 'supabase db push')"
echo ""
echo "✅ Schema preparation complete!"