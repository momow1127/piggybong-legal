#!/bin/bash

# Aggressive auto-commit script - commits after EVERY change
# Runs silently in background, only shows errors

# Colors for minimal output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Function to commit and push
commit_and_push() {
    # Check if there are changes
    if git diff --quiet && git diff --cached --quiet; then
        return 0
    fi
    
    # Get changed files
    CHANGED_FILES=$(git diff --name-only)
    STAGED_FILES=$(git diff --cached --name-only)
    ALL_FILES=$(echo -e "$CHANGED_FILES\n$STAGED_FILES" | sort -u | grep -v '^$' | head -5)
    FILE_COUNT=$(echo "$ALL_FILES" | wc -l | tr -d ' ')
    
    # Quick commit type detection
    if echo "$ALL_FILES" | head -1 | grep -q "\.swift$"; then
        TYPE="feat"
    elif echo "$ALL_FILES" | head -1 | grep -q "\.md$"; then
        TYPE="docs"
    else
        TYPE="update"
    fi
    
    # Get first changed file for context
    FIRST_FILE=$(echo "$ALL_FILES" | head -1 | xargs basename 2>/dev/null)
    
    # Stage all changes
    git add -A
    
    # Create minimal commit message
    COMMIT_OUTPUT=$(git commit -m "$TYPE: $FIRST_FILE and $((FILE_COUNT-1)) more files

🤖 Auto-commit by Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>" 2>&1)
    
    if [ $? -eq 0 ]; then
        # Push to remote
        PUSH_OUTPUT=$(git push origin piggy-bong-main 2>&1)
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓${NC} Auto-committed: $FIRST_FILE"
        else
            echo -e "${RED}✗${NC} Push failed"
        fi
    fi
}

# Export function for use in other scripts
export -f commit_and_push

# If called directly, run once
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    commit_and_push
fi