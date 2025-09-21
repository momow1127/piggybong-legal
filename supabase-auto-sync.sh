#!/bin/bash

# Supabase Auto-Sync Script for PiggyBong2
# Automatically commits and pushes Supabase-related changes to GitHub

set -e

echo "🗄️ Starting Supabase auto-sync..."

# Check for Supabase environment variables
if [ -f ".env" ]; then
    echo "✅ Found .env file"
else
    echo "⚠️  No .env file found - Supabase configuration may not be loaded"
fi

# Check Supabase connection
if [ -x "./test_supabase_connection.sh" ]; then
    echo "🔍 Testing Supabase connection..."
    if ./test_supabase_connection.sh; then
        echo "✅ Supabase connection successful"
        SUPABASE_STATUS="connected"
    else
        echo "⚠️  Supabase connection failed"
        SUPABASE_STATUS="disconnected"
    fi
else
    echo "📝 Skipping connection test (test script not found)"
    SUPABASE_STATUS="unknown"
fi

# Stage Supabase-related changes
echo "📦 Staging Supabase-related changes..."
git add -A

# Check if there are changes to commit
if git diff --cached --quiet; then
    echo "⚠️  No Supabase changes to commit."
    exit 0
fi

# Get Supabase-related changes
SUPABASE_FILES=$(git diff --cached --name-only | grep -E "(Supabase|Auth|Database|User|Profile)" || echo "")
SCHEMA_CHANGES=$(git diff --cached --name-only | grep -E "\.sql$" || echo "")

# Create timestamp
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Create Supabase-specific commit message
COMMIT_MSG="feat(supabase): Auto-sync Supabase integration - $TIMESTAMP

🗄️ Supabase Status: $SUPABASE_STATUS
📋 Files changed:
$(git diff --cached --name-status | head -10)

$(if [ -n "$SCHEMA_CHANGES" ]; then echo "🗃️ Database schema changes:"; echo "$SCHEMA_CHANGES"; fi)
$(if [ -n "$SUPABASE_FILES" ]; then echo "🔐 Auth/Profile changes:"; echo "$SUPABASE_FILES"; fi)

🤖 Generated with Claude Code - Supabase Auto-Sync
Co-Authored-By: Claude <noreply@anthropic.com>"

# Commit changes
echo "💾 Committing Supabase changes..."
git commit -m "$COMMIT_MSG"

# Pull and push
echo "⬇️  Syncing with GitHub..."
git pull origin main --rebase

echo "☁️  Pushing Supabase updates to GitHub..."
git push origin main

echo "🎉 Supabase auto-sync complete!"
echo "🔗 View at: https://github.com/momow1127/PiggyBong2"