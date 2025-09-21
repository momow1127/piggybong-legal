import SwiftUI

/// Shared component sizing system for consistent heights across all form components
enum PiggyComponentSize {
    case small        // Small height - matches button small
    case medium       // Medium height - matches button medium  
    case large        // Large height - matches button large
    
    var height: CGFloat {
        switch self {
        case .small: return PiggySpacing.minTouchTarget      // 44pt
        case .medium: return PiggySpacing.touchTarget        // 48pt
        case .large: return PiggySpacing.largeTouchTarget    // 56pt
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .small: return PiggySpacing.xs    // 4pt
        case .medium: return PiggySpacing.sm   // 8pt
        case .large: return PiggySpacing.md    // 12pt (for 56pt height)
        }
    }
}