import Foundation

/// Diagnostic helper to debug Info.plist reading issues
struct DiagnosticHelper {
    static func runDiagnostics() {
        print("\n========================================")
        print("🔍 INFO.PLIST DIAGNOSTIC REPORT")
        print("========================================")

        // 1. Check Bundle Information
        print("\n📦 Bundle Information:")
        print("   Bundle Identifier: \(Bundle.main.bundleIdentifier ?? "nil")")
        print("   Bundle Path: \(Bundle.main.bundlePath)")
        if let infoPlistPath = Bundle.main.path(forResource: "Info", ofType: "plist") {
            print("   Info.plist Path: \(infoPlistPath)")
        } else {
            print("   ❌ Info.plist file not found in bundle!")
        }

        // 2. Check all keys in Info.plist
        print("\n📋 Info.plist Contents:")
        if let infoDict = Bundle.main.infoDictionary {
            print("   Total keys: \(infoDict.count)")

            // Look for our specific keys
            let keysToCheck = ["REVENUECAT_API_KEY", "SUPABASE_URL", "SUPABASE_ANON_KEY"]
            for key in keysToCheck {
                if let value = infoDict[key] {
                    let valueStr = String(describing: value)
                    print("   ✅ \(key) = \(valueStr.prefix(30))...")
                } else {
                    print("   ❌ \(key) = NOT FOUND")
                }
            }

            // Show all keys (for debugging)
            print("\n   All keys in Info.plist:")
            for (key, _) in infoDict.sorted(by: { $0.key < $1.key }) {
                if key.contains("API") || key.contains("KEY") || key.contains("SUPABASE") || key.contains("REVENUE") {
                    print("   - \(key)")
                }
            }
        } else {
            print("   ❌ Bundle.main.infoDictionary is nil!")
        }

        // 3. Try different reading methods
        print("\n🔬 Testing Different Reading Methods:")

        // Method 1: object(forInfoDictionaryKey:)
        if let value1 = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") {
            print("   Method 1 (object): Type=\(type(of: value1)), Value=\(String(describing: value1).prefix(30))...")
            if let stringValue = value1 as? String {
                print("   ✅ Can cast to String: \(stringValue.prefix(30))...")
            } else {
                print("   ❌ Cannot cast to String!")
            }
        } else {
            print("   Method 1 (object): nil")
        }

        // Method 2: infoDictionary
        if let value2 = Bundle.main.infoDictionary?["REVENUECAT_API_KEY"] {
            print("   Method 2 (dict): Type=\(type(of: value2)), Value=\(String(describing: value2).prefix(30))...")
        } else {
            print("   Method 2 (dict): nil")
        }

        // Method 3: Direct plist reading
        if let plistPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let plistData = FileManager.default.contents(atPath: plistPath),
           let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] {
            if let value3 = plist["REVENUECAT_API_KEY"] {
                print("   Method 3 (direct): Type=\(type(of: value3)), Value=\(String(describing: value3).prefix(30))...")
            } else {
                print("   Method 3 (direct): Key not found in plist")
            }
        } else {
            print("   Method 3 (direct): Failed to read plist")
        }

        // 4. Check for build configuration issues
        print("\n🏗 Build Configuration:")
        #if DEBUG
        print("   Configuration: DEBUG")
        #else
        print("   Configuration: RELEASE")
        #endif

        // 5. Check environment variables
        print("\n🌍 Environment Variables:")
        if let envValue = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"] {
            print("   ✅ REVENUECAT_API_KEY = \(envValue.prefix(30))...")
        } else {
            print("   ❌ REVENUECAT_API_KEY not set")
        }

        print("\n========================================")
        print("🔍 END OF DIAGNOSTIC REPORT")
        print("========================================\n")
    }
}