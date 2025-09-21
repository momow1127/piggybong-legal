import SwiftUI

// MARK: - Button Style Compatibility Shims
// Provides backward compatibility for legacy button styles

/// Legacy button style shim - redirects to PiggyButtonStyles
@available(*, deprecated, message: "Use PiggyPrimaryButtonStyle instead")
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PiggyPrimaryButtonStyle(buttonState: .constant(.default))
            .makeBody(configuration: configuration)
    }
}

/// Legacy button style shim - redirects to PiggyButtonStyles
@available(*, deprecated, message: "Use PiggySecondaryButtonStyle instead")  
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PiggySecondaryButtonStyle(buttonState: .constant(.default))
            .makeBody(configuration: configuration)
    }
}

/// Simple scale animation shim
@available(*, deprecated, message: "Use PiggyButton component with haptics instead")
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}