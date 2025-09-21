#!/bin/bash

# Environment loader for PiggyBong project
# This script safely loads API keys and configuration

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔐 Loading PiggyBong Environment${NC}"
echo "=================================="

# Check for .env.local file
if [ -f ".env.local" ]; then
    echo -e "${GREEN}✓ Found .env.local file${NC}"
    source .env.local
    export $(grep -v '^#' .env.local | xargs)
elif [ -f ".env" ]; then
    echo -e "${YELLOW}⚠ Using .env file (consider using .env.local for security)${NC}"
    source .env
    export $(grep -v '^#' .env | xargs)
else
    echo -e "${RED}✗ No environment file found${NC}"
    echo ""
    echo "Creating .env.local with secure defaults..."
    
    cat > .env.local << 'EOF'
# Supabase Configuration
SUPABASE_URL=""
SUPABASE_ANON_KEY=""

# RevenueCat Configuration
REVENUECAT_API_KEY=""

# Other API Keys (add as needed)
# TICKETMASTER_API_KEY=""
# OPENAI_API_KEY=""
EOF
    
    echo -e "${GREEN}✓ Created .env.local file${NC}"
    source .env.local
    export $(grep -v '^#' .env.local | xargs)
fi

# Verify critical environment variables
echo ""
echo -e "${BLUE}Verifying Environment Variables:${NC}"
echo "--------------------------------"

# Check Supabase
if [ -n "$SUPABASE_URL" ] && [ "$SUPABASE_URL" != "your_supabase_url_here" ]; then
    echo -e "${GREEN}✓ SUPABASE_URL${NC}: ${SUPABASE_URL:0:30}..."
else
    echo -e "${RED}✗ SUPABASE_URL not set${NC}"
fi

if [ -n "$SUPABASE_ANON_KEY" ] && [ "$SUPABASE_ANON_KEY" != "your_supabase_anon_key_here" ]; then
    echo -e "${GREEN}✓ SUPABASE_ANON_KEY${NC}: ${SUPABASE_ANON_KEY:0:20}..."
else
    echo -e "${RED}✗ SUPABASE_ANON_KEY not set${NC}"
fi

# Check RevenueCat
if [ -n "$REVENUECAT_API_KEY" ] && [ "$REVENUECAT_API_KEY" != "your_revenuecat_api_key_here" ]; then
    echo -e "${GREEN}✓ REVENUECAT_API_KEY${NC}: ${REVENUECAT_API_KEY:0:15}..."
else
    echo -e "${YELLOW}⚠ REVENUECAT_API_KEY not set${NC}"
fi

echo ""
echo -e "${BLUE}Environment loaded successfully!${NC}"
echo ""
echo "To use in Xcode:"
echo "1. Product → Scheme → Edit Scheme"
echo "2. Run → Arguments → Environment Variables"
echo "3. Add the keys shown above"
echo ""
echo "To make permanent (zsh):"
echo "echo 'source $(pwd)/load-env.sh' >> ~/.zshrc"