import SwiftUI

// MARK: - Enhanced Onboarding View (Refactored)
struct EnhancedOnboardingView: View {
    @Binding var showDashboard: Bool
    @State private var navigationPath = NavigationPath()
    @State private var name = ""
    @State private var monthlyBudget: Double = 300.0
    @State private var isAnimating = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                PiggyGradients.background
                    .ignoresSafeArea()
                
                WelcomeStepView(
                    isAnimating: $isAnimating,
                    onNext: { navigationPath.append(OnboardingStep.intro) },
                    onSkip: { showDashboard = true }
                )
                
                // MARK: - Development Bypass Button (Remove before production)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button("🚀 DEV: SKIP TO DASHBOARD") {
                            showDashboard = true
                        }
                        .font(.system(.body, design: .monospaced, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.red)
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
                        Spacer()
                    }
                }
                .padding(.bottom, 50)
            }
            .navigationBarHidden(true)
            .navigationDestination(for: OnboardingStep.self) { step in
                destinationView(for: step)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    @ViewBuilder
    private func destinationView(for step: OnboardingStep) -> some View {
        switch step {
        case .intro:
            IntroCardsView(
                onNext: { navigationPath.append(OnboardingStep.name) },
                onSkip: { navigationPath.append(OnboardingStep.artistSelection) }
            )
        default:
            OnboardingStepView(
                step: step,
                name: $name,
                monthlyBudget: $monthlyBudget,
                navigationPath: $navigationPath,
                showDashboard: $showDashboard
            )
        }
    }
}

#Preview {
    EnhancedOnboardingView(showDashboard: .constant(false))
}
