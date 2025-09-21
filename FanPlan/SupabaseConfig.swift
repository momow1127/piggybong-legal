import Foundation

/// Supabase Configuration Helper
/// Reads from build settings and provides secure fallbacks
struct SupabaseConfig {
    
    /// Get Supabase URL from build configuration
    static var url: String {
        #if DEBUG
        // DEBUG: ProcessInfo.environment[...] ?? Bundle.main[...]
        if let envURL = ProcessInfo.processInfo.environment["SUPABASE_URL"],
           !envURL.isEmpty && envURL != "$(SUPABASE_URL)" {
            return envURL
        }
        // Fallback to Bundle.main for DEBUG
        if let plistURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
           !plistURL.isEmpty && !plistURL.contains("$(") {
            return plistURL
        }
        print("⚠️ SUPABASE_URL not found in environment or bundle")
        return ""
        #else
        // RELEASE: Try environment first, then Info.plist
        if let envURL = ProcessInfo.processInfo.environment["SUPABASE_URL"],
           !envURL.isEmpty && envURL != "$(SUPABASE_URL)" {
            return envURL
        }
        if let plistURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
           !plistURL.isEmpty && !plistURL.contains("$(") {
            return plistURL
        }
        fatalError("SUPABASE_URL must be configured in environment variables or Info.plist for production builds")
        #endif
    }
    
    /// Get Supabase Anon Key from build configuration
    static var anonKey: String {
        #if DEBUG
        // DEBUG: ProcessInfo.environment[...] ?? Bundle.main[...]
        if let envKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"],
           !envKey.isEmpty && envKey != "$(SUPABASE_ANON_KEY)" {
            // Clean up any XML encoding that might be present
            let cleanKey = envKey.replacingOccurrences(of: "&#10;", with: "")
                                 .replacingOccurrences(of: "\n", with: "")
                                 .replacingOccurrences(of: " ", with: "")
                                 .trimmingCharacters(in: .whitespacesAndNewlines)
            return cleanKey
        }
        // Fallback to Bundle.main for DEBUG
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
           !plistKey.isEmpty && !plistKey.contains("$(") {
            let cleanKey = plistKey.replacingOccurrences(of: "&#10;", with: "")
                                  .replacingOccurrences(of: "\n", with: "")
                                  .replacingOccurrences(of: " ", with: "")
                                  .trimmingCharacters(in: .whitespacesAndNewlines)
            return cleanKey
        }
        print("⚠️ SUPABASE_ANON_KEY not found in environment or bundle")
        return ""
        #else
        // RELEASE: Try environment first, then Info.plist
        if let envKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"],
           !envKey.isEmpty && envKey != "$(SUPABASE_ANON_KEY)" {
            let cleanKey = envKey.replacingOccurrences(of: "&#10;", with: "")
                                 .replacingOccurrences(of: "\n", with: "")
                                 .replacingOccurrences(of: " ", with: "")
                                 .trimmingCharacters(in: .whitespacesAndNewlines)
            return cleanKey
        }
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
           !plistKey.isEmpty && !plistKey.contains("$(") {
            let cleanKey = plistKey.replacingOccurrences(of: "&#10;", with: "")
                                  .replacingOccurrences(of: "\n", with: "")
                                  .replacingOccurrences(of: " ", with: "")
                                  .trimmingCharacters(in: .whitespacesAndNewlines)
            return cleanKey
        }
        fatalError("SUPABASE_ANON_KEY must be configured in environment variables or Info.plist for production builds")
        #endif
    }
    
    /// Validate configuration
    static var isValid: Bool {
        let url = Self.url
        let key = Self.anonKey
        
        return !url.isEmpty && 
               !key.isEmpty && 
               !url.contains("$(") && 
               !key.contains("$(") &&
               url.hasPrefix("http")
    }
    
    /// Debug description
    static var debugDescription: String {
        return """
        Supabase Configuration:
        - URL: \(url.prefix(30))...
        - Key: \(anonKey.prefix(10))...
        - Valid: \(isValid)
        """
    }
}