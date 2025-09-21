import SwiftUI

struct OnboardingStepView: View {
    let step: OnboardingStep
    @Binding var name: String
    @Binding var monthlyBudget: Double
    @Binding var navigationPath: NavigationPath
    @Binding var showDashboard: Bool
    
    @StateObject private var onboardingService = OnboardingService.shared
    @State private var isAnimating = false
    
    var body: some View {
        OnboardingScaffold(
            title: buttonTitle,
            canProceed: canProceed,
            showSkip: false,
            currentStep: step.onboardingProgressStep,
            action: handleNextAction,
            onSkip: nil,
            showScrim: true
        ) {
            VStack(spacing: 0) {
                    // Header
                    OnboardingHeaderView(
                        step: step,
                        onBack: { navigationPath.removeLast() }
                    )
                    
                    // Content
                    ScrollView {
                        VStack(spacing: PiggySpacing.xxl) {
                            stepContent
                        }
                        .padding(.horizontal, PiggySpacing.xl)
                        .padding(.bottom, 140) // Consistent spacing for sticky button
                    }
                    
                    Spacer()
                }
        }
        .navigationBarHidden(true)
        .onAppear {
            isAnimating = true
        }
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .name:
            OnboardingNameStepContent(name: $name, isAnimating: $isAnimating)
        case .artistSelection:
            OnboardingArtistsStepContent(isAnimating: $isAnimating)
        case .goalSetting:
            OnboardingGoalsStepContent(isAnimating: $isAnimating)
        case .permissions:
            OnboardingNotificationsStepContent(isAnimating: $isAnimating)
        case .bridge:
            OnboardingCompletionStepContent(name: name, isAnimating: $isAnimating)
        default:
            EmptyView()
        }
    }
    
    private var canProceed: Bool {
        switch step {
        case .name:
            return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .artistSelection:
            return !onboardingService.selectedArtists.isEmpty
        case .goalSetting:
            return !onboardingService.selectedGoals.isEmpty
        default:
            return true
        }
    }
    
    private var buttonTitle: String {
        switch step {
        case .bridge:
            return "Let's Go!"
        default:
            return "Continue"
        }
    }
    
    private func handleNextAction() {
        switch step {
        case .name:
            navigationPath.append(OnboardingStep.artistSelection)
        case .artistSelection:
            navigationPath.append(OnboardingStep.goalSetting)
        case .goalSetting:
            navigationPath.append(OnboardingStep.permissions)
        case .permissions:
            navigationPath.append(OnboardingStep.insights)
        case .bridge:
            completeOnboarding()
        default:
            break
        }
    }
    
    private func completeOnboarding() {
        onboardingService.completeOnboarding(
            for: UUID(), // Generate a new UUID since we don't have a userId in this context
            name: name,
            monthlyBudget: 0.0
        )
        showDashboard = true
    }
}

// MARK: - OnboardingStep Extension
extension OnboardingStep {
    var onboardingProgressStep: OnboardingProgressStep? {
        switch self {
        case .artistSelection:
            return .artistSelection
        case .goalSetting:
            return .goalSetting
        default:
            return nil // Other steps don't map to progress steps
        }
    }
}

struct OnboardingHeaderView: View {
    let step: OnboardingStep
    let onBack: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
            }
            
            Spacer()
            
            Text(step.title)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            // Progress indicator
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 3)
                    .frame(width: 32, height: 32)
                
                Circle()
                    .trim(from: 0, to: step.progressValue)
                    .stroke(Color.piggyPrimary, lineWidth: 3)
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: step.progressValue)
                
                Text("\(Int(step.progressValue * 100))%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 20)
    }
}

#Preview {
    OnboardingStepView(
        step: .name,
        name: .constant(""),
        monthlyBudget: .constant(300),
        navigationPath: .constant(NavigationPath()),
        showDashboard: .constant(false)
    )
}