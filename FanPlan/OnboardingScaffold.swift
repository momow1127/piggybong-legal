import SwiftUI

// MARK: - Onboarding Scaffold
/// A reusable wrapper that provides consistent sticky button behavior for all onboarding screens
/// Eliminates manual padding and button positioning conflicts
struct OnboardingScaffold<Content: View>: View {
    let title: String
    let canProceed: Bool
    let showSkip: Bool
    let showButton: Bool
    let currentStep: OnboardingProgressStep?
    let action: () -> Void
    let onSkip: (() -> Void)?
    let content: () -> Content
    
    let showScrim: Bool
    let scrimHeight: CGFloat
    let scrimTopOpacity: Double
    let scrimBottomOpacity: Double
    
    init(
        title: String,
        canProceed: Bool = true,
        showSkip: Bool = false,
        showButton: Bool = true,
        currentStep: OnboardingProgressStep? = nil,
        action: @escaping () -> Void,
        onSkip: (() -> Void)? = nil,
        showScrim: Bool = false,
        scrimHeight: CGFloat = 28,
        scrimTopOpacity: Double = 0.06,
        scrimBottomOpacity: Double = 0.18,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.canProceed = canProceed
        self.showSkip = showSkip
        self.showButton = showButton
        self.currentStep = currentStep
        self.action = action
        self.onSkip = onSkip
        self.content = content
        self.showScrim = showScrim
        self.scrimHeight = scrimHeight
        self.scrimTopOpacity = scrimTopOpacity
        self.scrimBottomOpacity = scrimBottomOpacity
    }
    
    var body: some View {
        ZStack {
            // Full-screen gradient background
            PiggyGradients.background.ignoresSafeArea(.all)

            // Content with proper spacing
            VStack(spacing: 0) {
                // Progress bar removed - only 2 steps in onboarding

                content()
                
                // Spacer to push content up and make room for button
                if showButton {
                    Spacer().frame(height: buttonAreaHeight)
                }
            }
            
            // Floating sticky footer overlay (no background)
            if showButton {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        // Transparent sticky footer (dots removed)
                        stickyFooter
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Bulletproof Sticky Footer
    private var stickyFooter: some View {
        VStack(spacing: 0) {
            if showScrim {
                LinearGradient(
                    colors: [Color.black.opacity(scrimTopOpacity), Color.black.opacity(scrimBottomOpacity)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: scrimHeight)
            }
            
            // Button container with transparent background
            VStack(spacing: 16) {
                // Main action button
                Button(action: action) {
                    bulletproofButtonLabel
                }
                .disabled(!canProceed)
                .allowsHitTesting(canProceed)
                
                // Skip button with better visual separation
                if showSkip {
                    Button(action: { onSkip?() }) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 4) // Additional spacing for better visual hierarchy
                }
            }
            .padding(.horizontal, PiggySpacing.lg) // Consistent 20pt horizontal padding
            .padding(.top, 12)
            .padding(.bottom, dynamicBottomPadding) // Dynamic spacing above home indicator
            .frame(maxWidth: .infinity) // Full width
            .background(Color.clear) // Explicit transparent background
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    // MARK: - Bulletproof Button Label
    private var bulletproofButtonLabel: some View {
        Text(title)
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 24) // Internal padding for text breathing room
            .frame(height: 56) // Consistent height
            .frame(minWidth: 200, maxWidth: 350) // Adaptive width with sensible bounds
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: canProceed ? [Color.piggyPrimary, Color.piggySecondary] : [Color.gray, Color.gray.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .scaleEffect(canProceed ? 1.0 : 0.95)
            .animation(.easeInOut(duration: 0.1), value: canProceed)
    }
    
    // MARK: - Layout Helpers
    /// Calculate total height needed for button area
    private var buttonAreaHeight: CGFloat {
        var height: CGFloat = 0

        // Button area height
        height += 12 + 56 + 12 + dynamicBottomPadding // top + button + spacing + bottom
        
        // Skip button height (if shown)
        if showSkip {
            height += 24 // skip button height
        }
        
        return height
    }
    
    // MARK: - Safe-Area Helpers
    /// Returns an appropriate padding above the iOS home indicator.
    /// Devices with a home indicator (bottom safe inset ≈ 34pt) get extra breathing room.
    private var dynamicBottomPadding: CGFloat {
        let bottomInset = keyWindow?.safeAreaInsets.bottom ?? 0
        return bottomInset >= 34 ? 32 : 20
    }

    /// Best-effort way to access the current key window's safe area insets.
    private var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    // MARK: - Progress Indicator
    private func progressIndicator(currentStep: OnboardingProgressStep) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<OnboardingProgressStep.totalSteps, id: \.self) { index in
                Circle()
                    .fill(index <= currentStep.rawValue ? Color.piggyPrimary : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        PiggyGradients.background.ignoresSafeArea()
        
        OnboardingScaffold(
            title: "Continue",
            canProceed: true,
            showSkip: false,
            currentStep: .artistSelection,
            action: { print("Continue tapped") }
        ) {
            VStack {
                Spacer()
                Text("Sample Content")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }
}
