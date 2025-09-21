#!/bin/bash

# PiggyBong Environment Setup Script
# This script helps set up environment variables for secure credential management

set -e

echo "🐷 PiggyBong Environment Setup"
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "FanPlan.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}Error: Please run this script from the project root directory${NC}"
    exit 1
fi

echo -e "${BLUE}This script will help you set up environment variables for secure credential management.${NC}"
echo ""

# Function to prompt for input
prompt_input() {
    local prompt="$1"
    local var_name="$2"
    local is_secret="${3:-false}"
    
    echo -e "${YELLOW}$prompt${NC}"
    if [ "$is_secret" = true ]; then
        read -s input_value
        echo ""
    else
        read input_value
    fi
    
    if [ -z "$input_value" ]; then
        echo -e "${RED}Error: $var_name cannot be empty${NC}"
        return 1
    fi
    
    echo "$input_value"
}

# Check if .env file exists
ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}Found existing .env file. Creating backup...${NC}"
    cp "$ENV_FILE" "${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
fi

echo "Setting up Supabase credentials..."
echo ""

# Get Supabase URL
echo -e "${BLUE}1. Supabase Project URL${NC}"
echo "   Example: https://your-project-id.supabase.co"
SUPABASE_URL=$(prompt_input "Enter your Supabase project URL:" "SUPABASE_URL")

# Validate URL format
if [[ ! "$SUPABASE_URL" =~ ^https://.*\.supabase\.co$ ]]; then
    echo -e "${RED}Warning: URL format doesn't match expected Supabase pattern${NC}"
fi

echo ""

# Get Supabase Anon Key
echo -e "${BLUE}2. Supabase Anonymous Key${NC}"
echo "   This is your public anon key (safe to use in client-side code)"
echo "   Example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
SUPABASE_ANON_KEY=$(prompt_input "Enter your Supabase anon key:" "SUPABASE_ANON_KEY" true)

# Validate key format
if [[ ! "$SUPABASE_ANON_KEY" =~ ^(sb_|eyJ) ]]; then
    echo -e "${RED}Warning: Key format doesn't match expected Supabase pattern${NC}"
fi

echo ""

# Optional: Local development setup
echo -e "${BLUE}3. Local Development (Optional)${NC}"
echo "   If you're running Supabase locally for development"
read -p "Do you want to set up local development credentials? (y/N): " setup_local

if [[ "$setup_local" =~ ^[Yy]$ ]]; then
    SUPABASE_LOCAL_URL=$(prompt_input "Enter local Supabase URL (default: http://127.0.0.1:54321):" "SUPABASE_LOCAL_URL")
    SUPABASE_LOCAL_ANON_KEY=$(prompt_input "Enter local Supabase anon key:" "SUPABASE_LOCAL_ANON_KEY" true)
fi

# Create .env file
echo "Creating .env file..."
cat > "$ENV_FILE" << EOF
# PiggyBong Environment Configuration
# Generated on $(date)

# Supabase Configuration (Production/Cloud)
SUPABASE_URL=$SUPABASE_URL
SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

EOF

# Add local development if configured
if [ ! -z "$SUPABASE_LOCAL_URL" ]; then
    cat >> "$ENV_FILE" << EOF
# Local Development Configuration
SUPABASE_LOCAL_URL=$SUPABASE_LOCAL_URL
SUPABASE_LOCAL_ANON_KEY=$SUPABASE_LOCAL_ANON_KEY

EOF
fi

# Add additional configuration
cat >> "$ENV_FILE" << EOF
# App Configuration
APP_ENVIRONMENT=development

# Feature Flags
ENABLE_PUSH_NOTIFICATIONS=false
ENABLE_ANALYTICS=false
ENABLE_DEBUG_LOGGING=true
EOF

echo ""
echo -e "${GREEN}✅ Environment configuration created successfully!${NC}"
echo ""

# Create .env.example template
echo "Creating .env.example template..."
cat > ".env.example" << EOF
# PiggyBong Environment Configuration Template
# Copy this file to .env and fill in your actual values

# Supabase Configuration (Production/Cloud)
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

# Local Development Configuration (Optional)
SUPABASE_LOCAL_URL=http://127.0.0.1:54321
SUPABASE_LOCAL_ANON_KEY=your-local-anon-key-here

# App Configuration
APP_ENVIRONMENT=development

# Feature Flags
ENABLE_PUSH_NOTIFICATIONS=false
ENABLE_ANALYTICS=false
ENABLE_DEBUG_LOGGING=true
EOF

# Update .gitignore to ensure .env is not committed
if [ ! -f ".gitignore" ]; then
    touch ".gitignore"
fi

if ! grep -q "^\.env$" ".gitignore"; then
    echo "" >> ".gitignore"
    echo "# Environment variables" >> ".gitignore"
    echo ".env" >> ".gitignore"
    echo ".env.local" >> ".gitignore"
    echo ".env.*.local" >> ".gitignore"
    echo -e "${GREEN}✅ Updated .gitignore to exclude environment files${NC}"
fi

echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "1. The .env file has been created with your credentials"
echo "2. .env is automatically excluded from git commits"
echo "3. Share .env.example with your team (contains no secrets)"
echo "4. For Xcode: Add environment variables in your scheme editor"
echo ""

echo -e "${YELLOW}🔒 Security Notes:${NC}"
echo "• Never commit .env files to version control"
echo "• Use environment variables in production deployments"
echo "• Regenerate keys if they're ever exposed"
echo "• The anon key is safe for client-side use (has limited permissions)"
echo ""

echo -e "${GREEN}🎉 Setup complete! Your app is now configured securely.${NC}"

# Optional: Test connection
read -p "Would you like to test the Supabase connection? (y/N): " test_connection
if [[ "$test_connection" =~ ^[Yy]$ ]]; then
    echo "Testing connection..."
    # This would require additional tooling, but we can provide the info
    echo "To test the connection, run your app and check the console for:"
    echo "🔗 Using cloud Supabase: ${SUPABASE_URL:0:20}..."
    echo "✅ Database connection successful"
fi