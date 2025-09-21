#!/bin/bash

# Start auto-sync to GitHub in background
# This will continuously monitor and push changes

echo "🚀 Starting PiggyBong Auto-Sync to GitHub"
echo "=================================================="
echo ""
echo "This will:"
echo "  ✅ Monitor file changes every 60 seconds"
echo "  ✅ Auto-commit when changes are detected"
echo "  ✅ Push to GitHub automatically"
echo ""
echo "To stop: Press Ctrl+C or close this terminal"
echo "=================================================="
echo ""

# Run the auto-watch script
./auto-watch-commit.sh