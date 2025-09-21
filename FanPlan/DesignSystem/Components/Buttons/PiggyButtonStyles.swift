import SwiftUI

// MARK: - Button State Enum
enum PiggyButtonState: Equatable {
    case `default`
    case pressed
    case loading(text: String = "Loading...")
    case success(text: String = "Success!")
    case error(text: String)
    case disabled
}

// MARK: - Primary Button Style
struct PiggyPrimaryButtonStyle: ButtonStyle {
    @Binding var buttonState: PiggyButtonState
    var hapticEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        PiggyPrimaryButton(
            configuration: configuration,
            buttonState: $buttonState,
            isPressed: configuration.isPressed,
            hapticEnabled: hapticEnabled
        )
    }
}

private struct PiggyPrimaryButton: View {
    let configuration: ButtonStyle.Configuration
    @Binding var buttonState: PiggyButtonState
    let isPressed: Bool
    let hapticEnabled: Bool
    
    private var isDisabled: Bool {
        switch buttonState {
        case .disabled, .loading, .success:
            return true
        default:
            return false
        }
    }
    
    private var scale: CGFloat {
        if isPressed { return 0.95 }
        switch buttonState {
        case .loading: return 0.98
        case .success: return 1.05
        default: return 1.0
        }
    }
    
    private var opacity: Double {
        if isDisabled { return 0.6 }
        if isPressed { return 0.9 }
        return 1.0
    }
    
    var body: some View {
        HStack(spacing: 8) {
            switch buttonState {
            case .default:
                configuration.label
                
            case .pressed:
                configuration.label
                
            case .loading(let text):
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .piggyTextPrimary))
                    .scaleEffect(0.8)
                Text(text)
                    .font(PiggyFont.bodyEmphasized)
                
            case .success(let text):
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.piggyTextPrimary)
                Text(text)
                    .font(PiggyFont.bodyEmphasized)
                
            case .error(let text):
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.piggyTextPrimary)
                Text(text)
                    .font(PiggyFont.bodyEmphasized)
                
            case .disabled:
                configuration.label
                    .opacity(0.5)
            }
        }
        .foregroundColor(.piggyTextPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                .fill(PiggyGradients.primaryButton)
        )
        .shadow(
            color: {
                if case .success = buttonState {
                    return Color.piggySuccess.opacity(0.3)
                } else {
                    return Color.piggyPrimary.opacity(0.3)
                }
            }(),
            radius: {
                if case .success = buttonState {
                    return 12
                } else {
                    return 8
                }
            }(),
            x: 0,
            y: 4
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: buttonState)
        .onChange(of: isPressed) { _, pressed in
            if pressed && hapticEnabled {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            }
        }
        .onChange(of: buttonState) { _, newState in
            if hapticEnabled {
                switch newState {
                case .success:
                    let impact = UIImpactFeedbackGenerator(style: .heavy)
                    impact.impactOccurred()
                case .error:
                    let notification = UINotificationFeedbackGenerator()
                    notification.notificationOccurred(.error)
                default:
                    break
                }
            }
        }
    }
}

// MARK: - Secondary Button Style
struct PiggySecondaryButtonStyle: ButtonStyle {
    @Binding var buttonState: PiggyButtonState
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            switch buttonState {
            case .loading(let text):
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .piggyPrimary))
                    .scaleEffect(0.8)
                Text(text)
                    
            case .success(let text):
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.piggySuccess)
                Text(text)
                    
            default:
                configuration.label
            }
        }
        .font(PiggyFont.body)
        .foregroundColor(.piggyPrimary)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                .fill(Color.piggyCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                        .stroke(Color.piggyPrimary, lineWidth: 1)
                )
        )
        .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        .opacity(buttonState == .disabled ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: buttonState)
    }
}

// MARK: - Text Button Style
struct PiggyTextButtonStyle: ButtonStyle {
    var color: Color = .piggyPrimary
    @Binding var isLoading: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: color))
                    .scaleEffect(0.7)
            }
            configuration.label
        }
        .font(PiggyFont.caption)
        .foregroundColor(color)
        .opacity(configuration.isPressed ? 0.6 : 1.0)
        .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Icon Button Style
struct PiggyIconButtonStyle: ButtonStyle {
    var size: CGFloat = 44
    var backgroundColor: Color = .piggyTextPrimary.opacity(0.1)
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(backgroundColor)
                    .overlay(
                        Circle()
                            .stroke(Color.piggyTextPrimary.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Floating Action Button
struct PiggyFloatingButtonStyle: ButtonStyle {
    @Binding var isExpanded: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.piggyTextPrimary)
            .padding(PiggySpacing.lg)
            .background(
                Circle()
                    .fill(PiggyGradients.primaryButton)
            )
            .shadow(
                color: Color.piggyPrimary.opacity(0.4),
                radius: isExpanded ? 16 : 12,
                x: 0,
                y: isExpanded ? 8 : 4
            )
            .scaleEffect(configuration.isPressed ? 0.9 : (isExpanded ? 1.1 : 1.0))
            .rotationEffect(.degrees(isExpanded ? 45 : 0))
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isExpanded)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Usage Examples
struct PiggyButtonExamples: View {
    @State private var primaryState: PiggyButtonState = .default
    @State private var secondaryState: PiggyButtonState = .default
    @State private var textLoading = false
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Primary Button
            Button(action: {
                simulateAction(state: $primaryState)
            }) {
                Label("Get Recommendation", systemImage: "sparkles")
            }
            .buttonStyle(PiggyPrimaryButtonStyle(buttonState: $primaryState))
            
            // Secondary Button
            Button("Regenerate") {
                simulateAction(state: $secondaryState)
            }
            .buttonStyle(PiggySecondaryButtonStyle(buttonState: $secondaryState))
            
            // Text Button
            Button("Learn More") {
                textLoading.toggle()
            }
            .buttonStyle(PiggyTextButtonStyle(isLoading: $textLoading))
            
            // Icon Button
            Button(action: {}) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.piggyTextPrimary)
            }
            .buttonStyle(PiggyIconButtonStyle())
            
            // Floating Action Button
            Button(action: { isExpanded.toggle() }) {
                Image(systemName: "plus")
                    .font(.title2)
            }
            .buttonStyle(PiggyFloatingButtonStyle(isExpanded: $isExpanded))
        }
        .padding()
    }
    
    private func simulateAction(state: Binding<PiggyButtonState>) {
        state.wrappedValue = .loading(text: "Processing...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            state.wrappedValue = .success(text: "Done!")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                state.wrappedValue = .default
            }
        }
    }
}

// MARK: - Convenience View Modifiers
extension View {
    func piggyPrimaryButton(state: Binding<PiggyButtonState>, haptic: Bool = true) -> some View {
        self.buttonStyle(PiggyPrimaryButtonStyle(buttonState: state, hapticEnabled: haptic))
    }
    
    func piggySecondaryButton(state: Binding<PiggyButtonState>) -> some View {
        self.buttonStyle(PiggySecondaryButtonStyle(buttonState: state))
    }
    
    func piggyTextButton(isLoading: Binding<Bool>, color: Color = .piggyPrimary) -> some View {
        self.buttonStyle(PiggyTextButtonStyle(color: color, isLoading: isLoading))
    }
    
    func piggyIconButton(size: CGFloat = 44, background: Color = .piggyTextPrimary.opacity(0.1)) -> some View {
        self.buttonStyle(PiggyIconButtonStyle(size: size, backgroundColor: background))
    }
}

// MARK: - ButtonStyle Extension for Legacy Support
extension ButtonStyle where Self == PiggyPrimaryButtonStyle {
    static func primaryButton() -> PiggyPrimaryButtonStyle {
        return PiggyPrimaryButtonStyle(buttonState: .constant(.default))
    }
}

extension ButtonStyle where Self == PiggySecondaryButtonStyle {
    static func secondaryButton() -> PiggySecondaryButtonStyle {
        return PiggySecondaryButtonStyle(buttonState: .constant(.default))
    }
}

#Preview {
    ZStack {
        LinearGradient(
            gradient: Gradient(colors: [Color.piggyPrimary, Color.piggySecondary]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        PiggyButtonExamples()
    }
}
