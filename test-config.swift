#!/usr/bin/env swift

import Foundation

// Test script to verify API key configuration
print("🔍 Testing API Key Configuration")
print(String(repeating: "=", count: 50))

// Check environment variables
print("\n📋 Environment Variables:")
let envSupabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"]
let envSupabaseKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
let envRevenueCat = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"]

print("SUPABASE_URL: \(envSupabaseURL != nil ? "✅ Set (\(String(envSupabaseURL!.prefix(30)))...)" : "❌ Not set")")
print("SUPABASE_ANON_KEY: \(envSupabaseKey != nil ? "✅ Set (\(String(envSupabaseKey!.prefix(20)))...)" : "❌ Not set")")
print("REVENUECAT_API_KEY: \(envRevenueCat != nil ? "✅ Set (\(String(envRevenueCat!.prefix(20)))...)" : "❌ Not set")")

// Validate Supabase configuration
if let url = envSupabaseURL, let key = envSupabaseKey {
    print("\n🚀 Supabase Configuration:")
    print("URL: \(url)")
    print("Key: \(String(key.prefix(20)))...")
    
    // Test connection
    print("\n🔗 Testing Supabase connection...")
    let testURL = URL(string: "\(url)/rest/v1/")!
    var request = URLRequest(url: testURL)
    request.setValue(key, forHTTPHeaderField: "apikey")
    request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
    
    let semaphore = DispatchSemaphore(value: 0)
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 404 {
                print("✅ Supabase connection successful!")
            } else {
                print("⚠️ Supabase responded with status: \(httpResponse.statusCode)")
            }
        } else if let error = error {
            print("❌ Connection error: \(error.localizedDescription)")
        }
        semaphore.signal()
    }
    task.resume()
    semaphore.wait()
} else {
    print("\n⚠️ Supabase credentials not found in environment")
    print("Please set them in Xcode Build Settings or as environment variables")
}

print("\n📝 Configuration Summary:")
print(String(repeating: "=", count: 50))
if envSupabaseURL != nil && envSupabaseKey != nil {
    print("✅ Supabase is configured properly")
} else {
    print("❌ Supabase needs configuration")
}

if envRevenueCat != nil {
    print("✅ RevenueCat is configured properly")
} else {
    print("⚠️ RevenueCat needs configuration")
}

print("\n💡 To set these in Xcode:")
print("1. Select your project → Target → Build Settings")
print("2. Add User-Defined Settings:")
print("   SUPABASE_URL = your_url")
print("   SUPABASE_ANON_KEY = your_key")
print("   REVENUECAT_API_KEY = your_key")