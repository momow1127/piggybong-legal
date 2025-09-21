import SwiftUI

// MARK: - UI Shims for FanDashboardData
// Minimal compatibility shims for dashboard compilation
// Only includes properties used by the current dashboard screen today

extension FanDashboardData {
    
    // MARK: - Artist Data
    var uiFanArtists: [FanArtist] { 
        return fanArtists
    }
    
    // MARK: - Events Data  
    var uiUpcomingEvents: [UpcomingEvent] {
        return upcomingEvents
    }
    
    // MARK: - Budget Data (Optional - only if legacy summary card is shown)
    var uiTotalMonthlyBudget: Double {
        return totalMonthlyBudget
    }
    
    var uiTotalMonthSpent: Double {
        return totalMonthSpent
    }
}

// MARK: - Additional Properties for Dashboard Views
extension FanDashboardData {
    // Computed properties for UI
    var topBias: FanArtist? { 
        return fanArtists.first
    }
    
    // urgentGoals property removed - goal functionality no longer supported
}

// MARK: - Type Compatibility Extensions

extension FanUser {
    var monthlyBudget: Double { return 0.0 }
}

extension Double {
    var safeCurrencyString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: self)) ?? "$0"
    }
}

extension ActivityItem {
    var createdAt: Date { return Date() }
}