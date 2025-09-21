#!/usr/bin/env swift

import Foundation

print("🔍 Testing Environment Variables Configuration")
print(String(repeating: "=", count: 50))

// Test Supabase URL
if let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] {
    print("✅ SUPABASE_URL found:")
    print("   Value: \(supabaseURL)")
} else {
    print("❌ SUPABASE_URL not found in environment")
}

// Test Supabase Anon Key  
if let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] {
    print("✅ SUPABASE_ANON_KEY found:")
    print("   Length: \(supabaseKey.count) characters")
    print("   First 20 chars: \(supabaseKey.prefix(20))...")
} else {
    print("❌ SUPABASE_ANON_KEY not found in environment")
}

// Test RevenueCat API Key
if let revenueCatKey = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"] {
    print("✅ REVENUECAT_API_KEY found:")
    print("   Value: \(revenueCatKey)")
} else {
    print("❌ REVENUECAT_API_KEY not found in environment")
}

print("\n📝 How to set environment variables:")
print("1. In Xcode: Edit Scheme → Run → Arguments → Environment Variables")
print("2. In Terminal: export VARIABLE_NAME=value")
print("3. In .env file (requires loading mechanism)")

print("\n🎯 Your Xcode scheme has these set, but they only work when:")
print("- Running from Xcode (Cmd+R)")
print("- NOT when: Building archives, TestFlight, or App Store")