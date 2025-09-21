import SwiftUI

struct VipUpgradePromptView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var revenueCatManager: RevenueCatManager
    @EnvironmentObject private var globalLoading: GlobalLoadingManager
    
    var body: some View {
        ZStack {
            // Background
            PiggyGradients.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.piggyPrimary, Color.piggySecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "star.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Unlock More Idols")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("You've reached your free limit of 3 idols")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Benefits
                VStack(spacing: 16) {
                    benefitRow(icon: "person.3.fill", title: "Up to 6 Idols", description: "Follow more artists")
                    benefitRow(icon: "bell.fill", title: "Priority Alerts", description: "Never miss comebacks")
                    benefitRow(icon: "chart.line.uptrend.xyaxis", title: "Advanced Analytics", description: "Detailed spending insights")
                    benefitRow(icon: "sparkles", title: "Premium Features", description: "Exclusive tools & content")
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                )
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        upgradeToVip()
                    }) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 16, weight: .bold))

                            Text("Upgrade to VIP")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.piggyPrimary, Color.piggySecondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .disabled(globalLoading.isVisible)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Maybe Later")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 40)
        }
    }
    
    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.piggyPrimary)
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
    }
    
    private func upgradeToVip() {
        globalLoading.showRevenueCat()

        revenueCatManager.purchaseMonthlySubscription { success, error in
            DispatchQueue.main.async {
                globalLoading.hide()
                if success {
                    dismiss()
                } else {
                    // Handle error - could show an alert here
                    print("Purchase failed: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
}

#Preview {
    VipUpgradePromptView()
        .environmentObject(RevenueCatManager.shared)
        .environmentObject(GlobalLoadingManager.shared)
}