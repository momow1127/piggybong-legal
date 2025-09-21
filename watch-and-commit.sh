#!/bin/bash

# File watcher and auto-commit script for PiggyBong project
# This script watches for file changes and automatically commits them to GitHub

# Configuration
WATCH_INTERVAL=60  # Check for changes every 60 seconds
AUTO_COMMIT_SCRIPT="./auto-commit.sh"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if auto-commit script exists
if [ ! -f "$AUTO_COMMIT_SCRIPT" ]; then
    echo -e "${RED}Error: auto-commit.sh not found!${NC}"
    exit 1
fi

echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     PiggyBong Auto-Commit Watcher         ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}👁️  Watching for changes every ${WATCH_INTERVAL} seconds...${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo ""

# Track last commit time
LAST_COMMIT_TIME=$(date +%s)
COMMIT_COOLDOWN=300  # Minimum 5 minutes between commits

# Main watch loop
while true; do
    # Check if there are changes
    if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
        CURRENT_TIME=$(date +%s)
        TIME_SINCE_LAST=$((CURRENT_TIME - LAST_COMMIT_TIME))
        
        # Check if enough time has passed since last commit
        if [ $TIME_SINCE_LAST -ge $COMMIT_COOLDOWN ]; then
            echo ""
            echo -e "${YELLOW}📝 Changes detected! Running auto-commit...${NC}"
            echo -e "${BLUE}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
            
            # Run auto-commit script
            bash "$AUTO_COMMIT_SCRIPT"
            
            # Update last commit time if successful
            if [ $? -eq 0 ]; then
                LAST_COMMIT_TIME=$CURRENT_TIME
                echo -e "${GREEN}✅ Auto-commit completed successfully${NC}"
            else
                echo -e "${RED}❌ Auto-commit failed${NC}"
            fi
            
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        else
            REMAINING=$((COMMIT_COOLDOWN - TIME_SINCE_LAST))
            echo -e "${BLUE}⏳ Changes detected but waiting ${REMAINING}s before next commit (cooldown)${NC}"
        fi
    else
        # Show heartbeat every 5 checks
        if [ $(($(date +%s) % 300)) -lt $WATCH_INTERVAL ]; then
            echo -e "${GREEN}💚 $(date '+%H:%M:%S') - No changes detected${NC}"
        fi
    fi
    
    # Wait before next check
    sleep $WATCH_INTERVAL
done