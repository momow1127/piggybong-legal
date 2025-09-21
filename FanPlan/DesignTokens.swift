import SwiftUI

// MARK: - DesignTokens.swift (LEGACY FILE - BEING PHASED OUT)
// 🚨 This file is maintained for backward compatibility only
// ALL NEW CODE SHOULD USE: DesignSystem/Tokens/* and DesignSystem/PiggyDesignSystem.swift

// MARK: - Import Centralized Design System
// Re-export centralized design tokens for backward compatibility

// Color tokens are available from DesignSystem/Tokens/Colors.swift
// Usage: Color.piggyPrimary, Color.piggyCardBackground, Color.piggyTextPrimary, etc.

// Typography tokens are available from DesignSystem/Tokens/Typography.swift  
// Usage: PiggyFont.body, PiggyFont.title2, PiggyFont.captionEmphasized, etc.

// Spacing tokens are available from DesignSystem/Tokens/Spacing.swift
// Usage: PiggySpacing.lg, PiggyBorderRadius.card, PiggyShadows.cardElevated, etc.

// MARK: - Legacy Gradients (Re-exported for compatibility)
// 🚨 DEPRECATED: Use DesignSystem/Tokens/Colors.swift -> PiggyGradients
// All gradient definitions now live in the centralized design system
@available(*, deprecated, message: "Use PiggyGradients from DesignSystem/Tokens/Colors.swift")
typealias LegacyPiggyGradients = PiggyGradients

// Re-export centralized gradients for backward compatibility
// This prevents "ambiguous use" errors while maintaining exact same values

// MARK: - Animation Compatibility Bridge
// Components expect PiggyAnimation (singular) but we have PiggyAnimations (plural)
@available(*, deprecated, message: "Use PiggyAnimations (plural) from DesignSystem/Tokens/Animations.swift")
public enum PiggyAnimation {
    // Bridge most commonly used animations
    public static let fast = PiggyAnimations.fast
    public static let standard = PiggyAnimations.standard  
    public static let slow = PiggyAnimations.slow
    public static let spring = PiggyAnimations.spring
    public static let bounce = PiggyAnimations.springBouncy
    public static let quick = PiggyAnimations.buttonPress
}

// MARK: - Button Style Compatibility Bridge
// Components expect .primaryButton() and .secondaryButton() view modifiers
extension View {
    /// Legacy button style - use PiggyButton component instead
    @available(*, deprecated, message: "Use PiggyButton component instead of Button().primaryButton()")
    func primaryButton() -> some View {
        self
            .font(PiggyFont.bodyEmphasized)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, PiggySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                    .fill(PiggyGradients.primaryButton)
            )
            .shadow(color: Color.piggyPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    /// Legacy button style - use PiggyButton component instead  
    @available(*, deprecated, message: "Use PiggyButton component instead of Button().secondaryButton()")
    func secondaryButton() -> some View {
        self
            .font(PiggyFont.body)
            .foregroundColor(.piggyPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, PiggySpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                    .fill(Color.piggyCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                            .stroke(Color.piggyPrimary, lineWidth: 1)
                    )
            )
    }
    
    // MARK: - Card Style Compatibility Bridge
    /// Legacy card style - use PiggyCard component instead
    @available(*, deprecated, message: "Use PiggyCard component instead of .unifiedCardStyle()")  
    func unifiedCardStyle() -> some View {
        self
            .padding(PiggySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                    .fill(Color.piggyCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                            .stroke(Color.piggyCardBorder, lineWidth: 1)
                    )
            )
    }
    
    /// Legacy elevated card style - use PiggyCard component instead  
    @available(*, deprecated, message: "Use PiggyCard component instead of .unifiedElevatedCardStyle()")
    func unifiedElevatedCardStyle() -> some View {
        self
            .padding(PiggySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                    .fill(Color.piggyCardElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                            .stroke(Color.piggyCardBorderElevated, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 4)
            )
    }
    
    // MARK: - Form Style Compatibility Bridge  
    /// Legacy text field style - use PiggyTextField component instead
    @available(*, deprecated, message: "Use PiggyTextField component instead of .unifiedTextFieldStyle()")
    func unifiedTextFieldStyle() -> some View {
        self
            .font(PiggyFont.body)
            .foregroundColor(.piggyTextPrimary)
            .padding(.horizontal, PiggySpacing.md)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.input)
                    .fill(Color.piggyInputBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.input)
                            .stroke(Color.piggyInputBorder, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Migration Notice
/*
 🚨 MIGRATION TO CENTRALIZED DESIGN SYSTEM:
 
 This DesignTokens.swift file will be phased out in favor of:
 - DesignSystem/Tokens/Colors.swift
 - DesignSystem/Tokens/Typography.swift  
 - DesignSystem/Tokens/Spacing.swift
 - DesignSystem/PiggyDesignSystem.swift
 
 The centralized design system provides:
 ✅ Single source of truth (no duplicates)
 ✅ Better organization and documentation
 ✅ Eliminates "ambiguous type lookup" errors
 ✅ Comprehensive component library
 ✅ Future theme switching support
 
 CURRENT STATUS:
 - All design tokens have been migrated to centralized system
 - Components can access tokens directly (no import needed)
 - This file remains for legacy compatibility only
 
 NEXT STEPS:
 1. Update remaining views to use centralized tokens
 2. Remove duplicate token definitions
 3. Deprecate this file completely
*/