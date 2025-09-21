import SwiftUI

struct WelcomeScreenCoordinator: View {
    @Binding var showDashboard: Bool
    @EnvironmentObject private var authService: AuthenticationService
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    @State private var showLogin = false
    @State private var isProcessing = false

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingCoordinator(showDashboard: $showDashboard)
                    .onAppear { print("🔧 DEBUG: Showing OnboardingCoordinator") }
            } else if showLogin {
                AuthenticationView(onComplete: {
                    authService.isAuthenticated = true
                })
                .onAppear { print("🔧 DEBUG: Showing AuthenticationView") }
            } else {
                // Restored original welcome view
                WelcomeView {
                    handleWelcomeAction()
                }
                .onAppear { print("🔧 DEBUG: Showing WelcomeView") }
            }
        }
        .onAppear {
            print("🔧 DEBUG: WelcomeScreenCoordinator appeared")
            print("🔧 DEBUG: showOnboarding = \(showOnboarding)")
            print("🔧 DEBUG: showLogin = \(showLogin)")
            print("🔧 DEBUG: hasCompletedOnboarding = \(hasCompletedOnboarding)")
            print("🔧 DEBUG: authService.isAuthenticated = \(authService.isAuthenticated)")
        }
    }

    private func handleWelcomeAction() {
        // Prevent double-tap by checking if already processing
        guard !isProcessing else {
            print("🚫 DEBUG: Ignoring duplicate tap")
            return
        }

        isProcessing = true

        #if DEBUG
        // ALWAYS show onboarding in debug/test builds
        print("🧪 DEBUG: Forcing onboarding flow for testing")
        withAnimation(.easeInOut(duration: 0.3)) {
            showOnboarding = true
        }
        #else
        // Production behavior - check if onboarding was completed
        if hasCompletedOnboarding {
            // User has completed onboarding before, go to login
            withAnimation(.easeInOut(duration: 0.3)) {
                showLogin = true
            }
        } else {
            // First time user, start onboarding
            withAnimation(.easeInOut(duration: 0.3)) {
                showOnboarding = true
            }
        }
        #endif

        // Reset processing flag after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isProcessing = false
        }
    }
}

#Preview {
    WelcomeScreenCoordinator(showDashboard: .constant(false))
        .environmentObject(AuthenticationService.shared)
}