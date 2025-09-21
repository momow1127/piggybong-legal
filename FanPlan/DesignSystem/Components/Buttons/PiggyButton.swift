import SwiftUI

// MARK: - PiggyBong Button Component
// 🚨 SINGLE SOURCE OF TRUTH - Use this component for all button needs
// Consolidated from PiggyReusableComponents and PiggyButtonStyles

struct PiggyButton: View {
    // MARK: - Properties
    let title: String
    let action: () -> Void
    var style: PiggyButtonStyle = .primary
    var size: PiggyButtonSize = .medium
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var icon: String? = nil
    var hapticEnabled: Bool = true
    
    @State private var isPressed: Bool = false
    
    // MARK: - Style System
    enum PiggyButtonStyle {
        case primary      // Main CTA with brand gradient
        case secondary    // Card background with outline
        case tertiary     // Transparent with accent outline
        case destructive  // Critical, irreversible actions (Delete Account, Remove Budget)
        case success      // Success confirmation actions
        case cancel       // Safe dismissal action in modals (Cancel, Close)

        var description: String {
            switch self {
            case .primary: return "Primary action button"
            case .secondary: return "Secondary action button"
            case .tertiary: return "Tertiary action button"
            case .destructive: return "Destructive action button"
            case .success: return "Success action button"
            case .cancel: return "Cancel action button"
            }
        }
    }
    
    // MARK: - Size System
    enum PiggyButtonSize {
        case small        // Small height - uses design tokens
        case medium       // Medium height - uses design tokens
        case large        // Large height - uses design tokens
        
        var height: CGFloat {
            switch self {
            case .small: return PiggySpacing.minTouchTarget
            case .medium: return PiggySpacing.touchTarget
            case .large: return PiggySpacing.largeTouchTarget
            }
        }
        
        var font: Font {
            switch self {
            case .small: return PiggyFont.callout
            case .medium: return PiggyFont.bodyEmphasized
            case .large: return PiggyFont.bodyEmphasized
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 14
            case .large: return 16
            }
        }
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            if hapticEnabled {
                triggerHapticFeedback()
            }
            action()
        }) {
            HStack(spacing: PiggySpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(PiggyFont.bodyEmphasized)
                        .scaleEffect(size == .small ? 0.8 : size == .large ? 1.2 : 1.0)
                }
                
                Text(title)
                    .font(size.font)
                    .fontWeight(.medium)
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                    .stroke(borderColor, lineWidth: strokeWidth)
            )
            .cornerRadius(PiggyBorderRadius.button)
        }
        .disabled(isDisabled || isLoading)
        .opacity(effectiveOpacity)
        .scaleEffect(effectiveScale)
        .animation(PiggyAnimations.fast, value: isLoading)
        .animation(PiggyAnimations.fast, value: isPressed)
        .animation(PiggyAnimations.fast, value: isDisabled)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(PiggyAnimations.fast) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
        .accessibilityLabel(title)
        .accessibilityHint(style.description)
        .accessibilityAddTraits(isDisabled || isLoading ? [] : [.isButton])
        .accessibilityRemoveTraits(isDisabled || isLoading ? [.isButton] : [])
        .accessibilityValue(isLoading ? "Loading" : "")
    }
    
    // MARK: - Computed Properties
    @ViewBuilder
    private var backgroundColor: some View {
        switch style {
        case .primary:
            LinearGradient(
                colors: [Color.piggyPrimary, Color.piggySecondary],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .secondary:
            Color.piggyCardBackground
        case .tertiary:
            Color.clear
        case .destructive:
            Color.budgetRed.opacity(0.15)
        case .success:
            Color.budgetGreen.opacity(0.8)
        case .cancel:
            Color.white.opacity(0.15)
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary, .success, .cancel:
            return .white
        case .destructive:
            return .budgetRed
        case .secondary, .tertiary:
            return .piggyTextPrimary
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary, .success:
            return .clear
        case .destructive:
            return .budgetRed.opacity(0.3)
        case .secondary:
            return .piggyTextSecondary.opacity(0.3)
        case .tertiary:
            return .piggyAccent
        case .cancel:
            return .white.opacity(0.3)
        }
    }
    
    private var strokeWidth: CGFloat {
        switch style {
        case .primary, .destructive, .success:
            return 0
        case .secondary, .tertiary, .cancel:
            return 1
        }
    }
    
    private var effectiveOpacity: Double {
        if isDisabled {
            return 0.6
        }
        return isPressed ? 0.8 : 1.0
    }
    
    private var effectiveScale: CGFloat {
        if isPressed {
            return 0.97
        }
        if isLoading {
            return 0.98
        }
        return 1.0
    }
    
    // MARK: - Haptic Feedback
    private func triggerHapticFeedback() {
        switch style {
        case .primary:
            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator.impactOccurred()
        case .secondary, .tertiary:
            let impactGenerator = UIImpactFeedbackGenerator(style: .light)
            impactGenerator.impactOccurred()
        case .destructive:
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.notificationOccurred(.warning)
        case .success:
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.notificationOccurred(.success)
        case .cancel:
            let impactGenerator = UIImpactFeedbackGenerator(style: .light)
            impactGenerator.impactOccurred()
        }
    }
}

// MARK: - Convenience Initializers
extension PiggyButton {
    /// Primary button with icon
    init(
        _ title: String,
        icon: String,
        action: @escaping () -> Void
    ) {
        self.init(title: title, action: action, style: .primary, icon: icon)
    }
    
    /// Loading button variant
    init(
        _ title: String,
        isLoading: Bool,
        action: @escaping () -> Void
    ) {
        self.init(title: title, action: action, isLoading: isLoading)
    }
    
    /// Simple primary button
    init(
        _ title: String,
        action: @escaping () -> Void
    ) {
        self.init(title: title, action: action, style: .primary)
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension PiggyButton {
    static var previewButtons: some View {
        VStack(spacing: PiggySpacing.md) {
            // Style variants
            PiggyButton("Primary Button", action: {})
            PiggyButton(title: "Secondary Button", action: {}, style: .secondary)
            PiggyButton(title: "Tertiary Button", action: {}, style: .tertiary)
            PiggyButton(title: "Destructive Button", action: {}, style: .destructive)
            PiggyButton(title: "Success Button", action: {}, style: .success)
            PiggyButton(title: "Cancel Button", action: {}, style: .cancel)
            
            // Size variants
            HStack(spacing: PiggySpacing.sm) {
                PiggyButton(title: "Small", action: {}, size: .small)
                PiggyButton(title: "Medium", action: {}, size: .medium)
                PiggyButton(title: "Large", action: {}, size: .large)
            }
            
            // State variants
            PiggyButton(title: "With Icon", action: {}, icon: "star.fill")
            PiggyButton(title: "Loading...", action: {}, isLoading: true)
            PiggyButton(title: "Disabled", action: {}, isDisabled: true)
        }
        .padding(PiggySpacing.lg)
    }
}
#endif

// MARK: - Usage Guidelines
/*
 🎯 PIGGYBUTTON USAGE GUIDELINES:

 ✅ DO:
 - Use PiggyButton("Save", action: saveAction) for primary actions
 - Use PiggyButton(title: "Cancel", action: cancelAction, style: .secondary)
 - Use PiggyButton(title: "Delete", action: deleteAction, style: .destructive)
 - Use icon parameter for buttons with icons
 - Use isLoading for async operations

 ❌ DON'T:
 - Create custom button components
 - Use Button(action:) with custom styling instead
 - Hardcode colors or sizes
 - Skip accessibility labels

 🎨 STYLE GUIDE:
 - Primary: Main CTAs (Save, Continue, Submit)
 - Secondary: Secondary actions (Cancel, Back, Skip)
 - Tertiary: Subtle actions (Help, Learn More)
 - Destructive: Dangerous actions (Delete, Remove, Clear)
 - Success: Confirmation actions (Done, Complete, Confirm)

 📱 ACCESSIBILITY:
 - Automatic accessibility labels and hints
 - Minimum 44pt touch targets (medium/large sizes)
 - High contrast maintained across all styles
 - Haptic feedback for user confirmation
 */
