#!/usr/bin/env swift

import Foundation

print("🔍 Testing Environment Variables at Runtime:")
print("==========================================")

// Test the exact same code as SupabaseConfig
if let envURL = ProcessInfo.processInfo.environment["SUPABASE_URL"],
   !envURL.isEmpty && envURL != "$(SUPABASE_URL)" {
    print("✅ SUPABASE_URL found: \(envURL)")
} else {
    print("❌ SUPABASE_URL not found")
    print("   Available env vars starting with 'SUP': \(ProcessInfo.processInfo.environment.keys.filter { $0.hasPrefix("SUP") })")
}

if let envKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"],
   !envKey.isEmpty && envKey != "$(SUPABASE_ANON_KEY)" {
    // Clean up any XML encoding
    let cleanKey = envKey.replacingOccurrences(of: "&#10;", with: "")
                         .replacingOccurrences(of: "\n", with: "")
                         .replacingOccurrences(of: " ", with: "")
                         .trimmingCharacters(in: .whitespacesAndNewlines)
    print("✅ SUPABASE_ANON_KEY found: \(cleanKey.prefix(20))...")
    print("   Raw key length: \(envKey.count), cleaned length: \(cleanKey.count)")
} else {
    print("❌ SUPABASE_ANON_KEY not found")
    print("   Available env vars starting with 'SUP': \(ProcessInfo.processInfo.environment.keys.filter { $0.hasPrefix("SUP") })")
}

// Test Info.plist access 
if let plistURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String {
    print("✅ SUPABASE_URL in Info.plist: \(plistURL)")
} else {
    print("⚠️ SUPABASE_URL not in Info.plist")
}

if let plistKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String {
    print("✅ SUPABASE_ANON_KEY in Info.plist: \(plistKey.prefix(20))...")
} else {
    print("⚠️ SUPABASE_ANON_KEY not in Info.plist")
}