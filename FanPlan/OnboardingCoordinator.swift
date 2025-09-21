import SwiftUI
import UserNotifications

// MARK: - Enhanced Onboarding Coordinator
struct OnboardingCoordinator: View {
    @Binding var showDashboard: Bool
    @StateObject private var onboardingData = OnboardingData()
    @StateObject private var onboardingService = OnboardingService.shared
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var globalLoading: GlobalLoadingManager
    @State private var navigationPath = NavigationPath()
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isCompletingOnboarding = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            WelcomeView {
                navigationPath.append(OnboardingStep.intro)
                trackStepProgress(.welcome)
            }
            .navigationDestination(for: OnboardingStep.self) { step in
                stepView(for: step)
                    .onAppear {
                        onboardingData.currentStep = step
                    }
            }
        }
        .alert("Onboarding Error", isPresented: $showingErrorAlert) {
            Button("Try Again") {
                // Retry the last action
            }
            Button("OK", role: .cancel) {
                // Dismiss alert
            }
        } message: {
            Text(errorMessage)
        }
        .overlay(
            OnboardingCompletionOverlay(isVisible: isCompletingOnboarding)
        )
    }
    
    @ViewBuilder
    private func stepView(for step: OnboardingStep) -> some View {
        switch step {
        case .welcome:
            WelcomeView {
                nextStep(from: .welcome)
            }
            
        case .intro:
            IntroCardsView(
                onNext: {
                    nextStep(from: .intro)
                },
                onSkip: {
                    // Skip to artist selection
                    nextStep(from: .intro)
                }
            )
            
        case .name:
            NameInputView(
                name: $onboardingData.name,
                onNext: {
                    nextStep(from: .name)
                }
            )
            
            
        case .artistSelection:
            ArtistSelectionView(
                onboardingData: onboardingData,
                onNext: {
                    nextStep(from: .artistSelection)
                },
                onBack: {
                    previousStep()
                }
            )
            
        case .prioritySetting:
            FanWishlistView(
                onNext: { categories in
                    onboardingData.setPriorityRanking(categories)
                    onboardingData.syncCategoryPrioritiesFromRanking()
                    nextStep(from: .prioritySetting)
                },
                onBack: {
                    previousStep()
                }
            )
            
        case .goalSetting:
            // GoalSetupView removed - goal functionality no longer supported
            // This case should be skipped in the onboarding flow
            EmptyView()
            
        case .bridge:
            PermissionExplainerView {
                nextStep(from: .bridge)
            }
            .navigationBarBackButtonHidden(true)
            
        case .permissions:
            PermissionRequestView(
                onboardingData: onboardingData,
                onComplete: {
                    nextStep(from: .permissions)
                },
                onBack: {
                    previousStep()
                }
            )
            
        case .insights:
            OnboardingInsightView(
                onboardingData: onboardingData,
                showDashboard: $showDashboard,
                onNext: {
                    nextStep(from: .insights)
                }
            )
            
        case .authentication:
            AuthenticationView(
                onComplete: {
                    // After successful authentication, continue to next onboarding step
                    nextStep(from: .authentication)
                },
                showDashboard: $showDashboard
            )
            .navigationBarBackButtonHidden(true)
            
        case .notifications:
            PermissionExplainerView {
                completeOnboarding()
            }
            .navigationBarBackButtonHidden(true)
        }
    }
    
    // MARK: - Navigation Methods
    private func nextStep(from currentStep: OnboardingStep) {
        print("🔄 OnboardingCoordinator: Moving from \(currentStep)")
        trackStepProgress(currentStep)
        
        if let nextStep = currentStep.nextStep {
            print("➡️ OnboardingCoordinator: Next step is \(nextStep)")
            navigationPath.append(nextStep)
        } else {
            print("🎯 OnboardingCoordinator: No next step, completing onboarding...")
            completeOnboarding()
        }
    }
    
    private func previousStep() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    private func trackStepProgress(_ step: OnboardingStep) {
        Task {
            guard let userId = authService.currentUser?.id else { return }
            
            do {
                try await onboardingService.updateOnboardingStep(
                    userId: userId,
                    currentStep: step.rawValue,
                    markCompleted: true
                )
            } catch {
                print("⚠️ Failed to track onboarding progress: \(error)")
            }
        }
    }
    
    // MARK: - Completion
    private func completeOnboarding() {
        #if DEBUG
        // In debug mode, allow completing onboarding even without authentication
        print("🧪 DEBUG: Completing onboarding in test mode")
        let testUser = authService.currentUser
        if testUser == nil {
            print("⚠️ DEBUG: No authenticated user, using test mode")
        }
        #else
        guard let currentUser = authService.currentUser else {
            print("❌ Cannot complete onboarding: User not authenticated")
            return
        }
        #endif

        isCompletingOnboarding = true

        Task {
            #if DEBUG
            let currentUser = authService.currentUser ?? AuthenticationService.AuthUser(
                id: UUID(),
                email: "test@piggybong.com",
                name: "Test User",
                monthlyBudget: 0.0,
                createdAt: Date()
            )
            #else
            let currentUser = authService.currentUser!
            #endif

            // Save onboarding data to Supabase for the authenticated user
            _ = SupabaseService.shared
            let databaseService = DatabaseService.shared

            // Save selected artists to DatabaseService
            for artist in onboardingData.selectedArtists {
                await databaseService.addUserArtist(artist)
            }

            // Goal creation removed - goal functionality no longer supported
            /*
            for goal in onboardingData.selectedGoals {
                let customAmount = onboardingData.customGoalAmounts[goal.id] ?? goal.suggestedAmount
                _ = try await supabaseService.createGoal(
                    userId: currentUser.id,
                    artistId: nil, // No artist linking for MVP
                    name: goal.name,
                    targetAmount: customAmount,
                    deadline: Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date(),
                    category: goal.category.rawValue
                )
            }
            */

            print("✅ Onboarding data saved to Supabase successfully")
            
            // Complete onboarding with all data (local service)
            onboardingService.completeOnboarding(
                for: currentUser.id,
                name: onboardingData.name,
                monthlyBudget: 0.0,
                selectedArtists: onboardingData.selectedArtists,
                selectedGoals: onboardingData.selectedGoals,
                customGoalAmounts: onboardingData.customGoalAmounts,
                preferences: onboardingData.preferences
            )
            
            // Track completion
            OnboardingAnalytics.trackOnboardingCompleted(
                totalTime: 0, // Would track actual time in real implementation
                stepsCompleted: OnboardingStep.allCases.count
            )
            
            // Set onboarding as completed - this will trigger app routing change
            hasCompletedOnboarding = true
            
            // Cache selected artists for Events tab integration
            cacheSelectedArtistsForEvents()
            
            // Update auth service with user info
            await MainActor.run {
                // Update current user info if needed
                isCompletingOnboarding = false
                showDashboard = true

                // Request notification permission after onboarding completion
                // This provides better UX than interrupting the onboarding flow
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    requestNotificationPermission()
                }
            }

            print("🎉 Onboarding completed successfully for user: \(currentUser.email)")
        }
    }
    
    // MARK: - Events Tab Integration
    private func cacheSelectedArtistsForEvents() {
        let artistNames = onboardingData.selectedArtists.map { $0.name }
        
        if let encoded = try? JSONEncoder().encode(artistNames) {
            UserDefaults.standard.set(encoded, forKey: "CachedSelectedArtists")
            print("📱 Cached \(artistNames.count) selected artists for Events tab: \(artistNames.joined(separator: ", "))")
        } else {
            print("⚠️ Failed to cache selected artists for Events tab")
        }
    }

    // MARK: - Notification Permission Request
    private func requestNotificationPermission() {
        print("🔔 Requesting notification permission after onboarding completion...")
        print("🔔 Selected artists: \(onboardingData.selectedArtists.map { $0.name })")

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Notifications enabled for your selected artists!")
                    UIApplication.shared.registerForRemoteNotifications()

                    // Register device with push notification service
                    Task {
                        await PushNotificationService.shared.requestPushNotificationPermission()
                    }
                } else {
                    print("⚠️ Notifications denied by user - they can enable later in Settings")
                }
            }
        }
    }

}

// MARK: - Onboarding Completion Overlay
struct OnboardingCompletionOverlay: View {
    let isVisible: Bool

    var body: some View {
        if isVisible {
            ZStack {
                // Background overlay
                Color.black.opacity(0.8)
                    .ignoresSafeArea()

                // Completion content
                VStack(spacing: PiggySpacing.lg) {
                    // Animated Piggy Lightstick
                    ZStack {
                        // Glow effects
                        Image("piggy-lightstick")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .shadow(color: Color.piggyPrimary.opacity(0.6), radius: 30, x: 0, y: 0)
                            .shadow(color: Color.piggySecondary.opacity(0.4), radius: 20, x: 0, y: 0)
                            .blur(radius: 1)

                        // Main image
                        Image("piggy-lightstick")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                    }
                    .rotationEffect(.degrees(isVisible ? 5 : -5))
                    .animation(
                        Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: isVisible
                    )

                    // Completion text
                    VStack(spacing: PiggySpacing.sm) {
                        Text("Setting Up Your")
                            .font(PiggyFont.title2)
                            .foregroundColor(.white)

                        Text("Fan Journey")
                            .font(PiggyFont.largeTitle)
                            .foregroundColor(.white)
                            .fontWeight(.bold)

                        Text("Finalizing your setup...")
                            .font(PiggyFont.body)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, PiggySpacing.xs)
                    }
                    .multilineTextAlignment(.center)

                    // Progress indicator
                    HStack(spacing: PiggySpacing.xs) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color.piggyPrimary)
                                .frame(width: 8, height: 8)
                                .scaleEffect(isVisible ? 1.2 : 0.8)
                                .animation(
                                    Animation.easeInOut(duration: 0.6)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.2),
                                    value: isVisible
                                )
                        }
                    }
                    .padding(.top, PiggySpacing.md)
                }
                .padding(PiggySpacing.xl)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            .animation(.easeInOut(duration: 0.3), value: isVisible)
        }
    }
}

#Preview {
    OnboardingCoordinator(showDashboard: .constant(false))
        .environmentObject(AuthenticationService.shared)
        .environmentObject(GlobalLoadingManager.shared)
}