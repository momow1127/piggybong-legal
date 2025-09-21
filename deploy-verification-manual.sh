#!/bin/bash

# Manual Deployment Guide for Email Verification System
# Since automatic deployment requires Supabase CLI login, this provides manual steps

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Manual Deployment Guide for Email Verification System${NC}"
echo ""
echo -e "${YELLOW}Since automatic deployment requires Supabase CLI authentication,${NC}"
echo -e "${YELLOW}please follow these manual steps in the Supabase Dashboard:${NC}"
echo ""

# Load environment variables
source .env 2>/dev/null || echo "Note: .env file not found, using example values"

SUPABASE_URL=${SUPABASE_URL:-"https://lxnenbhkmdvjsmnripax.supabase.co"}
PROJECT_REF=$(echo "$SUPABASE_URL" | sed 's|https://||' | sed 's|\.supabase\.co||')

echo -e "${BLUE}🌐 Your Project Details:${NC}"
echo "Project URL: $SUPABASE_URL"
echo "Project Ref: $PROJECT_REF"
echo ""

echo -e "${BLUE}📊 Step 1: Create Database Table${NC}"
echo "1. Go to your Supabase Dashboard: https://app.supabase.com"
echo "2. Select your project: $PROJECT_REF"
echo "3. Go to 'SQL Editor'"
echo "4. Click 'New Query'"
echo "5. Copy and paste this SQL:"
echo ""
echo -e "${YELLOW}--- SQL to run in Supabase Dashboard ---${NC}"
cat supabase/migrations/create_verification_codes.sql
echo ""
echo -e "${YELLOW}--- End of SQL ---${NC}"
echo ""
echo "6. Click 'Run' to execute the SQL"
echo "7. Verify the 'verification_codes' table was created in the Table Editor"
echo ""

echo -e "${BLUE}☁️ Step 2: Create Edge Functions${NC}"
echo "1. In Supabase Dashboard, go to 'Edge Functions'"
echo "2. Click 'Create a new function'"
echo "3. Create these three functions:"
echo ""

echo -e "${YELLOW}Function 1: send-verification-code${NC}"
echo "- Function name: send-verification-code"
echo "- Copy code from: supabase/functions/send-verification-code/index.ts"
echo "- Deploy the function"
echo ""

echo -e "${YELLOW}Function 2: verify-email-code${NC}"
echo "- Function name: verify-email-code"
echo "- Copy code from: supabase/functions/verify-email-code/index.ts"
echo "- Deploy the function"
echo ""

echo -e "${YELLOW}Function 3: cleanup-expired-codes${NC}"
echo "- Function name: cleanup-expired-codes"
echo "- Copy code from: supabase/functions/cleanup-expired-codes/index.ts"
echo "- Deploy the function"
echo ""

echo -e "${BLUE}🧪 Step 3: Test the Functions${NC}"
echo "Once deployed, test with these curl commands:"
echo ""
echo -e "${YELLOW}Test send-verification-code:${NC}"
echo "curl -X POST \"$SUPABASE_URL/functions/v1/send-verification-code\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -H \"Authorization: Bearer $SUPABASE_ANON_KEY\" \\"
echo "  -d '{\"email\":\"test@example.com\",\"type\":\"signup\"}'"
echo ""

echo -e "${YELLOW}Test verify-email-code:${NC}"
echo "curl -X POST \"$SUPABASE_URL/functions/v1/verify-email-code\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -H \"Authorization: Bearer $SUPABASE_ANON_KEY\" \\"
echo "  -d '{\"email\":\"test@example.com\",\"code\":\"123456\"}'"
echo ""

echo -e "${BLUE}⚙️ Step 4: Verify App Configuration${NC}"
echo "Your app should already be configured to use the functions."
echo "Check these files have the right settings:"
echo "- .env: SUPABASE_URL and SUPABASE_ANON_KEY"
echo "- App uses SupabaseService.sendVerificationCode() and verifyEmailCode()"
echo ""

echo -e "${BLUE}📝 Step 5: Optional - Set up Automated Cleanup${NC}"
echo "Set up a cron job or scheduled task to call:"
echo "$SUPABASE_URL/functions/v1/cleanup-expired-codes"
echo "Recommended: Every 30 minutes"
echo ""

echo -e "${GREEN}🎉 Manual deployment steps complete!${NC}"
echo ""
echo -e "${BLUE}📋 Quick Checklist:${NC}"
echo "□ Database table created (verification_codes)"
echo "□ Three Edge Functions deployed"
echo "□ Functions tested with curl"
echo "□ App configuration verified"
echo "□ Cleanup cron job set up (optional)"
echo ""
echo -e "${BLUE}🔗 Useful Links:${NC}"
echo "Supabase Dashboard: https://app.supabase.com/project/$PROJECT_REF"
echo "SQL Editor: https://app.supabase.com/project/$PROJECT_REF/sql"
echo "Edge Functions: https://app.supabase.com/project/$PROJECT_REF/functions"
echo "Table Editor: https://app.supabase.com/project/$PROJECT_REF/editor"
echo ""
echo -e "${YELLOW}💡 Need help? Check EMAIL_VERIFICATION_SYSTEM.md for detailed documentation${NC}"