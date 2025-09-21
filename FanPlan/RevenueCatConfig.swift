import Foundation

/// Secure configuration for RevenueCat API keys
/// DO NOT commit actual API keys to git
struct RevenueCatConfig {
    
    /// Returns the appropriate API key based on environment
    static var apiKey: String {
        print("🔍 [RevenueCatConfig] Checking RevenueCat API key sources...")

        // 0. Ensure Bundle.main is ready before accessing Info.plist
        guard Bundle.main.bundleIdentifier != nil else {
            print("   ⚠️ Bundle.main not ready, using fallback key")
            return "appl_aXABVpZnhojTFHMskeYPUsIzXuX"
        }

        // 1. Check environment variable FIRST (highest priority for Xcode scheme)
        if let envKey = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"],
           !envKey.isEmpty,
           envKey != "$(REVENUECAT_API_KEY)" {
            print("   ✅ Found REVENUECAT_API_KEY in environment: \(envKey.prefix(10))...")
            return envKey
        }

        // 2. Check Info.plist (for production/archived builds) with safe access
        if let infoPlistKey = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String,
           !infoPlistKey.isEmpty,
           !infoPlistKey.contains("$(") {  // Make sure it's resolved and not placeholder
            print("   ✅ Found REVENUECAT_API_KEY in Info.plist: \(infoPlistKey.prefix(10))...")
            return infoPlistKey
        }

        // 3. Try alternative Info.plist reading method with safe access
        if let infoPlistKey = Bundle.main.infoDictionary?["REVENUECAT_API_KEY"] as? String,
           !infoPlistKey.isEmpty,
           !infoPlistKey.contains("$(") {
            print("   ✅ Found REVENUECAT_API_KEY via infoDictionary: \(infoPlistKey.prefix(10))...")
            return infoPlistKey
        }

        print("   ❌ No Info.plist or environment variables found, checking Secrets.swift...")

        // 4. Check for local secrets file (development fallback)
        #if DEBUG
        // Use local secrets file for development
        let secretKey = Secrets.revenueCatAPIKey
        print("   📝 Secrets.swift returned: \(secretKey.isEmpty ? "EMPTY" : secretKey.prefix(10) + "...")")

        // If Secrets also returns empty, use hardcoded development key
        if secretKey.isEmpty {
            print("   ⚠️ Using hardcoded development key to prevent crash")
            return "appl_LTzZxrqzQBpTTIkBOJXnsmQJyzG"
        }
        return secretKey
        #else
        // Production build fallback to development key to prevent crashes
        print("   ⚠️ Production build using development RevenueCat key")
        return "appl_LTzZxrqzQBpTTIkBOJXnsmQJyzG"
        #endif
    }
    
    /// RevenueCat App ID
    static let appID = "proj47b37f59"
    
    /// Product identifiers
    struct Products {
        static let stanPlusMonthly = "piggybong_vip_monthly"
        static let stanPlusAnnual = "piggybong_vip_annual" // Future option
    }
    
    /// Entitlement identifiers
    struct Entitlements {
        static let premium = "vip_access"
        static let stanPlus = "vip_access" // Keep for compatibility
    }
    
    /// Offering identifiers
    struct Offerings {
        static let `default` = "default"
        static let trial = "seven_day_trial"
    }
    
    /// Promo codes for hackathon
    struct PromoCodes {
        static let hackathonJudges = "PIGGYVIP25"
        static let shippathon = "SHIPPATHON2025"
        static let betaTesters = "KPOPBETA2025"
    }
}

/// Instructions for setup:
/// 1. Get your API key from https://app.revenuecat.com
/// 2. For development: Replace "appl_XXXXXXXXXXXXXXXXXXXXX" above
/// 3. For production: Set REVENUECAT_API_KEY environment variable
/// 4. Never commit your actual API key to git