#!/usr/bin/env swift

import Foundation

print("🔍 Testing RevenueCat API Key Configuration")
print("==========================================")

// Check environment variable
if let envKey = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"] {
    print("✅ Environment variable REVENUECAT_API_KEY found: \(envKey.prefix(15))...")
    if envKey == "appl_aXABVpZnhojTFHMskeYPUsIzXuX" {
        print("✅ API key matches the correct value!")
    } else if envKey == "appl_LTzZxrqzQBpTTIkBOJXnsmQJyzG" {
        print("❌ API key is still the OLD/INVALID value")
    } else {
        print("⚠️ API key is different from both old and new values")
    }
} else {
    print("❌ Environment variable REVENUECAT_API_KEY not found")
}

// Check Info.plist (simulated - would need actual bundle)
print("\n📋 To fix the API key:")
print("1. In Xcode → Project Settings → Build Settings")
print("2. Search for 'User Defined'")
print("3. Find REVENUECAT_API_KEY")
print("4. Change value to: appl_aXABVpZnhojTFHMskeYPUsIzXuX")
print("5. Or set environment variable: export REVENUECAT_API_KEY=appl_aXABVpZnhojTFHMskeYPUsIzXuX")