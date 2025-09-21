import SwiftUI

// MARK: - PiggyBong Icon Button Component
// 🚨 SINGLE SOURCE OF TRUTH - Do not duplicate this component elsewhere
// This is the definitive PiggyIconButton implementation using centralized design tokens

struct PiggyIconButton: View {
    
    // MARK: - Size System
    enum Size {
        case small
        case medium  
        case large
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 20
            case .large: return 24
            }
        }
        
        var frameSize: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 44  // Meets accessibility touch target
            case .large: return 56   // Large touch target for primary actions
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small: return PiggyBorderRadius.sm
            case .medium: return PiggyBorderRadius.md
            case .large: return PiggyBorderRadius.lg
            }
        }
    }
    
    // MARK: - Style System
    enum Style {
        case primary      // High emphasis - CTA buttons
        case secondary    // Medium emphasis - Standard actions
        case tertiary     // Low emphasis - Subtle actions
        case destructive  // Destructive actions - Delete, remove
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .piggyPrimary
            case .secondary: return .piggyCardBackground
            case .tertiary: return .clear
            case .destructive: return .budgetRed.opacity(0.15)
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .piggyTextPrimary
            case .secondary: return .piggyTextPrimary
            case .tertiary: return .piggyTextTertiary
            case .destructive: return .budgetRed
            }
        }
        
        var borderColor: Color? {
            switch self {
            case .primary: return nil
            case .secondary: return .piggyBorder
            case .tertiary: return nil
            case .destructive: return .budgetRed.opacity(0.3)
            }
        }
        
        var pressedBackgroundColor: Color {
            switch self {
            case .primary: return .piggySecondary
            case .secondary: return .piggyPressedBackground
            case .tertiary: return .piggyHoverBackground
            case .destructive: return .budgetRed.opacity(0.25)
            }
        }
    }
    
    // MARK: - Haptic Feedback System
    enum HapticStyle {
        case light
        case medium
        case heavy
        case selection
        case success
        case warning
        case error
        
        @MainActor
        func trigger() {
            switch self {
            case .light:
                let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                impactGenerator.impactOccurred()
            case .medium:
                let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                impactGenerator.impactOccurred()
            case .heavy:
                let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
                impactGenerator.impactOccurred()
            case .selection:
                let selectionGenerator = UISelectionFeedbackGenerator()
                selectionGenerator.selectionChanged()
            case .success:
                let notificationGenerator = UINotificationFeedbackGenerator()
                notificationGenerator.notificationOccurred(.success)
            case .warning:
                let notificationGenerator = UINotificationFeedbackGenerator()
                notificationGenerator.notificationOccurred(.warning)
            case .error:
                let notificationGenerator = UINotificationFeedbackGenerator()
                notificationGenerator.notificationOccurred(.error)
            }
        }
    }
    
    // MARK: - Properties
    let iconName: String
    let size: Size
    let style: Style
    let isSelected: Bool
    let hapticStyle: HapticStyle
    let customColor: Color?
    let action: () -> Void
    
    @State private var isPressed = false
    
    // MARK: - Initializers
    /// Standard initializer with all parameters
    init(
        _ iconName: String,
        size: Size = .medium,
        style: Style = .secondary,
        isSelected: Bool = false,
        hapticStyle: HapticStyle = .selection,
        customColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.iconName = iconName
        self.size = size
        self.style = style
        self.isSelected = isSelected
        self.hapticStyle = hapticStyle
        self.customColor = customColor
        self.action = action
    }
    
    /// Convenience initializer for simple use cases
    init(
        icon: String,
        action: @escaping () -> Void
    ) {
        self.init(icon, size: .medium, style: .secondary, customColor: nil, action: action)
    }
    
    /// Convenience initializer for primary actions
    init(
        primaryIcon: String,
        action: @escaping () -> Void
    ) {
        self.init(primaryIcon, size: .medium, style: .primary, customColor: nil, action: action)
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            hapticStyle.trigger()
            action()
        }) {
            Image(systemName: iconName)
                .font(.system(size: size.iconSize, weight: .semibold))
                .foregroundColor(customColor ?? effectiveStyle.foregroundColor)
                .frame(width: size.frameSize, height: size.frameSize)
                .background(
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .fill(isPressed ? effectiveStyle.pressedBackgroundColor : effectiveStyle.backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: size.cornerRadius)
                                .stroke(
                                    effectiveStyle.borderColor ?? Color.clear,
                                    lineWidth: effectiveStyle.borderColor != nil ? 1 : 0
                                )
                        )
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .opacity(isPressed ? 0.9 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
    
    // MARK: - Computed Properties
    private var effectiveStyle: Style {
        if isSelected {
            return .primary
        }
        return style
    }
    
    private var accessibilityLabel: String {
        // Convert system icon names to readable labels
        switch iconName {
        case "heart": return "Like"
        case "heart.fill": return "Liked"
        case "star": return "Favorite"
        case "star.fill": return "Favorited"
        case "plus": return "Add"
        case "minus": return "Remove"
        case "delete": return "Delete"
        case "pencil": return "Edit"
        case "checkmark": return "Confirm"
        case "xmark": return "Close"
        default: return iconName.replacingOccurrences(of: ".", with: " ")
        }
    }
    
    private var accessibilityHint: String {
        switch style {
        case .primary: return "Primary action button"
        case .secondary: return "Secondary action button"
        case .tertiary: return "Subtle action button"
        case .destructive: return "Destructive action - use caution"
        }
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension PiggyIconButton {
    static var previewButtons: some View {
        VStack(spacing: PiggySpacing.lg) {
            // Size variants
            HStack(spacing: PiggySpacing.md) {
                PiggyIconButton("heart", size: .small) { print("Small heart") }
                PiggyIconButton("heart", size: .medium) { print("Medium heart") }
                PiggyIconButton("heart", size: .large) { print("Large heart") }
            }
            
            // Style variants
            HStack(spacing: PiggySpacing.md) {
                PiggyIconButton("plus", style: .primary) { print("Primary plus") }
                PiggyIconButton("star", style: .secondary) { print("Secondary star") }
                PiggyIconButton("heart", style: .tertiary) { print("Tertiary heart") }
                PiggyIconButton("delete", style: .destructive) { print("Delete") }
            }
            
            // Selected states
            HStack(spacing: PiggySpacing.md) {
                PiggyIconButton("heart.fill", style: .secondary, isSelected: true) { print("Selected heart") }
                PiggyIconButton("star.fill", style: .tertiary, isSelected: true) { print("Selected star") }
            }
        }
    }
}
#endif

// MARK: - Previews
#Preview("Icon Button Sizes") {
    ZStack {
        PiggyGradients.background
        
        VStack(spacing: PiggySpacing.lg) {
            Text("Size Variants")
                .font(PiggyFont.title2)
                .foregroundColor(.piggyTextPrimary)
            
            HStack(spacing: PiggySpacing.md) {
                VStack(spacing: PiggySpacing.xs) {
                    PiggyIconButton("heart", size: .small) {}
                    Text("Small")
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextSecondary)
                }
                
                VStack(spacing: PiggySpacing.xs) {
                    PiggyIconButton("heart", size: .medium) {}
                    Text("Medium")
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextSecondary)
                }
                
                VStack(spacing: PiggySpacing.xs) {
                    PiggyIconButton("heart", size: .large) {}
                    Text("Large")
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextSecondary)
                }
            }
        }
        .padding(PiggySpacing.xl)
    }
}

#Preview("Icon Button Styles") {
    ZStack {
        PiggyGradients.background
        
        VStack(spacing: PiggySpacing.lg) {
            Text("Style Variants")
                .font(PiggyFont.title2)
                .foregroundColor(.piggyTextPrimary)
            
            HStack(spacing: PiggySpacing.md) {
                VStack(spacing: PiggySpacing.xs) {
                    PiggyIconButton("plus", style: .primary) {}
                    Text("Primary")
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextSecondary)
                }
                
                VStack(spacing: PiggySpacing.xs) {
                    PiggyIconButton("star", style: .secondary) {}
                    Text("Secondary")
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextSecondary)
                }
                
                VStack(spacing: PiggySpacing.xs) {
                    PiggyIconButton("heart", style: .tertiary) {}
                    Text("Tertiary")
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextSecondary)
                }
                
                VStack(spacing: PiggySpacing.xs) {
                    PiggyIconButton("delete", style: .destructive) {}
                    Text("Destructive")
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextSecondary)
                }
            }
        }
        .padding(PiggySpacing.xl)
    }
}

#Preview("Interactive Demo") {
    ZStack {
        PiggyGradients.background
        
        VStack(spacing: PiggySpacing.lg) {
            Text("Haptic Feedback Demo")
                .font(PiggyFont.title2)
                .foregroundColor(.piggyTextPrimary)
            
            Text("Tap buttons to feel haptic feedback")
                .font(PiggyFont.body)
                .foregroundColor(.piggyTextSecondary)
            
            VStack(spacing: PiggySpacing.md) {
                HStack(spacing: PiggySpacing.sm) {
                    PiggyIconButton("heart", hapticStyle: .light) {
                        print("Light haptic")
                    }
                    Text("Light")
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextTertiary)
                    
                    Spacer()
                    
                    PiggyIconButton("star", hapticStyle: .medium) {
                        print("Medium haptic")
                    }
                    Text("Medium")
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextTertiary)
                }
                
                HStack(spacing: PiggySpacing.sm) {
                    PiggyIconButton("bolt", hapticStyle: .heavy) {
                        print("Heavy haptic")
                    }
                    Text("Heavy")
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextTertiary)
                    
                    Spacer()
                    
                    PiggyIconButton("checkmark", style: .primary, hapticStyle: .success) {
                        print("Success haptic")
                    }
                    Text("Success")
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextTertiary)
                }
            }
        }
        .padding(PiggySpacing.xl)
    }
}

// MARK: - Usage Guidelines
/*
 🧩 PIGGYICONBUTTON USAGE GUIDELINES:

 ✅ DO:
 - Use PiggyIconButton("plus", style: .primary) for main CTAs
 - Use PiggyIconButton("heart", style: .secondary) for standard actions
 - Use PiggyIconButton("info", style: .tertiary) for subtle actions
 - Use appropriate haptic feedback for user actions
 - Use .large size for primary actions in prominent locations

 ❌ DON'T:
 - Create custom icon button components
 - Use Button(action:) with Image(systemName:) instead
 - Hardcode colors or sizes
 - Skip haptic feedback for important actions

 🎯 COMMON PATTERNS:
 - Primary CTA: PiggyIconButton("plus", style: .primary, size: .large)
 - Like button: PiggyIconButton("heart", isSelected: isLiked)
 - Close button: PiggyIconButton("xmark", style: .tertiary)
 - Delete action: PiggyIconButton("delete", style: .destructive, hapticStyle: .warning)

 📱 ACCESSIBILITY:
 - Minimum 44pt touch targets (medium/large sizes)
 - Automatic accessibility labels based on icon names
 - Proper accessibility hints for screen readers
 - High contrast color ratios maintained
*/