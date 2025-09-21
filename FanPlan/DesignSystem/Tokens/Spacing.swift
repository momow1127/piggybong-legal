import SwiftUI

// MARK: - PiggyBong Spacing & Layout System  
// 🚨 SINGLE SOURCE OF TRUTH - Do not create spacing values elsewhere
// All components and views must import and use these spacing tokens ONLY

struct PiggySpacing {
    
    // MARK: - Base Spacing Scale (8pt Grid System)
    /// Extra small spacing - 4pt (Tight element spacing)
    static let xs: CGFloat = 4
    
    /// Small spacing - 8pt (Close element relationships)  
    static let sm: CGFloat = 8
    
    /// Medium spacing - 16pt (Standard element spacing)
    static let md: CGFloat = 16
    
    /// Large spacing - 24pt (Section spacing)
    static let lg: CGFloat = 24
    
    /// Extra large spacing - 32pt (Major section spacing)
    static let xl: CGFloat = 32
    
    /// Extra extra large spacing - 40pt (Screen-level spacing)
    static let xxl: CGFloat = 40
    
    /// Section spacing - 24pt (Between major content sections)
    static let sectionSpacing: CGFloat = 24
    
    // MARK: - Component-Specific Spacing
    /// Standard button height across the app
    static let buttonHeight: CGFloat = 56
    
    /// Input field internal padding
    static let inputPadding: CGFloat = 14
    
    /// Card internal padding
    static let cardPadding: CGFloat = 18
    
    /// Input field vertical padding  
    static let inputVertical: CGFloat = 12
    
    /// Card vertical padding
    static let cardVertical: CGFloat = 16
    
    /// Standard list item height
    static let listItemHeight: CGFloat = 60
    
    /// Navigation bar height
    static let navigationHeight: CGFloat = 44
    
    /// Tab bar height
    static let tabBarHeight: CGFloat = 83
    
    // MARK: - Layout Margins
    /// Standard screen edge margins
    static let screenMargin: CGFloat = 20
    
    /// Compact screen edge margins (small screens)
    static let screenMarginCompact: CGFloat = 16
    
    /// Card edge margins from screen
    static let cardMargin: CGFloat = 16
    
    /// Modal margins from screen edges
    static let modalMargin: CGFloat = 24
    
    // MARK: - Safe Area & Insets
    /// Additional bottom spacing for tab bar overlap
    static let tabBarInset: CGFloat = 100
    
    /// Safe area bottom spacing
    static let safeAreaBottom: CGFloat = 34
    
    /// Keyboard avoidance spacing
    static let keyboardPadding: CGFloat = 16
    
    /// Dropdown overlay clearance spacing
    static let dropdownClearance: CGFloat = 240
    
    // MARK: - Interactive Element Spacing
    /// Minimum touch target size (44pt)
    static let minTouchTarget: CGFloat = 44
    
    /// Recommended touch target size (48pt)
    static let touchTarget: CGFloat = 48
    
    /// Large touch target (56pt) for primary actions
    static let largeTouchTarget: CGFloat = 56
    
    // MARK: - Content Spacing
    /// Spacing between form fields
    static let formFieldSpacing: CGFloat = 16
    
    /// Spacing between form sections
    static let formSectionSpacing: CGFloat = 32
    
    /// Spacing between list items
    static let listItemSpacing: CGFloat = 8
    
    /// Spacing within button groups
    static let buttonGroupSpacing: CGFloat = 12
    
    /// Spacing for inline elements (badges, tags)
    static let inlineSpacing: CGFloat = 6
    
    // MARK: - Visual Hierarchy Spacing
    /// Tight grouping (related elements)
    static let groupTight: CGFloat = 8
    
    /// Standard grouping (related sections)
    static let groupStandard: CGFloat = 16
    
    /// Loose grouping (separate content areas)
    static let groupLoose: CGFloat = 24
    
    /// Separate grouping (distinct content sections)
    static let groupSeparate: CGFloat = 32
}

// MARK: - Border Radius System
struct PiggyBorderRadius {
    
    // MARK: - Base Radius Scale
    /// Extra small radius - 4pt (Small buttons, badges)
    static let xs: CGFloat = 4
    
    /// Small radius - 8pt (Form elements, small cards)
    static let sm: CGFloat = 8
    
    /// Medium radius - 12pt (Standard components)
    static let md: CGFloat = 12
    
    /// Large radius - 16pt (Cards, major components)
    static let lg: CGFloat = 16
    
    /// Extra large radius - 20pt (Prominent components)
    static let xl: CGFloat = 20
    
    /// Fully rounded - 50pt (Pills, circular buttons)
    static let round: CGFloat = 50
    
    // MARK: - Component-Specific Radius
    /// Input field corner radius
    static let input: CGFloat = 14
    
    /// Card corner radius  
    static let card: CGFloat = 18
    
    /// Button corner radius (pill-shaped)
    static let button: CGFloat = 24
    
    /// Modal corner radius
    static let modal: CGFloat = 20
    
    /// Badge corner radius
    static let badge: CGFloat = 8
    
    /// Avatar corner radius
    static let avatar: CGFloat = 12
    
    /// Sheet corner radius (bottom sheets)
    static let sheet: CGFloat = 16
}

// MARK: - Icon Size System
struct PiggyIcon {
    
    // MARK: - Standard Icon Sizes
    /// Small icons - 16pt (Inline icons, small buttons)
    static let small: CGFloat = 16
    
    /// Medium icons - 20pt (Standard buttons, navigation)
    static let medium: CGFloat = 20
    
    /// Large icons - 24pt (Primary actions, emphasis)
    static let large: CGFloat = 24
    
    /// Extra large icons - 32pt (Hero sections, empty states)
    static let extraLarge: CGFloat = 32
    
    /// Huge icons - 40pt (Major feature highlights)
    static let huge: CGFloat = 40
    
    // MARK: - Component-Specific Sizes
    /// Button icons - matches PiggyIconButton sizing
    static let button = medium // 20pt
    
    /// Navigation bar icons
    static let navigation = medium // 20pt
    
    /// Tab bar icons
    static let tabBar = large // 24pt
    
    /// Empty state icons
    static let emptyState = extraLarge // 32pt
    
    /// Hero section icons
    static let hero = huge // 40pt
}

// MARK: - Shadow System
struct PiggyShadows {
    
    // MARK: - Shadow Presets
    /// Light shadow for subtle elevation
    static let light = PiggyShadowToken(
        color: Color.black.opacity(0.1),
        radius: 2,
        x: 0,
        y: 1
    )
    
    /// Medium shadow for standard elevation
    static let medium = PiggyShadowToken(
        color: Color.black.opacity(0.15),
        radius: 4,
        x: 0,
        y: 2
    )
    
    /// Heavy shadow for high elevation
    static let heavy = PiggyShadowToken(
        color: Color.black.opacity(0.25),
        radius: 8,
        x: 0,
        y: 4
    )
    
    // MARK: - Component-Specific Shadows
    /// Input field shadow
    static let input = PiggyShadowToken(
        color: Color.black.opacity(0.05),
        radius: 2,
        x: 0,
        y: 1
    )
    
    /// Card shadow
    static let card = PiggyShadowToken(
        color: Color.black.opacity(0.15),
        radius: 8,
        x: 0,
        y: 4
    )
    
    /// Elevated card shadow
    static let cardElevated = PiggyShadowToken(
        color: Color.black.opacity(0.25),
        radius: 12,
        x: 0,
        y: 6
    )
    
    /// Button shadow
    static let button = PiggyShadowToken(
        color: Color.black.opacity(0.1),
        radius: 3,
        x: 0,
        y: 2
    )
    
    /// Modal shadow
    static let modal = PiggyShadowToken(
        color: Color.black.opacity(0.3),
        radius: 16,
        x: 0,
        y: 8
    )
}

// MARK: - Shadow Token Structure
struct PiggyShadowToken {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Layout Utilities
extension View {
    
    // MARK: - Spacing Modifiers
    /// Apply standard screen margins
    func screenMargins() -> some View {
        self.padding(.horizontal, PiggySpacing.screenMargin)
    }
    
    /// Apply compact screen margins
    func screenMarginsCompact() -> some View {
        self.padding(.horizontal, PiggySpacing.screenMarginCompact)
    }
    
    /// Apply card margins
    func cardMargins() -> some View {
        self.padding(.horizontal, PiggySpacing.cardMargin)
    }
    
    /// Apply section spacing
    func sectionSpacing() -> some View {
        self.padding(.vertical, PiggySpacing.sectionSpacing)
    }
    
    /// Apply form field spacing
    func formFieldSpacing() -> some View {
        self.padding(.bottom, PiggySpacing.formFieldSpacing)
    }
    
    // MARK: - Shadow Modifiers
    /// Apply light shadow
    func lightShadow() -> some View {
        let shadow = PiggyShadows.light
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    /// Apply medium shadow
    func mediumShadow() -> some View {
        let shadow = PiggyShadows.medium
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    /// Apply heavy shadow
    func heavyShadow() -> some View {
        let shadow = PiggyShadows.heavy
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    /// Apply custom shadow token
    func applyShadow(_ shadowToken: PiggyShadowToken) -> some View {
        self.shadow(
            color: shadowToken.color,
            radius: shadowToken.radius,
            x: shadowToken.x,
            y: shadowToken.y
        )
    }
    
    // MARK: - Border Radius Modifiers
    /// Apply card corner radius
    func cardCornerRadius() -> some View {
        self.cornerRadius(PiggyBorderRadius.card)
    }
    
    /// Apply input corner radius
    func inputCornerRadius() -> some View {
        self.cornerRadius(PiggyBorderRadius.input)
    }
    
    /// Apply button corner radius
    func buttonCornerRadius() -> some View {
        self.cornerRadius(PiggyBorderRadius.button)
    }
}

// MARK: - Spacing Usage Guidelines
/*
 📐 SPACING USAGE GUIDELINES:

 ✅ DO:
 - Use .padding(.horizontal, PiggySpacing.md) instead of .padding(.horizontal, 16)
 - Use .screenMargins() for consistent edge margins
 - Use PiggyBorderRadius.card for all card components
 - Use shadow modifiers (.lightShadow(), .mediumShadow()) for elevation

 ❌ DON'T:
 - Use hardcoded spacing values (16, 20, 24) directly in views
 - Create custom corner radius values inline
 - Use inconsistent shadow values
 - Mix spacing systems

 🎯 SEMANTIC SPACING HIERARCHY:
 - Element: xs (4) -> sm (8) -> md (16)
 - Sections: lg (24) -> xl (32) -> xxl (40)
 - Grouping: groupTight (8) -> groupStandard (16) -> groupLoose (24) -> groupSeparate (32)
 - Components: Use component-specific tokens (inputPadding, cardPadding)

 📱 LAYOUT PRINCIPLES:
 - 8pt grid system for all spacing values
 - Minimum 44pt touch targets for accessibility
 - Consistent margins and padding across components
 - Elevation through shadow, not just borders
 - Responsive spacing for different screen sizes
*/