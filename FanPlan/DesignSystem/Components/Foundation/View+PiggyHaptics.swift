import SwiftUI

enum PiggyHapticStyle {
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
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.impactOccurred()

        case .medium:
            let haptic = UIImpactFeedbackGenerator(style: .medium)
            haptic.impactOccurred()

        case .heavy:
            let haptic = UIImpactFeedbackGenerator(style: .heavy)
            haptic.impactOccurred()

        case .selection:
            let haptic = UISelectionFeedbackGenerator()
            haptic.selectionChanged()

        case .success:
            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(.success)

        case .warning:
            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(.warning)

        case .error:
            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(.error)
        }
    }
}

extension View {
    
    func piggyHaptic(_ style: PiggyHapticStyle) -> some View {
        self.onTapGesture {
            style.trigger()
        }
    }
    
    func piggyHapticFeedback(_ style: PiggyHapticStyle) {
        style.trigger()
    }
}

// MARK: - Global Haptic Function for Backward Compatibility
@MainActor
func piggyHapticFeedback(_ style: PiggyHapticStyle) {
    style.trigger()
}