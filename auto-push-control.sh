#!/bin/bash

<<<<<<< HEAD
# Quick control script for auto-push

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

case "$1" in
    start)
        # Quick start with default 30 minutes
        ./auto-push-timer.sh <<< "3"
        ;;
    stop)
        ./auto-push-timer.sh stop
        ;;
    status)
        ./auto-push-timer.sh status
        ;;
    logs)
        ./auto-push-timer.sh logs
        ;;
    5min)
        echo -e "${GREEN}Starting 5-minute auto-push...${NC}"
        ./auto-push-timer.sh 5min
        ;;
    15min)
        echo -e "${GREEN}Starting 15-minute auto-push...${NC}"
        ./auto-push-timer.sh <<< "2"
        ;;
    30min)
        echo -e "${GREEN}Starting 30-minute auto-push...${NC}"
        ./auto-push-timer.sh <<< "3"
        ;;
    1hr)
        echo -e "${GREEN}Starting hourly auto-push...${NC}"
        ./auto-push-timer.sh <<< "4"
        ;;
    *)
        echo -e "${BLUE}🐷 PiggyBong Auto-Push Control${NC}"
        echo ""
        echo "Usage:"
        echo "  ./auto-push-control.sh start     - Start with 30-min interval"
        echo "  ./auto-push-control.sh stop      - Stop auto-push"
        echo "  ./auto-push-control.sh status    - Check status"
        echo "  ./auto-push-control.sh logs      - View logs"
        echo ""
        echo "Quick timers:"
        echo "  ./auto-push-control.sh 5min     - Every 5 minutes"
        echo "  ./auto-push-control.sh 15min    - Every 15 minutes"
        echo "  ./auto-push-control.sh 30min    - Every 30 minutes"
        echo "  ./auto-push-control.sh 1hr      - Every hour"
        echo ""
        echo "Or run ./auto-push-timer.sh for interactive menu"
        ;;
esac
=======
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
>>>>>>> 579a307ccd822b076de16e6798bcc63283f70c21
