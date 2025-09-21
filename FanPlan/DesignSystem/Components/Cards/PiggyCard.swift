import SwiftUI

struct PiggyCard<Content: View>: View {
    enum Style {
        case primary
        case secondary
        case elevated
        case subtle
        case outlined  // Legacy compatibility - emphasized border with transparent background
        
        var backgroundColor: LinearGradient {
            switch self {
            case .primary:
                return LinearGradient(
                    colors: [Color.piggyCardPrimary, Color.piggyCardPrimarySecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .secondary:
                return LinearGradient(
                    colors: [Color.piggyCardSecondary, Color.piggyCardSecondarySecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .elevated:
                return LinearGradient(
                    colors: [Color.piggyCardElevated, Color.piggyCardElevatedSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .subtle:
                return LinearGradient(
                    colors: [Color.piggyCardSubtle],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .outlined:
                return LinearGradient(
                    colors: [Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        
        var strokeColor: Color {
            switch self {
            case .primary: return Color.piggyCardBorderPrimary
            case .secondary: return Color.piggyCardBorderSecondary
            case .elevated: return Color.piggyCardBorderElevated
            case .subtle: return Color.piggyCardBorderSubtle
            case .outlined: return Color.piggyPrimary  // Emphasized border for selection states
            }
        }
        
        var shadowRadius: CGFloat {
            switch self {
            case .primary: return 8
            case .secondary: return 4
            case .elevated: return 12
            case .subtle: return 0
            case .outlined: return 4  // Subtle shadow for outlined style
            }
        }
    }
    
    enum CornerRadius {
        case small
        case medium
        case large
        case custom(CGFloat)
        
        var value: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 16
            case .custom(let radius): return radius
            }
        }
    }
    
    let content: Content
    let style: Style
    let cornerRadius: CornerRadius
    let padding: EdgeInsets
    let action: (() -> Void)?
    
    init(
        style: Style = .secondary,
        cornerRadius: CornerRadius = .large,
        padding: EdgeInsets = EdgeInsets(
            top: PiggySpacing.md,
            leading: PiggySpacing.md,
            bottom: PiggySpacing.md,
            trailing: PiggySpacing.md
        ),
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.style = style
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.action = action
    }
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    cardContent
                }
                .buttonStyle(PiggyCardButtonStyle())
            } else {
                cardContent
            }
        }
    }
    
    private var cardContent: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius.value)
                    .fill(style.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius.value)
                            .stroke(style.strokeColor, lineWidth: 1)
                    )
                    .shadow(
                        color: .black.opacity(0.1),
                        radius: style.shadowRadius,
                        x: 0,
                        y: style.shadowRadius > 0 ? 2 : 0
                    )
            )
    }
}

// MARK: - Custom Button Style for Cards
struct PiggyCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Extension for Card Style Modifier
extension View {
    func piggyCardStyle(
        _ style: PiggyCard<AnyView>.Style = .secondary,
        cornerRadius: PiggyCard<AnyView>.CornerRadius = .large,
        padding: EdgeInsets = EdgeInsets(
            top: PiggySpacing.md,
            leading: PiggySpacing.md,
            bottom: PiggySpacing.md,
            trailing: PiggySpacing.md
        )
    ) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius.value)
                    .fill(style.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius.value)
                            .stroke(style.strokeColor, lineWidth: 1)
                    )
                    .shadow(
                        color: .black.opacity(0.1),
                        radius: style.shadowRadius,
                        x: 0,
                        y: style.shadowRadius > 0 ? 2 : 0
                    )
            )
    }
}

#Preview("Card Styles") {
    ZStack {
        PiggyGradients.background
        
        ScrollView {
            VStack(spacing: PiggySpacing.lg) {
                // Different card styles
                PiggyCard(style: .primary) {
                    VStack(alignment: .leading, spacing: PiggySpacing.sm) {
                        Text("Primary Card")
                            .font(PiggyFont.bodyEmphasized)
                            .foregroundColor(.piggyTextPrimary)
                        Text("High emphasis content with stronger background")
                            .font(PiggyFont.body)
                            .foregroundColor(.piggyTextSecondary)
                    }
                }
                
                PiggyCard(style: .secondary) {
                    VStack(alignment: .leading, spacing: PiggySpacing.sm) {
                        Text("Secondary Card")
                            .font(PiggyFont.bodyEmphasized)
                            .foregroundColor(.piggyTextPrimary)
                        Text("Standard content with balanced styling")
                            .font(PiggyFont.body)
                            .foregroundColor(.piggyTextSecondary)
                    }
                }
                
                PiggyCard(style: .elevated) {
                    VStack(alignment: .leading, spacing: PiggySpacing.sm) {
                        Text("Elevated Card")
                            .font(PiggyFont.bodyEmphasized)
                            .foregroundColor(.piggyTextPrimary)
                        Text("Important content that needs to stand out")
                            .font(PiggyFont.body)
                            .foregroundColor(.piggyTextSecondary)
                    }
                }
                
                PiggyCard(style: .subtle) {
                    VStack(alignment: .leading, spacing: PiggySpacing.sm) {
                        Text("Subtle Card")
                            .font(PiggyFont.bodyEmphasized)
                            .foregroundColor(.piggyTextPrimary)
                        Text("Low emphasis content with minimal styling")
                            .font(PiggyFont.body)
                            .foregroundColor(.piggyTextSecondary)
                    }
                }
            }
            .padding(PiggySpacing.lg)
        }
    }
}

#Preview("Interactive Cards") {
    ZStack {
        PiggyGradients.background
        
        VStack(spacing: PiggySpacing.lg) {
            PiggyCard(style: .primary, action: {
                print("Primary card tapped")
            }) {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.piggyPrimary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tap Me!")
                            .font(PiggyFont.bodyEmphasized)
                            .foregroundColor(.piggyTextPrimary)
                        Text("This card has an action")
                            .font(PiggyFont.caption)
                            .foregroundColor(.piggyTextSecondary)
                    }
                    
                    Spacer()
                }
            }
            
            PiggyCard(style: .elevated, cornerRadius: .large, action: {
                print("Custom card tapped")
            }) {
                HStack {
                    PiggyIconButton("heart.fill", style: PiggyIconButton.Style.primary) {
                        print("Heart button")
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Interactive Card")
                            .font(PiggyFont.bodyEmphasized)
                            .foregroundColor(.piggyTextPrimary)
                        Text("With custom corner radius")
                            .font(PiggyFont.caption)
                            .foregroundColor(.piggyTextSecondary)
                    }
                    
                    Spacer()
                    
                    PiggyBadge(count: 5, style: .notification)
                }
            }
        }
        .padding(PiggySpacing.lg)
    }
}

#Preview("Card Style Modifier") {
    ZStack {
        PiggyGradients.background
        
        VStack(spacing: PiggySpacing.lg) {
            // Using the modifier approach
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 20))
                    .foregroundColor(.piggyTextPrimary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Event Title")
                        .font(PiggyFont.bodyEmphasized)
                        .foregroundColor(.piggyTextPrimary)
                    Text("Today at 3:00 PM")
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextSecondary)
                }
                
                Spacer()
            }
            .piggyCardStyle(.secondary)
            
            // Compact card with minimal padding
            Text("Quick Info")
                .font(PiggyFont.body)
                .foregroundColor(.piggyTextPrimary)
                .piggyCardStyle(
                    .subtle,
                    cornerRadius: .small,
                    padding: EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
                )
        }
        .padding(PiggySpacing.lg)
    }
}
