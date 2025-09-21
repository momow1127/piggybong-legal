#!/bin/bash
# Permanent fix for Xcode workspace corruption
# Run this script whenever you see "multiple references with the same GUID" error

echo "🔧 PERMANENT XCODE CORRUPTION FIX"
echo "================================="

# Kill any running Xcode processes
killall Xcode 2>/dev/null || true
sleep 2

# Nuclear cleanup
echo "📦 Removing corrupted workspace data..."
rm -rf DerivedData/
rm -rf FanPlan.xcodeproj/project.xcworkspace/xcuserdata
rm -f FanPlan.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

# Clear global Xcode cache
echo "🗑️ Clearing global Xcode cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/FanPlan-* 2>/dev/null || true

# Create fresh package resolver
echo "🆕 Creating fresh Package.resolved..."
mkdir -p FanPlan.xcodeproj/project.xcworkspace/xcshareddata/swiftpm
cat > FanPlan.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved << 'RESOLVED'
{
  "pins" : [ ],
  "version" : 2
}
RESOLVED

echo "✅ Corruption fix complete!"
echo "📱 You can now open your project in Xcode safely"
