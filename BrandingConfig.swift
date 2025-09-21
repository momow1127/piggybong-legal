import SwiftUI

// MARK: - Branding Configuration
// This file makes it easy to update branding elements globally
struct BrandingConfig {
    
    // MARK: - Brand Identity
    static let appName = "Piggy Bong"
    static let tagline = "Plan smart. Love hard. Stay joyful."
    
    // MARK: - Primary Brand Colors
    // Change these values to update the entire app's color scheme
    struct BrandColors {
        // K-pop inspired gradient colors
        static let primaryStart = Color(red: 0.45, green: 0.30, blue: 0.85) // Purple
        static let primaryEnd = Color(red: 0.85, green: 0.30, blue: 0.65)   // Pink
        
        // Accent colors for different fan activities
        static let concertGold = Color(red: 1.0, green: 0.84, blue: 0.0)     // Concerts
        static let albumBlue = Color(red: 0.13, green: 0.59, blue: 0.95)     // Albums
        static let merchGreen = Color(red: 0.06, green: 0.73, blue: 0.51)    // Merchandise
        static let subscriptionOrange = Color(red: 0.96, green: 0.62, blue: 0.04) // Subscriptions
        
        // Background theme
        static let darkStart = Color(red: 0.1, green: 0.1, blue: 0.2)
        static let darkEnd = Color(red: 0.05, green: 0.05, blue: 0.15)
    }
    
    // MARK: - Typography Branding
    struct BrandTypography {
        // Font family - change to update app-wide typography
        static let fontDesign: Font.Design = .rounded
        
        // Display weights for headlines
        static let displayWeight: Font.Weight = .bold
        static let headlineWeight: Font.Weight = .semibold
        static let bodyWeight: Font.Weight = .medium
        
        // K-pop inspired typography hierarchy
        static let heroSize: CGFloat = 36
        static let titleSize: CGFloat = 30
        static let headlineSize: CGFloat = 24
        static let subtitleSize: CGFloat = 20
        static let bodySize: CGFloat = 16
        static let captionSize: CGFloat = 14
        static let labelSize: CGFloat = 12
    }
    
    // MARK: - Spacing & Layout
    struct BrandLayout {
        // Content spacing - adjust for different UI density
        static let contentPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
        static let cardSpacing: CGFloat = 12
        static let buttonSpacing: CGFloat = 12
        
        // Corner radius for brand personality
        static let cardRadius: CGFloat = 16
        static let buttonRadius: CGFloat = 12
        static let inputRadius: CGFloat = 12
        
        // Animation timing
        static let fastAnimation: Double = 0.15
        static let standardAnimation: Double = 0.3
        static let slowAnimation: Double = 0.5
    }
    
    // MARK: - Component Variants
    struct ComponentStyles {
        // Button heights for consistency
        static let primaryButtonHeight: CGFloat = 48
        static let secondaryButtonHeight: CGFloat = 44
        static let compactButtonHeight: CGFloat = 36
        
        // Card styles
        static let cardOpacity: Double = 0.08
        static let cardBorderOpacity: Double = 0.1
        static let cardShadowOpacity: Double = 0.15
    }
    
    // MARK: - Semantic Color Mapping
    // Maps brand colors to semantic usage
    static func colorForPriority(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "concert", "concerts", "show", "shows":
            return BrandColors.concertGold
        case "album", "albums", "music":
            return BrandColors.albumBlue
        case "merch", "merchandise", "goods":
            return BrandColors.merchGreen
        case "subscription", "subscriptions", "membership":
            return BrandColors.subscriptionOrange
        default:
            return DesignSystem.Colors.primaryPurple
        }
    }
    
    // MARK: - Dynamic Gradients
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [BrandColors.primaryStart, BrandColors.primaryEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [BrandColors.darkStart, BrandColors.darkEnd],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Theme Variants
    enum ThemeVariant {
        case standard    // Purple to Pink
        case warm        // Orange to Red
        case cool        // Blue to Teal
        case monochrome  // Gray scale
        
        var gradient: LinearGradient {
            switch self {
            case .standard:
                return LinearGradient(
                    colors: [BrandColors.primaryStart, BrandColors.primaryEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .warm:
                return LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.62, blue: 0.04), // Orange
                        Color(red: 0.94, green: 0.27, blue: 0.27)  // Red
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .cool:
                return LinearGradient(
                    colors: [
                        Color(red: 0.13, green: 0.59, blue: 0.95), // Blue
                        Color(red: 0.06, green: 0.73, blue: 0.51)  // Teal
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .monochrome:
                return LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.4, blue: 0.4),
                        Color(red: 0.6, green: 0.6, blue: 0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    // Current theme - change this to update app-wide theming
    static let currentTheme: ThemeVariant = .standard
}

// MARK: - Easy Branding Updates
// Use these computed properties in your DesignSystem.swift
extension DesignSystem.Colors {
    // Override existing colors with branding config
    static var dynamicPrimaryPurple: Color { BrandingConfig.BrandColors.primaryStart }
    static var dynamicPrimaryPink: Color { BrandingConfig.BrandColors.primaryEnd }
    static var dynamicPrimaryGradient: LinearGradient { BrandingConfig.primaryGradient }
    static var dynamicBackgroundGradient: LinearGradient { BrandingConfig.backgroundGradient }
}

extension DesignSystem.Typography {
    // Override with branding typography
    static var brandedDisplayLarge: Font {
        Font.system(
            size: BrandingConfig.BrandTypography.heroSize,
            weight: BrandingConfig.BrandTypography.displayWeight,
            design: BrandingConfig.BrandTypography.fontDesign
        )
    }
    
    static var brandedHeadlineLarge: Font {
        Font.system(
            size: BrandingConfig.BrandTypography.headlineSize,
            weight: BrandingConfig.BrandTypography.headlineWeight,
            design: BrandingConfig.BrandTypography.fontDesign
        )
    }
}

extension DesignSystem.Spacing {
    static var brandedStandardHorizontal: CGFloat { BrandingConfig.BrandLayout.contentPadding }
    static var brandedSectionSpacing: CGFloat { BrandingConfig.BrandLayout.sectionSpacing }
}

extension DesignSystem.CornerRadius {
    static var brandedCard: CGFloat { BrandingConfig.BrandLayout.cardRadius }
    static var brandedButton: CGFloat { BrandingConfig.BrandLayout.buttonRadius }
}