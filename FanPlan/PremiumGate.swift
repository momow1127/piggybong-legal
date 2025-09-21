import SwiftUI

struct PremiumGate<Content: View>: View {
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @State private var showPaywall = false
    
    let content: () -> Content
    let fallbackContent: (() -> AnyView)?
    let requiresPremium: Bool
    
    init(
        requiresPremium: Bool = true,
        fallbackContent: (() -> AnyView)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.requiresPremium = requiresPremium
        self.fallbackContent = fallbackContent
        self.content = content
    }
    
    var body: some View {
        Group {
            if !requiresPremium || revenueCatManager.isSubscriptionActive || revenueCatManager.hasValidPromoCode {
                content()
            } else {
                if let fallbackContent = fallbackContent {
                    fallbackContent()
                } else {
                    premiumRequiredView
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            SimplePaywallView()
        }
    }
    
    private var premiumRequiredView: some View {
        VStack(spacing: 16) {
            // Premium icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.pink]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("Premium Feature")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Upgrade to Stan Plus Premium to unlock this feature")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                showPaywall = true
            }) {
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                    
                    Text("Upgrade to Premium")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.pink]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(24)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }
}

// MARK: - Premium Feature Card
struct PremiumFeatureCard: View {
    let title: String
    let description: String
    let iconName: String
    let action: () -> Void
    
    @State private var showPaywall = false
    
    var body: some View {
        Button(action: {
            showPaywall = true
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Premium badge
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                            
                            Text("PREMIUM")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.pink]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .sheet(isPresented: $showPaywall) {
            SimplePaywallView()
        }
    }
}

// MARK: - Premium Banner
struct PremiumBanner: View {
    @State private var showPaywall = false
    
    var body: some View {
        Button(action: {
            showPaywall = true
        }) {
            HStack(spacing: 12) {
                // Gradient circle with crown
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.pink]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upgrade to Stan Plus Premium")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Unlock unlimited artists & AI suggestions")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.3)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .sheet(isPresented: $showPaywall) {
            SimplePaywallView()
        }
    }
}

// MARK: - Usage Examples and Previews
#Preview("Premium Gate") {
    VStack(spacing: 20) {
        PremiumGate(requiresPremium: true) {
            Text("This is premium content!")
                .foregroundColor(.white)
                .padding()
                .background(Color.green.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        
        PremiumFeatureCard(
            title: "AI Fan Concierge",
            description: "Get personalized suggestions for your favorite groups",
            iconName: "brain.head.profile",
            action: {}
        )
        
        PremiumBanner()
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}