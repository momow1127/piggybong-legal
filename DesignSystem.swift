import SwiftUI

// MARK: - Design System Constants
struct DesignSystem {
    
    // MARK: - Colors
    struct Colors {
        // Primary gradient colors
        static let primaryPurple = Color(red: 0.45, green: 0.30, blue: 0.85)
        static let primaryPink = Color(red: 0.85, green: 0.30, blue: 0.65)
        
        // Background colors with proper opacity
        static let searchBarBackground = Color.white.opacity(0.15)
        static let searchBarBackgroundActive = Color.white.opacity(0.25)
        static let cardBackground = Color.white.opacity(0.08)
        static let overlayBackground = Color.black.opacity(0.6)
        
        // Text colors
        static let primaryText = Color.white
        static let secondaryText = Color.white.opacity(0.8)
        static let placeholderText = Color.white.opacity(0.6)
        static let disabledText = Color.white.opacity(0.4)
        
        // System colors
        static let success = Color(red: 0.06, green: 0.73, blue: 0.51) // #10B981
        static let warning = Color(red: 0.96, green: 0.62, blue: 0.04) // #F59E0B
        static let error = Color(red: 0.94, green: 0.27, blue: 0.27) // #EF4444
        
        // Gradient definitions
        static let primaryGradient = LinearGradient(
            colors: [primaryPurple, primaryPink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let backgroundGradient = LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.05, green: 0.05, blue: 0.15)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Typography
    struct Typography {
        static let displayLarge = Font.system(size: 36, weight: .bold, design: .rounded)
        static let displayMedium = Font.system(size: 30, weight: .bold, design: .rounded)
        static let headlineLarge = Font.system(size: 24, weight: .semibold, design: .rounded)
        static let headlineMedium = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let bodyLarge = Font.system(size: 16, weight: .medium, design: .default)
        static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
        static let caption = Font.system(size: 11, weight: .medium, design: .default)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        
        // Standard horizontal padding from README
        static let standardHorizontal: CGFloat = 16
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let soft = Shadow(
            color: Color.black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
        
        static let medium = Shadow(
            color: Color.black.opacity(0.15),
            radius: 8,
            x: 0,
            y: 4
        )
        
        static let strong = Shadow(
            color: Color.black.opacity(0.25),
            radius: 16,
            x: 0,
            y: 8
        )
    }
}

// MARK: - Shadow Helper
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Custom View Modifiers
extension View {
    
    // MARK: - Standard Padding
    func standardHorizontalPadding() -> some View {
        self.padding(.horizontal, DesignSystem.Spacing.standardHorizontal)
    }
    
    // MARK: - Search Bar Styling
    func searchBarStyle(isActive: Bool = false) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(isActive ? DesignSystem.Colors.searchBarBackgroundActive : DesignSystem.Colors.searchBarBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .overlay(
                // Subtle inner glow effect
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .blendMode(.overlay)
            )
    }
    
    // MARK: - Card Styling
    func cardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(DesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
    }
    
    // MARK: - Custom Shadow
    func customShadow(_ shadow: Shadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    // MARK: - Gradient Background
    func gradientBackground() -> some View {
        self.background(DesignSystem.Colors.backgroundGradient.ignoresSafeArea())
    }
}

// MARK: - Search Bar Component
struct CustomSearchBar: View {
    @Binding var text: String
    @State private var isEditing = false
    
    let placeholder: String
    let onSearchButtonClicked: (() -> Void)?
    
    init(
        text: Binding<String>,
        placeholder: String = "Search...",
        onSearchButtonClicked: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSearchButtonClicked = onSearchButtonClicked
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Search Icon
            Image(systemName: "magnifyingglass")
                .foregroundColor(DesignSystem.Colors.placeholderText)
                .font(DesignSystem.Typography.bodyMedium)
            
            // Text Field
            TextField(placeholder, text: $text)
                .font(DesignSystem.Typography.bodyLarge)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder)
                        .foregroundColor(DesignSystem.Colors.placeholderText)
                        .font(DesignSystem.Typography.bodyLarge)
                }
                .onTapGesture {
                    isEditing = true
                }
                .onSubmit {
                    onSearchButtonClicked?()
                }
            
            // Clear Button
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .font(DesignSystem.Typography.bodyMedium)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm + 2)
        .searchBarStyle(isActive: isEditing)
        .animation(.easeInOut(duration: 0.2), value: isEditing)
        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
    }
}

// MARK: - Placeholder Extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Interactive Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.bodyLarge)
            .foregroundColor(DesignSystem.Colors.primaryText)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(isEnabled ? DesignSystem.Colors.primaryGradient : Color.gray.opacity(0.3))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .disabled(!isEnabled)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.bodyLarge)
            .foregroundColor(DesignSystem.Colors.primaryText)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(DesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}