import SwiftUI

struct PiggyToggleRow: View {
    enum Style {
        case standard       // Basic toggle row
        case settings       // Settings screen style
        case card           // Card-wrapped toggle
        case inline         // Inline with other content
        
        var backgroundColor: Color {
            switch self {
            case .standard, .inline: return Color.clear
            case .settings: return Color.piggyInputBackground
            case .card: return Color.piggyCardBackground
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .inline:
                return EdgeInsets(
                    top: PiggySpacing.md,
                    leading: PiggySpacing.md,
                    bottom: PiggySpacing.md,
                    trailing: PiggySpacing.md
                )
            default:
                return EdgeInsets(
                    top: PiggySpacing.sm,
                    leading: PiggySpacing.md,
                    bottom: PiggySpacing.sm,
                    trailing: PiggySpacing.md
                )
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .standard, .inline: return 0
            case .settings: return PiggyBorderRadius.input
            case .card: return PiggyBorderRadius.card
            }
        }
    }
    
    // MARK: - Properties
    let title: String
    let subtitle: String?
    let icon: String?
    @Binding var isOn: Bool
    let style: Style
    let isDisabled: Bool
    let onChange: ((Bool) -> Void)?
    
    // MARK: - Initializer
    init(
        _ title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        isOn: Binding<Bool>,
        style: Style = .standard,
        isDisabled: Bool = false,
        onChange: ((Bool) -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self._isOn = isOn
        self.style = style
        self.isDisabled = isDisabled
        self.onChange = onChange
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            guard !isDisabled else { return }
            
            piggyHapticFeedback(.light)
            let newValue = !isOn
            isOn = newValue
            onChange?(newValue)
        }) {
            HStack(spacing: PiggySpacing.sm) {
                // Leading Icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isDisabled ? .gray : .white.opacity(0.9))
                        .frame(width: 24)
                }
                
                // Title and Subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(PiggyFont.body)
                        .foregroundColor(isDisabled ? .gray : .white)
                        .multilineTextAlignment(.leading)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(PiggyFont.caption)
                            .foregroundColor(isDisabled ? .gray.opacity(0.7) : .white.opacity(0.6))
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                // Toggle Switch
                Toggle("", isOn: $isOn)
                    .toggleStyle(PiggyToggleStyle())
                    .disabled(isDisabled)
                    .onChange(of: isOn) { _, newValue in
                        onChange?(newValue)
                    }
            }
            .padding(style.padding)
            .frame(minHeight: 52)
            .background(style.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
            .overlay(
                style == .card ? 
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .stroke(Color.piggyCardBorderSubtle, lineWidth: 1)
                : nil
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Toggle Style
struct PiggyToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            Spacer()
            
            // Custom Toggle Switch
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? AnyShapeStyle(PiggyGradients.primaryButton) : AnyShapeStyle(Color.toggleTrackInactive))
                .frame(width: 52, height: 32)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .frame(width: 28, height: 28)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isOn)
                )
                .onTapGesture {
                    piggyHapticFeedback(.selection)
                    configuration.isOn.toggle()
                }
        }
    }
}

// MARK: - Convenience Initializers
extension PiggyToggleRow {
    // Notification-style toggle
    init(
        notification title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        onChange: ((Bool) -> Void)? = nil
    ) {
        self.init(
            title,
            subtitle: subtitle,
            icon: "bell",
            isOn: isOn,
            style: .settings,
            onChange: onChange
        )
    }
    
    // Privacy-style toggle
    init(
        privacy title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        onChange: ((Bool) -> Void)? = nil
    ) {
        self.init(
            title,
            subtitle: subtitle,
            icon: "lock.shield",
            isOn: isOn,
            style: .settings,
            onChange: onChange
        )
    }
    
    // Feature toggle
    init(
        feature title: String,
        subtitle: String? = nil,
        icon: String,
        isOn: Binding<Bool>,
        onChange: ((Bool) -> Void)? = nil
    ) {
        self.init(
            title,
            subtitle: subtitle,
            icon: icon,
            isOn: isOn,
            style: .card,
            onChange: onChange
        )
    }
}

// MARK: - Group Helper
struct PiggyToggleGroup<Content: View>: View {
    let title: String
    let content: () -> Content
    
    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.sm) {
            PiggySectionHeader(title, style: .accent)
            
            PiggyCard(style: .secondary) {
                VStack(spacing: 0) {
                    content()
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Toggle Styles") {
    ZStack {
        PiggyGradients.background
        
        ScrollView {
            VStack(spacing: PiggySpacing.xl) {
                // Settings-style toggles
                PiggyToggleGroup("Notifications") {
                    PiggyToggleRow(
                        notification: "Push Notifications",
                        subtitle: "Get notified about new releases and events",
                        isOn: .constant(true)
                    )
                    
                    Divider()
                        .background(Color.piggyCardBorderSubtle)
                        .padding(.leading, PiggySpacing.lg)
                    
                    PiggyToggleRow(
                        notification: "Email Updates",
                        subtitle: "Weekly summary of your fan activities",
                        isOn: .constant(false)
                    )
                }
                
                // Privacy toggles
                PiggyToggleGroup("Privacy") {
                    PiggyToggleRow(
                        privacy: "Profile Visibility",
                        subtitle: "Make your profile visible to other fans",
                        isOn: .constant(true)
                    )
                    
                    Divider()
                        .background(Color.piggyCardBorderSubtle)
                        .padding(.leading, PiggySpacing.lg)
                    
                    PiggyToggleRow(
                        privacy: "Activity Sharing",
                        subtitle: "Share your activities with friends",
                        isOn: .constant(false)
                    )
                }
                
                // Feature toggles
                VStack(spacing: PiggySpacing.md) {
                    PiggySectionHeader("Features", style: .accent)
                    
                    PiggyToggleRow(
                        feature: "Dark Mode",
                        subtitle: "Use dark appearance",
                        icon: "moon.stars",
                        isOn: .constant(false)
                    )
                    
                    PiggyToggleRow(
                        feature: "Auto-Backup",
                        subtitle: "Automatically backup your data",
                        icon: "icloud.and.arrow.up",
                        isOn: .constant(true)
                    )
                    
                    PiggyToggleRow(
                        feature: "Analytics",
                        icon: "chart.line.uptrend.xyaxis",
                        isOn: .constant(true)
                    )
                }
                
                // Inline toggles
                VStack(spacing: PiggySpacing.sm) {
                    PiggySectionHeader("Quick Settings", style: .accent)
                    
                    PiggyCard(style: .secondary) {
                        VStack(spacing: PiggySpacing.sm) {
                            PiggyToggleRow(
                                "Haptic Feedback",
                                isOn: .constant(true),
                                style: .inline
                            )
                            
                            PiggyToggleRow(
                                "Sound Effects",
                                isOn: .constant(false),
                                style: .inline
                            )
                            
                            PiggyToggleRow(
                                "Offline Mode",
                                subtitle: "Download content for offline use",
                                isOn: .constant(false),
                                style: .inline
                            )
                        }
                    }
                }
            }
            .padding(PiggySpacing.lg)
        }
    }
}