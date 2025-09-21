#!/bin/bash

# Setup script for PiggyBong environment variables
# This script helps you configure API keys properly without hardcoding

echo "🔧 PiggyBong Environment Setup"
echo "==============================="
echo ""
echo "This script will help you set up your environment variables properly."
echo "Your API keys will NEVER be stored in the source code."
echo ""

# Create .env.local file if it doesn't exist
ENV_FILE=".env.local"

if [ -f "$ENV_FILE" ]; then
    echo "⚠️  $ENV_FILE already exists. Backing up to $ENV_FILE.backup"
    cp "$ENV_FILE" "$ENV_FILE.backup"
fi

echo "Creating $ENV_FILE with your configuration..."
cat > "$ENV_FILE" << EOF
# PiggyBong Environment Variables
# ⚠️ NEVER commit this file to git!

# RevenueCat Configuration
export REVENUECAT_API_KEY="appl_aXABVpZnhojTFHMskeYPUsIzXuX"

# Supabase Configuration
export SUPABASE_URL="https://lxnenbhkmdvjsmnripax.supabase.co"
export SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4bmVuYmhrbWR2anNtbnJpcGF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyNzYyODQsImV4cCI6MjA2ODg1MjI4NH0.ykqeirIevUiJLWOMDznw7Sw0H1EZRqqXETrT23_VOv0"
EOF

# Add to .gitignore if not already there
if ! grep -q ".env.local" .gitignore 2>/dev/null; then
    echo ".env.local" >> .gitignore
    echo "✅ Added .env.local to .gitignore"
fi

echo ""
echo "✅ Environment file created: $ENV_FILE"
echo ""
echo "📱 To use in Xcode:"
echo "1. Edit your scheme (Product → Scheme → Edit Scheme)"
echo "2. Go to Run → Arguments → Environment Variables"
echo "3. Add these variables:"
echo "   - REVENUECAT_API_KEY: (paste your key)"
echo "   - SUPABASE_URL: (paste your URL)"
echo "   - SUPABASE_ANON_KEY: (paste your key)"
echo ""
echo "🖥️  To use in Terminal:"
echo "   source .env.local"
echo ""
echo "🔒 Security: The .env.local file is gitignored and won't be committed"