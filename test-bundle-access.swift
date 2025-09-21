import Foundation

print("🔍 Testing Bundle Access to GOOGLE_CLIENT_ID")
print("=============================================")

// Test how the app accesses GOOGLE_CLIENT_ID at runtime
if let clientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String {
    print("✅ Found GOOGLE_CLIENT_ID in Bundle: \(clientID.prefix(20))...")

    // Check if it's empty or placeholder
    if clientID.isEmpty {
        print("❌ GOOGLE_CLIENT_ID is empty")
    } else if clientID.contains("$(") {
        print("❌ GOOGLE_CLIENT_ID contains placeholder: \(clientID)")
    } else {
        print("✅ GOOGLE_CLIENT_ID looks valid")
    }
} else {
    print("❌ GOOGLE_CLIENT_ID not found in Bundle.main")
}

// Let's also check what keys are available
print("\n📋 Available Keys in Bundle:")
if let infoDict = Bundle.main.infoDictionary {
    let googleKeys = infoDict.keys.filter { $0.localizedCaseInsensitiveContains("google") }
    if googleKeys.isEmpty {
        print("❌ No Google-related keys found")
    } else {
        for key in googleKeys {
            print("✅ Found key: \(key)")
        }
    }

    // Check some other auth-related keys
    let authKeys = ["GOOGLE_CLIENT_ID", "APPLE_CLIENT_ID", "SUPABASE_URL"]
    for key in authKeys {
        if let value = infoDict[key] as? String {
            print("✅ \(key): \(value.prefix(20))...")
        } else {
            print("❌ \(key): Not found")
        }
    }
} else {
    print("❌ Could not access Bundle.main.infoDictionary")
}

print("\n🎯 DIAGNOSIS:")
print("==============")
print("If GOOGLE_CLIENT_ID is not found in Bundle but exists in Info.plist,")
print("it means the Xcode build process isn't including it properly.")
print("This could be due to:")
print("1. Build configuration issues")
print("2. Info.plist not being processed correctly")
print("3. Bundle target configuration problems")