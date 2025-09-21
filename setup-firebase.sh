#!/bin/bash

echo "🔥 Setting up Firebase Crashlytics for PiggyBong..."

# Step 1: Create Podfile if it doesn't exist
if [ ! -f "Podfile" ]; then
    echo "📦 Creating Podfile..."
    cat > Podfile << 'EOF'
platform :ios, '15.0'

target 'Piggy Bong' do
  use_frameworks!

  # Firebase
  pod 'FirebaseAnalytics'
  pod 'FirebaseCrashlytics'

  # Existing dependencies
  pod 'Supabase'
  pod 'RevenueCat'
end
EOF
fi

echo "✅ Podfile ready!"
echo ""
echo "📋 Next steps:"
echo "1. Go to https://console.firebase.google.com"
echo "2. Create a new project called 'PiggyBong'"
echo "3. Add an iOS app with bundle ID: carmenwong.PiggyBong"
echo "4. Download GoogleService-Info.plist"
echo "5. Add it to your Xcode project"
echo ""
echo "Then run: pod install"