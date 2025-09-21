#!/bin/bash

# Auto-watch and commit changes to GitHub
# This script monitors for file changes and automatically commits/pushes them

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
WATCH_INTERVAL=60  # Check for changes every 60 seconds
MIN_FILES_FOR_COMMIT=1  # Minimum number of changed files to trigger commit
COMMIT_PREFIX="Auto-sync"  # Prefix for auto-generated commit messages

# Function to print colored output with timestamp
print_status() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ️${NC} $1"
}

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository!"
    exit 1
fi

# Function to commit and push changes
commit_and_push() {
    local changed_files=$(git status --porcelain | wc -l | tr -d ' ')
    
    if [ "$changed_files" -ge "$MIN_FILES_FOR_COMMIT" ]; then
        print_status "Found ${changed_files} changed files. Committing..."
        
        # Stage all changes
        git add -A
        
        # Generate detailed commit message
        local added=$(git diff --cached --name-only --diff-filter=A | wc -l | tr -d ' ')
        local modified=$(git diff --cached --name-only --diff-filter=M | wc -l | tr -d ' ')
        local deleted=$(git diff --cached --name-only --diff-filter=D | wc -l | tr -d ' ')
        
        local commit_msg="${COMMIT_PREFIX}: "
        
        if [ "$added" -gt 0 ]; then
            commit_msg="${commit_msg}+${added} "
        fi
        
        if [ "$modified" -gt 0 ]; then
            commit_msg="${commit_msg}~${modified} "
        fi
        
        if [ "$deleted" -gt 0 ]; then
            commit_msg="${commit_msg}-${deleted} "
        fi
        
        commit_msg="${commit_msg}files | $(date '+%Y-%m-%d %H:%M:%S')"
        
        # Commit (bypass pre-commit hook if needed)
        local commit_success=0
        if git commit -m "${commit_msg}" > /dev/null 2>&1; then
            print_success "Committed: ${commit_msg}"
            commit_success=1
        elif git commit --no-verify -m "${commit_msg}" > /dev/null 2>&1; then
            print_warning "Committed with --no-verify: ${commit_msg}"
            commit_success=1
        else
            print_warning "Nothing to commit (files may be ignored)"
            return 1
        fi
        
        # Push to remote if commit succeeded
        if [ "$commit_success" -eq 1 ]; then
            if git push origin "$(git branch --show-current)" > /dev/null 2>&1; then
                print_success "Pushed to GitHub successfully"
                return 0
            else
                print_warning "Push failed. Will retry next cycle."
                return 1
            fi
        fi
    else
        return 1
    fi
}

# Trap to handle script termination
cleanup() {
    print_info "Stopping auto-commit watcher..."
    exit 0
}

trap cleanup SIGINT SIGTERM

# Main loop
print_info "Starting auto-commit watcher for GitHub"
print_info "Watching for changes every ${WATCH_INTERVAL} seconds"
print_info "Press Ctrl+C to stop"
echo ""

LAST_COMMIT_TIME=$(date +%s)
COMMIT_COUNT=0

while true; do
    # Check for changes
    if [[ -n $(git status --porcelain) ]]; then
        if commit_and_push; then
            COMMIT_COUNT=$((COMMIT_COUNT + 1))
            LAST_COMMIT_TIME=$(date +%s)
            print_info "Total auto-commits this session: ${COMMIT_COUNT}"
        fi
    else
        # Calculate time since last commit
        CURRENT_TIME=$(date +%s)
        TIME_DIFF=$((CURRENT_TIME - LAST_COMMIT_TIME))
        MINUTES=$((TIME_DIFF / 60))
        
        if [ "$MINUTES" -gt 5 ]; then
            print_status "No changes detected (last commit: ${MINUTES}m ago)"
        fi
    fi
    
    # Wait before next check
    sleep "$WATCH_INTERVAL"
done