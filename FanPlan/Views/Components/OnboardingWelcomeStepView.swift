import SwiftUI

struct WelcomeStepView: View {
    @Binding var isAnimating: Bool
    let onNext: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            // Logo and App Name
            VStack(spacing: 16) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.piggyPrimary)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                
                Text("PiggyBong")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 1).delay(0.5), value: isAnimating)
            }
            
            // Welcome Message
            VStack(spacing: 16) {
                Text("Welcome to Your K-Pop Journey")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 1).delay(1.0), value: isAnimating)
                
                Text("Smart budgeting for the ultimate fan experience")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 1).delay(1.5), value: isAnimating)
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 16) {
                PiggyButton(
                    title: "Get Started",
                    action: onNext
                )
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.easeOut(duration: 1).delay(2.0), value: isAnimating)
                
                Button("Skip Introduction", action: onSkip)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 1).delay(2.2), value: isAnimating)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 100)
        }
        .padding(.top, 100)
        .padding(.horizontal, 32)
    }
}

// PiggyButton is defined in PiggyReusableComponents.swift

#Preview {
    WelcomeStepView(
        isAnimating: .constant(true),
        onNext: {},
        onSkip: {}
    )
    .background(PiggyGradients.background)
}