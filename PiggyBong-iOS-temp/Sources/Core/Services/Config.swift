import Foundation

enum Config {
    enum Supabase {
        // TODO: Replace these with your actual Supabase credentials
        static let url = "https://your-project-id.supabase.co"
        static let anonKey = "your-anon-key-here"
    }
    
    enum App {
        static let name = "PiggyBong"
        static let version = "1.0.0"
        static let buildNumber = "1"
    }
    
    enum Features {
        static let enableOnboarding = true
        static let enableBudgetTracking = true
        static let enableArtistAllocations = true
        static let enablePushNotifications = false // MVP: Disable for now
        static let enableDataExport = false // MVP: Disable for now
    }
    
    enum Defaults {
        static let currency = "USD"
        static let defaultBudget = 100.0
        static let budgetCategories = [
            "album": [15.99, 25.99, 35.99, 45.99],
            "concert": [75.00, 150.00, 250.00, 400.00],
            "merchandise": [20.00, 35.00, 50.00, 75.00],
            "digital": [1.99, 9.99, 19.99, 29.99],
            "photocard": [5.00, 10.00, 15.00, 25.00],
            "other": [10.00, 25.00, 50.00, 100.00]
        ]
    }
    
    enum UI {
        static let animationDuration = 0.3
        static let maxPurchaseAmount = 10000.0
        static let maxBudgetAmount = 50000.0
        static let defaultCornerRadius = 12.0
        static let cardPadding = 16.0
    }
}

// MARK: - Environment Configuration
extension Config {
    enum Environment {
        case development
        case staging
        case production
        
        static var current: Environment {
            #if DEBUG
            return .development
            #elseif STAGING
            return .staging
            #else
            return .production
            #endif
        }
        
        var apiBaseURL: String {
            switch self {
            case .development:
                return Config.Supabase.url
            case .staging:
                return "https://staging-project-id.supabase.co"
            case .production:
                return Config.Supabase.url
            }
        }
        
        var enableLogging: Bool {
            switch self {
            case .development, .staging:
                return true
            case .production:
                return false
            }
        }
    }
}

// MARK: - Debug Helpers
extension Config {
    static func printConfiguration() {
        guard Environment.current.enableLogging else { return }
        
        print("🐷 PiggyBong Configuration:")
        print("   Environment: \(Environment.current)")
        print("   App Version: \(App.version) (\(App.buildNumber))")
        print("   Supabase URL: \(Supabase.url)")
        print("   Features: Onboarding=\(Features.enableOnboarding), Budget=\(Features.enableBudgetTracking)")
    }
}