import SwiftUI

// MARK: - Reusable Component Library for PiggyBong App

// MARK: - PiggyCard - Base card component used throughout the app
struct PiggyCard<Content: View>: View {
    let content: Content
    let backgroundColor: Color
    let borderColor: Color?
    let shadowEnabled: Bool

    init(
        backgroundColor: Color = Color.white.opacity(0.1),
        borderColor: Color? = nil,
        shadowEnabled: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.shadowEnabled = shadowEnabled
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
                    .stroke(borderColor ?? Color.clear, lineWidth: borderColor != nil ? 1 : 0)
                    .shadow(
                        color: shadowEnabled ? Color.black.opacity(0.1) : Color.clear,
                        radius: shadowEnabled ? 8 : 0,
                        x: 0,
                        y: 4
                    )
            )
    }
}

// MARK: - PiggyButton - Consistent button styling
struct PiggyButton: View {
    let title: String
    let style: PiggyButtonStyle
    let size: PiggyButtonSize
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void

    init(
        _ title: String,
        style: PiggyButtonStyle = .primary,
        size: PiggyButtonSize = .medium,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(style.foregroundColor)
                } else {
                    Text(title)
                        .font(size.font)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(isEnabled ? style.foregroundColor : style.foregroundColor.opacity(0.6))
            .frame(maxWidth: size.maxWidth)
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(isEnabled ? style.backgroundColor : style.backgroundColor.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .stroke(style.borderColor ?? Color.clear, lineWidth: style.borderColor != nil ? 1 : 0)
            )
        }
        .disabled(!isEnabled || isLoading)
        .scaleEffect(isEnabled ? 1.0 : 0.95)
        .animation(.spring(response: 0.3), value: isEnabled)
    }
}

enum PiggyButtonStyle {
    case primary
    case secondary
    case tertiary
    case destructive

    var backgroundColor: Color {
        switch self {
        case .primary:
            return Color.white
        case .secondary:
            return Color.white.opacity(0.2)
        case .tertiary:
            return Color.clear
        case .destructive:
            return Color.red
        }
    }

    var foregroundColor: Color {
        switch self {
        case .primary:
            return Color.black
        case .secondary, .tertiary:
            return Color.white
        case .destructive:
            return Color.white
        }
    }

    var borderColor: Color? {
        switch self {
        case .primary, .secondary, .destructive:
            return nil
        case .tertiary:
            return Color.white.opacity(0.3)
        }
    }
}

enum PiggyButtonSize {
    case small
    case medium
    case large

    var font: Font {
        switch self {
        case .small:
            return .system(size: 14, weight: .semibold)
        case .medium:
            return .system(size: 16, weight: .semibold)
        case .large:
            return .system(size: 18, weight: .semibold)
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 12
        case .large: return 16
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 16
        case .large: return 20
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 12
        case .large: return 16
        }
    }

    var maxWidth: CGFloat? {
        switch self {
        case .small, .medium: return nil
        case .large: return .infinity
        }
    }
}

// MARK: - PiggyProgressIndicator - Reusable progress indicator
struct PiggyProgressIndicator: View {
    let current: Int
    let total: Int
    let style: ProgressStyle

    enum ProgressStyle {
        case dots
        case bar
        case text

        var spacing: CGFloat {
            switch self {
            case .dots: return 4
            case .bar, .text: return 0
            }
        }
    }

    var body: some View {
        switch style {
        case .dots:
            HStack(spacing: style.spacing) {
                ForEach(0..<total, id: \.self) { index in
                    Circle()
                        .fill(index < current ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }

        case .bar:
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .frame(width: geometry.size.width * (CGFloat(current) / CGFloat(total)), height: 8)
                        .animation(.easeInOut(duration: 0.3), value: current)
                }
            }
            .frame(height: 8)

        case .text:
            Text("\(current) of \(total)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - PiggyTextField - Consistent text field styling
struct PiggyTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let isSecure: Bool

    init(
        _ title: String,
        text: Binding<String>,
        placeholder: String = "",
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder.isEmpty ? title : placeholder
        self.keyboardType = keyboardType
        self.isSecure = isSecure
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .keyboardType(keyboardType)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - PiggyBadge - Versatile badge component
struct PiggyBadge: View {
    let text: String
    let style: BadgeStyle
    let size: BadgeSize

    enum BadgeStyle {
        case success
        case warning
        case error
        case info
        case custom(backgroundColor: Color, foregroundColor: Color)

        var backgroundColor: Color {
            switch self {
            case .success: return Color.green
            case .warning: return Color.orange
            case .error: return Color.red
            case .info: return Color.blue
            case .custom(let bg, _): return bg
            }
        }

        var foregroundColor: Color {
            switch self {
            case .success, .warning, .error, .info: return Color.white
            case .custom(_, let fg): return fg
            }
        }
    }

    enum BadgeSize {
        case small
        case medium
        case large

        var font: Font {
            switch self {
            case .small: return .system(size: 10, weight: .semibold)
            case .medium: return .system(size: 12, weight: .semibold)
            case .large: return .system(size: 14, weight: .semibold)
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .medium: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .large: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            }
        }
    }

    var body: some View {
        Text(text)
            .font(size.font)
            .foregroundColor(style.foregroundColor)
            .padding(size.padding)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(style.backgroundColor)
            )
    }
}

// MARK: - PiggyLoadingState - Consistent loading states
struct PiggyLoadingState: View {
    let message: String
    let style: LoadingStyle

    enum LoadingStyle {
        case spinner
        case pulse
        case skeleton
    }

    var body: some View {
        VStack(spacing: 16) {
            switch style {
            case .spinner:
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))

            case .pulse:
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 20)
                    .pulse()

            case .skeleton:
                VStack(spacing: 8) {
                    ForEach(0..<3) { _ in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 16)
                            .pulse()
                    }
                }
            }

            if !message.isEmpty {
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 40)
    }
}

// MARK: - PiggyEmptyState - Consistent empty states
struct PiggyEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.5))

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }

            if let actionTitle = actionTitle, let action = action {
                PiggyButton(actionTitle, style: .secondary, action: action)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
    }
}

// MARK: - PiggySection - Reusable section header
struct PiggySection<Content: View>: View {
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionTitle: String?
    let content: Content

    init(
        _ title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                Spacer()

                if let actionTitle = actionTitle, let action = action {
                    Button(actionTitle, action: action)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            content
        }
    }
}

// MARK: - Custom Modifiers

extension View {
    // Pulse animation for loading states
    func pulse() -> some View {
        self.modifier(PulseModifier())
    }

    // Standard horizontal padding used throughout the app
    func piggyPadding() -> some View {
        self.padding(.horizontal, 16)
    }

    // Consistent safe area handling
    func piggyBackground() -> some View {
        self
            .background(PiggyGradients.background.ignoresSafeArea())
    }
}

struct PulseModifier: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 0.5 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Enhanced PiggyGradients
extension PiggyGradients {
    static let primaryGradient = LinearGradient(
        colors: [
            Color(red: 0.6, green: 0.3, blue: 0.9),
            Color(red: 0.9, green: 0.3, blue: 0.7)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let secondaryGradient = LinearGradient(
        colors: [
            Color(red: 0.3, green: 0.7, blue: 0.9),
            Color(red: 0.5, green: 0.9, blue: 0.7)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let successGradient = LinearGradient(
        colors: [
            Color.green.opacity(0.8),
            Color.mint.opacity(0.6)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warningGradient = LinearGradient(
        colors: [
            Color.orange.opacity(0.8),
            Color.yellow.opacity(0.6)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Preview Provider
struct PiggyComponents_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Button Examples
                PiggySection("Buttons") {
                    VStack(spacing: 12) {
                        PiggyButton("Primary Button", style: .primary) { }
                        PiggyButton("Secondary Button", style: .secondary) { }
                        PiggyButton("Tertiary Button", style: .tertiary) { }
                        PiggyButton("Destructive Button", style: .destructive) { }
                    }
                }

                // Progress Indicator Examples
                PiggySection("Progress Indicators") {
                    VStack(spacing: 16) {
                        PiggyProgressIndicator(current: 2, total: 5, style: .dots)
                        PiggyProgressIndicator(current: 3, total: 5, style: .bar)
                            .frame(height: 8)
                        PiggyProgressIndicator(current: 4, total: 6, style: .text)
                    }
                }

                // Badge Examples
                PiggySection("Badges") {
                    HStack(spacing: 8) {
                        PiggyBadge(text: "Success", style: .success, size: .medium)
                        PiggyBadge(text: "Warning", style: .warning, size: .medium)
                        PiggyBadge(text: "Error", style: .error, size: .medium)
                        PiggyBadge(text: "Info", style: .info, size: .medium)
                    }
                }

                // Empty State Example
                PiggyEmptyState(
                    icon: "music.note",
                    title: "No Music Found",
                    message: "Browse and discover new K-pop artists to add to your collection",
                    actionTitle: "Browse Artists"
                ) {
                    print("Browse tapped")
                }
            }
            .piggyPadding()
        }
        .piggyBackground()
    }
}