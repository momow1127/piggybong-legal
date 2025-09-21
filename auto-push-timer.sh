#!/bin/bash

# Auto-Push Timer for PiggyBong2
# Automatically commits and pushes changes at regular intervals

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

PROJECT_DIR="/Users/momow1127/Desktop/Desktop/Portfolio/My Project/AI/PiggyBong2-piggy-bong-main"
PID_FILE="$PROJECT_DIR/.auto-push.pid"
LOG_FILE="$PROJECT_DIR/.auto-push.log"

# Function to show menu
show_menu() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║    🐷 PiggyBong Auto-Push Timer     ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Choose auto-push frequency:${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} Every 5 minutes    (Development mode)"
    echo -e "  ${GREEN}2)${NC} Every 15 minutes   (Active coding)"
    echo -e "  ${GREEN}3)${NC} Every 30 minutes   (Regular work)"
    echo -e "  ${GREEN}4)${NC} Every 1 hour       (Background sync)"
    echo -e "  ${GREEN}5)${NC} Every 2 hours      (Light sync)"
    echo -e "  ${GREEN}6)${NC} Custom interval"
    echo ""
    echo -e "  ${YELLOW}s)${NC} Stop auto-push"
    echo -e "  ${YELLOW}v)${NC} View status"
    echo -e "  ${YELLOW}l)${NC} View logs"
    echo -e "  ${RED}q)${NC} Quit"
    echo ""
    echo -n "Enter your choice: "
}

# Function to start auto-push
start_auto_push() {
    local interval=$1
    local description=$2

    # Stop any existing auto-push
    stop_auto_push silent

    echo -e "\n${GREEN}Starting auto-push: $description${NC}"

    # Create the background process
    (
        while true; do
            cd "$PROJECT_DIR"

            # Check if there are changes
            if [[ -n $(git status -s) ]]; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Changes detected, auto-committing..." >> "$LOG_FILE"

                # Run auto-commit script
                ./auto-commit.sh "Auto-push: $description" >> "$LOG_FILE" 2>&1

                if [ $? -eq 0 ]; then
                    echo "$(date '+%Y-%m-%d %H:%M:%S') - Successfully pushed changes" >> "$LOG_FILE"
                else
                    echo "$(date '+%Y-%m-%d %H:%M:%S') - Push failed" >> "$LOG_FILE"
                fi
            else
                echo "$(date '+%Y-%m-%d %H:%M:%S') - No changes to commit" >> "$LOG_FILE"
            fi

            sleep "$interval"
        done
    ) &

    # Save PID
    echo $! > "$PID_FILE"
    echo "$description|$interval" > "$PROJECT_DIR/.auto-push.config"

    echo -e "${GREEN}✅ Auto-push started!${NC}"
    echo -e "${YELLOW}   PID: $(cat $PID_FILE)${NC}"
    echo -e "${YELLOW}   Interval: $description${NC}"
    echo -e "${YELLOW}   Logs: $LOG_FILE${NC}"
    echo ""
    echo -e "${BLUE}Run './auto-push-timer.sh stop' to stop auto-pushing${NC}"
}

# Function to stop auto-push
stop_auto_push() {
    local silent=$1

    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            kill $PID 2>/dev/null
            [ "$silent" != "silent" ] && echo -e "${GREEN}✅ Auto-push stopped (PID: $PID)${NC}"
        else
            [ "$silent" != "silent" ] && echo -e "${YELLOW}Auto-push was not running${NC}"
        fi
        rm -f "$PID_FILE"
        rm -f "$PROJECT_DIR/.auto-push.config"
    else
        [ "$silent" != "silent" ] && echo -e "${YELLOW}No auto-push process found${NC}"
    fi
}

# Function to show status
show_status() {
    echo ""
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            if [ -f "$PROJECT_DIR/.auto-push.config" ]; then
                CONFIG=$(cat "$PROJECT_DIR/.auto-push.config")
                DESC=$(echo "$CONFIG" | cut -d'|' -f1)
                echo -e "${GREEN}🟢 Auto-push is RUNNING${NC}"
                echo -e "   PID: $PID"
                echo -e "   Mode: $DESC"
            else
                echo -e "${GREEN}🟢 Auto-push is RUNNING${NC}"
                echo -e "   PID: $PID"
            fi

            # Show last 3 log entries
            if [ -f "$LOG_FILE" ]; then
                echo -e "\n${BLUE}Recent activity:${NC}"
                tail -3 "$LOG_FILE" | while read line; do
                    echo "   $line"
                done
            fi
        else
            echo -e "${RED}🔴 Auto-push is STOPPED${NC}"
            rm -f "$PID_FILE"
        fi
    else
        echo -e "${RED}🔴 Auto-push is STOPPED${NC}"
    fi
    echo ""
}

# Function to view logs
view_logs() {
    if [ -f "$LOG_FILE" ]; then
        echo -e "\n${BLUE}=== Auto-Push Logs ===${NC}\n"
        tail -20 "$LOG_FILE"
        echo -e "\n${YELLOW}(Showing last 20 entries. Full log: $LOG_FILE)${NC}"
    else
        echo -e "${YELLOW}No logs found yet${NC}"
    fi
    echo ""
}

# Main script logic
case "$1" in
    stop)
        stop_auto_push
        ;;
    status)
        show_status
        ;;
    logs)
        view_logs
        ;;
    5min)
        start_auto_push 300 "Every 5 minutes"
        ;;
    *)
        while true; do
            show_menu
            read -r choice

            case $choice in
                1)
                    start_auto_push 300 "Every 5 minutes"
                    break
                    ;;
                2)
                    start_auto_push 900 "Every 15 minutes"
                    break
                    ;;
                3)
                    start_auto_push 1800 "Every 30 minutes"
                    break
                    ;;
                4)
                    start_auto_push 3600 "Every 1 hour"
                    break
                    ;;
                5)
                    start_auto_push 7200 "Every 2 hours"
                    break
                    ;;
                6)
                    echo -n "Enter interval in minutes: "
                    read -r minutes
                    if [[ "$minutes" =~ ^[0-9]+$ ]] && [ "$minutes" -gt 0 ]; then
                        seconds=$((minutes * 60))
                        start_auto_push $seconds "Every $minutes minutes"
                        break
                    else
                        echo -e "${RED}Invalid input. Please enter a positive number.${NC}"
                        sleep 2
                    fi
                    ;;
                s)
                    stop_auto_push
                    echo "Press Enter to continue..."
                    read
                    ;;
                v)
                    show_status
                    echo "Press Enter to continue..."
                    read
                    ;;
                l)
                    view_logs
                    echo "Press Enter to continue..."
                    read
                    ;;
                q)
                    echo -e "${GREEN}Goodbye!${NC}"
                    exit 0
                    ;;
                *)
                    echo -e "${RED}Invalid option${NC}"
                    sleep 1
                    ;;
            esac
        done
        ;;
esac