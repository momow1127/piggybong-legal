#!/bin/bash

# Deploy Email Verification System to Supabase
# This script deploys the database migration and Edge Functions for email verification

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Deploying Email Verification System to Supabase...${NC}"
echo ""

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}❌ Supabase CLI is not installed.${NC}"
    echo "Install it with: npm install -g supabase"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "supabase/config.toml" ]; then
    echo -e "${RED}❌ Not in a Supabase project directory.${NC}"
    echo "Make sure you're in the project root and have run 'supabase init'."
    exit 1
fi

# Step 1: Apply database migration
echo -e "${YELLOW}📊 Step 1: Applying database migration...${NC}"
if [ -f "supabase/migrations/create_verification_codes.sql" ]; then
    echo "Migration file found: create_verification_codes.sql"
    
    # Note: This will be applied automatically when we push to remote
    echo "✅ Migration ready for deployment"
else
    echo -e "${RED}❌ Migration file not found!${NC}"
    exit 1
fi

# Step 2: Deploy Edge Functions
echo ""
echo -e "${YELLOW}☁️ Step 2: Deploying Edge Functions...${NC}"

# Function 1: Send Verification Code
echo "Deploying send-verification-code function..."
if supabase functions deploy send-verification-code --project-ref $(grep 'project_id' supabase/config.toml | cut -d'"' -f2) --no-verify-jwt; then
    echo -e "${GREEN}✅ send-verification-code deployed successfully${NC}"
else
    echo -e "${RED}❌ Failed to deploy send-verification-code${NC}"
    exit 1
fi

# Function 2: Verify Email Code
echo "Deploying verify-email-code function..."
if supabase functions deploy verify-email-code --project-ref $(grep 'project_id' supabase/config.toml | cut -d'"' -f2) --no-verify-jwt; then
    echo -e "${GREEN}✅ verify-email-code deployed successfully${NC}"
else
    echo -e "${RED}❌ Failed to deploy verify-email-code${NC}"
    exit 1
fi

# Function 3: Cleanup Expired Codes
echo "Deploying cleanup-expired-codes function..."
if supabase functions deploy cleanup-expired-codes --project-ref $(grep 'project_id' supabase/config.toml | cut -d'"' -f2) --no-verify-jwt; then
    echo -e "${GREEN}✅ cleanup-expired-codes deployed successfully${NC}"
else
    echo -e "${RED}❌ Failed to deploy cleanup-expired-codes${NC}"
    exit 1
fi

# Step 3: Apply database changes
echo ""
echo -e "${YELLOW}🗄️ Step 3: Applying database changes to remote...${NC}"
if supabase db push; then
    echo -e "${GREEN}✅ Database migration applied successfully${NC}"
else
    echo -e "${RED}❌ Failed to apply database migration${NC}"
    echo "You may need to run this manually or check for conflicts."
fi

# Step 4: Test the functions
echo ""
echo -e "${YELLOW}🧪 Step 4: Testing deployed functions...${NC}"

# Get project details
PROJECT_REF=$(grep 'project_id' supabase/config.toml | cut -d'"' -f2)
SUPABASE_URL="https://${PROJECT_REF}.supabase.co"

echo "Project URL: $SUPABASE_URL"
echo ""

# Test 1: Send verification code
echo "Testing send-verification-code function..."
SEND_RESPONSE=$(curl -s -X POST \
  "${SUPABASE_URL}/functions/v1/send-verification-code" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY:-$(grep 'anon_key' supabase/config.toml | cut -d'"' -f2)}" \
  -d '{"email":"test@example.com","type":"signup"}' \
  --max-time 30)

if echo "$SEND_RESPONSE" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ send-verification-code function is working${NC}"
else
    echo -e "${RED}⚠️ send-verification-code function test failed${NC}"
    echo "Response: $SEND_RESPONSE"
fi

# Test 2: Verify code (will fail but should return proper error)
echo "Testing verify-email-code function..."
VERIFY_RESPONSE=$(curl -s -X POST \
  "${SUPABASE_URL}/functions/v1/verify-email-code" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY:-$(grep 'anon_key' supabase/config.toml | cut -d'"' -f2)}" \
  -d '{"email":"test@example.com","code":"123456"}' \
  --max-time 30)

if echo "$VERIFY_RESPONSE" | grep -q '"success"'; then
    echo -e "${GREEN}✅ verify-email-code function is responding${NC}"
else
    echo -e "${RED}⚠️ verify-email-code function test failed${NC}"
    echo "Response: $VERIFY_RESPONSE"
fi

# Step 5: Setup cron job for cleanup (optional)
echo ""
echo -e "${YELLOW}⏰ Step 5: Cron job setup (optional)${NC}"
echo "To automatically cleanup expired codes, you can set up a cron job to call:"
echo "${SUPABASE_URL}/functions/v1/cleanup-expired-codes"
echo ""
echo "Recommended: Every 30 minutes"
echo "Example cron: */30 * * * * curl -X POST ${SUPABASE_URL}/functions/v1/cleanup-expired-codes"

# Final summary
echo ""
echo -e "${GREEN}🎉 Email Verification System Deployment Complete!${NC}"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo "✅ Database table: verification_codes"
echo "✅ Edge Function: send-verification-code"
echo "✅ Edge Function: verify-email-code"
echo "✅ Edge Function: cleanup-expired-codes"
echo ""
echo -e "${BLUE}🔧 Next Steps:${NC}"
echo "1. Update your app to use the production URLs"
echo "2. Test the full flow with a real email address"
echo "3. Set up monitoring for the functions"
echo "4. Configure email templates (optional)"
echo ""
echo -e "${BLUE}🔗 Function URLs:${NC}"
echo "Send Code: ${SUPABASE_URL}/functions/v1/send-verification-code"
echo "Verify Code: ${SUPABASE_URL}/functions/v1/verify-email-code"
echo "Cleanup: ${SUPABASE_URL}/functions/v1/cleanup-expired-codes"