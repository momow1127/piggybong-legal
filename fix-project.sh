#!/bin/bash

# Fix Xcode project file visibility
echo "Fixing Xcode project file visibility..."

# Close Xcode
killall Xcode 2>/dev/null || true

# Wait a moment
sleep 2

# Remove user-specific Xcode data
rm -rf FanPlan.xcodeproj/xcuserdata/
rm -rf FanPlan.xcodeproj/project.xcworkspace/xcuserdata/

# Clean up any .DS_Store files that might interfere
find . -name ".DS_Store" -delete

# Touch all Swift files to update modification dates
find FanPlan -name "*.swift" -exec touch {} \;

echo "Project cleanup complete!"
echo "Now open Xcode and the files should appear."
echo ""
echo "In Xcode, if files are still missing:"
echo "1. Go to File → Add Files to 'FanPlan'"  
echo "2. Select the FanPlan folder"
echo "3. Make sure 'Create groups' is selected"
echo "4. Click 'Add'"

open FanPlan.xcodeproj