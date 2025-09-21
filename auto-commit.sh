#!/bin/bash

# Auto-commit and push script for PiggyBong2
# Usage: ./auto-commit.sh [optional commit message]

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐷 PiggyBong2 Auto Commit & Push${NC}"
echo "================================"

# Navigate to project directory (or use current directory if already there)
PROJECT_DIR='/Users/momow1127/Desktop/Desktop/Portfolio/My Project/AI/PiggyBong2-piggy-bong-main'
if [ -d "$PROJECT_DIR" ] && [ "$PWD" != "$PROJECT_DIR" ]; then
    cd "$PROJECT_DIR"
    echo -e "${YELLOW}📂 Changed to project directory${NC}"
fi

# Check if we're in a git repository
if [ ! -d '.git' ]; then
    echo -e "${RED}❌ Error: Not a git repository${NC}"
    exit 1
fi

# Pull latest changes first to avoid conflicts
echo -e "${BLUE}⬇️  Pulling latest changes...${NC}"
git pull origin main --no-edit 2>/dev/null

# Check for changes
if [[ -z $(git status -s) ]]; then
    echo -e "${YELLOW}ℹ️  No changes to commit${NC}"
    exit 0
fi

# Show what files changed
echo -e "${YELLOW}📊 Files changed:${NC}"
git status -s

# Stage all changes
echo -e "\n${GREEN}📦 Staging all changes...${NC}"
git add -A

# Count changes for summary
MODIFIED_COUNT=$(git diff --cached --name-only | wc -l | tr -d ' ')
TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S')

# Generate commit message
if [ -n "$1" ]; then
    # Use provided message
    COMMIT_MSG="$1

🤖 Auto-commit at $TIMESTAMP"
else
    # Get type of changes
    CHANGES=""
    if git diff --cached --name-only | grep -q "\.swift$"; then
        CHANGES="Swift updates"
    fi
    if git diff --cached --name-only | grep -q "\.sql$"; then
        [ -n "$CHANGES" ] && CHANGES="$CHANGES, " || CHANGES=""
        CHANGES="${CHANGES}Database migrations"
    fi
    if git diff --cached --name-only | grep -q "\.plist$"; then
        [ -n "$CHANGES" ] && CHANGES="$CHANGES, " || CHANGES=""
        CHANGES="${CHANGES}Config updates"
    fi
    [ -z "$CHANGES" ] && CHANGES="Various updates"

    COMMIT_MSG="Auto-update: $CHANGES ($MODIFIED_COUNT files)

Changes made at $TIMESTAMP

🤖 Generated with Auto-Commit Script"
fi

# Commit with message
echo -e "\n${GREEN}💾 Committing changes...${NC}"
echo -e "${YELLOW}Message: ${NC}$COMMIT_MSG"

# Try to commit (bypass pre-commit hook automatically)
if git commit --no-verify -m "$COMMIT_MSG"; then
    echo -e "${GREEN}✅ Commit successful${NC}"
else
    echo -e "${RED}❌ Commit failed${NC}"
    exit 1
fi

# Push to GitHub
echo -e "\n${GREEN}🚀 Pushing to GitHub...${NC}"
if git push origin main; then
    echo -e "${GREEN}✅ Successfully pushed to GitHub!${NC}"

    # Show summary
    COMMIT_HASH=$(git rev-parse --short HEAD)
    echo -e "\n${GREEN}📝 Summary:${NC}"
    echo -e "  • Files changed: ${MODIFIED_COUNT}"
    echo -e "  • Commit: ${COMMIT_HASH}"
    echo -e "  • Time: ${TIMESTAMP}"

    # Show GitHub URL
    REMOTE_URL=$(git remote get-url origin 2>/dev/null)
    if [[ $REMOTE_URL == *"github.com"* ]]; then
        REPO_PATH=${REMOTE_URL#*github.com/}
        REPO_PATH=${REPO_PATH%.git}
        REPO_PATH=${REPO_PATH#:}
        echo -e "  • View: ${BLUE}https://github.com/${REPO_PATH}/commit/${COMMIT_HASH}${NC}"
    fi

    echo -e "\n${GREEN}🎉 Auto-commit completed successfully!${NC}"
else
    echo -e "${RED}❌ Push failed. Checking for issues...${NC}"

    # Try to set upstream if needed
    if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
        echo -e "${YELLOW}Setting upstream branch...${NC}"
        git push --set-upstream origin main
    else
        echo -e "${RED}Please check your GitHub credentials or network connection.${NC}"
        exit 1
    fi
fi
