#!/bin/bash

echo "🔍 Testing Info.plist reading without environment variables..."

# Unset the environment variable to force plist reading
unset REVENUECAT_API_KEY

# Build and run a simple test
cd "/Users/momow1127/Desktop/Desktop/Portfolio/My Project/AI/PiggyBong2-piggy-bong-main"

# Run a quick Swift script to test plist reading
swift - <<EOF
import Foundation

print("\n🔍 Testing Info.plist Reading")
print("========================================")

// Get the app bundle path
let bundlePath = "/Users/momow1127/Desktop/Desktop/Portfolio/My Project/AI/PiggyBong2-piggy-bong-main"
let plistPath = bundlePath + "/Info.plist"

print("📋 Reading from: \(plistPath)")

// Read the plist directly
if let plistData = FileManager.default.contents(atPath: plistPath),
   let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] {

    print("✅ Successfully read plist with \(plist.count) keys")

    // Look for RevenueCat key
    if let rcKey = plist["REVENUECAT_API_KEY"] {
        print("✅ Found REVENUECAT_API_KEY: '\(rcKey)'")
        print("   Type: \(type(of: rcKey))")

        if let stringKey = rcKey as? String {
            print("   ✅ Can cast to String")
            print("   Length: \(stringKey.count)")
            print("   Value: \(stringKey.prefix(30))...")
        } else {
            print("   ❌ Cannot cast to String!")
        }
    } else {
        print("❌ REVENUECAT_API_KEY not found in plist")

        // Show all keys containing "REVENUE"
        print("\nKeys containing 'REVENUE':")
        for key in plist.keys {
            if key.contains("REVENUE") {
                print("  - \(key)")
            }
        }
    }

    // Also check SUPABASE keys
    if let supaUrl = plist["SUPABASE_URL"] {
        print("\n✅ Found SUPABASE_URL: \(String(describing: supaUrl).prefix(50))...")
    }
    if let supaKey = plist["SUPABASE_ANON_KEY"] {
        print("✅ Found SUPABASE_ANON_KEY: \(String(describing: supaKey).prefix(50))...")
    }

} else {
    print("❌ Failed to read plist file")
}

print("========================================\n")
EOF

echo "✅ Test complete"