#!/bin/bash

# Auto-push control script
# Usage: ./auto-push-control.sh [interval]
# Example: ./auto-push-control.sh 30min

# Default interval is 30 minutes
INTERVAL="${1:-30min}"

# Convert interval to seconds
if [[ $INTERVAL =~ ^([0-9]+)min$ ]]; then
    SECONDS=$((${BASH_REMATCH[1]} * 60))
elif [[ $INTERVAL =~ ^([0-9]+)h$ ]]; then
    SECONDS=$((${BASH_REMATCH[1]} * 3600))
elif [[ $INTERVAL =~ ^([0-9]+)s$ ]]; then
    SECONDS=${BASH_REMATCH[1]}
else
    echo "Invalid interval format. Use: 30min, 1h, or 3600s"
    exit 1
fi

echo "Starting auto-push with interval: $INTERVAL ($SECONDS seconds)"
echo "Press Ctrl+C to stop"

# Function to commit and push
auto_push() {
    # Check if there are changes
    if [[ -n $(git status --porcelain) ]]; then
        echo "$(date): Changes detected, committing and pushing..."

        # Add all changes
        git add -A

        # Create commit with timestamp
        COMMIT_MSG="Auto-commit: $(date '+%Y-%m-%d %H:%M:%S')"
        git commit -m "$COMMIT_MSG"

        # Push to remote
        git push origin main

        if [ $? -eq 0 ]; then
            echo "$(date): Successfully pushed changes"
        else
            echo "$(date): Push failed, will retry next interval"
        fi
    else
        echo "$(date): No changes to commit"
    fi
}

# Trap to handle script termination
trap "echo 'Auto-push stopped'; exit 0" INT TERM

# Main loop
while true; do
    auto_push
    echo "$(date): Waiting $INTERVAL until next check..."
    sleep $SECONDS
done