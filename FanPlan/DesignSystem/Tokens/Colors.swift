import SwiftUI

// MARK: - PiggyBong Design System Colors
// 🚨 SINGLE SOURCE OF TRUTH - Do not duplicate these definitions elsewhere
// All components and views must import and use these tokens ONLY

extension Color {
    
    // MARK: - Brand Colors
    /// Primary brand purple - Used for CTAs, focus states, primary actions
    static let piggyPrimary = Color(red: 0x5D/255, green: 0x2C/255, blue: 0xEE/255) // #5D2CEE
    
    /// Secondary brand purple - Used for gradients, secondary actions  
    static let piggySecondary = Color(red: 0x8B/255, green: 0x55/255, blue: 0xED/255) // #8B55ED
    
    /// Accent gold - Used for highlights, success states, premium features
    static let piggyAccent = Color(red: 1.0, green: 0.843, blue: 0.0) // #FFD700
    
    // MARK: - Background Colors
    /// Main app background - Dark space theme
    static let piggyBackground = Color(red: 0x0D/255, green: 0x00/255, blue: 0x11/255) // #0D0011
    
    /// Mid-level background for layering
    static let piggyBackgroundMid = Color(red: 0x36/255, green: 0x22/255, blue: 0x39/255) // #362239
    
    /// Surface background for cards and elevated content
    static let piggySurface = Color(red: 0.05, green: 0.05, blue: 0.1)
    
    // MARK: - Text Colors (WCAG AA Compliant)
    /// Primary text - Pure white for maximum contrast
    static let piggyTextPrimary = Color.white
    
    /// Secondary text - High contrast for readability
    static let piggyTextSecondary = Color.white.opacity(0.85)
    
    /// Tertiary text - Supporting information
    static let piggyTextTertiary = Color.white.opacity(0.65)
    
    /// Placeholder text - Form inputs and empty states
    static let piggyTextPlaceholder = Color.white.opacity(0.75)
    
    /// Hint text - Instructions and helper text
    static let piggyTextHint = Color.white.opacity(0.75)
    
    // MARK: - Component Background Colors
    /// Standard input field background
    static let piggyInputBackground = Color.white.opacity(0.12)
    
    /// Standard card background
    static let piggyCardBackground = Color.white.opacity(0.10)
    
    /// Elevated card background (modals, popovers)
    static let piggyCardBackgroundElevated = Color.white.opacity(0.15)
    
    // MARK: - Card Style Variants
    /// Primary card style - Most prominent content
    static let piggyCardPrimary = Color.white.opacity(0.15)
    
    /// Primary card secondary state
    static let piggyCardPrimarySecondary = Color.white.opacity(0.08)
    
    /// Secondary card style - Standard content
    static let piggyCardSecondary = Color.white.opacity(0.1)
    
    /// Secondary card secondary state  
    static let piggyCardSecondarySecondary = Color.white.opacity(0.05)
    
    /// Elevated card style - Important content
    static let piggyCardElevated = Color.white.opacity(0.2)
    
    /// Elevated card secondary state
    static let piggyCardElevatedSecondary = Color.white.opacity(0.1)
    
    /// Subtle card style - Background content
    static let piggyCardSubtle = Color.white.opacity(0.08)
    
    // MARK: - Border Colors
    /// Standard input field borders
    static let piggyInputBorder = Color.white.opacity(0.20)
    
    /// Standard card borders
    static let piggyCardBorder = Color.white.opacity(0.15)
    
    /// Neutral borders for dividers
    static let piggyNeutralBorder = Color(white: 0.5, opacity: 0.3)
    
    // MARK: - Border Style Variants
    /// Primary card border
    static let piggyCardBorderPrimary = Color.white.opacity(0.2)
    
    /// Secondary card border
    static let piggyCardBorderSecondary = Color.white.opacity(0.15)
    
    /// Elevated card border
    static let piggyCardBorderElevated = Color.white.opacity(0.25)
    
    /// Subtle card border
    static let piggyCardBorderSubtle = Color.white.opacity(0.1)
    
    // MARK: - Utility Colors
    /// Generic border for most use cases
    static let piggyBorder = Color.white.opacity(0.15)
    
    /// Overlay backgrounds for modals, sheets
    static let piggyOverlay = Color.white.opacity(0.1)
    
    /// Badge borders and outlines
    static let badgeBorder = Color.white.opacity(0.2)
    
    // MARK: - Status Colors (Budget & Semantic)
    /// Success states and positive budget
    static let budgetGreen = Color.green
    
    /// Warning states and neutral budget  
    static let budgetOrange = Color.orange
    
    /// Error states and over-budget
    static let budgetRed = Color.red
    
    // MARK: - Piggy Status Color Aliases
    /// Success states - Green for positive outcomes
    static let piggySuccess = budgetGreen
    
    /// Warning states - Orange for caution
    static let piggyWarning = budgetOrange
    
    /// Error states - Red for negative outcomes
    static let piggyError = budgetRed
    
    // MARK: - Interactive States
    /// Focus ring for inputs and interactive elements
    static let piggyFocusRing = Color.piggyPrimary
    
    /// Hover state background
    static let piggyHoverBackground = Color.white.opacity(0.12)
    
    /// Pressed state background
    static let piggyPressedBackground = Color.white.opacity(0.08)
    
    /// Disabled background
    static let piggyDisabledBackground = Color.white.opacity(0.04)
    
    /// Disabled foreground
    static let piggyDisabledForeground = Color.white.opacity(0.3)
    
    // MARK: - Modal & Overlay Colors
    /// Modal backdrop overlay
    static let modalOverlay = Color.black.opacity(0.6)
    
    /// Modal background
    static let modalBackground = Color.piggySurface
    
    /// Drag handle for sheets
    static let dragHandle = Color.white.opacity(0.3)
    
    // MARK: - Selection & Highlight Colors
    /// Selection background
    static let selectionBackground = Color.piggyPrimary.opacity(0.15)
    
    /// Selection border
    static let selectionBorder = Color.piggyPrimary.opacity(0.3)
    
    /// Highlight background
    static let highlightBackground = Color.piggyAccent.opacity(0.1)
    
    // MARK: - Basic Colors
    /// Pure transparent - Used for invisible spacers and overlays
    static let piggyClear = Color.clear

    /// Pure black - Used for overlays and high-contrast elements
    static let piggyBlack = Color.black

    // MARK: - Component-Specific Colors
    /// Toggle track inactive state
    static let toggleTrackInactive = Color.white.opacity(0.2)

    /// Toggle track active state
    static let toggleTrackActive = Color.piggyPrimary

    /// Toggle thumb
    static let toggleThumb = Color.white

    /// Badge background
    static let badgeBackground = Color.white.opacity(0.1)
}

// MARK: - Gradients
/// Pre-defined gradient combinations for consistent usage
struct PiggyGradients {
    /// Primary button gradient
    static let primaryButton = LinearGradient(
        colors: [Color.piggyPrimary, Color.piggySecondary],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// App background gradient
    static let background = LinearGradient(
        colors: [Color.piggyBackground, Color.piggyBackgroundMid, Color.piggyBackground],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Card elevation gradient
    static let cardElevated = LinearGradient(
        colors: [Color.piggyCardElevated, Color.piggyCardBackground],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Selection gradient
    static let selection = LinearGradient(
        colors: [Color.selectionBackground, Color.piggyPrimary.opacity(0.05)],
        startPoint: .top,
        endPoint: .bottom  
    )
}

// MARK: - Shadow Colors (Re-exported from Spacing.swift)
// 🚨 Shadow tokens now defined in DesignSystem/Tokens/Spacing.swift
// Use: PiggyShadows.light, PiggyShadows.card, etc.

// MARK: - Color Usage Guidelines
/*
 🎨 USAGE GUIDELINES:
 
 ✅ DO:
 - Use .piggyTextPrimary for all primary text
 - Use .piggyCardBackground for standard cards
 - Use .piggyBorder for most borders
 - Use PiggyGradients.primaryButton for CTAs
 
 ❌ DON'T:
 - Create Color(red:, green:, blue:) inline in views
 - Use Color.white.opacity() directly in components  
 - Duplicate these definitions in other files
 - Create local color extensions
 
 📱 SEMANTIC USAGE:
 - Background: piggyBackground -> piggySurface -> piggyCardBackground
 - Text: piggyTextPrimary -> piggyTextSecondary -> piggyTextTertiary
 - Borders: piggyBorder (default) -> piggyCardBorder (cards) -> piggyInputBorder (forms)
 - Interactive: piggyPrimary (default) -> piggyHoverBackground -> piggyPressedBackground
*/