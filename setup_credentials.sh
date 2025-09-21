#!/bin/bash

# Secure Supabase Credentials Setup
echo "🔐 Secure Supabase Setup"
echo "========================"
echo ""
echo "This script will help you securely configure your Supabase credentials"
echo "using environment variables (not hardcoded in files)."
echo ""

# Check if credentials are already set
if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_ANON_KEY" ]; then
    echo "✅ Environment variables already set:"
    echo "   SUPABASE_URL: $SUPABASE_URL"
    echo "   SUPABASE_ANON_KEY: [REDACTED]"
    echo ""
    echo "🎯 Your app should now connect to your Supabase project!"
    exit 0
fi

echo "❗ Environment variables not found."
echo ""
echo "📋 To set up your credentials securely:"
echo ""
echo "1. Add these lines to your shell profile (~/.zshrc, ~/.bashrc, or ~/.bash_profile):"
echo ""
echo "   export SUPABASE_URL=\"https://your-project-id.supabase.co\""
echo "   export SUPABASE_ANON_KEY=\"your-anon-key-here\""
echo ""
echo "2. Replace with your actual values from your Supabase dashboard:"
echo "   - Go to https://app.supabase.com/"
echo "   - Select your project"
echo "   - Go to Settings > API"
echo "   - Copy your Project URL and anon public key"
echo ""
echo "3. Restart your terminal or run: source ~/.zshrc"
echo ""
echo "4. Run this script again to verify setup"
echo ""
echo "🔒 This keeps your credentials secure and out of your code!"

# Alternative: Set for current session only
echo ""
echo "🚀 Or set for current session only (temporary):"
echo ""
read -p "Enter your Supabase URL: " temp_url
read -s -p "Enter your anon key: " temp_key
echo ""

if [ -n "$temp_url" ] && [ -n "$temp_key" ]; then
    export SUPABASE_URL="$temp_url"
    export SUPABASE_ANON_KEY="$temp_key"
    echo ""
    echo "✅ Credentials set for current session!"
    echo "   URL: $SUPABASE_URL"
    echo "   Key: [REDACTED]"
    echo ""
    echo "🎯 Your app will now connect to your Supabase project!"
    echo "⚠️  Remember: These will be lost when you close the terminal."
else
    echo ""
    echo "❌ Setup cancelled."
fi