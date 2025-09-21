import SwiftUI

// MARK: - Design System Usage Examples
// This file demonstrates proper usage of design tokens and identifies areas for improvement

struct ExampleUsage: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // MARK: - Proper Design Token Usage Examples
                
                // ✅ GOOD: Using design system colors
                Text("K-pop Budget Planning")
                    .font(DesignSystem.Typography.displayLarge)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .standardHorizontalPadding()
                
                // ✅ GOOD: Using design system components
                CustomSearchBar(text: .constant(""))
                    .standardHorizontalPadding()
                
                // ✅ GOOD: Proper card implementation
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Concert Savings")
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("$450 saved so far")
                        .font(DesignSystem.Typography.bodyLarge)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .padding(DesignSystem.Spacing.md)
                .cardStyle()
                .standardHorizontalPadding()
                
                // ✅ GOOD: Using button styles
                Button("Add Goal") {
                    // Action
                }
                .buttonStyle(PrimaryButtonStyle())
                .standardHorizontalPadding()
                
                Button("Edit Budget") {
                    // Action
                }
                .buttonStyle(SecondaryButtonStyle())
                .standardHorizontalPadding()
                
                // MARK: - Examples of What NOT to Do
                // These show common mistakes that break design system consistency
                
                Group {
                    // ❌ BAD: Hardcoded colors
                    Text("Don't use hardcoded colors")
                        .foregroundColor(.purple) // Should use DesignSystem.Colors.primaryPurple
                    
                    // ❌ BAD: Hardcoded font sizes
                    Text("Don't use hardcoded fonts")
                        .font(.system(size: 18)) // Should use DesignSystem.Typography.bodyLarge
                    
                    // ❌ BAD: Hardcoded spacing
                    VStack(spacing: 15) { // Should use DesignSystem.Spacing tokens
                        Text("Item 1")
                        Text("Item 2")
                    }
                    .padding(.horizontal, 20) // Should use .standardHorizontalPadding()
                    
                    // ❌ BAD: Hardcoded corner radius
                    RoundedRectangle(cornerRadius: 10) // Should use DesignSystem.CornerRadius.medium
                        .fill(Color.white.opacity(0.1)) // Should use DesignSystem.Colors.cardBackground
                        .frame(height: 50)
                }
                .opacity(0.5) // Making "bad" examples less prominent
            }
        }
        .gradientBackground()
    }
}

// MARK: - Component Usage Best Practices
struct DesignSystemShowcase: View {
    @State private var searchText = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // MARK: - Typography Scale Example
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Typography Scale")
                    .font(DesignSystem.Typography.headlineLarge)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("Display Large - Hero Headlines")
                    .font(DesignSystem.Typography.displayLarge)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("Display Medium - Page Titles")
                    .font(DesignSystem.Typography.displayMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("Headline Large - Section Headers")
                    .font(DesignSystem.Typography.headlineLarge)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("Body Large - Default Text")
                    .font(DesignSystem.Typography.bodyLarge)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("Body Medium - Secondary Text")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Text("Caption - Small Details")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.placeholderText)
            }
            .standardHorizontalPadding()
            
            // MARK: - Color System Example
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignSystem.Spacing.md) {
                ColorSwatch(name: "Primary Purple", color: DesignSystem.Colors.primaryPurple)
                ColorSwatch(name: "Primary Pink", color: DesignSystem.Colors.primaryPink)
                ColorSwatch(name: "Success", color: DesignSystem.Colors.success)
                ColorSwatch(name: "Warning", color: DesignSystem.Colors.warning)
                ColorSwatch(name: "Error", color: DesignSystem.Colors.error)
                ColorSwatch(name: "Card Background", color: DesignSystem.Colors.cardBackground)
            }
            .standardHorizontalPadding()
            
            // MARK: - Component States Example
            VStack(spacing: DesignSystem.Spacing.md) {
                // Normal state
                Button("Normal State") {}
                    .buttonStyle(PrimaryButtonStyle())
                
                // Disabled state  
                Button("Disabled State") {}
                    .buttonStyle(PrimaryButtonStyle(isEnabled: false))
                
                // Secondary style
                Button("Secondary Style") {}
                    .buttonStyle(SecondaryButtonStyle())
                
                // Loading state example (would need custom implementation)
                Button("Loading...") {}
                    .buttonStyle(PrimaryButtonStyle(isEnabled: false))
                    .opacity(0.6)
            }
            .standardHorizontalPadding()
            
            // MARK: - Search Component Example
            CustomSearchBar(
                text: $searchText,
                placeholder: "Search K-pop artists...",
                onSearchButtonClicked: {
                    // Handle search
                }
            )
            .standardHorizontalPadding()
        }
        .gradientBackground()
    }
}

// MARK: - Helper Components
struct ColorSwatch: View {
    let name: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .fill(color)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            Text(name)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(DesignSystem.Spacing.sm)
        .cardStyle()
    }
}

// MARK: - Enhanced Button Styles with More States
struct EnhancedPrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    let isLoading: Bool
    
    init(isEnabled: Bool = true, isLoading: Bool = false) {
        self.isEnabled = isEnabled
        self.isLoading = isLoading
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primaryText))
                    .scaleEffect(0.8)
            }
            
            configuration.label
        }
        .font(DesignSystem.Typography.bodyLarge)
        .foregroundColor(DesignSystem.Colors.primaryText)
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .fill(
                    isEnabled && !isLoading
                        ? DesignSystem.Colors.primaryGradient
                        : Color.gray.opacity(0.3)
                )
        )
        .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        .opacity(configuration.isPressed ? 0.8 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        .disabled(!isEnabled || isLoading)
    }
}

// MARK: - Priority Color Helper
extension DesignSystem.Colors {
    static func colorForFanActivity(_ activity: String) -> Color {
        return BrandingConfig.colorForPriority(activity)
    }
}

// MARK: - Preview
struct ExampleUsage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ExampleUsage()
                .previewDisplayName("Usage Examples")
            
            DesignSystemShowcase()
                .previewDisplayName("Design System Showcase")
        }
    }
}