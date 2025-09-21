import SwiftUI

// MARK: - Name Input View
struct NameInputView: View {
    @Binding var name: String
    let onNext: () -> Void
    
    var body: some View {
        OnboardingContainer(
            title: "",
            showBackButton: false,
            buttonTitle: "Continue",
            canProceed: true, // Always allow proceeding
            currentStep: .artistSelection,
            showSkip: true,
            onBack: {},
            onNext: onNext,
            onSkip: onNext
        ) {
            NameInputContent(name: $name)
        }
    }
}

// MARK: - Name Input Content
struct NameInputContent: View {
    @Binding var name: String
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        VStack(spacing: PiggySpacing.xl) {  // Standardized spacing
            // Header
            VStack(spacing: PiggySpacing.sm) {
                Text("What should we call you?")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.piggyTextPrimary)
                    .multilineTextAlignment(.center)
            }
            
            // Name Input
            VStack(spacing: PiggySpacing.sm) {
                PiggyTextField(
                    "Enter your name or nickname",
                    text: $name
                )
                .focused($isNameFocused)
                    .onAppear {
                        // Auto-focus immediately when view appears
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isNameFocused = true
                        }
                    }
            }
            
        }
    }
}

#Preview {
    NameInputView(
        name: .constant(""),
        onNext: {}
    )
}