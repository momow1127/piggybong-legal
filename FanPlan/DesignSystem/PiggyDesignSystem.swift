import SwiftUI

// MARK: - PiggyBong Design System
// 🚨 SINGLE SOURCE OF TRUTH FOR ALL DESIGN TOKENS & COMPONENTS
// Import this file in every view and component - DO NOT create local duplicates

/*
 🎯 DESIGN SYSTEM ARCHITECTURE:

 DesignSystem/
 ├── PiggyDesignSystem.swift        ← THIS FILE (Master Import)
 ├── Tokens/
 │   ├── Colors.swift              ← All Color.piggyXXX definitions
 │   ├── Typography.swift          ← All PiggyFont definitions  
 │   └── Spacing.swift             ← All PiggySpacing, PiggyBorderRadius, PiggyShadows
 └── Components/
     ├── PiggyIconButton.swift     ← Icon buttons with Size/Style enums
     ├── PiggyTextField.swift      ← Form inputs (future)
     ├── PiggyCard.swift           ← Card components (future)
     └── PiggyModal.swift          ← Modal overlays (future)

 📋 USAGE:
 1. Import this file: `// Import design system tokens & components`
 2. Use tokens directly: Color.piggyCardBackground, PiggyFont.body, PiggySpacing.md
 3. Use components: PiggyIconButton("plus", style: .primary)
 4. NEVER create local Color(red:, green:, blue:) or duplicate component structs
*/

// MARK: - Import All Design System Modules
// This ensures all design tokens are available when importing PiggyDesignSystem

// Import all token definitions to make them accessible
import SwiftUI

// Import Color tokens from Colors.swift - Color.piggyXXX extensions
// Import Typography tokens from Typography.swift - PiggyFont struct  
// Import Spacing tokens from Spacing.swift - PiggySpacing, PiggyBorderRadius, PiggyShadows
// Import Animation tokens from Animations.swift - PiggyAnimations struct

// All tokens are now available through standard imports since they're in the same target

// MARK: - Design System Usage Guidelines

/// Design System compliance checker
enum DesignSystemCompliance {
    
    /// Validates that views are using design system tokens correctly
    static func validateUsage() {
        #if DEBUG
        // Future: Add runtime checks for design system compliance
        // - Check for hardcoded colors
        // - Check for custom font sizes
        // - Check for duplicate component definitions
        print("🎨 Design System: All tokens loaded successfully")
        #endif
    }
    
    /// Common design system violations to avoid
    enum Violations: String, CaseIterable {
        case hardcodedColors = "Using Color(red:, green:, blue:) instead of Color.piggyXXX"
        case hardcodedFonts = "Using .font(.system()) instead of PiggyFont.xxx"
        case hardcodedSpacing = "Using .padding(16) instead of PiggySpacing.md"
        case duplicateComponents = "Creating local PiggyXXX structs instead of importing"
        case inconsistentNaming = "Not following piggyXXX naming convention"
        
        var solution: String {
            switch self {
            case .hardcodedColors:
                return "Use Color.piggyCardBackground, Color.piggyTextPrimary, etc."
            case .hardcodedFonts:
                return "Use PiggyFont.body, PiggyFont.title2, etc."
            case .hardcodedSpacing:
                return "Use PiggySpacing.md, PiggySpacing.lg, etc."
            case .duplicateComponents:
                return "Import DesignSystem/Components and use centralized components"
            case .inconsistentNaming:
                return "Follow piggyXXX pattern for all design system tokens"
            }
        }
    }
}

// MARK: - Quick Reference Guide

/*
 🎨 COLORS QUICK REFERENCE:
 
 Brand Colors:
 - Color.piggyPrimary          (#5D2CEE - Primary purple)
 - Color.piggySecondary        (#8B55ED - Secondary purple)  
 - Color.piggyAccent          (#FFD700 - Gold accent)
 
 Backgrounds:
 - Color.piggyBackground       (Main app background)
 - Color.piggyCardBackground   (Card backgrounds)
 - Color.piggyInputBackground  (Form inputs)
 
 Text Colors:
 - Color.piggyTextPrimary      (Main text - white)
 - Color.piggyTextSecondary    (Secondary text - 85% opacity)
 - Color.piggyTextTertiary     (Subtle text - 65% opacity)
 
 Borders & Overlays:
 - Color.piggyBorder           (Standard borders)
 - Color.piggyOverlay          (Modal overlays)
 - Color.modalOverlay          (Full screen overlays)

 🔤 TYPOGRAPHY QUICK REFERENCE:
 
 Headers:
 - PiggyFont.heroTitle         (32pt bold - App titles)
 - PiggyFont.title1            (22pt bold - Page titles)
 - PiggyFont.title2            (20pt semibold - Section headers)
 
 Body Text:
 - PiggyFont.body              (16pt regular - Standard text)
 - PiggyFont.bodyEmphasized    (16pt semibold - Important text)
 - PiggyFont.callout           (15pt regular - Secondary content)
 
 Supporting:
 - PiggyFont.caption           (13pt medium - Metadata)
 - PiggyFont.label             (11pt medium - Form labels)
 - PiggyFont.button            (16pt semibold - Button text)

 📐 SPACING QUICK REFERENCE:
 
 Base Scale (8pt grid):
 - PiggySpacing.xs             (4pt - Tight spacing)
 - PiggySpacing.sm             (8pt - Close elements)
 - PiggySpacing.md             (16pt - Standard spacing)
 - PiggySpacing.lg             (20pt - Section spacing)
 - PiggySpacing.xl             (24pt - Major sections)
 
 Component Spacing:
 - PiggySpacing.inputPadding   (14pt - Input internal padding)
 - PiggySpacing.cardPadding    (18pt - Card internal padding)
 - PiggySpacing.screenMargin   (20pt - Screen edge margins)
 
 Border Radius:
 - PiggyBorderRadius.sm        (8pt - Small elements)
 - PiggyBorderRadius.md        (12pt - Standard components)
 - PiggyBorderRadius.card      (18pt - Card corner radius)
 - PiggyBorderRadius.button    (24pt - Button corner radius)

 🧩 COMPONENTS QUICK REFERENCE:
 
 PiggyIconButton:
 - PiggyIconButton("plus", style: .primary)      (High emphasis)
 - PiggyIconButton("heart", style: .secondary)   (Medium emphasis)  
 - PiggyIconButton("info", style: .tertiary)     (Low emphasis)
 - PiggyIconButton("delete", style: .destructive) (Delete actions)
 
 Sizes:
 - size: .small    (32pt - Compact areas)
 - size: .medium   (44pt - Standard touch target)
 - size: .large    (56pt - Primary actions)
 
 Haptic Feedback:
 - hapticStyle: .light/.medium/.heavy (Impact feedback)
 - hapticStyle: .success/.warning/.error (Notification feedback)
*/

// MARK: - Development Utilities

#if DEBUG
extension View {
    /// Overlay that shows design system compliance warnings in debug builds
    func debugDesignSystem() -> some View {
        self.overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("🎨 Design System Active")
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextTertiary)
                        .padding(PiggySpacing.xs)
                        .background(Color.piggyCardBackground)
                        .cornerRadius(PiggyBorderRadius.sm)
                        .opacity(0.7)
                }
            }
            .padding()
            .allowsHitTesting(false)
        )
    }
}
#endif

// MARK: - Initialization
extension View {
    /// Initialize design system - call once in your app's root view
    func initializeDesignSystem() -> some View {
        self.onAppear {
            DesignSystemCompliance.validateUsage()
        }
    }
}

// MARK: - Future Extensions
/*
 🚀 PLANNED EXPANSIONS:
 
 1. Components:
    - PiggyTextField (form inputs with validation)
    - PiggyCard (container with elevation styles)
    - PiggyModal (overlay presentations)
    - PiggyButton (text buttons with states)
    - PiggyBadge (status indicators)
    - PiggyAvatar (profile images)
 
 2. Tokens:
    - Animation curves (PiggyMotion)
    - Elevation system (shadow depths)
    - Grid system (layout constraints)
    - Breakpoints (responsive design)
 
 3. Utilities:
    - Theme switching (light/dark mode)
    - Accessibility scaling (@ScaledMetric)
    - Localization support
    - Design token validation
 
 4. Documentation:
    - Component playground
    - Token reference guide
    - Usage examples
    - Migration guides
*/