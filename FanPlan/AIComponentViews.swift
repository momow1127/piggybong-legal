import SwiftUI

// MARK: - VIP Tip Card (Shown to subscribers)

struct VIPTipCard: View {
    let decision: PurchaseDecision
    let price: Double
    let remainingBudget: Double
    @State private var showDetails = false
    
    private var tip: VIPTip {
        VIPTip.getTip(for: decision, price: price, remainingBudget: remainingBudget)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("\(tip.icon) VIP Smart Tip")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                
                Button(action: { showDetails.toggle() }) {
                    Image(systemName: showDetails ? "chevron.up.circle.fill" : "info.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Tip message
            Text(tip.message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(2)
            
            // Details (expandable)
            if showDetails {
                Text("This personalized tip is based on your fan wallet balance and spending patterns.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [.purple.opacity(0.3), .pink.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.purple.opacity(0.5), .pink.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            VIPAnalytics.logTipShown(decision: decision, price: price)
        }
    }
}

// MARK: - VIP Tip Teaser (Shown to free users)

struct VIPTipTeaser: View {
    @Binding var showPaywall: Bool
    
    var body: some View {
        Button(action: { 
            showPaywall = true
            VIPAnalytics.logTeaserTapped()
        }) {
            ZStack {
                // Blurred background effect
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.2), .pink.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [.purple.opacity(0.3), .pink.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                // Blur overlay
                VisualEffectBlur(blurStyle: .systemThinMaterial)
                    .cornerRadius(16)
                    .opacity(0.9)
                
                // Content
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.purple)
                        
                        Text("VIP Smart Tip")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Text("Unlock personalized tips • 7-day free trial")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(16)
            }
            .frame(height: 80)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Monthly Check Limit View

struct MonthlyCheckLimitView: View {
    let remainingChecks: Int
    @Binding var showPaywall: Bool
    
    var body: some View {
        if remainingChecks <= 0 {
            VStack(spacing: 12) {
                Image(systemName: "hourglass")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                
                Text("Monthly limit reached")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("You've used all 3 free checks this month")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                Button(action: { showPaywall = true }) {
                    Text("Get Unlimited with VIP")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        } else if remainingChecks <= 1 {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                
                Text("\(remainingChecks) free check\(remainingChecks == 1 ? "" : "s") left this month")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Button("Go VIP") {
                    showPaywall = true
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.purple)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Visual Effect Blur Helper

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}