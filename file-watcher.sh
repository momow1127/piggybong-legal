#!/bin/bash
# Real-time File Watcher for Duplicate Detection
# Monitors FanPlan directory for changes and runs checks automatically

echo "👁️  Starting FanPlan File Watcher"
echo "Press Ctrl+C to stop"

FANPLAN_DIR="FanPlan"
CHECK_INTERVAL=5

# Function to run quick duplicate check
quick_check() {
    echo "📝 File changed detected, running quick check..."
    
    # Run basic duplicate detection
    duplicates=$(grep -r "struct HapticManager\|class HapticManager\|func formatCurrency\|struct.*ButtonStyle" $FANPLAN_DIR/ 2>/dev/null | wc -l)
    
    if [ "$duplicates" -gt 3 ]; then  # Expecting 3 legitimate instances
        echo "⚠️ Potential duplicates detected! Run ./pre-build-check.sh for details"
        
        # Optional: Play system sound on macOS
        if command -v afplay &> /dev/null; then
            afplay /System/Library/Sounds/Funk.aiff &
        fi
    fi
}

# Function to monitor specific patterns
monitor_patterns() {
    # Watch for new HapticManager declarations
    new_haptic=$(grep -r "struct HapticManager\|class HapticManager" $FANPLAN_DIR/ 2>/dev/null | grep -v "Utils/HapticManager.swift" | wc -l)
    
    if [ "$new_haptic" -gt 0 ]; then
        echo "🚨 NEW HAPTIC MANAGER DETECTED!"
        echo "   Use existing HapticManager from Utils/HapticManager.swift"
    fi
    
    # Watch for new format functions
    new_format=$(grep -r "func format.*Currency\|func.*format.*Money" $FANPLAN_DIR/ 2>/dev/null | grep -v "Utils/CurrencyFormatter.swift" | wc -l)
    
    if [ "$new_format" -gt 0 ]; then
        echo "🚨 NEW CURRENCY FORMATTER DETECTED!"
        echo "   Use existing formatCurrency from Utils/CurrencyFormatter.swift"
    fi
}

# Main monitoring loop
if command -v fswatch &> /dev/null; then
    echo "Using fswatch for real-time monitoring..."
    fswatch -o $FANPLAN_DIR | while read num; do
        quick_check
        monitor_patterns
    done
else
    echo "fswatch not available, using polling method..."
    echo "Install fswatch for better performance: brew install fswatch"
    
    while true; do
        sleep $CHECK_INTERVAL
        monitor_patterns
    done
fi