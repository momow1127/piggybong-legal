#!/bin/bash

echo "🔧 Fixing Xcode project dependency graph issue..."

# Close Xcode if it's running
echo "📱 Closing Xcode..."
killall Xcode 2>/dev/null || true

# Remove all derived data
echo "🗑️ Clearing all derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData

# Remove project specific caches
echo "🗑️ Clearing project caches..."
rm -rf ./.build
rm -rf ./build
rm -rf ./DerivedData

# Remove Swift Package Manager workspace data
echo "📦 Resetting Swift Package Manager data..."
rm -rf ./FanPlan.xcodeproj/project.xcworkspace/xcshareddata/swiftpm

# Create fresh workspace directory
echo "📂 Creating fresh workspace structure..."
mkdir -p ./FanPlan.xcodeproj/project.xcworkspace/xcshareddata/swiftpm

echo "✅ Project cleanup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Open FanPlan.xcodeproj in Xcode"
echo "2. Xcode will automatically resolve package dependencies"
echo "3. Wait for 'Resolving Package Graph' to complete"
echo "4. Build the project (Cmd+B)"
echo ""
echo "If you still get the duplicate GUID error:"
echo "• File → Packages → Reset Package Caches"
echo "• File → Packages → Resolve Package Versions"