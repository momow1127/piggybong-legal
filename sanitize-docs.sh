#!/bin/bash

# Sanitize Documentation - Replace API keys with placeholders
# This script makes documentation safe for public sharing

echo "🧹 Sanitizing documentation files..."

# RevenueCat API keys
echo "Replacing RevenueCat API keys..."
find . -name "*.md" -type f -exec sed -i '' 's/appl_LTzZxrqzQBpTTIkBOJXnsmQJyzG/appl_XXXXXXXXXXXXXXXXXXXXXXX/g' {} +
find . -name "*.md" -type f -exec sed -i '' 's/appl_aXABVpZnhojTFHMskeYPUsIzXuX/appl_XXXXXXXXXXXXXXXXXXXXXXX/g' {} +

# Supabase URLs
echo "Replacing Supabase URLs..."
find . -name "*.md" -type f -exec sed -i '' 's/https:\/\/lxnenbhkmdvjsmnripax\.supabase\.co/https:\/\/YOUR-PROJECT.supabase.co/g' {} +

# Supabase anon keys (JWT tokens)
echo "Replacing Supabase anon keys..."
find . -name "*.md" -type f -exec sed -i '' 's/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4bmVuYmhrbWR2anNtbnJpcGF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyNzYyODQsImV4cCI6MjA2ODg1MjI4NH0\.ykqeirIevUiJLWOMDznw7Sw0H1EZRqqXETrT23_VOv0/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.../g' {} +

# Project ref IDs
echo "Replacing project references..."
find . -name "*.md" -type f -exec sed -i '' 's/lxnenbhkmdvjsmnripax/YOUR-PROJECT-REF/g' {} +

echo "✅ Documentation sanitization complete!"
echo ""
echo "📋 Files sanitized:"
echo "  - All .md files now use placeholder keys"
echo "  - RevenueCat keys: appl_XXXXXXXXXXXXXXXXXXXXXXX"
echo "  - Supabase URL: https://YOUR-PROJECT.supabase.co"
echo "  - Supabase key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
echo ""
echo "⚠️  NOTE: Production files (Info.plist, project.pbxproj) were NOT modified"
echo "   These contain the real keys needed for your app to function."