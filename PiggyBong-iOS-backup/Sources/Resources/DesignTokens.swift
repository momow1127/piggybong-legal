import SwiftUI

// MARK: - Color Tokens
extension Color {
    static let piggyPrimary = Color("PiggyPrimary", bundle: .main) // Pink piggy color
    static let piggySecondary = Color("PiggySecondary", bundle: .main) // Soft purple
    static let piggyAccent = Color("PiggyAccent", bundle: .main) // Gold accent
    
    // Budget Colors
    static let budgetGreen = Color("BudgetGreen", bundle: .main)
    static let budgetOrange = Color("BudgetOrange", bundle: .main)
    static let budgetRed = Color("BudgetRed", bundle: .main)
    
    // Background Colors
    static let piggyBackground = Color("PiggyBackground", bundle: .main)
    static let piggySurface = Color("PiggySurface", bundle: .main)
    
    // Text Colors
    static let piggyTextPrimary = Color("PiggyTextPrimary", bundle: .main)
    static let piggyTextSecondary = Color("PiggyTextSecondary", bundle: .main)
    
    // Fallback colors for when assets aren't available
    static let piggyPrimaryFallback = Color(red: 1.0, green: 0.7, blue: 0.8) // Light pink
    static let piggySecondaryFallback = Color(red: 0.8, green: 0.7, blue: 1.0) // Light purple
    static let piggyAccentFallback = Color(red: 1.0, green: 0.8, blue: 0.4) // Gold
}

// MARK: - Typography Tokens
struct PiggyFont {
    // Headings
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    
    // Body Text
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyEmphasized = Font.system(size: 17, weight: .semibold, design: .default)
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    
    // Small Text
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let caption1 = Font.system(size: 12, weight: .regular, design: .default)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
    
    // Special
    static let budgetAmount = Font.system(size: 32, weight: .bold, design: .rounded)
    static let smallAmount = Font.system(size: 14, weight: .semibold, design: .rounded)
}

// MARK: - Spacing Tokens
struct PiggySpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
    
    // Component specific
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let buttonHeight: CGFloat = 48
    static let cornerRadius: CGFloat = 12
    static let cardCornerRadius: CGFloat = 16
}

// MARK: - Animation Tokens
struct PiggyAnimation {
    static let quick = Animation.easeInOut(duration: 0.2)
    static let standard = Animation.easeInOut(duration: 0.3)
    static let slow = Animation.easeInOut(duration: 0.5)
    static let bounce = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let wiggle = Animation.spring(response: 0.3, dampingFraction: 0.3)
}

// MARK: - Shadow Tokens
struct PiggyShadow {
    static let card = Shadow(
        color: Color.black.opacity(0.1),
        radius: 8,
        x: 0,
        y: 2
    )
    
    static let button = Shadow(
        color: Color.black.opacity(0.15),
        radius: 4,
        x: 0,
        y: 2
    )
    
    static let modal = Shadow(
        color: Color.black.opacity(0.25),
        radius: 16,
        x: 0,
        y: 8
    )
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Component Styles
struct PiggyCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.piggySurface)
            .cornerRadius(PiggySpacing.cardCornerRadius)
            .shadow(
                color: PiggyShadow.card.color,
                radius: PiggyShadow.card.radius,
                x: PiggyShadow.card.x,
                y: PiggyShadow.card.y
            )
    }
}

struct PiggyButtonStyle: ButtonStyle {
    let variant: ButtonVariant
    
    enum ButtonVariant {
        case primary
        case secondary
        case outline
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PiggyFont.bodyEmphasized)
            .frame(maxWidth: .infinity)
            .frame(height: PiggySpacing.buttonHeight)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(PiggyBorderRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                    .stroke(borderColor, lineWidth: variant == .outline ? 2 : 0)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(PiggyAnimation.quick, value: configuration.isPressed)
    }
    
    private var backgroundColor: Color {
        switch variant {
        case .primary: return .piggyPrimary
        case .secondary: return .piggySecondary
        case .outline: return .clear
        }
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .primary, .secondary: return .white
        case .outline: return .piggyPrimary
        }
    }
    
    private var borderColor: Color {
        switch variant {
        case .outline: return .piggyPrimary
        default: return .clear
        }
    }
}

// MARK: - View Extensions
extension View {
    func piggyCard() -> some View {
        modifier(PiggyCardStyle())
    }
    
    func piggyButton(_ variant: PiggyButtonStyle.ButtonVariant = .primary) -> some View {
        buttonStyle(PiggyButtonStyle(variant: variant))
    }
}