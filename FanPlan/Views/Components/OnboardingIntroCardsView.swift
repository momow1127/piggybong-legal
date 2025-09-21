import SwiftUI

struct IntroCardsView: View {
    let onNext: () -> Void
    let onSkip: () -> Void
    
    @State private var currentCard = 0
    @State private var isAnimating = false
    
    private let introCards = [
        IntroCard(
            icon: "star.leadinghalf.filled",
            title: "Focus Fan Priorities",
            description: "Manage and prioritize your favorite artists, comebacks, and events that matter most to you.",
            color: .piggyPrimary
        ),
        IntroCard(
            icon: "brain.head.profile",
            title: "AI Fan Insights",
            description: "Get personalized recommendations and smart insights about your K-pop preferences and fandom journey.",
            color: .piggySecondary
        ),
        IntroCard(
            icon: "newspaper.fill",
            title: "Latest K-pop News",
            description: "Stay updated with breaking news, comebacks, and exclusive updates from the K-pop world.",
            color: .piggyAccent
        )
    ]
    
    var body: some View {
        OnboardingScaffold(
            title: "Continue",
            canProceed: true,
            showSkip: true,
            currentStep: nil,
            action: {
                if currentCard == introCards.count - 1 {
                    onNext()
                } else {
                    withAnimation {
                        currentCard += 1
                    }
                }
            },
            onSkip: onSkip
        ) {
            VStack(spacing: 0) {
                    // Top spacing
                    Spacer()
                        .frame(height: 80)
                    
                    // Card Content with consistent spacing
                    VStack(spacing: 40) {
                        // Card TabView
                        TabView(selection: $currentCard) {
                            ForEach(0..<introCards.count, id: \.self) { index in
                                IntroCardView(card: introCards[index])
                                    .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .animation(.easeInOut(duration: 0.5), value: currentCard)
                        
                        // Progress Indicator
                        HStack(spacing: 8) {
                            ForEach(0..<introCards.count, id: \.self) { index in
                                Circle()
                                    .fill(index <= currentCard ? Color.white : Color.white.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(index == currentCard ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 0.3), value: currentCard)
                            }
                        }
                    }
                    .padding(.horizontal, PiggySpacing.lg)
                    
                    Spacer()
                }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct IntroCard {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct IntroCardView: View {
    let card: IntroCard
    
    var body: some View {
        VStack(spacing: 32) {
            // Icon
            ZStack {
                Circle()
                    .fill(card.color.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: card.icon)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(card.color)
            }
            
            // Content
            VStack(spacing: 16) {
                Text(card.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(card.description)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 24)
            }
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    IntroCardsView(
        onNext: {},
        onSkip: {}
    )
}