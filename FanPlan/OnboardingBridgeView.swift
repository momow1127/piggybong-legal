import SwiftUI
import UserNotifications

struct OnboardingBridgeView: View {
    @State private var showingFeatures = false
    @State private var currentFeature = 0
    @State private var isRequestingPermission = false
    
    let onContinue: () -> Void
    
    private let features = [
        BridgeFeature(
            icon: "brain.head.profile",
            title: "Smart Priority Assistant",
            description: "Get personalized advice from PiggyBot about your K-pop priorities",
            color: .piggyPrimary
        ),
        BridgeFeature(
            icon: "bell.badge.fill",
            title: "Smart Notifications",
            description: "Never miss comeback announcements or presale opportunities",
            color: .piggySecondary
        ),
        BridgeFeature(
            icon: "chart.line.uptrend.xyaxis",
            title: "Goal Tracking",
            description: "Watch your progress toward concert tickets and album collections",
            color: .piggyAccent
        ),
        BridgeFeature(
            icon: "heart.fill",
            title: "Priority Planning",
            description: "Make smart decisions about your favorite artists automatically",
            color: .budgetGreen
        )
    ]
    
    var body: some View {
        OnboardingScaffold(
            title: isRequestingPermission ? "Requesting..." : "Let's Go!",
            canProceed: !isRequestingPermission,
            showSkip: true,
            currentStep: nil, // Final step, no progress indicator
            action: requestNotificationPermission,
            onSkip: onContinue
        ) {
            VStack(spacing: 0) {
                    // Top spacing similar to other onboarding screens
                    Spacer()
                        .frame(height: 80)
                    
                    // Content with consistent padding - no manual bottom padding needed
                    VStack {
                        CompletionContent(
                            showingFeatures: $showingFeatures,
                            currentFeature: $currentFeature,
                            features: features
                        )
                    }
                    .padding(.horizontal, PiggySpacing.lg)
                    
                    Spacer()
                }
        }
        .onAppear {
            // Start animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showingFeatures = true
                
                // Animate features one by one
                for i in 0..<features.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2 + 1.4) {
                        currentFeature = i
                    }
                }
            }
        }
    }
    
    // MARK: - Notification Permission Request
    private func requestNotificationPermission() {
        isRequestingPermission = true
        
        Task {
            let center = UNUserNotificationCenter.current()
            
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                
                await MainActor.run {
                    isRequestingPermission = false
                    print(granted ? "✅ Notifications enabled" : "⚠️ Notifications denied")
                    onContinue()
                }
            } catch {
                await MainActor.run {
                    isRequestingPermission = false
                    print("❌ Notification permission error: \(error)")
                    onContinue()
                }
            }
        }
    }
}

// MARK: - Completion Content
struct CompletionContent: View {
    @Binding var showingFeatures: Bool
    @Binding var currentFeature: Int
    let features: [BridgeFeature]
    
    var body: some View {
        VStack(spacing: PiggySpacing.xl) {
            // Success message - no celebration icon
            VStack(spacing: PiggySpacing.sm) {
                Text("You're All Set!")
                    .font(PiggyFont.largeTitle)  // 24pt bold rounded
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.piggyTextPrimary, Color.piggyPrimary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)
                    .opacity(showingFeatures ? 1.0 : 0.0)
                    .animation(PiggyAnimations.standard.delay(0.2), value: showingFeatures)
                
                Text("Ready to start your K-pop journey")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))  // 18pt semibold
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(showingFeatures ? 1.0 : 0.0)
                    .animation(PiggyAnimations.standard.delay(0.4), value: showingFeatures)
                
                Text("Here's what you can do with Piggy Bong")
                    .font(PiggyFont.subheadline)  // 15pt regular
                    .foregroundColor(.piggyTextHint)
                    .multilineTextAlignment(.center)
                    .padding(.top, PiggySpacing.xs)
                    .opacity(showingFeatures ? 1.0 : 0.0)
                    .animation(PiggyAnimations.standard.delay(0.6), value: showingFeatures)
            }
            
            // Features preview
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: PiggySpacing.md) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    FeatureCard(
                        feature: feature,
                        isVisible: showingFeatures && currentFeature >= index
                    )
                }
            }
            .opacity(showingFeatures ? 1.0 : 0.0)
            .animation(PiggyAnimations.standard.delay(0.8), value: showingFeatures)
        }
    }
}

// MARK: - Supporting Views

struct FeatureCard: View {
    let feature: BridgeFeature
    let isVisible: Bool
    
    var body: some View {
        VStack(spacing: PiggySpacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill(feature.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(feature.color)
            }
            
            // Text
            VStack(spacing: PiggySpacing.xs) {
                Text(feature.title)
                    .font(PiggyFont.bodyEmphasized)
                    .foregroundColor(.piggyTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text(feature.description)
                    .font(PiggyFont.caption)
                    .foregroundColor(.piggyTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(PiggySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                .fill(Color.piggyCardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(PiggyAnimations.springBouncy, value: isVisible)
    }
}


// MARK: - Data Models

struct BridgeFeature {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Preview

#Preview {
    OnboardingBridgeView {
        print("Continue to notifications")
    }
}