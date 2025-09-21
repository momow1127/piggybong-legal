# PiggyBong UI Style Guidelines 🎨

> **CRITICAL**: Every new screen/component MUST follow these exact guidelines to maintain visual consistency across the entire K-pop fan planning app.

**✅ SINGLE SOURCE OF TRUTH**: All design tokens are defined in `DesignTokens.swift` - this is the ONLY design system file.

## 📋 Quick Reference Checklist

Before creating any UI component, ensure you use:
- ✅ **Colors**: Only from `PiggyColors` enum
- ✅ **Fonts**: Only from `PiggyFont` system
- ✅ **Spacing**: Only from `PiggySpacing` tokens
- ✅ **Border Radius**: Only from `PiggyBorderRadius` values
- ✅ **Gradients**: Only from `PiggyGradients` system
- ✅ **Animations**: Only from `PiggyAnimation` presets
- ✅ **Safe Areas**: Always handle properly with `.safeAreaInsets`

---

## 🎨 Color System

### Primary Colors (ALWAYS USE THESE)
```swift
// Background Colors
Color.piggyBackground      // Dark purple main background (#0D0011)
Color.piggySurface         // Card/sheet backgrounds (dark with opacity)
Color.piggyCardBackground  // Individual card backgrounds (white 10% opacity)

// Brand Colors
Color.piggyPrimary         // Main purple brand color (#5D2CEE)
Color.piggySecondary       // Light purple accent (#8B55ED) 
Color.piggyAccent          // Gold accent color (#FFD700) - WCAG AA compliant

// Text Colors
Color.piggyTextPrimary     // Main text (white)
Color.piggyTextSecondary   // Secondary text (white 85% opacity)
Color.piggyTextTertiary    // Subtle text (white 65% opacity)

// Semantic Colors
Color.budgetGreen          // Success/money positive
Color.budgetOrange         // Warnings
Color.budgetRed            // Errors/negative
```

### ✅ Accessibility Compliance
**All colors meet WCAG AA standards:**
- Gold accent (#FFD700) has excellent contrast on dark purple background
- White text (#FFFFFF) has perfect contrast on dark backgrounds  
- All combinations tested and verified for accessibility

### ❌ NEVER Use These
```swift
// DON'T USE:
.white, .black, .gray, .blue, .red, .green, .yellow, .purple, .pink
Color.primary, Color.secondary, Color.accentColor
// Always use the PiggyColors design tokens instead!

// ACCESSIBILITY WARNING:
// Never use white text on gold background - fails WCAG AA (1.4:1 ratio)
```

---

## 🎭 Gradient System

### Primary Gradients (Use These for Major Elements)
```swift
// Buttons & Call-to-Actions
PiggyGradients.primaryButton    // Purple to light purple gradient

// Backgrounds  
PiggyGradients.background       // Dark purple gradient background
```

### Example Usage
```swift
// ✅ CORRECT
Button("Start Planning") { }
    .background(PiggyGradients.primaryButton)

// ❌ WRONG
Button("Start Planning") { }
    .background(Color.blue)
```

---

## ✏️ Typography System

### Font Hierarchy (EXACT Usage)
```swift
// Headers
.font(PiggyFont.largeTitle)    // 34pt, bold
.font(PiggyFont.title1)        // 28pt, bold
.font(PiggyFont.title2)        // 22pt, bold
.font(PiggyFont.title3)        // 20pt, semibold

// Body Text
.font(PiggyFont.headline)      // 17pt, semibold
.font(PiggyFont.body)          // 17pt, regular
.font(PiggyFont.bodyEmphasized) // 17pt, semibold
.font(PiggyFont.callout)       // 16pt, regular

// Small Text
.font(PiggyFont.subheadline)   // 15pt, regular
.font(PiggyFont.footnote)      // 13pt, regular
.font(PiggyFont.caption)       // 12pt, regular
.font(PiggyFont.caption2)      // 11pt, regular
```

### Text Color Pairing Rules
```swift
// ✅ CORRECT Combinations
Text("Main Heading")
    .font(PiggyFont.title2)
    .foregroundColor(.piggyTextPrimary)

Text("Subtitle or description")
    .font(PiggyFont.body)
    .foregroundColor(.piggyTextSecondary)

Text("Fine print or labels")
    .font(PiggyFont.caption)
    .foregroundColor(.piggyTextTertiary)
```

---

## 🃏 Card Design System

### Standard Card Pattern
```swift
// ✅ ALWAYS Use This Card Structure
VStack(spacing: PiggySpacing.md) {
    // Card Content Here
}
.padding(PiggySpacing.lg)
.background(
    RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
        .fill(Color.piggyCardBackground)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
)
.padding(.horizontal, PiggySpacing.lg)
```

### Card Variants

#### Simple Info Card
```swift
VStack(alignment: .leading, spacing: PiggySpacing.sm) {
    Text("Card Title")
        .font(PiggyFont.headline)
        .foregroundColor(.piggyTextPrimary)
    
    Text("Card description or content")
        .font(PiggyFont.body)
        .foregroundColor(.piggyTextSecondary)
}
.padding(PiggySpacing.lg)
.background(
    RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
        .fill(Color.piggyCardBackground)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
)
```

#### Feature Card with Icon
```swift
VStack(spacing: PiggySpacing.md) {
    // Icon
    ZStack {
        Circle()
            .fill(Color.piggyAccent.opacity(0.2))
            .frame(width: 60, height: 60)
        
        Image(systemName: "star.fill")
            .font(.system(size: 24, weight: .medium))
            .foregroundColor(.piggyAccent)
    }
    
    // Content
    VStack(spacing: PiggySpacing.xs) {
        Text("Feature Title")
            .font(PiggyFont.bodyEmphasized)
            .foregroundColor(.piggyTextPrimary)
        
        Text("Feature description")
            .font(PiggyFont.caption)
            .foregroundColor(.piggyTextSecondary)
            .multilineTextAlignment(.center)
    }
}
.padding(PiggySpacing.lg)
.background(
    RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
        .fill(Color.piggyCardBackground)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
)
```

---

## 🔘 Button System

### Primary Button (Main Actions)
```swift
Button("Primary Action") { }
    .font(PiggyFont.bodyEmphasized)
    .foregroundColor(.white)
    .frame(maxWidth: .infinity)
    .frame(height: 56)
    .background(PiggyGradients.primaryButton)
    .cornerRadius(PiggyBorderRadius.button)
```

### Secondary Button (Alternative Actions)
```swift
Button("Secondary Action") { }
    .font(PiggyFont.body)
    .foregroundColor(.piggyTextPrimary)
    .frame(maxWidth: .infinity)
    .frame(height: 48)
    .background(
        RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
            .stroke(Color.piggyTextSecondary.opacity(0.3), lineWidth: 1)
    )
```

### Text Button (Subtle Actions)
```swift
Button("Text Action") { }
    .font(PiggyFont.callout)
    .foregroundColor(.piggyTextSecondary)
```

### Button States
```swift
// Loading State
Button(action: {}) {
    HStack(spacing: PiggySpacing.sm) {
        if isLoading {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.8)
        }
        Text(isLoading ? "Loading..." : "Button Text")
            .font(PiggyFont.bodyEmphasized)
    }
}
.disabled(isLoading)
```

---

## 📏 Spacing System (8px Grid)

### Spacing Tokens (ONLY Use These)
```swift
PiggySpacing.xs     // 4pt
PiggySpacing.sm     // 8pt
PiggySpacing.md     // 16pt
PiggySpacing.lg     // 24pt
PiggySpacing.xl     // 32pt
PiggySpacing.xxl    // 48pt
```

### Layout Spacing Rules
```swift
// ✅ CORRECT - Between related items
VStack(spacing: PiggySpacing.sm) { }

// ✅ CORRECT - Between sections
VStack(spacing: PiggySpacing.lg) { }

// ✅ CORRECT - Screen edges
.padding(.horizontal, PiggySpacing.lg)

// ❌ WRONG - Custom spacing
VStack(spacing: 12) { }
.padding(.horizontal, 20)
```

---

## 🔲 Border Radius System

### Border Radius Values (ONLY Use These)
```swift
PiggyBorderRadius.sm      // 8pt
PiggyBorderRadius.md      // 12pt  
PiggyBorderRadius.lg      // 16pt
PiggyBorderRadius.xl      // 20pt
PiggyBorderRadius.card    // 16pt
PiggyBorderRadius.button  // 28pt (for 56pt height buttons)
```

---

## ⚡ Animation System

### Standard Animations (ONLY Use These)
```swift
// Basic animations
PiggyAnimation.standard    // 0.3s ease-in-out
PiggyAnimation.quick      // 0.15s ease-out
PiggyAnimation.bounce     // 0.6s spring animation

// Usage examples
.animation(PiggyAnimation.standard, value: someState)
.scaleEffect(isPressed ? 0.95 : 1.0)
.animation(PiggyAnimation.quick, value: isPressed)
```

---

## 📱 Safe Area Handling

### ALWAYS Handle Safe Areas
```swift
// ✅ CORRECT - Full screen views
VStack {
    // Content
}
.frame(maxWidth: .infinity, maxHeight: .infinity)
.background(Color.piggyBackground)
.ignoresSafeArea(edges: .bottom) // Only if needed

// ✅ CORRECT - Screen padding
VStack {
    // Content
}
.padding(.horizontal, PiggySpacing.lg)
.padding(.top, PiggySpacing.md)
.safeAreaInset(edge: .bottom) {
    // Bottom content like buttons
}
```

---

## 🎬 Screen Layout Patterns

### Full Screen Layout
```swift
struct NewScreenView: View {
    var body: some View {
        ZStack {
            // Background
            Color.piggyBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: PiggySpacing.lg) {
                    // Screen content
                }
                .padding(.horizontal, PiggySpacing.lg)
                .padding(.top, PiggySpacing.md)
            }
        }
    }
}
```

### Modal/Sheet Layout
```swift
VStack(spacing: PiggySpacing.lg) {
    // Content
}
.padding(PiggySpacing.lg)
.background(Color.piggySurface)
.cornerRadius(PiggyBorderRadius.xl)
```

---

## 🚨 Common Mistakes to Avoid

### ❌ DON'T DO THESE:
```swift
// Wrong colors
.foregroundColor(.blue)
.background(Color.white)

// Wrong spacing
.padding(15)
VStack(spacing: 10)

// Wrong fonts
.font(.title)
.font(.system(size: 18))

// Wrong border radius
.cornerRadius(10)

// Wrong animations
.animation(.easeInOut(duration: 0.5))

// No safe area handling
// Missing .padding(.horizontal, PiggySpacing.lg)
```

---

## 📋 Pre-Flight Checklist

Before submitting any new UI component, verify:

- [ ] ✅ Uses only `PiggyColors` for all colors
- [ ] ✅ Uses only `PiggyFont` for all typography  
- [ ] ✅ Uses only `PiggySpacing` for all spacing
- [ ] ✅ Uses only `PiggyBorderRadius` for corner radius
- [ ] ✅ Uses only `PiggyGradients` for gradients
- [ ] ✅ Uses only `PiggyAnimation` for animations
- [ ] ✅ Handles safe areas properly
- [ ] ✅ Follows card design patterns
- [ ] ✅ Uses correct button styles
- [ ] ✅ Has consistent visual hierarchy
- [ ] ✅ Looks good in both light/dark mode
- [ ] ✅ Works on iPhone 14 Pro Max and iPhone SE

---

## 🔧 Development Tools

### Quick Start Template
```swift
import SwiftUI

struct NewScreenView: View {
    var body: some View {
        ZStack {
            Color.piggyBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: PiggySpacing.lg) {
                    // Header
                    Text("Screen Title")
                        .font(PiggyFont.title2)
                        .foregroundColor(.piggyTextPrimary)
                    
                    // Content Cards
                    VStack(spacing: PiggySpacing.md) {
                        // Card content here
                    }
                    .padding(PiggySpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                            .fill(Color.piggyCardBackground)
                    )
                    
                    // Bottom Button
                    Button("Action") { }
                        .font(PiggyFont.bodyEmphasized)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(PiggyGradients.primaryButton)
                        .cornerRadius(PiggyBorderRadius.button)
                }
                .padding(.horizontal, PiggySpacing.lg)
                .padding(.vertical, PiggySpacing.md)
            }
        }
    }
}
```

---

## 🎯 Final Note

**CONSISTENCY IS EVERYTHING** in the PiggyBong app. Users should feel like they're using one cohesive product, not a collection of different screens. Every pixel should feel intentional and aligned with our K-pop fan community brand.

When in doubt, copy an existing well-designed screen and modify the content rather than creating something entirely new.

---

*Last Updated: August 2025*  
*Version: 1.0*