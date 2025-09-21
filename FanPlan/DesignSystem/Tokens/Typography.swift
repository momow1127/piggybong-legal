import SwiftUI

// MARK: - PiggyBong Typography System
// 🚨 SINGLE SOURCE OF TRUTH - Do not duplicate font definitions elsewhere
// All components and views must import and use these font tokens ONLY

struct PiggyFont {
    
    // MARK: - Dynamic Type Support Infrastructure
    /// Creates scaled fonts with rounded design for brand consistency
    private static func scaledFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return Font.system(size: size, weight: weight, design: .rounded)
    }
    
    // Future: Add @ScaledMetric support for full accessibility
    // @ScaledMetric private static var heroTitleSize: CGFloat = 32
    
    // MARK: - Display & Hero Typography
    /// Large hero titles - 32pt bold (App titles, major CTAs)
    static let heroTitle = scaledFont(size: 32, weight: .bold)
    
    /// Large display text - 28pt bold (Section heroes, feature titles)
    static let displayLarge = scaledFont(size: 28, weight: .bold)
    
    /// Medium display text - 24pt bold (Page headers, modal titles)
    static let displayMedium = scaledFont(size: 24, weight: .bold)
    
    // MARK: - Page & Section Headers
    /// Main page titles - 22pt bold (Screen titles)
    static let title1 = scaledFont(size: 22, weight: .bold)
    
    /// Section titles - 20pt semibold (Card headers, sections)
    static let title2 = scaledFont(size: 20, weight: .semibold)
    
    /// Sub-section titles - 18pt semibold (Component headers)
    static let title3 = scaledFont(size: 18, weight: .semibold)
    
    /// Generic section title alias
    static let sectionTitle = title2
    
    // MARK: - Body Text Hierarchy  
    /// Large body text - 17pt regular (Important content)
    static let bodyLarge = scaledFont(size: 17, weight: .regular)
    
    /// Standard body text - 16pt regular (Primary reading content)
    static let body = scaledFont(size: 16, weight: .regular)
    
    /// Medium body text - 16pt medium (Emphasized content)
    static let bodyMedium = scaledFont(size: 16, weight: .medium)
    
    /// Emphasized body text - 16pt semibold (Important body text)
    static let bodyEmphasized = scaledFont(size: 16, weight: .semibold)
    
    /// Callout text - 15pt regular (Secondary content)
    static let callout = scaledFont(size: 15, weight: .regular)
    
    /// Subheading text - 14pt regular (Labels, descriptions)
    static let subheadline = scaledFont(size: 14, weight: .regular)
    
    // MARK: - Supporting Text
    /// Caption text - 13pt medium (Metadata, timestamps)
    static let caption = scaledFont(size: 13, weight: .medium)
    
    /// Light caption - 13pt regular (Subtle information)
    static let captionLight = scaledFont(size: 13, weight: .regular)
    
    /// Emphasized caption - 13pt semibold (Important metadata, highlighted captions)
    static let captionEmphasized = scaledFont(size: 13, weight: .semibold)
    
    /// Footnote text - 12pt regular (Fine print, disclaimers)
    static let footnote = scaledFont(size: 12, weight: .regular)
    
    /// Label text - 11pt medium (Form labels, badges)
    static let label = scaledFont(size: 11, weight: .medium)
    
    // MARK: - Specialized Typography
    /// Large budget amounts - 32pt bold (Money displays)
    static let budgetAmount = scaledFont(size: 32, weight: .bold)
    
    /// Small amounts - 14pt semibold (Compact money displays)
    static let smallAmount = scaledFont(size: 14, weight: .semibold)
    
    /// Button text - 16pt semibold (All button labels)
    static let button = scaledFont(size: 16, weight: .semibold)
    
    /// Input field text - 16pt regular (TextField, TextEditor)
    static let inputText = scaledFont(size: 16, weight: .regular)
    
    /// Navigation text - 17pt regular (Tab bars, nav bars)
    static let navigation = scaledFont(size: 17, weight: .regular)
    
    /// Badge text - 12pt semibold (Status badges, counts)
    static let badge = scaledFont(size: 12, weight: .semibold)
    
    // MARK: - Legacy Aliases (Backward Compatibility)
    /// Alias for title3 - maintains backward compatibility
    static let headline = title3
    
    /// Alias for title1 - maintains backward compatibility
    static let title = title1
    
    /// Alias for displayMedium - maintains backward compatibility
    static let largeTitle = displayMedium
    
    /// Alias for caption - maintains backward compatibility
    static let caption1 = caption
    
    /// Alias for footnote - maintains backward compatibility  
    static let caption2 = footnote
    
    // MARK: - Accessibility Support
    /// Creates accessible fonts using dynamic type when needed
    static func accessibilityFont(for style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        if #available(iOS 16.0, *) {
            return Font.system(style, design: .rounded, weight: weight)
        } else {
            return Font.system(style).weight(weight)
        }
    }
    
    /// Returns font scaled for current accessibility settings
    static func scaledFont(_ font: Font, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        // This will be enhanced when @ScaledMetric is fully implemented
        return font
    }
}

// MARK: - Font Weight Utilities
extension Font.Weight {
    /// Brand-specific font weights for consistency
    static let piggyLight = Font.Weight.light
    static let piggyRegular = Font.Weight.regular  
    static let piggyMedium = Font.Weight.medium
    static let piggySemibold = Font.Weight.semibold
    static let piggyBold = Font.Weight.bold
    static let piggyHeavy = Font.Weight.heavy
}

// MARK: - Text Style Modifiers
extension Text {
    /// Apply hero styling with proper color
    func heroStyle() -> some View {
        self
            .font(PiggyFont.heroTitle)
            .foregroundColor(.piggyTextPrimary)
            .multilineTextAlignment(.center)
    }
    
    /// Apply title styling with proper color
    func titleStyle() -> some View {
        self
            .font(PiggyFont.title1)
            .foregroundColor(.piggyTextPrimary)
    }
    
    /// Apply body styling with proper color
    func bodyStyle() -> some View {
        self
            .font(PiggyFont.body)
            .foregroundColor(.piggyTextPrimary)
    }
    
    /// Apply secondary text styling
    func secondaryTextStyle() -> some View {
        self
            .font(PiggyFont.body)
            .foregroundColor(.piggyTextSecondary)
    }
    
    /// Apply caption styling
    func captionStyle() -> some View {
        self
            .font(PiggyFont.caption)
            .foregroundColor(.piggyTextTertiary)
    }
    
    /// Apply button text styling
    func buttonTextStyle() -> some View {
        self
            .font(PiggyFont.button)
            .foregroundColor(.piggyTextPrimary)
    }
    
    /// Apply label styling
    func labelStyle() -> some View {
        self
            .font(PiggyFont.label)
            .foregroundColor(.piggyTextSecondary)
    }
    
    /// Apply budget amount styling with color
    func budgetAmountStyle(isPositive: Bool = true) -> some View {
        self
            .font(PiggyFont.budgetAmount)
            .foregroundColor(isPositive ? .budgetGreen : .budgetRed)
    }
}

// MARK: - Typography Usage Guidelines
/*
 📝 TYPOGRAPHY USAGE GUIDELINES:

 ✅ DO:
 - Use PiggyFont.body for all standard text
 - Use PiggyFont.title2 for section headers
 - Use PiggyFont.button for all button labels
 - Use Text().bodyStyle() for quick styling
 - Use semantic names (button, body, caption) over sizes

 ❌ DON'T:
 - Use Font.system() directly in components
 - Create custom font sizes inline
 - Mix system fonts with PiggyFont
 - Hardcode font weights without using PiggyFont

 🎯 SEMANTIC HIERARCHY:
 - Display: heroTitle -> displayLarge -> displayMedium
 - Headers: title1 -> title2 -> title3  
 - Body: bodyLarge -> body -> bodyMedium -> bodyEmphasized
 - Supporting: callout -> subheadline -> caption -> footnote -> label
 - Specialized: budgetAmount, button, inputText, badge

 📱 ACCESSIBILITY:
 - All fonts use .rounded design for brand consistency
 - Font sizes follow 8pt grid system (12, 16, 20, 24, 32)
 - High contrast ratios maintained with piggyText colors
 - Future: Full @ScaledMetric support for dynamic type
*/