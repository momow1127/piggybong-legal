import Foundation

enum Config {
    enum Supabase {
        // Secure configuration using environment variables only
        static let url = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "https://your-project-id.supabase.co"
        static let anonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? "your-anon-key-here"
        
        // Local development configuration (requires environment variables)
        static let localURL = ProcessInfo.processInfo.environment["SUPABASE_LOCAL_URL"] ?? "http://127.0.0.1:54321"
        static let localAnonKey = ProcessInfo.processInfo.environment["SUPABASE_LOCAL_ANON_KEY"] ?? "local-key-required"
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
        
        // Analytics features
        static let enableExperiments = false // Disabled - experimental feature removed
        static let enableAnalytics = true
        static let enableUserSegmentation = true
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
    
    enum Network {
        // Network timeout configurations (in seconds)
        static let standardTimeout: TimeInterval = 15.0
        static let quickTimeout: TimeInterval = 8.0
        static let authTimeout: TimeInterval = 10.0
        static let uploadTimeout: TimeInterval = 30.0
        static let revenueCatTimeout: TimeInterval = 12.0
        
        // Retry configurations
        static let maxRetries = 2
        static let retryDelay: TimeInterval = 1.0
        
        // Connection limits
        static let maxConcurrentConnections = 4
    }
    
    enum UI {
        static let animationDuration = 0.3
        static let maxPurchaseAmount = 10000.0
        static let maxBudgetAmount = 50000.0
        static let defaultCornerRadius = 12.0
        static let cardPadding = 16.0
        
        // Loading and error handling
        static let loadingTimeoutMessage = "Taking longer than expected..."
        static let offlineModeMessage = "Some features limited offline"
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
        
        var networkTimeout: TimeInterval {
            switch self {
            case .development:
                return Config.Network.standardTimeout
            case .staging:
                return Config.Network.standardTimeout * 1.5
            case .production:
                return Config.Network.standardTimeout
            }
        }
        
        var enableNetworkOptimizations: Bool {
            switch self {
            case .development:
                return false
            case .staging, .production:
                return true
            }
        }
        
        var experimentSampleRate: Double {
            switch self {
            case .development:
                return 1.0 // All users in experiments for testing
            case .staging:
                return 0.5 // 50% of users
            case .production:
                return 0.3 // 30% of users
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
        print("   Experiments: Enabled=\(Features.enableExperiments), Analytics=\(Features.enableAnalytics)")
    }
    
    // MARK: - Experiment Configuration
    enum Experiments {
        // Statistical thresholds for PiggyBong2 K-pop fan experiments
        static let minSampleSize = 1000
        static let confidenceLevel = 0.95
        static let statisticalPower = 0.80
        static let minPracticalSignificance = 0.05 // 5%
        
        // K-pop specific success metrics
        static let conversionGoals = [
            "freemium_to_vip": 0.12, // Target 12% conversion
            "first_purchase_within_7d": 0.25, // 25% first purchase rate
            "monthly_retention": 0.60 // 60% monthly retention
        ]
        
        // Experiment focus areas for K-pop spending tracker
        static let priorityAreas = [
            "vip_conversion": "Subscription paywall optimization",
            "onboarding_completion": "First-time user activation",
            "artist_engagement": "K-pop artist discovery and following",
            "spending_insights": "AI-powered spending analytics"
        ]
    }
    
    // Quick access for experiment enablement
    static var experimentsEnabled: Bool {
        return Features.enableExperiments && Features.enableAnalytics
    }
}