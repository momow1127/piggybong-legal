import SwiftUI

// MARK: - Welcome View
struct WelcomeView: View {
    let onNext: () -> Void
    @State private var isAnimating = false
    
    var body: some View {
        OnboardingScaffold(
            title: "Start My Fan Journey",
            canProceed: true,
            showSkip: false,
            currentStep: nil,
            action: onNext
        ) {
            ZStack {
                // Decorative layer group (sits above OnboardingScaffold gradient)
                ZStack {
                    // Full background image on top of gradient
                    Image("fanchant")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .opacity(0.15)
                        .blur(radius: 2)
                        .ignoresSafeArea()

                    // Floating sparkles animation (TODO: implement FloatingSparkles component)
                    // FloatingSparkles()
                    //     .allowsHitTesting(false)
                    //     .opacity(0.7)
                }
                .allowsHitTesting(false)
                
                // Content layer - let OnboardingScaffold handle spacing
                WelcomeContent(isAnimating: $isAnimating)
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill available space
                    .padding(.horizontal, PiggySpacing.lg)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Welcome Content
struct WelcomeContent: View {
    @Binding var isAnimating: Bool
    @State private var glowIntensity: Double = 0.3
    // @State private var waveAngle: Double = 0  // Removed - testing without rotation
    @State private var bounceOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: PiggySpacing.xl) {
                // Animated Piggy Lightstick
                ZStack {
                    // Outer glow effect
                    Image("piggy-lightstick")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 320, height: 320)
                        .shadow(color: Color.piggyPrimary.opacity(glowIntensity * 0.6), radius: 40, x: 0, y: 0)
                        .shadow(color: Color.piggySecondary.opacity(glowIntensity * 0.4), radius: 30, x: 0, y: 0)
                        .blur(radius: 2)
                    
                    // Inner glow effect
                    Image("piggy-lightstick")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 320, height: 320)
                        .shadow(color: Color.white.opacity(glowIntensity * 0.3), radius: 15, x: 0, y: 0)
                    
                    // Main lightstick image
                    Image("piggy-lightstick")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 320, height: 320)
                }
                // Removed rotation to test centering - only vertical bounce
                .offset(y: bounceOffset)
                .onAppear {
                    // Rotation animation REMOVED for testing
                    // withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    //     waveAngle = 5
                    // }
                    
                    // Gentle vertical bounce
                    withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                        bounceOffset = -5
                    }
                    
                    // Pulsing glow effect
                    withAnimation(.easeIn(duration: 1.5).repeatForever(autoreverses: true)) {
                        glowIntensity = 0.9
                    }
                }
                
                
                // Welcome text
                VStack(spacing: PiggySpacing.sm) {
                    Text("Welcome to Piggy Bong")
                        .font(PiggyFont.largeTitle)
                        .foregroundColor(.piggyTextPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, PiggySpacing.md)
                    
                    Text("Your K-pop Fan Manager")
                        .font(PiggyFont.title3)
                        .foregroundColor(.piggyTextPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, PiggySpacing.md)
                    
                    Text("Always stay prepared for your idols comeback.")
                        .font(PiggyFont.subheadline)
                        .foregroundColor(.piggyTextHint)
                        .multilineTextAlignment(.center)
                        .padding(.top, PiggySpacing.xs)
                        .padding(.horizontal, PiggySpacing.md)
                }
        }
        .frame(maxWidth: .infinity) // Ensure content is centered horizontally
        .multilineTextAlignment(.center) // Ensure all text content is centered
    }
}

#Preview {
    WelcomeView(onNext: {})
}
