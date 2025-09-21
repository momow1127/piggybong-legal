import SwiftUI

// MARK: - Priority Manager Section View Component
struct PriorityManagerSectionView: View {
    let data: FanDashboardData
    let subscriptionService: SubscriptionService
    let dashboardService: FanDashboardService
    @Binding var selectedSmartPickEvent: SmartFanPickEvent?
    @Binding var showPriorityAdjustment: Bool
    @Binding var showPurchaseCalculator: Bool
    @Binding var showPaywall: Bool
    
    var body: some View {
        if subscriptionService.isVIP {
            FanPriorityManagerView(
                smartFanPickService: SmartFanPickService.shared,
                subscriptionService: subscriptionService,
                dashboardService: dashboardService,
                selectedSmartPickEvent: $selectedSmartPickEvent,
                showPriorityAdjustment: $showPriorityAdjustment,
                showPurchaseCalculator: $showPurchaseCalculator
            )
        } else {
            // Non-VIP static fallback - exceptional case with manual button styling
            Button(action: { 
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                showPaywall = true 
            }) {
                HStack(spacing: PiggySpacing.sm) { // Use design token for 8pt spacing
                    // Left content - Fixed width to prevent truncation
                    VStack(alignment: .leading, spacing: PiggySpacing.md) {
                        // Title - Changed to "Piggy Bong AI" with AI icon after
                        HStack(spacing: PiggySpacing.xs) {
                            Text("Piggy Bong AI")
                                .font(PiggyFont.sectionTitle)
                                .foregroundColor(.white)
                            
                            Image("AI")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .foregroundColor(.white)
                        }
                        .lineLimit(1)
                        
                        // Description - Fix truncation issue
                        Text("Get personalized tips to set better priorities for your idols")
                            .font(PiggyFont.body)    // Use design system font instead of hardcoded
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(3) // Allow 3 lines if needed
                            .minimumScaleFactor(0.9) // Allow slight scaling to fit
                        
                        // Manual secondary button styling - exceptional case
                        HStack(spacing: PiggySpacing.sm) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.piggyPrimary)
                            
                            Text("Upgrade to VIP")
                                .font(PiggyFont.captionEmphasized) // 13pt semibold rounded
                                .foregroundColor(.piggyPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8) // Allow scaling if needed
                        }
                        .padding(.horizontal, PiggySpacing.inputPadding) // Use design system token: 14pt
                        .padding(.vertical, PiggySpacing.inputVertical) // Use design system token: 12pt
                        .background(.white)
                        .cornerRadius(PiggyBorderRadius.button) // Already using design system token
                        .overlay(
                            RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                                .stroke(Color.piggyTextSecondary.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .frame(width: 160) // Reduced width to make room for pig image
                    
                    Spacer() // Push pig to the right
                    
                    // Right visual element - Pig with proper clipping
                    ZStack {
                        Image("piggy-lightstick-crown")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 160) // Much smaller to fit properly
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 1, y: 1)
                            .shadow(color: .white.opacity(0.6), radius: 8, x: 0, y: 0)
                            .shadow(color: .white.opacity(0.3), radius: 12, x: 0, y: 0)
                    }
                    .frame(width: 120, alignment: .center) // Match the image width
                }
                .padding(PiggySpacing.md)  // Consistent 16pt padding using design token
                .background(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                        .fill(PiggyGradients.primaryButton)
                        .overlay(
                            RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .mask(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.card)
                )
                .shadow(
                    color: Color.piggyPrimary.opacity(0.4),
                    radius: 20,
                    x: 0,
                    y: 10
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview
struct PriorityManagerSectionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: PiggySpacing.lg) {
            // VIP Preview
            PriorityManagerSectionView(
                data: FanDashboardData.mock,
                subscriptionService: SubscriptionService.shared,
                dashboardService: FanDashboardService.shared,
                selectedSmartPickEvent: .constant(nil),
                showPriorityAdjustment: .constant(false),
                showPurchaseCalculator: .constant(false),
                showPaywall: .constant(false)
            )
            
            // Non-VIP Preview
            PriorityManagerSectionView(
                data: FanDashboardData.mock,
                subscriptionService: {
                    let service = SubscriptionService.shared
                    service.isVIP = false
                    service.subscriptionStatus = .free
                    return service
                }(),
                dashboardService: FanDashboardService.shared,
                selectedSmartPickEvent: .constant(nil),
                showPriorityAdjustment: .constant(false),
                showPurchaseCalculator: .constant(false),
                showPaywall: .constant(false)
            )
        }
        .padding()
        .background(PiggyGradients.background)
    }
}