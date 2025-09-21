import SwiftUI

// MARK: - Onboarding Progress Steps
enum OnboardingProgressStep: Int, CaseIterable {
    case fandom = 0
    case artistSelection = 1
    case goalSetting = 2
    
    var progress: Float {
        return Float(self.rawValue) / Float(OnboardingProgressStep.allCases.count - 1)
    }
    
    static var totalSteps: Int {
        return OnboardingProgressStep.allCases.count
    }
}

// MARK: - Onboarding Container
struct OnboardingContainer<Content: View>: View {
    let title: String?
    let showBackButton: Bool
    let buttonTitle: String
    let canProceed: Bool
    let currentStep: OnboardingProgressStep?
    let showSkip: Bool
    let noTopPadding: Bool
    let onBack: (() -> Void)?
    let onNext: () -> Void
    let onSkip: (() -> Void)?
    let content: () -> Content
    
    init(
        title: String? = nil,
        showBackButton: Bool = false,
        buttonTitle: String,
        canProceed: Bool = true,
        currentStep: OnboardingProgressStep? = nil,
        showSkip: Bool = false,
        noTopPadding: Bool = false,
        onBack: (() -> Void)? = nil,
        onNext: @escaping () -> Void,
        onSkip: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.buttonTitle = buttonTitle
        self.canProceed = canProceed
        self.currentStep = currentStep
        self.showSkip = showSkip
        self.noTopPadding = noTopPadding
        self.onBack = onBack
        self.onNext = onNext
        self.onSkip = onSkip
        self.content = content
    }
    
    var body: some View {
        OnboardingScaffold(
            title: buttonTitle,
            canProceed: canProceed,
            showSkip: showSkip,
            currentStep: currentStep,
            action: onNext,
            onSkip: onSkip
        ) {
            VStack(spacing: 0) {
                    // Top navigation bar (if needed)
                    if showBackButton || title != nil {
                        OnboardingTopBar(
                            title: title,
                            showBackButton: showBackButton,
                            currentStep: currentStep,
                            onBack: onBack
                        )
                        .background(Color.clear)
                        .safeAreaInset(edge: .top) {
                            Color.clear.frame(height: 0)
                        }
                    }
                    
                    // Content area with consistent padding
                    ScrollView {
                        VStack(spacing: PiggySpacing.lg) {  // Reduced from xl to lg for consistency
                            if !noTopPadding {
                                Spacer(minLength: PiggySpacing.lg)  // Consistent spacing
                            }
                            content()
                            Spacer(minLength: 140) // Increased space for sticky button with safe area
                        }
                        .padding(.horizontal, PiggySpacing.lg) // Consistent 16pt
                    }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Onboarding Top Bar
struct OnboardingTopBar: View {
    let title: String?
    let showBackButton: Bool
    let currentStep: OnboardingProgressStep?
    let onBack: (() -> Void)?
    
    var body: some View {
        VStack(spacing: PiggySpacing.sm) {
            HStack {
                if showBackButton {
                    Button(action: { onBack?() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                } else {
                    Spacer()
                }
                
                if let title = title, !title.isEmpty {
                    Text(title)
                        .font(PiggyFont.bodyEmphasized)
                        .foregroundColor(.piggyTextPrimary)
                }
                
                Spacer()
            }
            .padding(.horizontal, PiggySpacing.lg)
            
            // Progress bar (only show for onboarding steps)
            if let step = currentStep {
                OnboardingProgressBar(currentStep: step)
                    .padding(.horizontal, PiggySpacing.lg)
            }
        }
        .padding(.bottom, PiggySpacing.lg)
        .background(Color.clear) // Transparent background to show app gradient
    }
}

// MARK: - Removed OnboardingStickyButton - Now using OnboardingScaffold for better consistency

// MARK: - Onboarding Progress Bar
struct OnboardingProgressBar: View {
    let currentStep: OnboardingProgressStep
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingProgressStep.allCases, id: \.self) { step in
                Rectangle()
                    .fill(step.rawValue <= currentStep.rawValue ? Color.piggyPrimary : Color.white.opacity(0.3))
                    .frame(height: 4)
                    .cornerRadius(2)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
}
