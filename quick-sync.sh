#!/bin/bash

# Quick Sync Script - One command to sync everything to GitHub
# Usage: ./quick-sync.sh [message]

set -e

CUSTOM_MESSAGE="$1"

echo "⚡ PiggyBong2 Quick Sync Starting..."

# Test build first (optional but recommended)
read -p "🔨 Test build before committing? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🏗️  Testing build..."
    if xcodebuild -project FanPlan.xcodeproj -scheme "Piggy Bong" -destination 'platform=iOS Simulator,name=iPhone 16' clean build -quiet; then
        echo "✅ Build successful!"
    else
        echo "❌ Build failed! Fix errors before committing."
        exit 1
    fi
fi

# Check what type of sync to perform
CHANGED_FILES=$(git status --porcelain | cut -c4-)
SUPABASE_CHANGES=$(echo "$CHANGED_FILES" | grep -c -E "(Supabase|Auth|Database|User|Profile|\.sql)" || true)

if [ "$SUPABASE_CHANGES" -gt 0 ]; then
    echo "🗄️  Detected Supabase changes, using Supabase sync..."
    if [ -n "$CUSTOM_MESSAGE" ]; then
        # Add custom message to Supabase sync
        git add -A
        git commit -m "feat(supabase): $CUSTOM_MESSAGE

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
        git pull origin main --rebase
        git push origin main
    else
        ./supabase-auto-sync.sh
    fi
else
    echo "📱 Using general auto-commit..."
    if [ -n "$CUSTOM_MESSAGE" ]; then
        # Add custom message to regular commit
        git add -A
        git commit -m "$CUSTOM_MESSAGE

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
        git pull origin main --rebase
        git push origin main
    else
        ./auto-commit.sh
    fi
fi

echo "🎉 Quick sync complete!"
echo "🔗 View changes: https://github.com/momow1127/PiggyBong2"
echo "📊 GitHub Actions: https://github.com/momow1127/PiggyBong2/actions"